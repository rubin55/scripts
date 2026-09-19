#!/usr/bin/env python3
"""Generate Codex model catalog JSON files from configured providers.

Reads model_providers from ~/.codex/config.toml, fetches each
<base_url>/models?client_version=... and writes
~/.codex/model-catalogs/<provider>.json in the Codex native
{"models": [...]} format.

Providers that already serve the Codex format (OpenRouter and
compatible routers sniff the codex-cli User-Agent) are saved as-is.
Providers that serve the standard OpenAI {"data": [...]} list get
each entry translated to a minimal ModelInfo. base_instructions is
copied from the bundled catalog so entries keep the builtin prompt.

Usage:
  codex-generate-model-catalogs.py [--provider NAME ...]
  codex-generate-model-catalogs.py --out-dir /tmp/cats --provider neuralwatt
"""

import argparse
import glob
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

import tomllib

EFFORT_DESCRIPTIONS = {
    "minimal": "Fastest responses with minimal reasoning",
    "low": "Fast responses with lighter reasoning",
    "medium": "Balanced speed and reasoning depth",
    "high": "Deep reasoning for complex problems",
    "xhigh": "Extra-deep reasoning for the hardest problems",
    "max": "Maximum reasoning depth for the hardest problems",
    "ultra": "Maximum reasoning with automatic task delegation",
    "none": "No reasoning",
}


def load_config(path):
    with open(path, "rb") as f:
        return tomllib.load(f)


def iter_providers(cfg):
    providers = cfg.get("model_providers", {})
    for key, info in providers.items():
        if not isinstance(info, dict):
            continue
        yield key, info


def resolve_token(key, info):
    auth = info.get("auth")
    if isinstance(auth, dict):
        cmd = auth.get("command")
        args = auth.get("args", [])
        if cmd:
            try:
                out = subprocess.run(
                    [cmd, *[str(a) for a in args]],
                    capture_output=True,
                    text=True,
                    timeout=15,
                    check=False,
                )
            except (OSError, subprocess.SubprocessError) as e:
                print(f"warn: {key}: auth command failed: {e}", file=sys.stderr)
                return None
            if out.returncode != 0:
                print(
                    f"warn: {key}: auth command exit {out.returncode}", file=sys.stderr
                )
                return None
            return (
                out.stdout.strip().splitlines()[0].strip()
                if out.stdout.strip()
                else None
            )
    env_key = info.get("env_key")
    if env_key and os.environ.get(env_key):
        return os.environ[env_key]
    token = info.get("experimental_bearer_token")
    return str(token) if token else None


def run_capture(argv, timeout=30):
    try:
        out = subprocess.run(
            argv, capture_output=True, text=True, timeout=timeout, check=False
        )
    except (OSError, subprocess.SubprocessError) as e:
        return None, str(e)
    if out.returncode != 0:
        return None, out.stderr.strip()[:200]
    return out.stdout, None


def codex_client_version(codex_bin):
    out, _ = run_capture([codex_bin, "--version"])
    if out:
        for tok in out.replace(",", " ").split():
            if tok and tok[0].isdigit():
                return tok.strip()
    return "0.155.1"


def bundled_base_instructions(codex_bin):
    out, err = run_capture([codex_bin, "debug", "models", "--bundled"])
    if not out:
        print(f"warn: cannot read bundled catalog: {err}", file=sys.stderr)
        return None
    try:
        data = json.loads(out)
    except json.JSONDecodeError as e:
        print(f"warn: bundled catalog not JSON: {e}", file=sys.stderr)
        return None
    for m in data.get("models", []):
        if m.get("base_instructions"):
            return m["base_instructions"]
        mm = m.get("model_messages") or {}
        if mm.get("instructions_template"):
            return mm["instructions_template"]
    return None


def fetch_models_json(base_url, token, client_version, timeout):
    url = base_url.rstrip("/") + f"/models?client_version={client_version}"
    headers = {
        "User-Agent": f"codex-cli/{client_version}",
        "Accept": "application/json",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.load(resp), None
    except urllib.error.HTTPError as e:
        try:
            body = e.read().decode()[:200]
        except (OSError, ValueError, UnicodeDecodeError):
            body = ""
        return None, f"HTTP {e.code}: {body}"
    except (urllib.error.URLError, OSError, ValueError, json.JSONDecodeError) as e:
        return None, str(e)[:200]


def first_int(*vals):
    for v in vals:
        if isinstance(v, bool):
            continue
        if isinstance(v, int) and v > 0:
            return v
        if isinstance(v, float) and v > 0:
            return int(v)
    return None


def as_str_list(v):
    return [e for e in v if isinstance(e, str)] if isinstance(v, list) else []


def translate_entry(item, index, base_instructions):
    meta = item.get("metadata") if isinstance(item.get("metadata"), dict) else {}
    limits = meta.get("limits") if isinstance(meta.get("limits"), dict) else {}
    caps = {}
    for src in (item.get("capabilities"), meta.get("capabilities")):
        if isinstance(src, dict):
            caps.update(src)
    arch = (
        item.get("architecture") if isinstance(item.get("architecture"), dict) else {}
    )

    model_id = str(item.get("id", f"unknown-{index}"))
    display = (
        meta.get("display_name")
        or item.get("name")
        or item.get("canonical_slug")
        or model_id
    )
    desc = item.get("description") or meta.get("description") or ""
    ctx = first_int(
        item.get("max_model_len"),
        item.get("context_size"),
        item.get("context_length"),
        item.get("contextLength"),
        limits.get("max_context_length"),
    )

    efforts = []
    for src in (meta.get("reasoning"), item.get("reasoning")):
        if isinstance(src, dict):
            efforts += as_str_list(src.get("supported_efforts"))
            efforts += as_str_list(src.get("accepted_efforts"))
    seen, ordered = set(), []
    for e in efforts:
        if e not in seen:
            seen.add(e)
            ordered.append(e)
    default_effort = None
    for src in (meta.get("reasoning"), item.get("reasoning")):
        if isinstance(src, dict) and isinstance(src.get("default_effort"), str):
            default_effort = src["default_effort"]
            break
    if default_effort and default_effort not in ordered:
        ordered.append(default_effort)

    modalities = []
    for src in (
        item.get("input_modalities"),
        arch.get("input_modalities"),
        caps.get("input_modalities"),
    ):
        for m in as_str_list(src):
            m = m.lower()
            if m in ("text", "image", "audio") and m not in modalities:
                modalities.append(m)
    if not modalities:
        tags = [t.lower() for t in as_str_list(item.get("tags"))]
        modalities = ["text"]
        if "image" in tags or caps.get("vision"):
            modalities.append("image")

    feats = {f.lower() for f in as_str_list(item.get("supported_features"))}
    params = {p.lower() for p in as_str_list(item.get("supported_parameters"))}
    parallel = bool(
        caps.get("supports_parallel_function_calling")
        or caps.get("supports_function_calling")
        or caps.get("tools")
        or "tools" in feats
        or "tools" in params
    )

    entry = {
        "slug": model_id,
        "display_name": str(display),
        "description": str(desc),
        "supported_reasoning_levels": [
            {"effort": e, "description": EFFORT_DESCRIPTIONS.get(e, f"{e} reasoning")}
            for e in ordered
        ],
        "shell_type": "default",
        "visibility": "list",
        "supported_in_api": True,
        "priority": 100 + index,
        "support_verbosity": False,
        "default_verbosity": None,
        "apply_patch_tool_type": None,
        "truncation_policy": {"mode": "bytes", "limit": 10000},
        "supports_parallel_tool_calls": parallel,
        "experimental_supported_tools": [],
        "input_modalities": modalities,
    }
    if default_effort and default_effort in ordered:
        entry["default_reasoning_level"] = default_effort
    if ctx:
        entry["context_window"] = ctx
        entry["max_context_window"] = ctx
    if base_instructions:
        entry["base_instructions"] = base_instructions
    else:
        entry["model_messages"] = {"instructions_template": "You are a coding agent."}
    return entry


def fetch_models_plain(base_url, token, timeout):
    url = base_url.rstrip("/") + "/models"
    headers = {"Accept": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.load(resp), None
    except urllib.error.HTTPError as e:
        try:
            body = e.read().decode()[:200]
        except (OSError, ValueError, UnicodeDecodeError):
            body = ""
        return None, f"HTTP {e.code}: {body}"
    except (urllib.error.URLError, OSError, ValueError, json.JSONDecodeError) as e:
        return None, str(e)[:200]


def merge_missing_translated(catalog, payload, base_instructions):
    """Append translated entries for standard-list ids absent from a native catalog."""
    data = payload.get("data")
    if not isinstance(data, list):
        return 0
    known = {m.get("slug") for m in catalog["models"]}
    extra = [
        translate_entry(m, len(catalog["models"]) + i, base_instructions)
        for i, m in enumerate(data)
        if isinstance(m, dict) and str(m.get("id")) not in known
    ]
    catalog["models"].extend(extra)
    catalog["models"].sort(key=lambda m: m["slug"])
    return len(extra)


def build_catalog(payload, base_instructions):
    if isinstance(payload.get("models"), list):
        return {"models": payload["models"]}, None
    data = payload.get("data")
    if not isinstance(data, list):
        return None, f"unexpected shape, keys: {sorted(payload.keys())}"
    models = [
        translate_entry(m, i, base_instructions)
        for i, m in enumerate(data)
        if isinstance(m, dict)
    ]
    models.sort(key=lambda m: m["slug"])
    return {"models": models}, None


def main(argv=None):
    ap = argparse.ArgumentParser(description="Generate Codex model catalog JSON files.")
    ap.add_argument("--config", default=os.path.expanduser("~/.codex/config.toml"))
    ap.add_argument("--out-dir", default=os.path.expanduser("~/.codex/model-catalogs"))
    ap.add_argument(
        "--provider",
        action="append",
        default=[],
        help="only this provider (repeatable)",
    )
    ap.add_argument("--timeout", type=int, default=20)
    ap.add_argument("--client-version", default=None)
    ap.add_argument("--codex-bin", default="codex")
    ap.add_argument(
        "--dry-run", action="store_true", help="fetch and translate, do not write files"
    )
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args(argv)

    try:
        cfg = load_config(args.config)
    except FileNotFoundError:
        print(f"error: config not found: {args.config}", file=sys.stderr)
        return 2
    except tomllib.TOMLDecodeError as e:
        print(f"error: bad TOML in {args.config}: {e}", file=sys.stderr)
        return 2

    providers = {}
    for k, v in iter_providers(cfg):
        providers[k] = v
    config_dir = os.path.dirname(os.path.abspath(args.config))
    for profile_path in sorted(glob.glob(os.path.join(config_dir, "*.config.toml"))):
        try:
            with open(profile_path, "rb") as f:
                profile_cfg = tomllib.load(f)
        except (OSError, tomllib.TOMLDecodeError) as e:
            print(f"warn: skip {profile_path}: {e}", file=sys.stderr)
            continue
        for k, v in iter_providers(profile_cfg):
            providers.setdefault(k, v)
    provider_list = [
        (k, v) for k, v in providers.items() if not args.provider or k in args.provider
    ]
    if not provider_list:
        print("error: no matching providers", file=sys.stderr)
        return 2
    providers = provider_list

    client_version = args.client_version or codex_client_version(args.codex_bin)
    base_instructions = bundled_base_instructions(args.codex_bin)
    if not base_instructions:
        print("warn: no bundled instructions, using stub", file=sys.stderr)

    if not args.dry_run:
        os.makedirs(args.out_dir, exist_ok=True)
    failures = 0
    for key, info in providers:
        base_url = info.get("base_url")
        if not base_url:
            print(f"skip {key}: no base_url", file=sys.stderr)
            failures += 1
            continue
        token = resolve_token(key, info)
        payload, err = fetch_models_json(
            str(base_url), token, client_version, args.timeout
        )
        if err:
            print(f"fail {key}: {err}", file=sys.stderr)
            failures += 1
            continue
        catalog, err = build_catalog(payload, base_instructions)
        if err:
            print(f"fail {key}: {err}", file=sys.stderr)
            failures += 1
            continue
        label = "translated"
        if "models" in payload:
            label = "native"
            plain, plain_err = fetch_models_plain(str(base_url), token, args.timeout)
            if plain_err:
                print(f"warn {key}: plain list failed: {plain_err}", file=sys.stderr)
            else:
                added = merge_missing_translated(catalog, plain, base_instructions)
                if added:
                    label = f"native+{added} translated"
        path = os.path.join(args.out_dir, f"{key}.json")
        if not args.dry_run and os.path.isfile(path):
            try:
                with open(path) as f:
                    old = json.load(f)
                kept = 0
                known = {m.get("slug") for m in catalog["models"]}
                for m in old.get("models", []):
                    if isinstance(m, dict) and m.get("slug") not in known:
                        catalog["models"].append(m)
                        kept += 1
                if kept:
                    catalog["models"].sort(key=lambda m: m.get("slug", ""))
                    label += f"+{kept} kept"
            except (OSError, ValueError) as e:
                print(f"warn {key}: cannot merge old catalog: {e}", file=sys.stderr)
        n = len(catalog["models"])
        if args.dry_run:
            if not args.quiet:
                print(f"ok {key}: {n} models ({label})")
            continue
        with open(path, "w") as f:
            json.dump(catalog, f, indent=1)
            f.write("\n")
        if not args.quiet:
            print(f"wrote {path}: {n} models ({label})")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
