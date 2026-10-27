#!/usr/bin/env python3
"""aimap: AI Models and Providers price comparison.

Reads ~/.aimap.toml, fetches <base_url>/models from every provider
using a token from tipi.py, and prints one column per provider with
the price per million tokens of each configured model. Per row the
lowest price is green and the highest red, unless several cells
share it. A free price is blue.

Some providers serve a model without publishing its price, and many
state no cache price at all. Those fall back to what models.dev holds
for that same provider. A model with no price in either source shows
as n/a. A cache price missing from both is estimated from the
evaluator: the share of the input price its cache hit costs, applied
to the input price of the provider. Such cells carry a tilde. With no
estimate either, a missing cache price shows as a dash.

Prices are converted to one currency using reference rates from
frankfurter.dev. Model lists, the models.dev catalog and the rates are
cached in ~/.cache/aimap for 24 hours; --update fetches them again.

By default each cell holds one blended price, weighting cache hit,
input and output tokens 7:2:1, the mix Artificial Analysis states for
its blended price. --blend sets another weighting: three terms keep
the cache share, two drop it, so --blend 3:1 is the older input to
output convention and --blend 15:1 matches the traffic OpenRouter
reports across its own platform. Where no cache price is known the
input price stands in for it, marked with a tilde.

--blend 0, false or disabled shows the three prices side by side.

Under each provider name is the credit left on that account, where it
serves one. A few known paths are tried and the first number that
looks like a balance is kept, so most providers need no config. These
are held for an hour, and refreshed by --update.

A configured evaluator adds a score column, holding its intelligence
index for the model. --score coding shows its coding index instead,
and int and code are short forms. For artificial-analysis, coding
means its engineering index. A model with no such score shows a dash.
The evaluator finds a model by its scores name, else by its name. A
scores table sets that name per evaluator, so the others use the
name. Aliases only match provider names, or the upstream model a
provider names in metadata.huggingface_id, as Neuralwatt does for
aliases like nw-flash. Flex tiers are left out of that, as they
serve the same model at a discount. Where it rates
the model at more than one effort level, a sel column shows the
lowest level that keeps a share of the best score, 95 percent unless
--keep sets another, and score shows the score at that level. --effort
shows score at a set effort level instead, or the closest level below
it that the evaluator rates. A model the evaluator rates at no named
level keeps its one score, unless --effort sets a level below max,
as its score at a lower level is unknown.
The rel column shows the month the model was released.

Scores of two evaluators are not comparable, so aimap uses one: the
first in the config, or the one --model-evaluator names. An evaluator
has a type: artificial-analysis, the default, or benchlm. BenchLM has
no prices. It finds a model by slug or display name, as a slug can
lack a date. Its release dates are in a catalog that costs 10 more
reads, so rel shows dashes. It rates no effort levels, so sel shows
dashes and --effort has no effect. Its free plan has 250 reads a
month. One fetch takes 5 reads, 3 for the intelligence ranking and 2
for the coding ranking. The cache keeps it for 24 hours, also when a
ranking failed to come in, as each read counts.

A provider set to pricing = "energy" bills the power its GPUs draw,
not tokens, so its listed token prices are not what the account pays.
Those models are priced from the provider's own usage api instead:
the listed input and output prices of a model are scaled so they
reproduce what its requests were actually billed. Such cells carry a
star. The whole spend lands on fresh tokens, so a cache hit adds
nothing on top.

The usage history is cached in ~/.cache/aimap and never expires,
since past requests do not change. --update tops it up and walks
further back, a window at a time, until the history runs out.

--order name orders rows alphabetically, --order price by the cheapest
provider in each row, using the first number a cell shows. --order
score puts the highest score first. --order date puts the newest
release first. Without it rows keep the order of the config.

--limit keeps rows that match field filters such as "score=40+",
"price=0.10-" or "name=*deepseek*". Separate filters with commas.
A numeric value with - means that value or less, and + means that
value or higher. Price uses the cheapest paid cell, or a free cell
when no paid cell exists. A name filter uses shell wildcards and
ignores case.

Config format:

  [[model_providers]]
  name = "openrouter"
  base_url = "https://openrouter.ai/api/v1"
  auth_keys = ["openrouter", "rubins-raaf-api-key"]  # tipi key, user
  user_agent = "..."   # optional, some endpoints filter on it
  models_dev = "..."   # optional, its id on models.dev if it differs
  pricing = "energy"   # optional, default "token"
  usage_path = "..."   # optional, default /usage/requests
  balance_path = "..." # optional, path or url where credit left is served
  # Or, for credit shown only to a logged-in browser:
  balance_cookie = "host/name"           # session cookie from Firefox
  balance_api_url = "..."                # json endpoint it unlocks
  balance_field = "credits"              # its key in that reply
  balance_headers = { x-org-id = "..." } # optional request headers
  balance_scale = 1e8                    # optional currency divisor

  [[model_evaluators]]   # the first one is the default
  name = "artificial-analysis"                       # also the cache file
  base_url = "https://artificialanalysis.ai/api/v2/language/models/free"
  auth_keys = ["artificialanalysis", "default-api-token"]
  auth_header = "x-api-key"   # optional, default is Authorization

  [[model_evaluators]]
  name = "benchlm"
  type = "benchlm"            # required, default is "artificial-analysis"
  base_url = "https://data.benchlm.ai/v1"
  auth_keys = ["benchlm", "default-api-token"]

  [[models]]
  name = "deepseek-v4.1-flash"
  aliases = ["deepseek-v4-1-flash"]
  scores = "..."   # optional, the name evaluators know this model by
  # Or, per evaluator name, where the others use the name:
  scores = { artificial-analysis = "..." }

Usage:
  aimap.py [-v] [-b 15:1] [-o price] [-s coding] [-e high] [-k 90]
           [-m benchlm] [-c USD] [-l "score=40+,price=0.10-"] [-t 20]
           [-f FILE] [-n] [-u]
"""

import argparse
import fnmatch
import glob
import json
import logging
import math
import operator
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time
import tomllib
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime, timedelta

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
    "credits",
]
# Token mix for a blended price, cache hit to input to output. This
# is the ratio Artificial Analysis states for its blended figure.
DEFAULT_RATIO = "7:2:1"
# Effort levels an evaluator rates a model at, lowest first.
EFFORTS = ["low", "medium", "high", "xhigh", "max"]
DEFAULT_KEEP = 95.0
# Names that pick a score, and the kind of score each one stands for.
SCORE_KINDS = {
    "int": "intelligence",
    "intelligence": "intelligence",
    "code": "coding",
    "coding": "coding",
}
# Most rows BenchLM serves in one read. A free plan has few reads.
BENCHLM_PAGE = 100
# Most reads of one ranking, in case its pages do not end.
BENCHLM_PAGES = 10
# Tries of one read when BenchLM limits the rate.
BENCHLM_RETRIES = 3
# The BenchLM ranking that each kind of score is read from.
SURFACES = {"intelligence": "overall", "coding": "coding"}

RESET = "\033[0m"
RED = "\033[31m"
GREEN = "\033[32m"
BLUE = "\033[34m"
DIM = "\033[2m"
GUESSED = "~"
MEASURED = "*"
ONLY = "+"
MIN_WIDTH = 5
log = logging.getLogger(__name__)

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

# How much traffic a model needs before its spend sets its price.
MIN_REQUESTS = 20

# Price fields seen in the wild, with the factor that turns them
# into a price per million tokens. Order matters: per-million keys
# come first, since some providers publish both forms.
PRICE_KEYS = [
    ("price_1m_input_tokens", "price_1m_output_tokens", 1.0),
    ("input_per_million", "output_per_million", 1.0),
    ("prompt_per_million", "completion_per_million", 1.0),
    ("input_token", "output_token", 1.0),
    ("input_cost_per_token", "output_cost_per_token", 1e6),
    ("prompt", "completion", 1e6),
]

# Cache read fields, searched on their own because a provider can
# state the pair per million and the cache price per token.
CACHE_KEYS = [
    ("price_1m_cache_hit_tokens", 1.0),
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


def fetch_json(
    url,
    timeout,
    token=None,
    user_agent=USER_AGENT,
    auth_header=None,
    extra=None,
    body=None,
    retries=1,
):
    """GET, or POST when there is a body, waiting out a rate limit."""
    headers = {"Accept": "application/json", "User-Agent": user_agent}
    if token and auth_header and auth_header.lower() != "authorization":
        headers[auth_header] = token
    elif token:
        headers["Authorization"] = f"Bearer {token}"
    headers.update(extra or {})
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    for attempt in range(retries):
        req = urllib.request.Request(url, data=data, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return json.load(resp), None
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < retries - 1:
                delay = number(e.headers.get("Retry-After")) or 2**attempt
                log.info(f"  rate limited, waiting {delay:.0f}s")
                time.sleep(min(delay, 60))
                continue
            try:
                text = e.read().decode()[:120]
            except (OSError, ValueError, UnicodeDecodeError):
                text = ""
            return None, f"HTTP {e.code} {text}".strip()
        except (urllib.error.URLError, OSError, ValueError) as e:
            return None, str(e)[:120]
    return None, "rate limited"


def fetch_pages(url, timeout, *args):
    """GET a reply served in pages, with the data of every page joined."""
    payload, err = fetch_json(url, timeout, *args)
    if not isinstance(payload, dict):
        return payload, err
    for n in range(2, (payload.get("pagination") or {}).get("total_pages", 1) + 1):
        page, err = fetch_json(f"{url}?page={n}", timeout, *args)
        if not isinstance(page, dict):
            return None, err or "unexpected response"
        payload["data"] += page.get("data") or []
    return payload, None


def fetch_ranking(url, surface, timeout, *args):
    """GET the rows of one BenchLM ranking, and the error if it stopped."""
    items, offset = [], 0
    for _ in range(BENCHLM_PAGES):
        query = urllib.parse.urlencode(
            {"surface": surface, "limit": BENCHLM_PAGE, "offset": offset}
        )
        page, err = fetch_json(
            f"{url.rstrip('/')}/rankings/current?{query}",
            timeout,
            *args,
            retries=BENCHLM_RETRIES,
        )
        if not isinstance(page, dict) or not isinstance(page.get("items"), list):
            return items, err or "unexpected response"
        items += page["items"] + (page.get("regionalItems") or [])
        following = (page.get("pagination") or {}).get("nextOffset")
        # An offset that does not move on would read the same page again.
        if not isinstance(following, int) or following <= offset:
            break
        offset = following
    return items, None


def fetch_benchlm(url, timeout, *args):
    """GET the rankings of BenchLM as a list like the one of AA."""
    rows = {}
    for kind, surface in SURFACES.items():
        items, err = fetch_ranking(url, surface, timeout, *args)
        if err:
            # Each read counts against the plan, so keep what came in.
            warn(f"benchlm: {surface} ranking is incomplete: {err}")
        for item in items:
            if not isinstance(item, dict):
                continue
            slug = item.get("slug") or item.get("name")
            score = number(item.get("score"))
            if not isinstance(slug, str) or score is None:
                continue
            row = rows.setdefault(
                slug, {"slug": slug, "name": item.get("name"), "evaluations": {}}
            )
            # Regional rows come after the main ones, so the main score wins.
            row["evaluations"].setdefault(f"benchlm_{kind}_index", score)
    if not rows:
        return None, err
    data = list(rows.values())
    # A name finds a model too, as a slug can lack the date a name has.
    data += [
        {**row, "slug": row["name"], "name": None}
        for row in data
        if isinstance(row["name"], str) and squash(row["name"]) != squash(row["slug"])
    ]
    return {"data": data}, None


# Per evaluator type: its fetcher, score indexes, and effort levels.
EVALUATORS = {
    "artificial-analysis": {
        "fetch": fetch_pages,
        # Its coding index is obsolete, so use its engineering index.
        "indexes": {"intelligence": "intelligence", "coding": "engineering"},
        "efforts": True,
    },
    "benchlm": {
        "fetch": fetch_benchlm,
        "indexes": {"intelligence": "intelligence", "coding": "coding"},
        "efforts": False,
    },
}


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


def upstream_slugs(entry):
    """Slugs of the upstream model an entry names, unless flex tier."""
    meta = entry.get("metadata")
    if not isinstance(meta, dict):
        return set()
    upstream = meta.get("huggingface_id")
    pricing = meta.get("pricing")
    tier = pricing.get("service_tier") if isinstance(pricing, dict) else None
    if not isinstance(upstream, str) or tier == "flex":
        return set()
    return slugs(upstream)


def index_models(payload):
    """Map every slug a provider serves to its prices."""
    items = [e for e in (model_items(payload) or []) if isinstance(e, dict)]
    index = {}
    for entry in items:
        model_id = entry.get("id")
        if not isinstance(model_id, str):
            continue
        price = price_of(entry)
        for slug in slugs(model_id) | upstream_slugs(entry):
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


def cached_json(name, url, timeout, max_age, valid, source=None, fetch=fetch_json):
    """Cached payload, else fetched with the source's token and cached."""
    payload = cache_read(name, max_age)
    if valid(payload):
        return payload, None
    if not url:
        return None, "no base_url"
    source = source or {}
    token, err = get_token(source)
    if err:
        return None, err
    payload, err = fetch(
        url,
        timeout,
        token,
        str(source.get("user_agent") or USER_AGENT),
        str(source.get("auth_header") or ""),
    )
    if err or not valid(payload):
        return None, err or "unexpected response"
    cache_write(name, payload)
    log.info(f"{name}: fetched")
    return payload, None


def models_dev(timeout, max_age):
    """Curated catalog, used where a provider publishes no price."""
    payload, err = cached_json(
        "models-dev", MODELS_DEV_URL, timeout, max_age, lambda p: isinstance(p, dict)
    )
    if err:
        warn(f"models.dev unavailable: {err}")
    return payload or {}


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
    payload, err = fetch_json(url, timeout, extra=headers)
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
    log.info(f"{name}: fetching balance")
    base_url = provider.get("base_url")
    found = None
    if provider.get("balance_cookie"):
        found = cookie_balance(provider, timeout)
    elif base_url:
        token, err = get_token(provider)
        if not err:
            configured = provider.get("balance_path")
            paths = [str(configured)] if configured else BALANCE_PATHS
            for path in paths:
                url = path if "://" in path else str(base_url).rstrip("/") + path
                payload, err = fetch_json(
                    url,
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
        payload, err = fetch_json(page, timeout, token, retries=USAGE_RETRIES)
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

    def merge(found):
        added = sum(1 for r in found if r.get("request_id") not in rows)
        rows.update({r["request_id"]: r for r in found if "request_id" in r})
        log.info(f"{name}: {len(found)} requests, {added} new")

    span = timedelta(days=USAGE_DAYS)
    now = datetime.now(UTC)

    # Forward from the newest row held, or the whole window when the
    # cache is empty.
    newest = max(
        (r["created_at"] for r in rows.values() if r.get("created_at")), default=None
    )
    start = now - span
    if newest:
        start = max(start, datetime.fromisoformat(newest) - timedelta(minutes=5))
    log.info(f"{name}: fetching usage since {start:%Y-%m-%d %H:%M}")
    fresh, method, err = fetch_window(base_url, path, token, start, now, timeout)
    if err:
        warn(f"{name}: usage api: {err}")
    accounting = method or accounting
    merge(fresh)

    # Backwards until the history runs out, picking up where a past
    # run stopped.
    edge = cached.get("walked_to")
    walked = datetime.fromisoformat(edge) if edge else now - span
    empty = 0
    while not cached.get("complete") and empty < USAGE_EMPTY_STOP:
        probe = walked - span
        log.info(f"{name}: walking back to {probe:%Y-%m-%d}")
        older, _, err = fetch_window(base_url, path, token, probe, walked, timeout)
        if err:
            warn(f"{name}: usage api: {err}")
            break
        walked = probe
        if not older:
            empty += 1
            continue
        empty = 0
        merge(older)
    complete = cached.get("complete") or empty >= USAGE_EMPTY_STOP
    if complete and not cached.get("complete"):
        log.info(f"{name}: reached the start of history")

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
                # Cache hits skip the prefill, so they are not input.
                "input": prompt - cached,
                "output": output,
                "cost": number(row.get("cost_usd")) or 0.0,
            }
        )
    return models


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
        # The listed ratio splits the spend, the spend sets the level.
        low, high = pair
        spent = sum(e["cost"] for e in requests)
        at_list = sum(low * e["input"] + high * e["output"] for e in requests) / 1e6
        scale = spent / at_list if at_list else 1.0
        # The whole spend lands on fresh input and output, so a cache
        # hit carries nothing on top.
        for slug in slugs(model):
            index[slug] = (low * scale, high * scale, 0.0, currency)
    return index


def score_of(evaluations, index):
    """The named index out of an evaluations object."""
    for key, value in evaluations.items():
        if key.endswith(f"{index}_index"):
            return number(value)
    return None


def release_of(text):
    """Release date in an ISO 8601 string, or None."""
    try:
        return datetime.fromisoformat(text).date()
    except (TypeError, ValueError):
        return None


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
    floor = max(levels.values()) * keep / 100
    return next(e for e in EFFORTS if e in levels and levels[e] >= floor)


def at_effort(levels, effort):
    """Score at this effort level, or the closest level below it."""
    rated = [e for e in EFFORTS[: EFFORTS.index(effort) + 1] if e in levels]
    return levels[rated[-1]] if rated else None


def evaluations(evaluator, timeout, max_age, keep, effort, kind):
    """Scores, cache-price shares and release dates from an evaluator."""
    name = str(evaluator.get("name") or "evaluator")
    api = str(evaluator.get("type") or "artificial-analysis")
    spec = EVALUATORS.get(api)
    if not spec:
        warn(f"{name}: unknown type {api}")
        return {}, {}, {}
    if effort and not spec["efforts"]:
        warn(f"{name}: rates no effort levels, ignoring --effort")
        effort = None
    payload, err = cached_json(
        name,
        evaluator.get("base_url"),
        timeout,
        max_age,
        lambda p: isinstance(p, dict) and isinstance(p.get("data"), list),
        evaluator,
        spec["fetch"],
    )
    if not payload:
        warn(f"{name}: {err}")
        return {}, {}, {}
    index, families, shares, dates = {}, {}, {}, {}
    for entry in payload["data"]:
        if not isinstance(entry, dict):
            continue
        slug = entry.get("slug") or entry.get("id")
        scores = entry.get("evaluations")
        if not isinstance(slug, str) or not isinstance(scores, dict):
            continue
        score = score_of(scores, spec["indexes"][kind])
        index.setdefault(squash(slug), (score, None))
        released = release_of(entry.get("release_date"))
        if released:
            dates.setdefault(squash(slug), released)
        # A zero cache price next to a paid input is a placeholder.
        price = price_of(entry)
        if price and price[0] > 0 and price[2]:
            shares.setdefault(squash(slug), price[2] / price[0])
        # Variants are named base-level, the top level just base.
        level = spec["efforts"] and effort_of(str(entry.get("name") or ""))
        if level and score is not None:
            base = squash(slug.lower().removesuffix(f"-{level}"))
            levels = families.setdefault(base, {})
            levels.setdefault(level, score)
    for slug in index:
        if slug in families:
            levels = families[slug]
            sel = suggest(levels, keep)
            index[slug] = at_effort(levels, effort or sel.removesuffix(ONLY)), sel
        elif effort and effort != EFFORTS[-1]:
            # No named levels, so the score at a lower effort is unknown.
            index[slug] = (None, None)
    return index, shares, dates


def fx_rates(base, timeout, max_age):
    """Reference rates per unit of base."""
    payload, err = cached_json(
        f"fx-{base}",
        FX_URL.format(base),
        timeout,
        max_age,
        lambda p: isinstance(p, dict) and isinstance(p.get("rates"), dict),
    )
    if err:
        warn(f"exchange rates unavailable: {err}")
    rates = {base: 1.0}
    for code, value in (payload or {}).get("rates", {}).items():
        if rate := number(value):
            rates[code.upper()] = rate
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
    # A third decimal only where two would print as 0.00.
    if 0 < value < 0.005:
        return f"{value:.3f}"
    return f"{value:.2f}"


def split_number(text):
    """Integer part and fraction, so columns align on the point."""
    head, dot, tail = text.partition(".")
    return head, dot + tail


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


def parse_limit(text):
    """Filters in FIELD=VALUE form, as (field, test, value) rules."""
    rules = []
    for item in text.split(","):
        key, sep, value = item.partition("=")
        key, value = key.strip().lower(), value.strip()
        if not sep or not value or key not in ("name", "score", "price"):
            raise argparse.ArgumentTypeError(
                "expected FIELD=VALUE with FIELD set to name, score or price"
            )
        if key == "name":
            rules.append((key, fnmatch.fnmatchcase, value.casefold()))
            continue
        threshold = number(value[:-1])
        if value[-1] not in "+-" or threshold is None:
            raise argparse.ArgumentTypeError(
                f"bad {key} value {value!r}, expected a number and + or -"
            )
        test = operator.ge if value[-1] == "+" else operator.le
        rules.append((key, test, threshold))
    return rules


def field(text, width, color, use_color):
    """One number padded so its decimal point sits in place."""
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
        base_url = provider.get("base_url")
        payload, err = cached_json(
            f"models-{name}",
            base_url and str(base_url).rstrip("/") + "/models",
            timeout,
            max_age,
            lambda p: model_items(p) is not None,
            provider,
        )
        return name, {} if err else index_models(payload), err

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
    models,
    results,
    catalogs,
    scores,
    shares,
    dates,
    rater,
    measured,
    base,
    rates,
    missing,
    weights=None,
):
    """One row per model, with metadata and a cell per provider."""
    rows = []
    for model in models:
        name = str(model.get("name", ""))
        if not name:
            continue
        ordered = [name.lower()]
        ordered += [str(a).lower() for a in model.get("aliases", [])]
        names = set(ordered) | {squash(n) for n in ordered}
        rated_as = model.get("scores") or name
        # A scores table names the model per evaluator.
        if isinstance(rated_as, dict):
            rated_as = rated_as.get(rater) or name
        rated_as = squash(str(rated_as))
        rated = scores.get(rated_as, (None, None))
        share = shares.get(rated_as)
        release = dates.get(rated_as)
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
            if price[2] is None and share is not None:
                price = (price[0], price[1], price[0] * share, price[3])
                mark += GUESSED
            value = convert(price, base, rates, missing)
            if weights:
                blended, guessed = blend(value, weights)
                value = (blended,)
                mark += GUESSED if guessed else ""
            cells.append(("ok", value, mark))
        rows.append((name, rated, release, cells))
    return rows


def cheapest(row):
    """Cheapest price in a row, free only when nothing else, or None."""
    prices = [cell[1][0] for cell in row[3] if cell[0] == "ok"]
    prices = [p for p in prices if p > 0] or prices
    return min(prices, default=None)


def matches_limits(row, limits):
    """True when a row matches every limit rule."""
    values = {"name": row[0].casefold(), "score": row[1][0], "price": cheapest(row)}
    return all(
        values[key] is not None and test(values[key], limit)
        for key, test, limit in limits
    )


def sort_rows(rows, order):
    """Order rows by name, price, score, or release date."""
    if order == "name":
        return sorted(rows, key=lambda row: row[0])
    if order == "price":

        def price(row):
            value = cheapest(row)
            return value if value is not None else float("inf"), row[0]

        return sorted(rows, key=price)
    if order == "score":

        def rated(row):
            score = row[1][0]
            return -score if score is not None else float("inf"), row[0]

        return sorted(rows, key=rated)
    if order == "date":

        def released(row):
            return -row[2].toordinal() if row[2] else float("inf"), row[0]

        return sorted(rows, key=released)
    return rows


def fmt_balance(value):
    return f"({value:.2f})" if value is not None else "(n/a)"


def render(rows, headers, credits, use_color, total=""):
    """Print the table and return the marks it used."""
    labels = {"absent": "-", "unknown": "n/a", "err": "err"}
    # A cell is a label, or the printed text of each of its prices.
    grid = [
        [
            [None if v is None else fmt(v) for v in price]
            if state == "ok"
            else labels[state]
            for state, price, _ in cells
        ]
        for _, _, _, cells in rows
    ]
    # Fact columns trail the providers. They are one fact per model,
    # so they take no part in the ranking.
    n = 1 + len(credits)
    trail = headers[n:]
    facts = []
    for _, (score, sel), release, _ in rows:
        rel = release.strftime("%b'%y").lower() if release else None
        values = {"score": score, "sel": sel, "rel": rel}
        facts.append(
            [
                "-" if v is None else v if isinstance(v, str) else f"{v:.1f}"
                for v in map(values.get, trail)
            ]
        )
    # Leave room for a mark, so the words align on their last letter.
    for i in range(len(trail)):
        if any(s[i].endswith(ONLY) for s in facts):
            trail[i] += " "
            for s in facts:
                s[i] += "" if s[i].endswith(ONLY) else " "

    # Per column, how wide each number is on either side of its
    # decimal point, plus room for the marks. A number nothing in
    # the column states, such as a cache price, takes no space.
    layout = []
    widths = [max([len(headers[0])] + [len(row[0]) for row in rows])]
    for i, credit in enumerate(credits):
        column = [cells[i] for cells in grid]
        numbers = [c for c in column if isinstance(c, list)]
        size = []
        for j in range(max(map(len, numbers), default=0)):
            parts = [split_number(n[j]) for n in numbers if n[j]]
            if parts:
                size.append([max(len(p[k]) for p in parts) for k in (0, 1)])
        mark_width = max((len(row[3][i][2]) for row in rows), default=0)
        span = sum(map(sum, size)) + len(size) - 1 + mark_width if size else 0
        # A label starts under the last digit before the first point.
        indent = size[0][0] - 1 if size else 0
        layout.append((size, mark_width, span, indent))
        label = max((len(c) for c in column if isinstance(c, str)), default=0)
        # Columns fit their contents, so a long header is clipped.
        widths.append(max(MIN_WIDTH, span, indent + label, len(credit)))
    for i in range(len(trail)):
        widths.append(max([MIN_WIDTH] + [len(s[i]) for s in facts]))

    # Fact headers sit right, over their values.
    line = [h[:w].ljust(w) for h, w in zip(headers[:n], widths)]
    line += [h.rjust(w) for h, w in zip(trail, widths[n:])]
    print("  ".join(line).rstrip())
    if any(credits) or total:
        line = [total.ljust(widths[0])]
        line += [text.rjust(w) for text, w in zip(credits, widths[1:])]
        print(paint("  ".join(line).rstrip(), DIM, use_color))
    print("  ".join("-" * w for w in widths))

    seen = set()
    for row, cells, texts in zip(rows, grid, facts):
        # Rank on the printed value, so equal-looking prices from
        # providers that differ in the last decimals get one color.
        # Free prices are left out of the ranking, and a lowest or
        # highest price shared by several cells stays plain.
        numbers = [c for c in cells if isinstance(c, list)]
        extremes = []
        for j in range(max(map(len, numbers), default=0)):
            values = sorted(float(t) for n in numbers if (t := n[j]) and float(t))
            low = high = None
            if len(values) > 1:
                low = values[0] if values[0] < values[1] else None
                high = values[-1] if values[-1] > values[-2] else None
            extremes.append((low, high))
        out = [row[0].ljust(widths[0])]
        for cell, (*_, mark), (size, mark_width, span, indent), width in zip(
            cells, row[3], layout, widths[1:]
        ):
            if isinstance(cell, str):
                pad = " " * (width - indent - len(cell))
                out.append(" " * indent + paint(cell, DIM, use_color) + pad)
                continue
            fields = []
            for text, part, (low, high) in zip(cell, size, extremes):
                if text is None:
                    fields.append(field("-", part, DIM, use_color))
                    continue
                value = float(text)
                if value == 0:
                    color = BLUE
                else:
                    color = GREEN if value == low else RED if value == high else None
                fields.append(field(text, part, color, use_color))
            seen.update(mark)
            pad = " " * (mark_width - len(mark) + width - span)
            out.append(" ".join(fields) + paint(mark, DIM, use_color) + pad)
        for text, width in zip(texts, widths[n:]):
            cell = text.rjust(width)
            out.append(paint(cell, DIM, use_color) if text.strip() == "-" else cell)
        print("  ".join(out).rstrip())
    return seen


def main(argv=None):
    ap = argparse.ArgumentParser(description="Compare model prices per provider.")
    ap.add_argument(
        "-f", "--file", default=CONFIG, help=f"config file, default: {CONFIG}"
    )
    ap.add_argument(
        "-c", "--currency", default="USD", help="currency to show prices in"
    )
    ap.add_argument(
        "-b",
        "--blend",
        default=None,
        help="token mix for the blend, cache:input:output, or 0 for split "
        f"prices; default: {DEFAULT_RATIO}",
    )
    ap.add_argument(
        "-o",
        "--order",
        choices=("name", "price", "score", "date"),
        metavar="KEY",
        help="order rows by name, price, score or date; default: config order",
    )
    ap.add_argument(
        "-l",
        "--limit",
        action="extend",
        default=[],
        type=parse_limit,
        metavar="FIELD=VALUE",
        help="keep rows that match all name, score or price filters, "
        "separated by commas; numbers need - for up to or + for at "
        "least; * is a name wildcard",
    )
    ap.add_argument(
        "-m",
        "--model-evaluator",
        metavar="NAME",
        help="name of the evaluator that rates the models; "
        "default: the first in the config",
    )
    ap.add_argument(
        "-s",
        "--score",
        choices=SCORE_KINDS,
        default="intelligence",
        metavar="KIND",
        help="score to show: int or intelligence, code or coding; "
        "default: intelligence",
    )
    ap.add_argument(
        "-e",
        "--effort",
        choices=EFFORTS,
        metavar="LEVEL",
        help=f"effort level of the score: {', '.join(EFFORTS)}. "
        "default: determined by sel",
    )
    ap.add_argument(
        "-k",
        "--keep",
        type=float,
        default=DEFAULT_KEEP,
        metavar="PCT",
        help="keep PCT%% of the top score; "
        "influences suggested effort level (sel), default: 95",
    )
    ap.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="show the legend and explanations",
    )
    ap.add_argument(
        "-t",
        "--timeout",
        type=int,
        default=20,
        help="seconds to wait on one request, default: 20",
    )
    ap.add_argument(
        "-n",
        "--no-color",
        action="store_true",
        help="don't use color ansi codes when printing table",
    )
    ap.add_argument(
        "-u", "--update", action="store_true", help=f"ignore the cache in {CACHE}"
    )
    args = ap.parse_args(argv)

    try:
        cfg = load_config(args.file)
    except OSError as e:
        print(f"error: cannot read {args.file}: {e}", file=sys.stderr)
        return 2
    except tomllib.TOMLDecodeError as e:
        print(f"error: bad TOML in {args.file}: {e}", file=sys.stderr)
        return 2

    providers = [p for p in cfg.get("model_providers", []) if isinstance(p, dict)]
    models = [m for m in cfg.get("models", []) if isinstance(m, dict)]
    evaluators = [e for e in cfg.get("model_evaluators", []) if isinstance(e, dict)]
    if not providers or not models:
        print("error: config needs model_providers and models", file=sys.stderr)
        return 2

    base = args.currency.upper()
    if len(base) != 3 or not base.isalpha():
        print(
            f"error: bad currency {args.currency!r}, expected a code like EUR",
            file=sys.stderr,
        )
        return 2
    ratio = (args.blend or DEFAULT_RATIO).strip()
    split = ratio.lower() in ("false", "disabled", "off", "no") or number(ratio) == 0
    weights = None if split else parse_ratio(ratio)
    if weights is None and not split:
        print(f"error: bad blend {ratio!r}, expected 7:2:1, 3:1 or 0", file=sys.stderr)
        return 2
    if not 0 < args.keep <= 100:
        print(
            f"error: bad keep {args.keep:g}, expected above 0, up to 100",
            file=sys.stderr,
        )
        return 2
    kind = SCORE_KINDS[args.score]
    # Scores of evaluators are not comparable, so only one is used.
    evaluator = evaluators[0] if evaluators else None
    if args.model_evaluator:
        evaluator = next(
            (e for e in evaluators if e.get("name") == args.model_evaluator), None
        )
        if not evaluator:
            names = ", ".join(str(e.get("name")) for e in evaluators)
            print(
                f"error: no model evaluator {args.model_evaluator!r}, "
                f"config has: {names or 'none'}",
                file=sys.stderr,
            )
            return 2
    rater = str(evaluator.get("name") or "evaluator") if evaluator else None
    max_age = 0 if args.update else CACHE_TTL
    logging.basicConfig(
        format="%(message)s",
        level=logging.INFO if args.verbose and args.update else logging.WARNING,
        force=True,
    )
    if args.update:
        log.info("updating")
    rates = fx_rates(base, args.timeout, max_age)
    catalog = models_dev(args.timeout, max_age)
    catalogs = {
        str(p.get("name", "?")): index_catalog(
            catalog, str(p.get("models_dev") or p.get("name", ""))
        )
        for p in providers
    }
    scores, shares, dates = (
        evaluations(evaluator, args.timeout, max_age, args.keep, args.effort, kind)
        if evaluator
        else ({}, {}, {})
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
    rows = build_rows(
        models,
        results,
        catalogs,
        scores,
        shares,
        dates,
        rater,
        measured,
        base,
        rates,
        missing,
        weights,
    )
    rows = [row for row in rows if matches_limits(row, args.limit)]
    if args.limit and not rows:
        warn("no models match --limit")
        return 0
    rows = sort_rows(rows, args.order)
    use_color = not args.no_color and sys.stdout.isatty()
    trail = ["score", "sel", "rel"] if scores else []

    headers = ["model/provider"] + [name for name, _, _ in results] + trail
    credits = [fmt_balance(credit.get(name)) for name, _, _ in results]
    known = [credit.get(name) for name, _, _ in results]
    known = [v for v in known if v is not None]
    total = fmt_balance(sum(known)) if known else ""
    seen = render(rows, headers, credits, use_color, total)
    picked = any(row[1][1] for row in rows)
    only = any(str(row[1][1]).endswith(ONLY) for row in rows)
    print(
        f"{paint('green', GREEN, use_color)} = lowest, "
        f"{paint('red', RED, use_color)} = highest, "
        f"{paint('blue', BLUE, use_color)} = free"
    )
    if args.verbose:
        if weights:
            mix = "cache, input, output" if len(weights) == 3 else "input, output"
            shape = f"blended {ratio} {mix}"
        elif any(
            c[1] and len(c[1]) > 2 and c[1][2] is not None for *_, r in rows for c in r
        ):
            shape = "in, out, cached"
        else:
            shape = "in, out"
        print()
        if MEASURED in seen:
            print(
                f"{MEASURED} means the rate is measured from actual traffic, not estimated"
            )
        if GUESSED in seen:
            how = "the input price is used"
            if shares:
                how = f"estimated from {rater}, else the input price"
            print(f"{GUESSED} means no cache price is listed: {how}")
        if only:
            print(f"{ONLY} means {rater} tested only this effort level")
        print(f"- prices per 1M tokens in {base} ({shape})")
        if picked:
            print(
                f"- sel is a suggested effort level that gives "
                f"{args.keep:g}% of the top score"
            )
        if dates:
            print("- rel is the month the model was released")
        if scores and picked and args.effort:
            print(
                f"- score is the {kind} score at effort level {args.effort}, "
                "or the closest level below it"
            )
        elif scores and picked:
            print(f"- score is the {kind} score at the sel effort level")
        elif scores:
            print(f"- score is the {kind} score of {rater}")
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
