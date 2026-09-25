#!/usr/bin/env python3
"""aimap: AI Models and Providers price comparison.

Reads ~/.aimap.toml, fetches <base_url>/models from every provider
using a token from tipi.py, and prints one column per provider with
the price per million tokens of each configured model. Per row the
lowest price is green, the highest red.

Some providers serve a model without publishing its price, and many
state no cache price at all. Those fall back to what models.dev holds
for that same provider. A model with no price in either source shows
as n/a, a missing cache price as a dash.

Prices are converted to one currency using reference rates from
frankfurter.dev. Model lists, the models.dev catalog and the rates are
cached in ~/.cache/aimap for 24 hours; --update fetches them again.

By default each cell holds one blended price, weighting cache hit,
input and output tokens 7:2:1, the mix Artificial Analysis states for
its blended price. --ratio sets another weighting: three terms keep
the cache share, two drop it, so --ratio 3:1 is the older input to
output convention and --ratio 15:1 matches the traffic OpenRouter
reports across its own platform. Where no cache price is known the
input price stands in for it, marked with a tilde.

--verbose shows the three prices side by side instead of the blend.

Under each provider name is the credit left on that account, where it
serves one. A few known paths are tried and the first number that
looks like a balance is kept, so most providers need no config. These
are held for an hour, and refreshed by --update.

A configured evaluator adds an int and a code column, holding its
intelligence and coding index for the model. Where it rates the model
at more than one effort level, a sel column shows the lowest level
that keeps a share of the best int score, 95 percent unless --keep
sets another. --effort shows int and code at a lower effort level,
or the closest level below it that the evaluator rates. A model the
evaluator rates at no named level keeps its one score, but only
without --effort, as its score at a lower level is unknown.

A provider set to pricing = "energy" bills the power its GPUs draw,
not tokens, so its listed token prices are not what the account pays.
Those models are priced from the provider's own usage api instead:
requests are grouped per model into prompt-size bands, each band is
reduced to its median, and cost = input * a + output * b is fitted
over them, then scaled so it reproduces what was actually billed.
Where the traffic cannot separate input from output the listed ratio
is kept and only the level comes from the spend. Such cells carry a
star. The whole spend lands on fresh tokens, so a cache hit adds
nothing on top.

The usage history is cached in ~/.cache/aimap and never expires,
since past requests do not change. --update tops it up and walks
further back, a window at a time, until the history runs out.

--sort name orders rows alphabetically, --sort price by the cheapest
provider in each row, using the first number a cell shows. --sort int
and --sort code put the highest score first, spelled out as
intelligence and coding if you prefer. Without it rows keep the order
of the config.

Config format:

  [[model_providers]]
  name = "openrouter"
  base_url = "https://openrouter.ai/api/v1"
  auth_keys = ["openrouter", "rubins-raaf-api-key"]  # tipi key, user
  user_agent = "..."   # optional, some endpoints filter on it
  models_dev = "..."   # optional, its id on models.dev if it differs
  pricing = "energy"   # optional, default "token"
  usage_path = "..."   # optional, default /usage/requests
  balance_path = "..." # optional, where credit left is served
  # Or, for a site that only shows credit behind a login:
  balance_login = ["tipi-key", "user"]   # password from tipi.py
  balance_token_url = "..."              # trades password for a token
  balance_account_url = "..."            # account page the token reads
  balance_field = "credits"              # its key in that page
  # Or, for credit shown only to a logged-in browser:
  balance_cookie = "host/name"           # session cookie from Firefox
  balance_api_url = "..."                # json endpoint it unlocks
  balance_field = "credits"              # its key in that reply
  balance_headers = { x-org-id = "..." } # optional request headers
  balance_scale = 1e8                    # optional currency divisor

  [[model_evaluators]]
  name = "artificial-analysis"                       # also the cache file
  base_url = "https://artificialanalysis.ai/api/v2/data/llms/models"
  auth_keys = ["artificialanalysis", "default-api-token"]
  auth_header = "x-api-key"   # optional, default is Authorization

  [[models]]
  name = "deepseek-v4.1-flash"
  aliases = ["deepseek-v4-1-flash"]

Usage:
  aimap.py [-v | -r 15:1] [-s price] [-e high] [-k 90] [-b EUR] [-u]
           [--no-fx] [--no-color] [-t 20] [-c FILE]
"""

import argparse
import glob
import json
import math
import os
import shutil
import sqlite3
import statistics
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone

import tomllib

CONFIG = os.path.expanduser("~/.aimap.toml")
CACHE = os.path.expanduser("~/.cache/aimap")
TIPI = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tipi.py")
FX_URL = "https://api.frankfurter.dev/v1/latest?base={}"
MODELS_DEV_URL = "https://models.dev/api.json"
USER_AGENT = "aimap/1.0"
CACHE_TTL = 24 * 60 * 60
# Credit left moves with every request, so it is kept briefly.
BALANCE_TTL = 60 * 60
BALANCE_PATHS = ["/billing/balance", "/balance", "/credits", "/manage/balance"]
# Names a provider gives the money left, most specific first.
BALANCE_KEYS = [
    "credits_remaining_usd",
    "dollar_balance",
    "current_balance",
    "paid_balance",
    "balance_usd",
    "credit_balance",
    "balance",
]
# Token mix for a blended price, cache hit to input to output. This
# is the ratio Artificial Analysis states for its blended figure.
DEFAULT_RATIO = "7:2:1"
# Effort levels an evaluator rates a model at, lowest first.
EFFORTS = ["low", "medium", "high", "xhigh", "max"]
DEFAULT_KEEP = 95.0

RESET = "\033[0m"
RED = "\033[31m"
GREEN = "\033[32m"
DIM = "\033[2m"
GUESSED = "~"
MEASURED = "*"
ONLY = "+"

# Energy billed accounts are priced from the usage api. The window it
# serves is capped, so history is walked in chunks of that size.
USAGE_PATH = "/usage/requests"
USAGE_DAYS = 30
USAGE_LIMIT = 200
USAGE_PAGES = 400
USAGE_PAUSE = 1.0
USAGE_RETRIES = 6
# Two empty chunks in a row end the walk, so one quiet month does not
# look like the start of history.
USAGE_EMPTY_STOP = 2

# Prompt sizes that split requests into bands, in tokens, and how much
# traffic a fit needs before it is trusted.
BANDS = [0, 500, 2000, 8000, 32000]
MIN_REQUESTS = 20
MIN_ROWS = 3
# Reject a fit whose output to input ratio is off the listed one by
# more than this, which keeps a noisy window from inventing a split.
RATIO_SPREAD = 4.0

# Price fields seen in the wild, with the factor that turns them
# into a price per million tokens. Order matters: per-million keys
# come first, since some providers publish both forms.
PRICE_KEYS = [
    ("input_per_million", "output_per_million", 1.0),
    ("prompt_per_million", "completion_per_million", 1.0),
    ("input_token", "output_token", 1.0),
    ("input_cost_per_token", "output_cost_per_token", 1e6),
    ("prompt", "completion", 1e6),
]

# Cache read fields, searched on their own because a provider can
# state the pair per million and the cache price per token.
CACHE_KEYS = [
    ("cached_input_per_million", 1.0),
    ("cache_read_cost", 1.0),
    ("cache_read_input_token_cost", 1e6),
    ("input_cache_read", 1e6),
]


def warn(msg):
    print(f"warn: {msg}", file=sys.stderr)


def load_config(path):
    with open(path, "rb") as f:
        return tomllib.load(f)


def get_json(url, timeout, token=None, user_agent=USER_AGENT, auth_header=None,
             extra=None):
    headers = {"Accept": "application/json", "User-Agent": user_agent}
    if token and auth_header and auth_header.lower() != "authorization":
        headers[auth_header] = token
    elif token:
        headers["Authorization"] = f"Bearer {token}"
    headers.update(extra or {})
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.load(resp), None
    except urllib.error.HTTPError as e:
        try:
            body = e.read().decode()[:120]
        except (OSError, ValueError, UnicodeDecodeError):
            body = ""
        return None, f"HTTP {e.code} {body}".strip()
    except (urllib.error.URLError, OSError, ValueError) as e:
        return None, str(e)[:120]


def tipi_secret(keys):
    """The secret tipi.py holds for these lookup keys, or None."""
    if not keys:
        return None
    try:
        out = subprocess.run(
            [sys.executable, TIPI, *keys],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    return out.stdout.strip() if out.returncode == 0 else None


def get_token(provider):
    """Ask tipi.py for the provider token, using its auth_keys."""
    keys = [str(k) for k in provider.get("auth_keys", [])]
    if not keys:
        return None, None
    token = tipi_secret(keys)
    if not token:
        return None, f"tipi has no entry for {' '.join(keys)}"
    return token, None


def number(value):
    if value is None or isinstance(value, bool):
        return None
    try:
        result = float(value)
    except (TypeError, ValueError):
        return None
    return result if math.isfinite(result) else None


def cache_of(pricing):
    """Cache read price per million tokens, when published."""
    for key, factor in CACHE_KEYS:
        value = number(pricing.get(key))
        if value is not None and value >= 0:
            return value * factor
    return None


def price_of(entry):
    """Input, output, cache and currency per million tokens, or None."""
    meta = entry.get("metadata")
    sources = [entry.get("pricing")]
    if isinstance(meta, dict):
        sources.append(meta.get("pricing"))
    for src in sources:
        if not isinstance(src, dict):
            continue
        for in_key, out_key, factor in PRICE_KEYS:
            low, high = number(src.get(in_key)), number(src.get(out_key))
            if low is None or high is None or low < 0 or high < 0:
                continue
            currency = str(src.get("currency") or "USD").upper()
            return low * factor, high * factor, cache_of(src), currency
    return None


def squash(name):
    """Separator free form, so qwen-3.8-27b meets qwen3.8-27b."""
    return "".join(c for c in name.lower() if c.isalnum())


def slugs(model_id):
    """Names an entry can be matched by: full id and bare name."""
    base = model_id.lower()
    # Drop a trailing region tag such as @eu, but keep an id that
    # has an @ inside a path, like cloudflare/@cf/zai-org/glm-5.3.
    head, at, tail = base.rpartition("@")
    if at and "/" not in tail:
        base = head
    names = {base}
    if "/" in base:
        names.add(base.rsplit("/", 1)[1])
    return names | {squash(name) for name in names}


def model_items(payload):
    """The model list from a /models reply, or None if it has none."""
    if isinstance(payload, dict):
        for key in ("data", "models"):
            if isinstance(payload.get(key), list):
                return payload[key]
    return None


def index_models(payload):
    """Map every slug a provider serves to its prices."""
    items = [e for e in (model_items(payload) or []) if isinstance(e, dict)]
    index = {}
    for entry in items:
        model_id = entry.get("id")
        if not isinstance(model_id, str):
            continue
        price = price_of(entry)
        for slug in slugs(model_id):
            index.setdefault(slug, []).append(price)
    return index


def resolve(index, catalog, names):
    """Cheapest price across the slugs a model is known by.

    A slug the provider serves without a price falls back to the
    curated one for that same slug, so a free endpoint listed next
    to a paid one still counts.
    """
    state, best, slug = "absent", None, None
    for name in names:
        hits = index.get(name)
        if hits is None:
            continue
        state = "unknown"
        for price in hits:
            if price is None:
                price = catalog_price(catalog, {name})
            if price is None:
                continue
            if best is None or price[:2] < best[:2]:
                best, slug = price, name
    if best is None:
        return state, None
    # The pair can come from the provider while only models.dev
    # states what a cache hit costs.
    if best[2] is None:
        listed = catalog_price(catalog, {slug})
        if listed and listed[2] is not None and listed[3] == best[3]:
            best = (best[0], best[1], listed[2], best[3])
    return "ok", best


def index_catalog(catalog, provider_id):
    """Slug to price map for one provider in the models.dev data."""
    entry = catalog.get(provider_id) if isinstance(catalog, dict) else None
    models = entry.get("models") if isinstance(entry, dict) else None
    index = {}
    if not isinstance(models, dict):
        return index
    for model_id, entry in models.items():
        cost = entry.get("cost") if isinstance(entry, dict) else None
        if not isinstance(cost, dict):
            continue
        low, high = number(cost.get("input")), number(cost.get("output"))
        if low is None or high is None:
            continue
        cache = number(cost.get("cache_read"))
        for slug in slugs(str(model_id)):
            index.setdefault(slug, []).append((low, high, cache, "USD"))
    return index


def catalog_price(index, names):
    """Cheapest curated price for a model, or None if not listed."""
    hits = [p for name in names for p in index.get(name, [])]
    return min(hits, key=lambda p: (p[0], p[1])) if hits else None


def cache_file(name):
    safe = "".join(c if c.isalnum() or c in "-_." else "-" for c in name)
    return os.path.join(CACHE, f"{safe}.json")


def cache_read(name, max_age):
    """Cached payload, or None when absent, stale or unreadable."""
    if max_age <= 0:
        return None
    path = cache_file(name)
    try:
        if time.time() - os.path.getmtime(path) > max_age:
            return None
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def cache_write(name, payload):
    try:
        os.makedirs(CACHE, exist_ok=True)
        with open(cache_file(name), "w") as f:
            json.dump(payload, f)
    except OSError as e:
        warn(f"cannot cache {name}: {e}")


def models_dev(timeout, max_age):
    """Curated catalog, used where a provider publishes no price."""
    cached = cache_read("models-dev", max_age)
    if isinstance(cached, dict):
        return cached
    payload, err = get_json(MODELS_DEV_URL, timeout)
    if err or not isinstance(payload, dict):
        warn(f"models.dev unavailable: {err or 'unexpected response'}")
        return {}
    cache_write("models-dev", payload)
    note("models.dev: fetched")
    return payload


def balance_of(payload):
    """Credit left and its currency, whatever the payload calls it."""
    if not isinstance(payload, dict):
        return None
    currency = str(payload.get("currency") or "USD").upper()
    total = number(payload.get("total_credits"))
    used = number(payload.get("total_usage"))
    if total is not None and used is not None:
        return total - used, currency
    for key in BALANCE_KEYS:
        value = number(payload.get(key))
        if value is not None:
            return value, currency
    for value in payload.values():
        for item in value if isinstance(value, list) else [value]:
            if isinstance(item, dict):
                found = balance_of(item)
                if found is not None:
                    return found
    return None


def post_json(url, obj, timeout, token=None):
    """POST a json body and read a json reply."""
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": USER_AGENT,
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(
        url, data=json.dumps(obj).encode(), headers=headers, method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.load(resp), None
    except urllib.error.HTTPError as e:
        return None, f"HTTP {e.code}"
    except (urllib.error.URLError, OSError, ValueError) as e:
        return None, str(e)[:120]


def login_balance(provider, timeout):
    """Balance from a site login, for accounts with no key-auth api.

    The account password is traded for a bearer token, which then
    reads the account page. Configured with balance_login, the tipi
    key and user for the password.
    """
    login = provider.get("balance_login")
    if not isinstance(login, list) or len(login) < 2:
        return None
    password = tipi_secret([str(k) for k in login])
    if not password:
        warn(f"{provider.get('name', '?')}: no balance login password")
        return None
    token_url = str(provider.get("balance_token_url") or "")
    account_url = str(provider.get("balance_account_url") or "")
    field = str(provider.get("balance_field") or "credits")
    if not token_url or not account_url:
        return None
    reply, err = post_json(
        token_url, {"username": login[1], "password": password}, timeout
    )
    token = reply.get("access") if isinstance(reply, dict) else None
    if err or not token:
        warn(f"{provider.get('name', '?')}: balance login failed: {err or 'no token'}")
        return None
    payload, err = get_json(account_url, timeout, token)
    value = number(payload.get(field)) if isinstance(payload, dict) else None
    if not isinstance(payload, dict) or value is None:
        warn(f"{provider.get('name', '?')}: no {field} in account: {err or 'absent'}")
        return None
    return value, str(payload.get("currency") or "USD").upper()


def firefox_cookie(spec):
    """Value of a host/name cookie from the Firefox profile, or None."""
    host, _, name = str(spec).partition("/")
    if not host or not name:
        return None
    dbs = glob.glob(os.path.expanduser("~/.mozilla/firefox/*/cookies.sqlite"))
    for path in dbs:
        # Firefox holds new cookies in the WAL, so read a copy of both.
        with tempfile.TemporaryDirectory() as tmp:
            copy = os.path.join(tmp, "cookies.sqlite")
            try:
                shutil.copy(path, copy)
                if os.path.exists(path + "-wal"):
                    shutil.copy(path + "-wal", copy + "-wal")
                db = sqlite3.connect(copy)
                try:
                    row = db.execute(
                        "select value from moz_cookies where host = ? and name = ?",
                        (host, name),
                    ).fetchone()
                finally:
                    db.close()
            except (OSError, sqlite3.Error):
                continue
        if row and row[0]:
            return row[0]
    return None


def cookie_balance(provider, timeout):
    """Get balance from with help from cookie in Firefox.

    For a site that shows credit only to a logged-in browser. Reads
    the cookie from Firefox. If no valid cookie, returns nothing.
    """
    name = str(provider.get("name", "?"))
    spec = str(provider.get("balance_cookie") or "")
    cookie = firefox_cookie(spec)
    url = str(provider.get("balance_api_url") or "")
    field = str(provider.get("balance_field") or "")
    if not cookie or not url or not field:
        return None
    headers = {"Cookie": f"{spec.partition('/')[2]}={cookie}"}
    headers.update(provider.get("balance_headers") or {})
    payload, err = get_json(url, timeout, extra=headers)
    value = number(payload.get(field)) if isinstance(payload, dict) else None
    if value is None:
        warn(f"{name}: no {field} in balance: {err or 'login expired?'}")
        return None
    return value / (number(provider.get("balance_scale")) or 1.0), "USD"


def get_balance(provider, timeout, max_age):
    """What is left to spend at a provider, or None if it says."""
    name = str(provider.get("name", "?"))
    cached = cache_read(f"balance-{name}", max_age)
    if isinstance(cached, dict) and "balance" in cached:
        return cached["balance"], cached.get("currency") or "USD"
    note(f"{name}: fetching balance")
    base_url = provider.get("base_url")
    found = None
    if provider.get("balance_cookie"):
        found = cookie_balance(provider, timeout)
    elif provider.get("balance_login"):
        found = login_balance(provider, timeout)
    elif base_url:
        token, err = get_token(provider)
        if not err:
            configured = provider.get("balance_path")
            paths = [str(configured)] if configured else BALANCE_PATHS
            for path in paths:
                payload, err = get_json(
                    str(base_url).rstrip("/") + path,
                    timeout,
                    token,
                    str(provider.get("user_agent") or USER_AGENT),
                )
                if err or not payload:
                    continue
                found = balance_of(payload)
                if found is not None:
                    break
    value, currency = found if found else (None, "USD")
    # Remember a provider with no balance api too, so the paths are
    # not tried again on every run.
    cache_write(f"balance-{name}", {"balance": value, "currency": currency})
    return value, currency


def balances(providers, timeout, max_age, base, rates):
    """Credit left per provider, restated in the base currency."""
    with ThreadPoolExecutor(max_workers=8) as pool:
        found = list(pool.map(lambda p: get_balance(p, timeout, max_age), providers))
    credit = {}
    for provider, (value, currency) in zip(providers, found):
        rate = 1.0 if currency == base else rates.get(currency)
        credit[str(provider.get("name", "?"))] = (
            None if value is None or not rate else value / rate
        )
    return credit


def note(msg):
    """Progress for the long running fetches, so -u is not silent."""
    print(msg, file=sys.stderr)


def get_usage_page(url, token, timeout):
    """One page of the usage api, waiting out a rate limit."""
    headers = {
        "Accept": "application/json",
        "User-Agent": USER_AGENT,
        "Authorization": f"Bearer {token}",
    }
    for attempt in range(USAGE_RETRIES):
        req = urllib.request.Request(url, headers=headers, method="GET")
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return json.load(resp), None
        except urllib.error.HTTPError as e:
            if e.code != 429:
                return None, f"HTTP {e.code}"
            delay = number(e.headers.get("Retry-After")) or 2**attempt
            note(f"  rate limited, waiting {delay:.0f}s")
            time.sleep(min(delay, 60))
        except (urllib.error.URLError, OSError, ValueError) as e:
            return None, str(e)[:120]
    return None, "rate limited"


def fetch_window(base_url, path, token, start, end, timeout):
    """Every request the api lists in one window."""
    query = urllib.parse.urlencode(
        {
            "limit": USAGE_LIMIT,
            "start_date": start.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "end_date": end.strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
    )
    url = base_url.rstrip("/") + path
    rows, cursor, accounting, pages = [], None, None, 0
    while pages < USAGE_PAGES:
        page = f"{url}?{query}"
        if cursor:
            page += "&cursor=" + urllib.parse.quote(cursor, safe="")
        payload, err = get_usage_page(page, token, timeout)
        if err or not isinstance(payload, dict):
            return rows, accounting, err or "unexpected response"
        rows += payload.get("requests") or []
        accounting = accounting or payload.get("accounting_method")
        cursor = payload.get("next_cursor")
        pages += 1
        if not cursor:
            break
        time.sleep(USAGE_PAUSE)
    return rows, accounting, None


def update_usage(provider, cached, timeout):
    """Merge new requests into the cache, oldest history included.

    The api caps how wide a window may be, so history is walked one
    chunk at a time until it runs out. Where that walk finished is
    remembered, so later runs only top up the recent end.
    """
    name = str(provider.get("name", "?"))
    base_url = provider.get("base_url")
    token, err = get_token(provider)
    if err or not base_url:
        warn(f"{name}: {err or 'no base_url'}")
        return cached
    path = str(provider.get("usage_path") or USAGE_PATH)
    rows = {r["request_id"]: r for r in cached.get("requests", []) if "request_id" in r}
    accounting = cached.get("accounting_method")
    span = timedelta(days=USAGE_DAYS)
    now = datetime.now(timezone.utc)

    # Forward from the newest row held, or the whole window when the
    # cache is empty.
    newest = max(
        (r["created_at"] for r in rows.values() if r.get("created_at")), default=None
    )
    start = now - span
    if newest:
        start = max(start, datetime.fromisoformat(newest) - timedelta(minutes=5))
    note(f"{name}: fetching usage since {start:%Y-%m-%d %H:%M}")
    fresh, method, err = fetch_window(base_url, path, token, start, now, timeout)
    if err:
        warn(f"{name}: usage api: {err}")
    accounting = method or accounting
    added = sum(1 for r in fresh if r.get("request_id") not in rows)
    rows.update({r["request_id"]: r for r in fresh if "request_id" in r})
    note(f"{name}: {len(fresh)} requests, {added} new")

    # Backwards until the history runs out, picking up where a past
    # run stopped.
    edge = cached.get("walked_to")
    walked = datetime.fromisoformat(edge) if edge else now - span
    empty = 0
    while not cached.get("complete") and empty < USAGE_EMPTY_STOP:
        probe = walked - span
        note(f"{name}: walking back to {probe:%Y-%m-%d}")
        older, _, err = fetch_window(base_url, path, token, probe, walked, timeout)
        if err:
            warn(f"{name}: usage api: {err}")
            break
        walked = probe
        if not older:
            empty += 1
            continue
        empty = 0
        added = sum(1 for r in older if r.get("request_id") not in rows)
        rows.update({r["request_id"]: r for r in older if "request_id" in r})
        note(f"{name}: {len(older)} requests, {added} new")
    complete = cached.get("complete") or empty >= USAGE_EMPTY_STOP
    if complete and not cached.get("complete"):
        note(f"{name}: reached the start of history")

    return {
        "fetched": now.isoformat(timespec="seconds"),
        "accounting_method": accounting,
        "walked_to": walked.isoformat(timespec="seconds"),
        "complete": complete,
        "requests": sorted(
            rows.values(), key=lambda r: r.get("created_at") or "", reverse=True
        ),
    }


def by_model(rows):
    """Group the usable requests per model they were sent to."""
    models = {}
    for row in rows:
        name = row.get("requested_model") or row.get("model")
        prompt = number(row.get("prompt_tokens"))
        output = number(row.get("completion_tokens"))
        if not name or prompt is None or output is None:
            continue
        cached = min(number(row.get("cached_tokens")) or 0, prompt)
        models.setdefault(name, []).append(
            {
                "prompt": prompt,
                # Cache hits skip the prefill, so they are not input.
                "input": prompt - cached,
                "output": output,
                "cost": number(row.get("cost_usd")) or 0.0,
            }
        )
    return models


def aggregate(requests):
    """Reduce each prompt size band to its median request.

    Energy attribution swings by orders of magnitude between identical
    requests depending on how busy the server was, with a long tail on
    the high side. A median over the band averages that down.
    """
    bands = {}
    for entry in requests:
        edges = [e for e in BANDS if e <= entry["prompt"]]
        if edges:
            bands.setdefault(edges[-1], []).append(entry)
    points = [
        {
            "input": statistics.median(e["input"] for e in group),
            "output": statistics.median(e["output"] for e in group),
            "cost": statistics.median(e["cost"] for e in group),
            "requests": len(group),
        }
        for _, group in sorted(bands.items())
    ]
    # Thin bands are noise. Keep them only if nothing else is left.
    return [p for p in points if p["requests"] >= MIN_ROWS] or points


def fit_rates(points, listed):
    """Fit cost = a * input + b * output over the bands.

    Each band is divided by its token count, so long and short
    requests count the same, then weighted by the square root of how
    many requests it holds. Returns None when the bands do not cover a
    range of mixes, when a rate is not above zero, or when the fitted
    ratio is far off the listed one.
    """
    sii = sio = soo = sic = soc = 0.0
    for p in points:
        tokens = p["input"] + p["output"]
        if not tokens:
            continue
        weight = math.sqrt(p["requests"])
        x, y = p["input"] / tokens, p["output"] / tokens
        cost = p["cost"] / tokens
        sii += weight * x * x
        sio += weight * x * y
        soo += weight * y * y
        sic += weight * x * cost
        soc += weight * y * cost
    det = sii * soo - sio * sio
    if det <= 1e-12:
        return None
    low = (soo * sic - sio * soc) / det
    high = (sii * soc - sio * sic) / det
    if low <= 0 or high < 0:
        return None
    listed_in, listed_out = listed
    if listed_in > 0 and listed_out > 0:
        ratio = listed_out / listed_in
        if not ratio / RATIO_SPREAD <= high / low <= ratio * RATIO_SPREAD:
            return None
    return low, high


def analyse(requests, listed):
    """Rates per million tokens that reproduce what was billed."""
    listed_in, listed_out = listed
    rates = fit_rates(aggregate(requests), listed)
    method = "fit"
    if rates is None:
        # The traffic cannot tell input from output, so keep the
        # listed ratio and let the spend set the level.
        rates, method = (listed_in / 1e6, listed_out / 1e6), "listed ratio"
    low, high = rates

    spent = sum(e["cost"] for e in requests)
    shaped = sum(low * e["input"] + high * e["output"] for e in requests)
    if not shaped:
        return listed_in, listed_out, method
    # The bands give the ratio between the rates, the spend gives
    # their level.
    scale = spent / shaped
    return low * scale * 1e6, high * scale * 1e6, method


def measure(provider, listed, currency, timeout, update):
    """Price an energy billed provider from its own usage history."""
    name = str(provider.get("name", "?"))
    # History never goes stale, so the cache does not expire. It is
    # topped up on --update, or built when there is nothing yet.
    cached = cache_read(f"usage-{name}", math.inf) or {}
    if update or not cached:
        cached = update_usage(provider, cached, timeout)
        cache_write(f"usage-{name}", cached)
    rows = cached.get("requests") or []
    if not rows:
        warn(f"{name}: no usage history, keeping listed prices")
        return {}
    if cached.get("accounting_method") != "energy":
        warn(f"{name}: account bills by token, keeping listed prices")
        return {}

    index = {}
    for model, requests in by_model(rows).items():
        pair = next((listed[s] for s in slugs(model) if s in listed), None)
        # Without a listed ratio there is nothing to split the spend
        # between input and output, so leave the model alone.
        if len(requests) < MIN_REQUESTS or not pair or not any(pair):
            continue
        low, high, _ = analyse(requests, pair)
        # The fit charges the whole spend to fresh input and output,
        # so a cache hit carries nothing on top.
        for slug in slugs(model):
            index[slug] = (low, high, 0.0, currency)
    return index


def normalize(name):
    """Match key for evaluators, which spell 5.1 as 5-1."""
    return name.lower().replace(".", "-")


def score_of(evaluations):
    """Intelligence and coding index out of an evaluations object."""
    intelligence = coding = None
    for key, value in evaluations.items():
        if intelligence is None and key.endswith("intelligence_index"):
            intelligence = number(value)
        elif coding is None and key.endswith("coding_index"):
            coding = number(value)
    return intelligence, coding


def effort_of(name):
    """Effort level in the brackets of a name, such as (xhigh)."""
    head, _, tail = name.rpartition("(")
    words = tail.lower().replace(",", " ").replace(")", " ").split()
    if not head or "non-reasoning" in words:
        return None
    return next((w for w in words if w in EFFORTS), None)


def suggest(levels, keep):
    """Lowest effort level that keeps keep percent of the best score."""
    if len(levels) == 1:
        return next(iter(levels)) + ONLY
    floor = max(s[0] for s in levels.values()) * keep / 100
    return next(e for e in EFFORTS if e in levels and levels[e][0] >= floor)


def at_effort(levels, effort):
    """Scores at this effort level, or the closest level below it."""
    rated = [e for e in EFFORTS[: EFFORTS.index(effort) + 1] if e in levels]
    return levels[rated[-1]] if rated else (None, None)


def evaluations(evaluators, timeout, max_age, keep, effort):
    """Slug to (intelligence, coding, sel) from every evaluator."""
    index, families = {}, {}
    for evaluator in evaluators:
        name = str(evaluator.get("name") or "evaluator")
        payload = cache_read(name, max_age)
        if not isinstance(payload, dict):
            note(f"{name}: fetching evaluations")
            base_url = evaluator.get("base_url")
            if not base_url:
                warn(f"{name}: no base_url")
                continue
            token, err = get_token(evaluator)
            if err:
                warn(f"{name}: {err}")
                continue
            payload, err = get_json(
                str(base_url),
                timeout,
                token,
                USER_AGENT,
                str(evaluator.get("auth_header") or ""),
            )
            if (
                err
                or not isinstance(payload, dict)
                or not isinstance(payload.get("data"), list)
            ):
                warn(f"{name}: {err or 'no data in response'}")
                continue
            cache_write(name, payload)
            note(f"{name}: fetched")
        for entry in payload.get("data") or []:
            if not isinstance(entry, dict):
                continue
            slug = entry.get("slug") or entry.get("id")
            scores = entry.get("evaluations")
            if not isinstance(slug, str) or not isinstance(scores, dict):
                continue
            slug = normalize(slug)
            intelligence, coding = score_of(scores)
            index.setdefault(slug, (intelligence, coding, None))
            # Variants are named base-level, the top level just base.
            level = effort_of(str(entry.get("name") or ""))
            if level and intelligence is not None:
                base = slug.removesuffix(f"-{level}")
                levels = families.setdefault(base, {})
                levels.setdefault(level, (intelligence, coding))
    for slug in index:
        if slug in families:
            levels = families[slug]
            index[slug] = at_effort(levels, effort) + (suggest(levels, keep),)
        elif effort != EFFORTS[-1]:
            # No named levels, so the score at a lower effort is unknown.
            index[slug] = (None, None, None)
    return index


def fx_rates(base, timeout, max_age):
    """Reference rates per unit of base."""
    cached = cache_read(f"fx-{base}", max_age)
    if isinstance(cached, dict) and cached.get("rates"):
        return cached["rates"]
    payload, err = get_json(FX_URL.format(base), timeout)
    if (
        err
        or not isinstance(payload, dict)
        or not isinstance(payload.get("rates"), dict)
    ):
        warn(f"exchange rates unavailable: {err or 'no rates in response'}")
        return {base: 1.0}
    rates = {base: 1.0}
    for code, value in payload["rates"].items():
        rate = number(value)
        if rate:
            rates[code.upper()] = rate
    cache_write(f"fx-{base}", {"rates": rates})
    note("exchange rates: fetched")
    return rates


def convert(price, base, rates, missing):
    """Restate a price in the base currency."""
    low, high, cache, currency = price
    rate = 1.0 if not currency or currency == base else rates.get(currency)
    if not rate:
        missing.add(currency)
        rate = 1.0
    return low / rate, high / rate, None if cache is None else cache / rate


def blend(value, weights):
    """One price from the token mix, and whether cache was guessed."""
    low, high, cache = value
    if len(weights) == 2:
        return low * weights[0] + high * weights[1], False
    guessed = cache is None
    hit = low if guessed else cache
    return hit * weights[0] + low * weights[1] + high * weights[2], guessed


def fmt(value):
    if 0 < value < 0.01:
        return f"{value:.3f}"
    return f"{value:.2f}"


def split_number(text):
    """Integer part and fraction, so columns align on the point."""
    head, dot, tail = text.partition(".")
    return head, dot + tail


def cell_span(size, mark_width):
    """Visible width of a cell holding numbers of these widths."""
    if not size:
        return 0
    return sum(sum(s) for s in size) + len(size) - 1 + mark_width


def parse_ratio(text):
    """Weights from a ratio: 3:1 is input to output, 7:2:1 puts a
    cache hit share in front of it."""
    fields = text.split(":") if ":" in text else [text, "1"]
    weights = [w for f in fields if (w := number(f)) is not None]
    if len(weights) != len(fields) or len(weights) not in (2, 3):
        return None
    if min(weights) < 0 or sum(weights) <= 0:
        return None
    total = sum(weights)
    return tuple(w / total for w in weights)


def field(text, width, color, use_color):
    """One number padded so its decimal point sits in place."""
    if text is None:
        return " " * (width[0] - 1) + paint("-", DIM, use_color) + " " * width[1]
    head, frac = split_number(text)
    left = " " * (width[0] - len(head))
    right = " " * (width[1] - len(frac))
    return left + paint(text, color, use_color) + right


def paint(text, color, enabled):
    return f"{color}{text}{RESET}" if enabled and color and text else text


def collect(providers, timeout, max_age):
    """Fetch every provider in parallel; return indexes and errors."""

    def one(provider):
        name = provider.get("name", "?")
        payload = cache_read(f"models-{name}", max_age)
        if model_items(payload) is not None:
            return name, index_models(payload), None
        base_url = provider.get("base_url")
        if not base_url:
            return name, {}, "no base_url"
        token, err = get_token(provider)
        if err:
            return name, {}, err
        payload, err = get_json(
            str(base_url).rstrip("/") + "/models",
            timeout,
            token,
            str(provider.get("user_agent") or USER_AGENT),
        )
        if err:
            return name, {}, err
        if model_items(payload) is None:
            return name, {}, "no model list in response"
        cache_write(f"models-{name}", payload)
        note(f"{name}: models fetched")
        return name, index_models(payload), None

    with ThreadPoolExecutor(max_workers=8) as pool:
        return list(pool.map(one, providers))


def listed_pairs(index):
    """Slug to its cheapest listed (input, output)."""
    pairs = {}
    for slug, prices in index.items():
        priced = [p for p in prices if p]
        if priced:
            best = min(priced, key=lambda p: (p[0], p[1]))
            pairs[slug] = (best[0], best[1])
    return pairs


def listed_currency(index):
    """The currency a provider lists its prices in, or USD."""
    for prices in index.values():
        for price in prices:
            if price:
                return price[3]
    return "USD"


def build_rows(
    models, results, catalogs, scores, measured, base, rates, missing, weights=None
):
    """One row per model, with its scores and a cell per provider."""
    rows = []
    for model in models:
        name = str(model.get("name", ""))
        if not name:
            continue
        ordered = [name.lower()]
        ordered += [str(a).lower() for a in model.get("aliases", [])]
        names = set(ordered) | {squash(n) for n in ordered}
        rated = next(
            (scores[key] for key in map(normalize, ordered) if key in scores),
            (None, None, None),
        )
        cells = []
        for provider, index, err in results:
            if err:
                cells.append(("err", None, ""))
                continue
            state, price = resolve(index, catalogs.get(provider, {}), names)
            if price is None:
                cells.append((state, None, ""))
                continue
            # An energy billed account pays its own measured rate,
            # not the one the provider lists.
            rated_by_use = measured.get(provider) or {}
            hits = [rated_by_use[c] for c in names if c in rated_by_use]
            mark = ""
            if hits:
                price, mark = min(hits, key=lambda p: (p[0], p[1])), MEASURED
            value = convert(price, base, rates, missing)
            if weights:
                blended, guessed = blend(value, weights)
                value = (blended,)
                mark += GUESSED if guessed else ""
            cells.append(("ok", value, mark))
        rows.append((name, rated, cells))
    return rows


SORT_KEYS = {"int": 0, "intelligence": 0, "code": 1, "coding": 1}


def sort_rows(rows, order):
    """Order rows by name, cheapest price, or an evaluator score."""
    if order == "name":
        return sorted(rows, key=lambda row: row[0])
    if order == "price":

        def cheapest(row):
            prices = [cell[1][0] for cell in row[2] if cell[0] == "ok"]
            return min(prices) if prices else float("inf"), row[0]

        return sorted(rows, key=cheapest)
    if order in SORT_KEYS:
        half = SORT_KEYS[order]

        def rated(row):
            score = row[1][half]
            return -score if score is not None else float("inf"), row[0]

        return sorted(rows, key=rated)
    return rows


def fmt_balance(value):
    return f"({value:.2f})" if value is not None else "(n/a)"


def render(rows, headers, credits, use_color):
    # Rank on the printed value, so equal-looking prices from
    # providers that differ in the last decimals get one color.
    def extreme(shown, pos):
        values = [s[pos] for s in shown if s and s[pos] is not None]
        if len(set(values)) < 2:
            return None, None
        return min(values), max(values)

    labels = {"absent": "-", "unknown": "n/a", "err": "err"}
    # Score columns trail the providers. They are one fact per model,
    # so they take no part in the ranking.
    trail = len(headers) - 1 - len(rows[0][2]) if rows else 0
    printed, ranked, scores = [], [], []
    for _, rated, cells in rows:
        texts, shown = [], []
        for state, price, mark in cells:
            if state != "ok":
                texts.append((labels[state], ""))
                shown.append(None)
                continue
            values = tuple(None if v is None else fmt(v) for v in price)
            texts.append((values, mark))
            shown.append(tuple(None if v is None else float(v) for v in values))
        printed.append(texts)
        ranked.append(shown)
        scores.append(
            [
                "-" if v is None else v if isinstance(v, str) else f"{v:.1f}"
                for v in rated[:trail]
            ]
        )
    # Leave room for a mark, so the words align on their last letter.
    for i in range(trail):
        if any(s[i].endswith(ONLY) for s in scores):
            for s in scores:
                s[i] += "" if s[i].endswith(ONLY) else " "

    # Per column, how wide each number is on either side of its
    # decimal point, plus room for the marks. A number nothing in
    # the column states, such as a cache price, takes no space.
    parts = []
    widths = [max([len(headers[0])] + [len(row[0]) for row in rows])]
    for i in range(len(headers) - 1 - trail):
        size, mark_width, label = [], 0, 0
        for texts in printed:
            cell, mark = texts[i]
            if isinstance(cell, str):
                label = max(label, len(cell))
                continue
            while len(size) < len(cell):
                size.append([0, 0])
            for half, text in enumerate(cell):
                if text is None:
                    continue
                head, frac = split_number(text)
                size[half][0] = max(size[half][0], len(head))
                size[half][1] = max(size[half][1], len(frac))
            mark_width = max(mark_width, len(mark))
        size = [s for s in size if s[0]]
        parts.append((size, mark_width))
        span = max(len(headers[i + 1]), cell_span(size, mark_width), label)
        widths.append(max(span, len(credits[i])))
    for i in range(trail):
        header = headers[len(headers) - trail + i]
        widths.append(max([len(header)] + [len(s[i]) for s in scores]))

    print("  ".join(h.ljust(widths[i]) for i, h in enumerate(headers)).rstrip())
    if any(credits):
        line = [" " * widths[0]]
        line += [text.rjust(widths[i + 1]) for i, text in enumerate(credits)]
        print(paint("  ".join(line).rstrip(), DIM, use_color))
    print("  ".join("-" * w for w in widths))

    seen = set()
    for row, texts, shown, rated in zip(rows, printed, ranked, scores):
        count = max((len(s) for s in shown if s), default=0)
        extremes = [extreme(shown, j) for j in range(count)]
        out = [row[0].ljust(widths[0])]
        for i, (cell, mark) in enumerate(texts):
            width = widths[i + 1]
            if isinstance(cell, str):
                out.append(paint(cell, DIM, use_color) + " " * (width - len(cell)))
                continue
            size, mark_width = parts[i]
            fields = []
            for j in range(len(size)):
                low, high = extremes[j]
                value = shown[i][j]
                color = GREEN if value == low else RED if value == high else None
                fields.append(field(cell[j], size[j], color, use_color))
            text = (
                " ".join(fields)
                + paint(mark, DIM, use_color)
                + " " * (mark_width - len(mark))
            )
            seen.update(set(mark))
            out.append(text + " " * (width - cell_span(size, mark_width)))
        for i, text in enumerate(rated):
            cell = text.rjust(widths[len(widths) - trail + i])
            out.append(paint(cell, DIM, use_color) if text.strip() == "-" else cell)
        print("  ".join(out).rstrip())
    return seen


def main(argv=None):
    ap = argparse.ArgumentParser(description="Compare model prices per provider.")
    ap.add_argument(
        "-c", "--config", default=CONFIG, help=f"config file, default {CONFIG}"
    )
    ap.add_argument("-b", "--base", default="USD", help="currency to show prices in")
    ap.add_argument("--no-fx", action="store_true", help="do not convert currencies")
    ap.add_argument(
        "--no-color", action="store_true", help="print without the green and red"
    )
    ap.add_argument(
        "-r",
        "--ratio",
        default=None,
        help=f"token mix for the blend, cache:input:output, default {DEFAULT_RATIO}",
    )
    ap.add_argument(
        "-s",
        "--sort",
        choices=("name", "price", "int", "intelligence", "code", "coding"),
        metavar="KEY",
        help="order rows by name, price, int or code; default config order",
    )
    ap.add_argument(
        "-e",
        "--effort",
        choices=EFFORTS,
        default="max",
        metavar="LEVEL",
        help=f"effort level of the int and code scores, {', '.join(EFFORTS)}; "
        "default max",
    )
    ap.add_argument(
        "-k",
        "--keep",
        type=float,
        default=DEFAULT_KEEP,
        metavar="PCT",
        help="percent of the best int score the sel effort keeps, default 95",
    )
    ap.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="show input, output and cache prices instead of the blend",
    )
    ap.add_argument(
        "-t",
        "--timeout",
        type=int,
        default=20,
        help="seconds to wait on one request, default 20",
    )
    ap.add_argument(
        "-u", "--update", action="store_true", help=f"ignore the cache in {CACHE}"
    )
    args = ap.parse_args(argv)

    try:
        cfg = load_config(args.config)
    except OSError as e:
        print(f"error: cannot read {args.config}: {e}", file=sys.stderr)
        return 2
    except tomllib.TOMLDecodeError as e:
        print(f"error: bad TOML in {args.config}: {e}", file=sys.stderr)
        return 2

    providers = [p for p in cfg.get("model_providers", []) if isinstance(p, dict)]
    models = [m for m in cfg.get("models", []) if isinstance(m, dict)]
    evaluators = [e for e in cfg.get("model_evaluators", []) if isinstance(e, dict)]
    if not providers or not models:
        print("error: config needs model_providers and models", file=sys.stderr)
        return 2

    base = args.base.upper()
    ratio = args.ratio or DEFAULT_RATIO
    weights = None if args.verbose else parse_ratio(ratio)
    if weights is None and not args.verbose:
        print(f"error: bad ratio {ratio!r}, expected 7:2:1 or 3:1", file=sys.stderr)
        return 2
    if not 0 < args.keep <= 100:
        print(f"error: bad keep {args.keep:g}, expected above 0, up to 100", file=sys.stderr)
        return 2
    if args.ratio and args.verbose:
        warn("--ratio has no effect with --verbose")
    max_age = 0 if args.update else CACHE_TTL
    if args.update:
        note("updating")
    rates = {base: 1.0} if args.no_fx else fx_rates(base, args.timeout, max_age)
    catalog = models_dev(args.timeout, max_age)
    catalogs = {
        str(p.get("name", "?")): index_catalog(
            catalog, str(p.get("models_dev") or p.get("name", ""))
        )
        for p in providers
    }
    scores = (
        evaluations(evaluators, args.timeout, max_age, args.keep, args.effort)
        if evaluators
        else {}
    )
    credit = balances(
        providers, args.timeout, 0 if args.update else BALANCE_TTL, base, rates
    )
    results = collect(providers, args.timeout, max_age)
    for name, _, err in results:
        if err:
            warn(f"{name}: {err}")

    measured = {}
    indexes = {name: index for name, index, _ in results}
    for provider in providers:
        if str(provider.get("pricing") or "token") != "energy":
            continue
        name = str(provider.get("name", "?"))
        index = indexes.get(name, {})
        measured[name] = measure(
            provider,
            listed_pairs(index),
            listed_currency(index),
            args.timeout,
            args.update,
        )

    missing = set()
    rows = sort_rows(
        build_rows(
            models, results, catalogs, scores, measured, base, rates, missing, weights
        ),
        args.sort,
    )
    use_color = not args.no_color and sys.stdout.isatty()
    trail = ["int", "code", "sel"] if scores else []

    if weights:
        mix = "cache, input, output" if len(weights) == 3 else "input, output"
        shape = f"blended {ratio} {mix}"
    elif any(
        c[1] and len(c[1]) > 2 and c[1][2] is not None for *_, r in rows for c in r
    ):
        shape = "in, out, cached"
    else:
        shape = "in, out"
    print(f"prices per million tokens in {base} ({shape})")
    if scores:
        print(
            f"int and code are at effort level {args.effort}, "
            "or the closest level below it"
        )
        print(
            "sel is a suggested effort level that "
            f"gives {args.keep:g}% of the top int score"
        )
    print(
        f"{paint('green', GREEN, use_color)} = lowest, "
        f"{paint('red', RED, use_color)} = highest\n"
    )
    headers = ["model"] + [name for name, _, _ in results] + trail
    credits = [fmt_balance(credit.get(name)) for name, _, _ in results]
    seen = render(rows, headers, credits, use_color)
    only = any(str(row[1][2]).endswith(ONLY) for row in rows)
    if seen or only:
        print()
    if MEASURED in seen:
        print(f"{MEASURED} rate measured from actual traffic instead of estimate")
    if GUESSED in seen:
        print(f"{GUESSED} no cache price known, input price used for cache tokens")
    if only:
        print(f"{ONLY} suggested effort level is the only effort level aa tested")
    for currency in sorted(missing):
        warn(f"no {base} rate for {currency}, shown unconverted")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except BrokenPipeError:
        try:
            sys.stdout.close()
        except OSError:
            pass
        sys.exit(0)
