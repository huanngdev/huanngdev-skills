#!/usr/bin/env bash
# Dev mode: symlink every skill into the global skill dirs so edits apply everywhere instantly.
#   scripts/link.sh          link into ~/.claude/skills and ~/.agents/skills
#   scripts/link.sh --unlink remove those symlinks
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
targets=("$HOME/.claude/skills" "$HOME/.agents/skills")
shopt -s nullglob

for t in "${targets[@]}"; do
  mkdir -p "$t"
  for s in "$repo"/skills/*/; do
    name=$(basename "$s"); dest="$t/$name"
    if [ "${1:-}" = "--unlink" ]; then
      [ -L "$dest" ] && rm "$dest" && echo "unlinked $dest"
      continue
    fi
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then echo "skip $dest (real dir exists)"; continue; fi
    ln -sfn "${s%/}" "$dest" && echo "linked $dest"
  done
done
