#!/usr/bin/env bash

# My prompt and skills location(s).
my_prompt="$HOME/Documents/Rubin/Notes/custom-user-prompt.md"
my_skills="$HOME/Documents/Rubin/Skills"

# System prompt addition files.
prompt_files=(
  .claude/CLAUDE.md
  .codex/AGENTS.md
  .config/crush/CRUSH.md
  .config/opencode/AGENTS.md
  .pi/agent/APPEND_SYSTEM.md
  .vibe/AGENTS.md
)

# Locations of skills directories.
skill_dirs=(
  .agents/skills
  .claude/skills
  .config/crush/skills
  .config/opencode/skills
  .vibe/skills
  )

# Copy my prompt to prompt locations if parent directory exists.
# Also copy to my default dotfiles repository.
for prompt_file in "${prompt_files[@]}"; do
  if [[ -d "$(dirname "$HOME/$prompt_file")" ]]; then
    cp -v "$my_prompt" "$HOME/$prompt_file"
  fi
  if [[ -d "$(dirname "$HOME/Source/Rubin/dotfiles/$prompt_file")" ]]; then
    cp "$my_prompt" "$HOME/Source/Rubin/dotfiles/$prompt_file"
  fi
done

# Ensure links exist to my skills location for various agents.
for skill_dir in "${skill_dirs[@]}"; do
  if [[ -d "$HOME/$skill_dir" && ! -L "$HOME/$skill_dir" ]]; then
    rmdir "$HOME/$skill_dir"
  fi
  ln -sfnv "$my_skills" "$HOME/$skill_dir"
done
