#!/usr/bin/env python3
"""Price tools for the providers in pi's models.json.

Commands:

  table   group equivalent models across providers, print prices
  probe   sample neuralwatt energy billing, write price overrides
  scores  fetch artificial analysis intelligence scores

table is used when no command is given. Each takes --help.
Written data lives in ~/.pi/report-data.
"""

import argparse
import csv
import json
import os
import re
import statistics
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

REPORT_DATA = Path.home() / ".pi/report-data"
DEFAULT_CONFIG = Path.home() / ".pi/agent/models.json"
DEFAULT_CACHE = Path.home() / ".pi/model-doctor/models-cache.json"
DEFAULT_OVERRIDES = REPORT_DATA / "price-overrides.json"
DEFAULT_SCORES = REPORT_DATA / "aa-scores.json"


def read_providers(path):
    """Return the providers block of models.json."""
    return json.loads(path.read_text())["providers"]


GREEN = "\033[32m"
RED = "\033[31m"
RESET = "\033[0m"
COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ


def paint(text, colour):
    """Wrap text in an ANSI colour, unless colour is turned off."""
    return f"{colour}{text}{RESET}" if COLOR else text


def fmt_price(value):
    return f"{value:.3f}".rstrip("0").rstrip(".")


def fmt_score(value):
    return f"{value:.0f}" if value else "-"


# --- table ---------------------------------------------------------

TABLE_DOC = """Compare per-model prices across providers.

Reads the pi model config plus the pi-model-doctor models.dev cache,
groups equivalent models across providers, and prints a price table.
All prices are US dollars per million tokens.
"""


COLUMN_ORDER = ["orcarouter", "edenai", "cortecs", "neuralwatt", "hetzner"]

# Config key -> artificial analysis key, for names that differ.
ALIASES = {}


def normalise(model_id):
    """Reduce a provider-specific id to a comparable model key."""
    key = model_id.rsplit("/", 1)[-1].lower()
    key = key.split("@", 1)[0]           # drop region suffix
    key = re.sub(r"-\d{4,8}$", "", key)  # drop dated snapshot suffix
    return key.replace("-", "").replace("_", "").replace(".", "")


def load_config(path):
    """Collect one row per configured provider/model pair."""
    providers = read_providers(path)
    rows = []
    for provider, entry in providers.items():
        for model in entry.get("models", []):
            cost = model.get("cost") or {}
            rows.append({
                "provider": provider,
                "id": model["id"],
                "key": normalise(model["id"]),
                "input": cost.get("input", 0.0),
                "output": cost.get("output", 0.0),
                "cache_read": cost.get("cacheRead", 0.0),
                "tiered": "tiers" in cost,
                "context": model.get("contextWindow"),
                "max_tokens": model.get("maxTokens"),
                "reasoning": bool(model.get("reasoning")),
                "measured": False,
            })
    # Fixed column order, anything unlisted trails in config order.
    rank = {p: i for i, p in enumerate(COLUMN_ORDER)}
    return rows, sorted(providers, key=lambda p: rank.get(p, len(rank)))


def apply_overrides(rows, path):
    """Swap listed prices for measured effective rates where known."""
    if not path or not path.exists():
        return None
    data = json.loads(path.read_text())
    by_provider = data.get("providers", {})
    for row in rows:
        entry = by_provider.get(row["provider"], {}).get(row["id"])
        if not entry:
            continue
        row["input"] = entry.get("input", row["input"])
        row["output"] = entry.get("output", row["output"])
        row["measured"] = True
    return data


def load_names(path, providers):
    """Map model key to a display name from the models.dev cache."""
    if not path.exists():
        return {}
    catalog = json.loads(path.read_text())["data"]["providers"]
    names = {}
    for provider in providers:
        for model_id, model in catalog.get(provider, {}).get("models", {}).items():
            if model.get("name"):
                names.setdefault(normalise(model_id), model["name"])
    return names


def load_scores(path):
    """Map model key to its artificial analysis score entry."""
    if not path.exists():
        return {}
    return json.loads(path.read_text())["models"]


def blended(row, weight):
    """Cost per million tokens at the given input:output mix."""
    share = weight / (weight + 1.0)
    return row["input"] * share + row["output"] * (1.0 - share)


def priced(row):
    """False when the catalog carries no pricing for this entry."""
    return row["input"] > 0 or row["output"] > 0


def rank(row):
    """Sort key for cheapest: price, then flat pricing, then output."""
    return (round(row["blended"], 3), row["tiered"], row["output"])


def group(rows, names, weight, count_free):
    """Group rows by model key and pick the cheapest provider."""
    groups = {}
    for row in rows:
        row["blended"] = blended(row, weight)
        groups.setdefault(row["key"], []).append(row)

    result = []
    for key, entries in groups.items():
        usable = entries if count_free else [r for r in entries if priced(r)]
        best = min(usable, key=rank) if usable else None
        worst = max(usable, key=rank) if usable else None
        save = 0.0
        if best and worst and worst["blended"] > 0:
            save = 1.0 - best["blended"] / worst["blended"]
        result.append({
            "key": key,
            "name": names.get(key, entries[0]["id"]),
            "entries": entries,
            "best": best,
            "worst": worst,
            "save": save,
            "cheapest_price": best["blended"] if best else float("inf"),
        })
    return result


def print_table(groups, providers, weight, overrides):
    """Render the comparison table, one row per model."""
    name_width = max(len("model"), *(len(g["name"]) for g in groups))
    widths = [max(len(p), 8) for p in providers]
    scored = any(g["intel"] is not None for g in groups)
    coded = any(g["code"] is not None for g in groups)

    header = "model".ljust(name_width)
    for provider, width in zip(providers, widths):
        header += "  " + provider.rjust(width)
    header += "  save"
    if scored:
        header += "  intel"
    if coded:
        header += "   code"
    print(header)
    print("-" * len(header))

    for grp in groups:
        line = grp["name"].ljust(name_width)
        by_provider = {r["provider"]: r for r in grp["entries"]}
        for provider, width in zip(providers, widths):
            row = by_provider.get(provider)
            if row is None:
                cell = "-"
            elif not priced(row):
                cell = "free?"
            else:
                cell = fmt_price(row["blended"])
                if row["measured"]:
                    cell += "~"
                if row["tiered"]:
                    cell += "+"
            cell = cell.rjust(width)
            if row is grp["best"]:
                cell = paint(cell, GREEN)
            elif row is grp["worst"]:
                cell = paint(cell, RED)
            line += "  " + cell
        line += "  " + (f"{grp['save']:.0%}" if grp["save"] > 0 else "-").rjust(4)
        if scored:
            line += f"  {fmt_score(grp['intel']):>5}"
        if coded:
            line += f"  {fmt_score(grp['code']):>5}"
        print(line)

    print()
    print(f"USD per million tokens, blended at {weight}:1 input:output.")
    print(f"{paint('cheapest', GREEN)}     {paint('most expensive', RED)}"
          "     + has tiered pricing above a context threshold")
    print("free?        no pricing in the catalog, excluded from cheapest")
    if scored:
        label = "intel, code" if coded else "intel"
        print(f"{label:12} artificial analysis index scores, from "
              "https://artificialanalysis.ai/")
    if overrides:
        print(f"~            measured effective rate, not the listed price "
              f"({overrides.get('tariff_source', 'see overrides file')})")


def print_details(groups):
    """Print per-model context, output ceiling and reasoning support."""
    for grp in sorted(groups, key=lambda g: g["key"]):
        print(f"\n{grp['name']}")
        for row in sorted(grp["entries"], key=lambda r: r["blended"]):
            ctx = f"{row['context'] / 1000:.0f}K" if row["context"] else "?"
            out = f"{row['max_tokens'] / 1000:.0f}K" if row["max_tokens"] else "?"
            think = "reasoning" if row["reasoning"] else "-"
            print(f"  {row['provider']:12} {row['id']:28} "
                  f"in {fmt_price(row['input']):>7}  out {fmt_price(row['output']):>7}  "
                  f"ctx {ctx:>7}  max {out:>6}  {think}")


def write_csv(groups, stream):
    writer = csv.writer(stream)
    writer.writerow(["model", "provider", "id", "input", "output",
                     "cache_read", "blended", "context", "max_tokens",
                     "reasoning", "tiered", "cheapest", "intel", "code"])
    for grp in groups:
        for row in grp["entries"]:
            writer.writerow([grp["name"], row["provider"], row["id"],
                             row["input"], row["output"], row["cache_read"],
                             round(row["blended"], 4), row["context"],
                             row["max_tokens"], row["reasoning"], row["tiered"],
                             row is grp["best"], grp["intel"], grp["code"]])


def cmd_table(args):
    if not args.config.exists():
        sys.exit(f"no such file: {args.config}")

    rows, providers = load_config(args.config)
    if args.provider:
        providers = [p for p in providers if p in args.provider]
        rows = [r for r in rows if r["provider"] in providers]
    if not rows:
        sys.exit("no models matched")

    overrides = None
    if not args.no_overrides:
        overrides = apply_overrides(rows, args.overrides)

    names = load_names(args.cache, providers)
    groups = group(rows, names, args.blend, args.count_free)

    scores = load_scores(args.scores)
    for grp in groups:
        entry = scores.get(ALIASES.get(grp["key"], grp["key"]), {})
        grp["intel"] = entry.get("intelligence")
        grp["code"] = entry.get("coding")

    groups.sort(key={
        "price": lambda g: g["cheapest_price"],
        "name": lambda g: g["name"].lower(),
        "save": lambda g: -g["save"],
        "intel": lambda g: -(g["intel"] or 0),
        "code": lambda g: -(g["code"] or 0),
    }[args.sort])

    if args.csv:
        write_csv(groups, sys.stdout)
        return
    print_table(groups, providers, args.blend, overrides)
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
    request = urllib.request.Request(AA_URL, headers={"x-api-key": key})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.load(response)
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
        scores.setdefault(normalise(slug), {
            "name": model.get("name") or slug,
            "slug": slug,
            "intelligence": index,
            "coding": evaluations.get("artificial_analysis_coding_index"),
        })
    return scores


def cmd_scores(args):
    key = args.key or os.environ.get("AA_API_KEY")
    if not key:
        sys.exit("no api key: pass --key or set AA_API_KEY")

    scores = fetch_scores(key, args.timeout)
    if not scores:
        sys.exit("the api returned no intelligence scores")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps({
        "generated": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "source": "https://artificialanalysis.ai/",
        "models": scores,
    }, indent=2) + "\n")
    print(f"wrote {len(scores)} scores to {args.out}")

    rows, _ = load_config(args.config)
    missing = {r["key"]: r["id"] for r in rows
               if ALIASES.get(r["key"], r["key"]) not in scores}
    if missing:
        print("\nno score for these, add them to ALIASES:")
        for model_key, model_id in sorted(missing.items()):
            print(f"  {model_key:24} {model_id}")


# --- probe ---------------------------------------------------------

PROBE_DOC = """Measure neuralwatt's effective token price under energy billing.

Neuralwatt charges the lesser of an energy tariff and a ceiling set
at a multiple of the advertised token price:

    cost = min(tariff * energy_kWh, cap_multiple * token_price)

Energy drawn per request varies a lot, because attribution is
prorated across a shared GPU pool, so the effective rate has to be
sampled rather than calculated. This sends a few requests per model,
recomputes what each would cost at the chosen tariff, and writes an
overrides file that the table command reads.

Samples are billed at whatever rate your current credit was bought
at, which was 5.00 USD/kWh. The reported figures use --tariff
instead, so they project the rate you pay on your next top-up.
"""

PROVIDER = "neuralwatt"
PROMPT = "Explain what a hash map is, in one paragraph."
FILLER = ("Context follows. A hash table stores keys in buckets chosen by a "
          "hash function, and resolves collisions by probing or chaining. ")


def build_prompt(prompt_tokens):
    """Pad the prompt to roughly the requested input size."""
    if not prompt_tokens:
        return PROMPT
    # Rough but steady across these tokenisers: four chars per token.
    repeats = max(0, (prompt_tokens * 4 - len(PROMPT)) // len(FILLER))
    return FILLER * repeats + PROMPT


def api_key(provider):
    """Read the provider key from pi rather than the environment."""
    out = subprocess.run(["pi", "auth", "print-api-key", "--provider", provider],
                         capture_output=True, text=True)
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


def sample(base_url, key, model, cap_tokens, timeout, prompt):
    """Send one request and pull out tokens, energy and charge."""
    body = json.dumps({"model": model, "max_tokens": cap_tokens,
                       "messages": [{"role": "user", "content": prompt}]}).encode()
    request = urllib.request.Request(f"{base_url}/chat/completions", data=body,
                                     headers={"Authorization": f"Bearer {key}",
                                              "Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.load(response)
    usage = payload["usage"]
    return {"input": usage["prompt_tokens"], "output": usage["completion_tokens"],
            "kwh": (payload.get("energy") or {}).get("energy_kwh"),
            "usd": payload["cost"]["request_cost_usd"]}


def analyse(samples, prices, tariff, cap_multiple):
    """Recost the samples at the given tariff and summarise."""
    listed_in, listed_out = prices
    tokens_in = sum(s["input"] for s in samples)
    tokens_out = sum(s["output"] for s in samples)
    listed_total = (tokens_in * listed_in + tokens_out * listed_out) / 1e6

    projected, capped = [], 0
    for s in samples:
        cap = cap_multiple * (s["input"] * listed_in + s["output"] * listed_out) / 1e6
        energy_cost = tariff * s["kwh"] if s["kwh"] is not None else cap
        if energy_cost >= cap - 1e-12:
            capped += 1
        projected.append(min(energy_cost, cap))

    total = sum(projected)
    scale = total / listed_total if listed_total else 0.0
    per_mtok = [p / (s["input"] + s["output"]) * 1e6
                for p, s in zip(projected, samples)]
    energies = [s["kwh"] * 1e6 for s in samples if s["kwh"] is not None]

    return {
        "input": round(listed_in * scale, 6),
        "output": round(listed_out * scale, 6),
        "scale": round(scale, 4),
        "samples": len(samples),
        "capped": capped,
        "usd_per_mtok_mean": round(statistics.fmean(per_mtok), 4),
        "usd_per_mtok_min": round(min(per_mtok), 4),
        "usd_per_mtok_max": round(max(per_mtok), 4),
        "mwh_per_request": round(statistics.fmean(energies), 2) if energies else None,
        "usd_per_request": round(total / len(samples), 6),
        "billed_usd": round(sum(s["usd"] for s in samples), 6),
        "note": f"measured {datetime.now(timezone.utc):%Y-%m-%d}, "
                f"{capped}/{len(samples)} requests hit the price ceiling",
    }


def cmd_probe(args):
    base_url, models = load_models(args.config, PROVIDER)
    if args.model:
        models = {k: v for k, v in models.items() if k in args.model}
    if not models:
        sys.exit("no models matched")
    key = api_key(PROVIDER)
    prompt = build_prompt(args.prompt_tokens)

    print(f"tariff {args.tariff} USD/kWh, "
          f"ceiling at {args.cap_multiple}x token price\n")

    results, billed = {}, 0.0
    for model, prices in models.items():
        samples = []
        for i in range(args.samples):
            try:
                samples.append(sample(base_url, key, model, args.max_tokens,
                                      args.timeout, prompt))
            except (urllib.error.URLError, ValueError, KeyError) as exc:
                print(f"  {model} sample {i + 1} failed: {exc}", file=sys.stderr)
                continue
            time.sleep(0.4)
        if not samples:
            print(f"{model:22} no usable samples", file=sys.stderr)
            continue
        stats = analyse(samples, prices, args.tariff, args.cap_multiple)
        results[model] = stats
        billed += stats["billed_usd"]
        print(f"{model:22} {stats['usd_per_mtok_mean']:8.4f} usd/Mtok  "
              f"{stats['mwh_per_request'] or 0:8.2f} mWh/req  "
              f"{stats['usd_per_request']:9.6f} usd/req  "
              f"{stats['scale']:5.2f}x listed  {stats['capped']}/{stats['samples']} capped")

    print(f"\nbilled {billed:.6f} usd for this run at your existing credit rate")
    if args.dry_run:
        return

    args.out.parent.mkdir(parents=True, exist_ok=True)
    payload = {}
    if args.out.exists():
        payload = json.loads(args.out.read_text())
    payload.setdefault("providers", {})[PROVIDER] = results
    payload["generated"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
    payload["tariff_source"] = f"{args.tariff} USD/kWh"
    payload["cap_multiple"] = args.cap_multiple
    payload["prompt_tokens"] = args.prompt_tokens
    args.out.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"wrote {args.out}")


# --- entry point ---------------------------------------------------

def main():
    plain = argparse.RawDescriptionHelpFormatter
    shared = argparse.ArgumentParser(add_help=False)
    shared.add_argument("--config", type=Path, default=DEFAULT_CONFIG,
                        help="pi models.json (default: %(default)s)")

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=plain)
    commands = parser.add_subparsers(metavar="COMMAND")

    table = commands.add_parser("table", parents=[shared], help="print the price table",
                                description=TABLE_DOC, formatter_class=plain)
    table.set_defaults(run=cmd_table)
    table.add_argument("--cache", type=Path, default=DEFAULT_CACHE,
                       help="model-doctor models.dev cache (default: %(default)s)")
    table.add_argument("--blend", type=float, default=3.0, metavar="N",
                       help="input:output token ratio for blending (default: %(default)s)")
    table.add_argument("--sort", default="price",
                       choices=("price", "name", "save", "intel", "code"),
                       help="row order (default: %(default)s)")
    table.add_argument("--provider", action="append", metavar="ID",
                       help="limit to a provider, repeatable")
    table.add_argument("--overrides", type=Path, default=DEFAULT_OVERRIDES,
                       help="measured price overrides (default: %(default)s)")
    table.add_argument("--no-overrides", action="store_true",
                       help="ignore the overrides file and use listed prices")
    table.add_argument("--count-free", action="store_true",
                       help="let unpriced entries win the cheapest column")
    table.add_argument("--details", action="store_true",
                       help="also print per-provider limits and modalities")
    table.add_argument("--scores", type=Path, default=DEFAULT_SCORES,
                       help="intelligence scores (default: %(default)s)")
    table.add_argument("--csv", action="store_true",
                       help="emit CSV instead of a table")

    scores = commands.add_parser("scores", parents=[shared],
                                 help="fetch intelligence scores",
                                 description=SCORES_DOC, formatter_class=plain)
    scores.set_defaults(run=cmd_scores)
    scores.add_argument("--key", help="artificial analysis api key "
                                      "(default: $AA_API_KEY)")
    scores.add_argument("--out", type=Path, default=DEFAULT_SCORES,
                        help="scores file to write (default: %(default)s)")
    scores.add_argument("--timeout", type=int, default=60)

    probe = commands.add_parser("probe", parents=[shared], help="measure neuralwatt prices",
                                description=PROBE_DOC, formatter_class=plain)
    probe.set_defaults(run=cmd_probe)
    probe.add_argument("--out", type=Path, default=DEFAULT_OVERRIDES,
                       help="overrides file to write (default: %(default)s)")
    probe.add_argument("--samples", type=int, default=8, metavar="N",
                       help="requests per model (default: %(default)s)")
    probe.add_argument("--max-tokens", type=int, default=256)
    probe.add_argument("--prompt-tokens", type=int, default=0, metavar="N",
                       help="pad the prompt to roughly N input tokens")
    probe.add_argument("--timeout", type=int, default=180)
    probe.add_argument("--tariff", type=float, default=10.0, metavar="USD",
                       help="energy price in USD per kWh (default: %(default)s)")
    probe.add_argument("--cap-multiple", type=float, default=1.5, metavar="N",
                       help="ceiling as a multiple of token price (default: %(default)s)")
    probe.add_argument("--model", action="append", metavar="ID",
                       help="limit to a model, repeatable")
    probe.add_argument("--dry-run", action="store_true",
                       help="print results without writing the overrides file")

    argv = sys.argv[1:]
    if not argv or argv[0] not in ("table", "probe", "scores", "-h", "--help"):
        argv.insert(0, "table")
    args = parser.parse_args(argv)
    args.run(args)


if __name__ == "__main__":
    main()
