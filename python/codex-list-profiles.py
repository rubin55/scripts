#!/usr/bin/env python3
from pathlib import Path
import tomllib

# Read Codex profile configurations from ~/.codex.
codex_dir = Path.home() / ".codex"

for path in sorted(codex_dir.glob("*.config.toml")):
    with open(path, "rb") as file:
        data = tomllib.load(file)
    provider = data.get("model_provider", "-")
    model = data.get("model", "-")
    print(f"{provider}: {model}")
