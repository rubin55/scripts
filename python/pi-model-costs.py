#!/usr/bin/env python3
"""Price tools for the providers in pi's models.json.

Commands:

  table   group equivalent models across providers, print prices
  usage   price neuralwatt energy billing from your own traffic
  scores  fetch artificial analysis intelligence scores

table is used when no command is given. Each takes --help.
Written data lives in ~/.pi/report-data.
"""

import argparse
import csv
import http.client
import json
import math
import os
import re
import shutil
import statistics
import subprocess
import sys
import urllib.parse
from datetime import datetime, timedelta, timezone
from pathlib import Path

REPORT_DATA = Path.home() / ".pi/report-data"
DEFAULT_CONFIG = Path.home() / ".pi/agent/models.json"
DEFAULT_CACHE = Path.home() / ".pi/model-doctor/models-cache.json"
DEFAULT_SCORES = REPORT_DATA / "aa-scores.json"
DEFAULT_USAGE = REPORT_DATA / "neuralwatt-usage.json"


def parse_json(text, label):
    """Decode JSON text, or exit."""
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        sys.exit(f"invalid json in {label}: {exc}")


def read_json(path):
    """Load a JSON file, or exit if it is missing or malformed."""
    try:
        text = path.read_text()
    except FileNotFoundError:
        sys.exit(f"no such file: {path}")
    except OSError as exc:
        sys.exit(f"could not read {path}: {exc}")
    return parse_json(text, path)


def read_providers(path):
    """Return the providers block of models.json."""
    return read_json(path)["providers"]


GREEN = "\033[32m"
RED = "\033[31m"
RESET = "\033[0m"
COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ


def paint(text, colour):
    """Wrap text in an ANSI colour, unless colour is turned off."""
    return f"{colour}{text}{RESET}" if COLOR else text


def fmt_price(value):
    return f"{value:.3f}".rstrip("0").rstrip(".")


def fmt_cell(value):
    """Three significant digits, five characters at most."""
    if 0 < value < 0.0005:
        return "<.001"
    if value >= 100:
        return f"{value:.0f}"
    if value >= 10:
        text = f"{value:.1f}"
    elif value >= 1:
        text = f"{value:.2f}"
    else:
        text = f"{value:.3f}"
    return text.rstrip("0").rstrip(".")


def fmt_score(value):
    return f"{value:.0f}" if value else "-"


# --- usage ---------------------------------------------------------

USAGE_DOC = """Derive neuralwatt's token prices from your own traffic.

Neuralwatt bills the GPU energy a request draws, at one rate per kWh
for every model, instead of a per-token rate. Which of the two you
pay is an account setting, so there is no per-request ceiling at the
token price.

Energy per request is not a property of the request alone. The meter
reads the whole server and attributes a share of it from the tokens
in flight, bounded by a cap, so the same request draws far more on a
quiet server than under load.

The per-request usage API lists every request you made with its token
split and its measured energy. --refresh pulls it into a cache file,
merging on request id so the history grows past the 30 days the API
serves, and the prices are then worked out from the cache alone. The
fit is

    cost = input_rate * input_tokens + output_rate * output_tokens

Requests are grouped into prompt-size bands, the same way neuralwatt
aggregates its own published figures, and each band is reduced to its
median request, which keeps one unlucky request from setting the
price. The fit is kept only when both rates come out above zero and
the output:input ratio is within a factor of the catalog; both rates
are then scaled so that they reproduce what you were actually billed
over the window. There is no constant term: the whole spend is
attributed to tokens, which is what a price per million tokens means.

Input counts fresh prompt tokens only, since cached tokens skip most
of the prefill work, so the rates compare against the input and
output prices other providers list. When the traffic cannot tell
input from output, the listed ratio is kept and the spend sets the
level.

Each row also says what it was charged, so the per kWh rate is read
from the data also. Credit bought before a price change drains first,
so the prices follow whatever your credit actually costs: top up at
a new rate and the next run reflects it.
"""

PROVIDER = "neuralwatt"

# Prompt sizes that split requests into bands, in tokens.
BANDS = [0, 500, 2000, 8000, 32000]

# Requests a model needs before it is priced, and a band before it
# counts towards the fit.
MIN_REQUESTS = 20
MIN_ROWS = 3
MAX_PAGES = 50

# Reject a fit whose output:input ratio is off the catalog by more
# than this factor either way. It stops a noisy window from inventing
# a split, at the price of hiding a divergence that is there.
RATIO_SPREAD = 4.0


def api_key(provider):
    """Read the provider key from pi."""
    out = subprocess.run(
        ["pi", "auth", "print-api-key", "--provider", provider],
        capture_output=True,
        text=True,
        check=False,
    )
    if out.returncode != 0 or not out.stdout.strip():
        sys.exit(f"could not get an api key for {provider}")
    return out.stdout.strip().splitlines()[-1]


def load_models(config, provider):
    """Return the base url and {model id: (input, output) price}."""
    entry = read_providers(config)[provider]
    models = {}
    for model in entry.get("models", []):
        cost = model.get("cost") or {}
        models[model["id"]] = (cost.get("input", 0.0), cost.get("output", 0.0))
    return entry["baseUrl"], models


def fetch_https_json(url, headers, timeout, label):
    """GET JSON over https, or exit."""
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "https" or not parsed.hostname:
        sys.exit(f"{label} is not https")
    path = parsed.path or "/"
    if parsed.query:
        path += "?" + parsed.query
    try:
        conn = http.client.HTTPSConnection(
            parsed.hostname, parsed.port, timeout=timeout
        )
        try:
            conn.request("GET", path, headers=headers)
            response = conn.getresponse()
            status, reason, body = response.status, response.reason, response.read()
        finally:
            conn.close()
    except (OSError, http.client.HTTPException) as exc:
        sys.exit(f"could not reach {label}: {exc}")
    # Redirects are not followed, so anything but 2xx is an error.
    if status >= 300:
        sys.exit(f"{label} returned {status}: {reason}")
    try:
        text = body.decode()
    except UnicodeDecodeError as exc:
        sys.exit(f"invalid response from {label}: {exc}")
    return parse_json(text, label)


def fetch_usage(base_url, key, days, timeout):
    """Return the request rows in the window and how they were billed."""
    # The api rejects a window over 30 days, so pin both ends of it.
    end = datetime.now(timezone.utc)
    start = end - timedelta(days=days)
    query = (
        f"limit=200&start_date={start:%Y-%m-%dT%H:%M:%SZ}"
        f"&end_date={end:%Y-%m-%dT%H:%M:%SZ}"
    )
    rows, cursor, accounting = [], None, None
    seen = set()
    headers = {"Authorization": f"Bearer {key}"}
    while True:
        url = f"{base_url}/usage/requests?{query}"
        if cursor:
            url += "&cursor=" + urllib.parse.quote(cursor, safe="")
        payload = fetch_https_json(url, headers, timeout, "usage api")
        rows += payload.get("requests", [])
        accounting = accounting or payload.get("accounting_method")
        cursor = payload.get("next_cursor")
        if not cursor:
            return rows, accounting
        if cursor in seen:
            sys.exit("usage api repeated a cursor")
        seen.add(cursor)
        # Stop rather than fail: the cache merges on request id, so
        # what was fetched still lands and the next run carries on.
        if len(seen) >= MAX_PAGES:
            print(f"stopped after {MAX_PAGES} pages", file=sys.stderr)
            return rows, accounting


def billed_rate(requests):
    """The USD per kWh the rows worked out at, or None.

    The same figure the dashboard export reports as
    energy_rate_applied: what was charged over the energy that was
    drawn. Credit bought before a price change drains first. It reads
    lower where a discount applied on the flex tier or where surge
    protection capped a request that drew more energy than expected.
    """
    spent = sum(e["usd"] for e in requests)
    energy = sum(e["kwh"] for e in requests if e["usd"])
    return spent / energy if spent and energy else None


def by_model(rows):
    """Group the usable rows per model."""
    models = {}
    for row in rows:
        name = row.get("requested_model") or row.get("model")
        prompt = row.get("prompt_tokens")
        output = row.get("completion_tokens")
        energy = row.get("energy_kwh")
        if not name or not energy or prompt is None or output is None:
            continue
        cached = min(row.get("cached_tokens") or 0, prompt)
        models.setdefault(name, []).append(
            {
                "prompt": prompt,
                "cached": cached,
                # Cached tokens skip the prefill, so they are not input.
                "input": prompt - cached,
                "output": output,
                "kwh": energy,
                "usd": row.get("cost_usd") or 0.0,
            }
        )
    return models


def aggregate(requests):
    """Reduce each prompt-size band to its median request.

    Energy attribution swings by two orders of magnitude between
    identical requests, depending on how busy the server was, and the
    high side is a long tail. A median over the whole band averages
    that down, field by field. Picking one request at the median
    prompt size would keep the tokens and the cost together, but it
    also takes a single draw from that spread, which measures several
    times noisier over this traffic.
    """
    bands = {}
    for entry in requests:
        edges = [e for e in BANDS if e <= entry["prompt"]]
        bands.setdefault(edges[-1], []).append(entry)

    points = [
        {
            "input": statistics.median(e["input"] for e in group),
            "output": statistics.median(e["output"] for e in group),
            "cost": statistics.median(e["cost"] for e in group),
            "band": band,
            "requests": len(group),
        }
        for band, group in sorted(bands.items())
    ]
    # Thin bands are noise. Keep them only if nothing else is left.
    return [p for p in points if p["requests"] >= MIN_ROWS] or points


def fit_rates(points, listed=None):
    """Fit cost = a * input + b * output over the bands.

    Each band is divided by its token count first, so long and short
    requests count the same, then weighted by sqrt(n), since a median
    over more requests carries less noise. That turns the fit into a
    line through the per-token cost against the input share, which
    needs the bands to cover a range of mixes. Returns None when they
    do not, when a rate is not above zero, or when the fitted
    output:input ratio is off the listed one.
    """
    sii = sio = soo = sic = soc = 0.0
    for p in points:
        tokens = p["input"] + p["output"]
        if not tokens:
            continue
        weight = math.sqrt(p["requests"])
        x = p["input"] / tokens
        y = p["output"] / tokens
        cost = p["cost"] / tokens
        sii += weight * x * x
        sio += weight * x * y
        soo += weight * y * y
        sic += weight * x * cost
        soc += weight * y * cost

    det = sii * soo - sio * sio
    if det <= 1e-12:
        return None
    a = (soo * sic - sio * soc) / det
    b = (sii * soc - sio * sic) / det
    if a <= 0 or b < 0:
        return None
    if listed:
        listed_in, listed_out = listed
        if listed_in > 0 and listed_out > 0:
            catalog = listed_out / listed_in
            if not catalog / RATIO_SPREAD <= b / a <= catalog * RATIO_SPREAD:
                return None
    return (a, b)


def analyse(requests, prices):
    """Fit the two rates and summarise the window."""
    listed_in, listed_out = prices
    # What was charged, not energy times a rate: a discounted or
    # surge-capped request cost less than its energy suggests.
    for entry in requests:
        entry["cost"] = entry["usd"]
    points = aggregate(requests)
    rates, method = fit_rates(points, prices), "fit"
    if rates is None and (listed_in or listed_out):
        # The traffic cannot tell input from output, so keep the
        # ratio the provider lists and let the spend set the level.
        rates, method = (listed_in / 1e6, listed_out / 1e6), "listed ratio"
    elif rates is None:
        rates, method = (1e-6, 1e-6), "flat"
    rate_in, rate_out = rates

    spent = sum(e["cost"] for e in requests)
    shaped = sum(rate_in * e["input"] + rate_out * e["output"] for e in requests)
    # The bands give the ratio between the two rates, the window's own
    # spend gives their level: above 1 means the median request sat
    # under the average one.
    scale = spent / shaped if shaped else 0.0
    rate_in, rate_out = rate_in * scale, rate_out * scale

    tokens_in = sum(e["input"] for e in requests)
    tokens_out = sum(e["output"] for e in requests)
    prompt = sum(e["prompt"] for e in requests)
    listed = (tokens_in * listed_in + tokens_out * listed_out) / 1e6

    return {
        "input": round(rate_in * 1e6, 6),
        "output": round(rate_out * 1e6, 6),
        "method": method,
        "requests": len(requests),
        "bands": len(points),
        "level_scale": round(scale, 3),
        "cached_share": round(sum(e["cached"] for e in requests) / prompt, 3)
        if prompt
        else None,
        "vs_listed": round(spent / listed, 4) if listed else None,
        "usd_per_mtok": round(spent / (tokens_in + tokens_out) * 1e6, 4),
        "milliwatt_hours_per_request": round(
            statistics.fmean(e["kwh"] * 1e6 for e in requests), 2
        ),
        "usd_per_request": round(spent / len(requests), 6),
        "billed_usd": round(spent, 6),
        "usd_per_kwh": round(billed_rate(requests) or 0.0, 2),
        "note": f"{method} over {len(requests)} requests in {len(points)} "
        f"prompt-size band{'' if len(points) == 1 else 's'}, "
        f"as billed",
    }


def refresh_cache(path, base_url, timeout):
    """Pull the api into the cache file, keeping older rows.

    The api only serves the last 30 days, so rows are merged on their
    request id and the cache grows past that window over time.
    """
    key = api_key(PROVIDER)
    fetched, accounting = fetch_usage(base_url, key, 30, timeout)

    rows = {}
    if path.exists():
        for row in read_json(path).get("requests", []):
            rows[row["request_id"]] = row
    added = sum(1 for row in fetched if row["request_id"] not in rows)
    for row in fetched:
        rows[row["request_id"]] = row

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(
            {
                "fetched": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "accounting_method": accounting,
                "requests": sorted(
                    rows.values(), key=lambda r: r["created_at"], reverse=True
                ),
            },
            indent=1,
        )
        + "\n"
    )
    print(f"cached {len(rows)} requests in {path}, {added} new")


def read_cache(path, days):
    """Return the cached rows inside the window, and how they billed."""
    if not path.exists():
        sys.exit(f"no usage cache at {path}, run with --refresh")
    data = read_json(path)
    since = datetime.now(timezone.utc) - timedelta(days=days)
    rows = [
        row
        for row in data.get("requests", [])
        if datetime.fromisoformat(row["created_at"]) >= since
    ]
    return rows, data.get("accounting_method")


def price_models(path, days, prices):
    """Price each model in prices from the cached requests.

    Returns the per-model figures and a line describing the window,
    or nothing when there is no cache, no energy billing, or no rate
    to read out of it.
    """
    if not path.exists():
        return None, None
    rows, accounting = read_cache(path, days)
    traffic = by_model(rows)

    # cost_usd is the token cost on a token-billed account, so the
    # ratio to energy is a rate only when the account bills energy.
    if accounting != "energy":
        return None, f"{len(rows)} requests over {days} days, billed by token"
    rate = billed_rate([e for group in traffic.values() for e in group])
    if not rate:
        return None, f"{len(rows)} requests over {days} days, no rate to read"

    results = {}
    for model, listed in prices.items():
        requests = traffic.get(model, [])
        if len(requests) >= MIN_REQUESTS:
            results[model] = analyse(requests, listed)
    return results, (
        f"{len(rows)} requests over {days} days, billed at {rate:.2f} USD/kWh"
    )


def cmd_usage(args):
    base_url, models = load_models(args.config, PROVIDER)
    if args.model:
        models = {k: v for k, v in models.items() if k in args.model}
    if not models:
        sys.exit("no models matched")

    if args.refresh or not args.requests.exists():
        refresh_cache(args.requests, base_url, args.timeout)
    results, window = price_models(args.requests, args.days, models)
    if results is None:
        sys.exit(window or "no usage cache")
    if not results:
        detail = f"no model had {MIN_REQUESTS} requests to fit"
        sys.exit(f"{window}\n{detail}" if window else detail)

    print(f"{window}\n")
    for model, stats in results.items():
        print(
            f"{model:18} in {stats['input']:7.4f}  out {stats['output']:7.4f}"
            f"  n {stats['requests']:4}  {stats['cached_share']:5.0%} cached"
            f"  {stats['method']}"
        )
    if args.verbose:
        print()
        print(json.dumps(results, indent=2))


# --- table ---------------------------------------------------------

TABLE_DOC = """Compare per-model prices across providers.

Reads the pi model config plus the pi-model-doctor models.dev cache,
groups equivalent models across providers, and prints a price table.
All prices are US dollars per million tokens.

A cell prices one million tokens at an assumed mix: --blend sets the
prompt:output ratio, --cached the share of prompt tokens that hit the
cache and bill at the lower cache read price. Agentic traffic resends
a long prompt every turn, so most of its tokens are cache reads, and
a comparison that ignores them ranks providers by a price you do not
pay.

An entry that leaves the cache price out of the catalog is charged
the input price for reads, so it is not made to look cheap by
omission. An entry that lists zero is taken at its word, which is
worth checking before reading much into a cheap cell: a placeholder
zero and a real free-cache offer look the same here.

Providers that bill energy instead of tokens are priced from the
request cache the usage command keeps, marked with ~ in the table.
Their measured rate already covers cached tokens, so --cached only
shifts how much of the mix bills at the fitted input rate.
"""


COLUMN_ORDER = [
    "opencode",
    "openrouter",
    "orcarouter",
    "edenai",
    "cortecs",
    "neuralwatt",
    "hetzner",
]

# Column headers, kept short so the table fits in 80 columns.
SHORT_NAMES = {
    "opencode": "ocode",
    "openrouter": "oroute",
    "orcarouter": "orca",
    "edenai": "eden",
    "neuralwatt": "nwatt",
}

WIDTH = 80
MIN_COLUMN = 7


def _terminal_width():
    """Current terminal width, or WIDTH when not a tty."""
    try:
        cols = shutil.get_terminal_size(fallback=(WIDTH, 24)).columns
        return cols if cols > 0 else WIDTH
    except Exception:
        return WIDTH


# Canonical model id -> ids treated as the same model.
MODEL_ALIASES = {
    "deepseek-v4-flash": [
        "deepseek-v4-flash",
        "deepseek-v4-flash-free",
        "deepseek-v4-flash-0731",
    ],
    "deepseek-v4-pro": [
        "deepseek-v4-pro",
        "deepseek-v4-pro-0813",
    ],
    "mistral-medium-3": [
        "mistral-medium-2505",
    ],
    "mistral-medium-3.1": [
        "mistral-medium-2508",
    ],
    "mistral-medium-3.5": [
        "mistral-medium-2604",
    ],
    "mistral-small-3.1": [
        "mistral-small-2503",
    ],
    "mistral-small-3.2": [
        "mistral-small-2506",
    ],
    "mistral-small-4": [
        "mistral-small-2603",
    ],
    "mistral-large-2": [
        "mistral-large-2411",
    ],
    "mistral-large-3": [
        "mistral-large-2512",
    ],
    "muse-spark-1.2": [
        "muse-spark-1.2",
        "muse-spark-1.2-contributor",
        "muse-spark-1.2-contributor-free",
    ],
    "muse-spark-1.3": [
        "muse-spark-1.3",
        "muse-spark-1.3-contributor",
        "muse-spark-1.3-contributor-free",
    ],
}


def normalise(model_id):
    """Reduce a provider-specific id to a comparable model key."""
    key = model_id.rsplit("/", 1)[-1].lower()
    key = key.split("@", 1)[0]  # drop region suffix
    if not re.fullmatch(
        r"(mistral-(medium|small|large)|codestral)-2[4-8](0[1-9]|1[0-2])",
        key,
    ):
        key = re.sub(r"-\d{4,8}$", "", key)  # drop dated snapshot suffix
    return key.replace("-", "").replace("_", "").replace(".", "")


_ALIAS_MAP = {
    normalise(variant): normalise(canonical)
    for canonical, variants in MODEL_ALIASES.items()
    for variant in variants
}

_CANONICAL_DISPLAY = {normalise(k): k for k in MODEL_ALIASES}


def canonical_key(key):
    """Map a normalised key through MODEL_ALIASES, or return it."""
    return _ALIAS_MAP.get(key, key)


def load_config(path):
    """Collect one row per configured provider/model pair."""
    providers = read_providers(path)
    rows = []
    for provider, entry in providers.items():
        for model in entry.get("models", []):
            cost = model.get("cost") or {}
            rows.append(
                {
                    "provider": provider,
                    "id": model["id"],
                    "key": canonical_key(normalise(model["id"])),
                    "input": cost.get("input", 0.0),
                    "output": cost.get("output", 0.0),
                    # None means the catalog lists no cache price.
                    "cache_read": cost.get("cacheRead"),
                    "tiered": "tiers" in cost,
                    "context": model.get("contextWindow"),
                    "max_tokens": model.get("maxTokens"),
                    "reasoning": bool(model.get("reasoning")),
                    "measured": False,
                }
            )
    # Fixed column order, anything unlisted trails in config order.
    order = {p: i for i, p in enumerate(COLUMN_ORDER)}
    return rows, sorted(providers, key=lambda p: order.get(p, len(order)))


def apply_measured(rows, cache, days):
    """Swap listed prices for the rates measured from cached usage."""
    listed = {
        row["id"]: (row["input"], row["output"])
        for row in rows
        if row["provider"] == PROVIDER
    }
    if not listed:
        return None
    measured, window = price_models(cache, days, listed)
    if not measured:
        return None
    for row in rows:
        stats = measured.get(row["id"]) if row["provider"] == PROVIDER else None
        if not stats:
            continue
        row["input"] = stats["input"]
        row["output"] = stats["output"]
        # The fit charges the whole spend to fresh input and output,
        # so a cached token carries nothing on top.
        row["cache_read"] = 0.0
        row["measured"] = True
    return window


def load_names(path, providers):
    """Map model key to a display name from the models.dev cache."""
    if not path.exists():
        return {}
    catalog = read_json(path)["data"]["providers"]
    names = {}
    for provider in providers:
        for model_id, model in catalog.get(provider, {}).get("models", {}).items():
            if model.get("name"):
                ck = canonical_key(normalise(model_id))
                name = model["name"]
                prev = names.get(ck)
                # Keep the shortest name when several variants map together.
                if prev is None or len(name) < len(prev):
                    names[ck] = name
    return names


def load_scores(path):
    """Map model key to its artificial analysis score entry."""
    if not path.exists():
        return {}
    raw = read_json(path)["models"]
    # Fold any variant keys already on disk onto their canonical.
    scores = {}
    for key, value in raw.items():
        ck = canonical_key(key)
        scores.setdefault(ck, value)
    return scores


def cache_price(row):
    """What one cached prompt token costs.

    A catalog with no cache price gets charged the input price, so a
    provider is not made to look cheap by leaving it out.
    """
    return row["input"] if row["cache_read"] is None else row["cache_read"]


def blended(row, weight, cached):
    """Cost per million tokens at the given mix.

    weight is prompt:output tokens and cached the share of the prompt
    served from cache. The prompt that misses bills at the input
    price, the rest at the cache read price.
    """
    prompt = weight / (weight + 1.0)
    return (
        row["input"] * prompt * (1.0 - cached)
        + cache_price(row) * prompt * cached
        + row["output"] * (1.0 - prompt)
    )


def priced(row):
    """False when the catalog carries no pricing for this entry."""
    return row["input"] > 0 or row["output"] > 0


def rank(row):
    """Sort key for cheapest: price, then flat pricing, then output."""
    return (round(row["blended"], 3), row["tiered"], row["output"])


def group(rows, names, weight, cached, count_free):
    """Group rows by model key and pick the cheapest provider."""
    groups = {}
    for row in rows:
        row["blended"] = blended(row, weight, cached)
        groups.setdefault(row["key"], []).append(row)

    result = []
    for key, entries in groups.items():
        usable = entries if count_free else [r for r in entries if priced(r)]
        best = min(usable, key=rank) if usable else None
        worst = max(usable, key=rank) if usable else None
        save = 0.0
        if best and worst and worst["blended"] > 0:
            save = 1.0 - best["blended"] / worst["blended"]
        result.append(
            {
                "key": key,
                "name": names.get(key, _CANONICAL_DISPLAY.get(key, entries[0]["id"])),
                "entries": entries,
                "best": best,
                "worst": worst,
                "save": save,
                "cheapest_price": best["blended"] if best else math.inf,
            }
        )
    return result


def cell_text(row):
    """The price cell for one provider, without colour."""
    if row is None:
        return "-"
    if not priced(row):
        return "free?"
    text = fmt_cell(row["blended"])
    if row["measured"]:
        text += "~"
    if row["tiered"]:
        text += "+"
    return text


def measure_table(groups, providers, tail, max_width=None):
    """Work out the column headers, cells and widths.

    Model names take whatever the terminal leaves. If the table fits
    within max_width the names are shown in full, otherwise the name
    column is shortened.
    """
    if max_width is None:
        max_width = _terminal_width()
    heads = [(SHORT_NAMES.get(p) or p)[:MIN_COLUMN] for p in providers]
    cells = {}
    for grp in groups:
        by_provider = {r["provider"]: r for r in grp["entries"]}
        for provider in providers:
            cells[grp["key"], provider] = cell_text(by_provider.get(provider))

    widths = [
        max(MIN_COLUMN, *(len(cells[g["key"], p]) for g in groups)) for p in providers
    ]
    max_name = (
        max(len("model"), *(len(g["name"]) for g in groups)) if groups else len("model")
    )
    room = max_width - sum(w + 1 for w in widths) - tail
    if max_name <= room:
        name_width = max_name
    else:
        name_width = min(max_name, max(len("model"), room))
    return heads, cells, widths, name_width


def print_table(groups, providers, weight, cached, window):
    """Render the comparison table, one row per model."""
    scored = any(g["intel"] is not None for g in groups)
    coded = any(g["code"] is not None for g in groups)
    tail = 6 + (6 if scored else 0) + (6 if coded else 0)
    max_width = _terminal_width()
    heads, cells, widths, name_width = measure_table(groups, providers, tail, max_width)

    header = "model".ljust(name_width)
    for head, width in zip(heads, widths, strict=True):
        header += " " + head.rjust(width)
    header += "  save"
    if scored:
        header += " intel"
    if coded:
        header += "  code"
    print(header)
    print("-" * len(header))

    for grp in groups:
        line = grp["name"][:name_width].ljust(name_width)
        by_provider = {r["provider"]: r for r in grp["entries"]}
        for provider, width in zip(providers, widths, strict=True):
            row = by_provider.get(provider)
            cell = cells[grp["key"], provider].rjust(width)
            if row is grp["best"]:
                cell = paint(cell, GREEN)
            elif row is grp["worst"]:
                cell = paint(cell, RED)
            line += " " + cell
        line += "  " + (f"{grp['save']:.0%}" if grp["save"] > 0 else "-").rjust(4)
        if scored:
            line += f"{fmt_score(grp['intel']):>6}"
        if coded:
            line += f"{fmt_score(grp['code']):>6}"
        print(line)


def print_details(groups):
    """Print per-model context, output ceiling and reasoning support."""
    print("\nlisted input and output price, context, output ceiling")
    detail_width = _terminal_width()
    for grp in sorted(groups, key=lambda g: g["key"]):
        print(f"\n{grp['name'][:detail_width]}")
        for row in sorted(grp["entries"], key=lambda r: r["blended"]):
            ctx = f"{row['context'] / 1000:.0f}K" if row["context"] else "?"
            out = f"{row['max_tokens'] / 1000:.0f}K" if row["max_tokens"] else "?"
            think = "reason" if row["reasoning"] else "-"
            # Keep the tail of a long id, the vendor prefix repeats.
            model_id = row["id"] if len(row["id"]) <= 27 else row["id"][-27:]
            print(
                f"  {row['provider']:11}{model_id:28}"
                f"{fmt_price(row['input']):>7}{fmt_price(row['output']):>8}"
                f"{ctx:>7}{out:>6}{think:>7}"
            )


def write_csv(groups, stream):
    writer = csv.writer(stream)
    writer.writerow(
        [
            "model",
            "provider",
            "id",
            "input",
            "output",
            "cache_read",
            "blended",
            "context",
            "max_tokens",
            "reasoning",
            "tiered",
            "measured",
            "cheapest",
            "intel",
            "code",
        ]
    )
    for grp in groups:
        for row in grp["entries"]:
            writer.writerow(
                [
                    grp["name"],
                    row["provider"],
                    row["id"],
                    row["input"],
                    row["output"],
                    row["cache_read"],
                    round(row["blended"], 4),
                    row["context"],
                    row["max_tokens"],
                    row["reasoning"],
                    row["tiered"],
                    row["measured"],
                    row is grp["best"],
                    grp["intel"],
                    grp["code"],
                ]
            )


def cmd_table(args):
    if not 0.0 <= args.cached <= 1.0:
        sys.exit("--cached takes a share between 0 and 1")

    rows, providers = load_config(args.config)
    if args.provider:
        providers = [p for p in providers if p in args.provider]
        rows = [r for r in rows if r["provider"] in providers]
    if not rows:
        sys.exit("no models matched")

    window = None
    if not args.listed:
        window = apply_measured(rows, args.requests, args.days)

    names = load_names(args.cache, providers)
    groups = group(rows, names, args.blend, args.cached, args.count_free)

    scores = load_scores(args.scores)
    for grp in groups:
        entry = scores.get(grp["key"], {})
        grp["intel"] = entry.get("intelligence")
        grp["code"] = entry.get("coding")

    groups.sort(
        key={
            "price": lambda g: g["cheapest_price"],
            "name": lambda g: g["name"].lower(),
            "save": lambda g: -g["save"],
            "intel": lambda g: -(g["intel"] or 0),
            "code": lambda g: -(g["code"] or 0),
        }[args.sort]
    )

    if args.csv:
        write_csv(groups, sys.stdout)
        return
    print_table(groups, providers, args.blend, args.cached, window)
    if args.details:
        print_details(groups)


# --- scores --------------------------------------------------------

SCORES_DOC = """Fetch artificial analysis index scores.

Downloads the whole model list in one request and keeps the
intelligence and coding indexes, so the table command can show them
without going online.
Needs a free API key from https://artificialanalysis.ai/, passed
with --key or in AA_API_KEY. Use of the free tier requires
attribution, which the table legend prints.

Scores are per model, not per provider endpoint, so every provider
serving a model shares its score.
"""

AA_URL = "https://artificialanalysis.ai/api/v2/data/llms/models"


def fetch_scores(key, timeout):
    """Return {model key: score entry} from the artificial analysis API."""
    payload = fetch_https_json(
        AA_URL, {"x-api-key": key}, timeout, "artificial analysis api"
    )
    entries = payload.get("data", payload) if isinstance(payload, dict) else payload
    if isinstance(entries, dict):
        entries = entries.get("models", [])

    scores = {}
    for model in entries:
        # Some responses nest the indexes, others keep them flat.
        evaluations = model.get("evaluations") or model
        index = evaluations.get("artificial_analysis_intelligence_index")
        slug = model.get("slug") or model.get("id")
        if index is None or not slug:
            continue
        scores.setdefault(
            canonical_key(normalise(slug)),
            {
                "name": model.get("name") or slug,
                "slug": slug,
                "intelligence": index,
                "coding": evaluations.get("artificial_analysis_coding_index"),
            },
        )
    return scores


def cmd_scores(args):
    key = args.key or os.environ.get("AA_API_KEY")
    if not key:
        sys.exit("no api key: pass --key or set AA_API_KEY")

    scores = fetch_scores(key, args.timeout)
    if not scores:
        sys.exit("the api returned no intelligence scores")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps(
            {
                "generated": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "source": "https://artificialanalysis.ai/",
                "models": scores,
            },
            indent=2,
        )
        + "\n"
    )
    print(f"wrote {len(scores)} scores to {args.out}")

    rows, _ = load_config(args.config)
    missing = {r["key"]: r["id"] for r in rows if r["key"] not in scores}
    if missing:
        print("\nno score for these:")
        for model_key, model_id in sorted(missing.items()):
            print(f"  {model_key:24} {model_id}")


# --- entry point ---------------------------------------------------


def main():
    plain = argparse.RawDescriptionHelpFormatter
    shared = argparse.ArgumentParser(add_help=False)
    shared.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG,
        help="pi models.json (default: %(default)s)",
    )

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=plain)
    commands = parser.add_subparsers(metavar="COMMAND")

    table = commands.add_parser(
        "table",
        parents=[shared],
        help="print the price table",
        description=TABLE_DOC,
        formatter_class=plain,
    )
    table.set_defaults(run=cmd_table)
    table.add_argument(
        "--cache",
        type=Path,
        default=DEFAULT_CACHE,
        help="model-doctor models.dev cache (default: %(default)s)",
    )
    table.add_argument(
        "--blend",
        type=float,
        default=6.0,
        metavar="N",
        help="prompt:output token ratio to price at (default: %(default)s)",
    )
    table.add_argument(
        "--cached",
        type=float,
        default=0.7,
        metavar="N",
        help="share of the prompt served from cache (default: %(default)s)",
    )
    table.add_argument(
        "--sort",
        default="price",
        choices=("price", "name", "save", "intel", "code"),
        help="row order (default: %(default)s)",
    )
    table.add_argument(
        "--provider",
        action="append",
        metavar="ID",
        help="limit to a provider, repeatable",
    )
    table.add_argument(
        "--requests",
        type=Path,
        default=DEFAULT_USAGE,
        help="neuralwatt request cache (default: %(default)s)",
    )
    table.add_argument(
        "--days",
        type=int,
        default=30,
        metavar="N",
        help="window of cached requests to price from (default: %(default)s)",
    )
    table.add_argument(
        "--listed", action="store_true", help="use listed prices, ignore measured ones"
    )
    table.add_argument(
        "--count-free",
        action="store_true",
        help="let unpriced entries win the cheapest column",
    )
    table.add_argument(
        "--details",
        action="store_true",
        help="also print per-provider limits and reasoning",
    )
    table.add_argument(
        "--scores",
        type=Path,
        default=DEFAULT_SCORES,
        help="intelligence scores (default: %(default)s)",
    )
    table.add_argument("--csv", action="store_true", help="emit CSV instead of a table")

    scores = commands.add_parser(
        "scores",
        parents=[shared],
        help="fetch intelligence scores",
        description=SCORES_DOC,
        formatter_class=plain,
    )
    scores.set_defaults(run=cmd_scores)
    scores.add_argument(
        "--key", help="artificial analysis api key (default: $AA_API_KEY)"
    )
    scores.add_argument(
        "--out",
        type=Path,
        default=DEFAULT_SCORES,
        help="scores file to write (default: %(default)s)",
    )
    scores.add_argument("--timeout", type=int, default=60)

    usage = commands.add_parser(
        "usage",
        parents=[shared],
        help="price neuralwatt from your traffic",
        description=USAGE_DOC,
        formatter_class=plain,
    )
    usage.set_defaults(run=cmd_usage)
    usage.add_argument(
        "--requests",
        type=Path,
        default=DEFAULT_USAGE,
        help="request cache to read (default: %(default)s)",
    )
    usage.add_argument(
        "--refresh", action="store_true", help="pull the usage api into the cache first"
    )
    usage.add_argument(
        "--days",
        type=int,
        default=30,
        metavar="N",
        help="window of cached requests to use (default: %(default)s)",
    )
    usage.add_argument("--timeout", type=int, default=60)
    usage.add_argument(
        "--model", action="append", metavar="ID", help="limit to a model, repeatable"
    )
    usage.add_argument(
        "--verbose", action="store_true", help="also print the full figures per model"
    )

    argv = sys.argv[1:]
    if not argv or argv[0] not in ("table", "usage", "scores", "-h", "--help"):
        argv.insert(0, "table")
    args = parser.parse_args(argv)
    args.run(args)


if __name__ == "__main__":
    main()
