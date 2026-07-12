#!/usr/bin/env bash

my_prompt="$HOME/Documents/Rubin/Notes/custom-user-prompt.md"

prompt_files=(
  .claude/CLAUDE.md
  .codex/AGENTS.md
  .config/crush/CRUSH.md
  .config/opencode/AGENTS.md
  .pi/agent/APPEND_SYSTEM.md
  .vibe/AGENTS.md
)

for prompt_file in "${prompt_files[@]}"; do
  cp -v "$my_prompt" "$HOME/$prompt_file"
  cp "$my_prompt" "$HOME/Source/Rubin/dotfiles/$prompt_file"
done
