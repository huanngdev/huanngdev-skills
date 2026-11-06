#!/usr/bin/env bash
# Dev mode: symlink every skill into the global skill dirs so edits apply everywhere instantly.
#   scripts/link.sh [--dry-run]           link into ~/.claude/skills and ~/.agents/skills
#   scripts/link.sh --unlink [--dry-run]  remove only the symlinks that point into this checkout
# Never touches real directories or symlinks owned by another checkout / installer.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
targets=("$HOME/.claude/skills" "$HOME/.agents/skills")
shopt -s nullglob

unlink=false; dry=false
for a in "$@"; do
  case $a in
    --unlink) unlink=true;; --dry-run) dry=true;;
    *) echo "usage: $0 [--unlink] [--dry-run]" >&2; exit 2;;
  esac
done

for t in "${targets[@]}"; do
  if $unlink; then [ -d "$t" ] || continue; elif ! $dry; then mkdir -p "$t"; fi
  for s in "$repo"/skills/*/; do
    name=$(basename "$s"); src="${s%/}"; dest="$t/$name"
    if [ -L "$dest" ]; then
      current=$(readlink "$dest")
      if [ "$current" != "$src" ]; then echo "skip $dest (symlink to $current, not this checkout)"; continue; fi
      if ! $unlink; then echo "ok $dest"; elif $dry; then echo "would unlink $dest"; else rm "$dest"; echo "unlinked $dest"; fi
      continue
    fi
    $unlink && continue
    if [ -e "$dest" ]; then echo "skip $dest (real file/dir exists)"; continue; fi
    if $dry; then echo "would link $dest"; else ln -s "$src" "$dest"; echo "linked $dest"; fi
  done
done
