#!/usr/bin/env python3
from pathlib import Path
import tomllib

# Read Codex profile configurations from ~/.codex.
codex_dir = Path.home() / ".codex"
headers = ["profile", "provider", "model", "effort"]
rows = []

for path in sorted(codex_dir.glob("*.config.toml")):
    profile = path.stem.removesuffix(".config")
    with open(path, "rb") as file:
        data = tomllib.load(file)
    provider = data.get("model_provider", "-")
    model = data.get("model", "-")
    effort = data.get("model_reasoning_effort", "-")
    rows.append([profile, provider, model, effort])

if not rows:
    raise SystemExit(0)

widths = [max(len(h), *(len(r[i]) for r in rows)) for i, h in enumerate(headers)]
print("  ".join(h.ljust(widths[i]) for i, h in enumerate(headers)).rstrip())
print("  ".join("-" * w for w in widths))
for row in rows:
    print("  ".join(cell.ljust(widths[i]) for i, cell in enumerate(row)).rstrip())
