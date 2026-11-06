#!/usr/bin/env bash
# Release the huanngdev plugin. main is protected, so a release is two steps:
#   scripts/release.sh patch|minor|major [--dry-run]
#       on main → branch release/vX.Y.Z, bump plugin.json, move CHANGELOG [Unreleased], push, open PR
#   scripts/release.sh tag
#       after the release PR is merged → on main, tag huanngdev--vX.Y.Z and push the tag
#       (the tag triggers .github/workflows/release.yml → GitHub Release)
set -euo pipefail
cd "$(dirname "$0")/.."

manifest=.claude-plugin/plugin.json
repo_url=https://github.com/huanngdev/huanngdev-skills
die() { echo "✗ $1" >&2; exit 1; }

require_clean_synced_main() {
  [ "$(git branch --show-current)" = main ] || die "run from main"
  [ -z "$(git status --porcelain)" ] || die "working tree not clean"
  git fetch -q origin main --tags
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || die "main is not in sync with origin/main (git pull)"
}

cmd=${1:-}; shift || true

# ---------- step 2: tag ----------
if [ "$cmd" = tag ]; then
  require_clean_synced_main
  v=$(jq -r .version "$manifest")
  [ "$v" != 0.0.0 ] || die "nothing released yet (version 0.0.0)"
  grep -q "^## \[$v\] - " CHANGELOG.md || die "CHANGELOG.md has no section for $v"
  claude plugin tag . -m "huanngdev v%s" --push
  echo "✓ tagged and pushed huanngdev--v$v — auto-update users get it on next start"
  exit 0
fi

# ---------- step 1: release PR ----------
[[ $cmd =~ ^(patch|minor|major)$ ]] || { echo "usage: $0 patch|minor|major [--dry-run] | tag"; exit 2; }
dry=false; [ "${1:-}" = --dry-run ] && dry=true

require_clean_synced_main
scripts/validate.sh >/dev/null || die "scripts/validate.sh failed (run it for details)"
claude plugin validate . >/dev/null || die "claude plugin validate failed"
ls skills/*/SKILL.md >/dev/null 2>&1 || die "no skills to release"

cur=$(jq -r .version "$manifest")
IFS=. read -r ma mi pa <<<"$cur"
case $cmd in
  major) next="$((ma+1)).0.0";; minor) next="$ma.$((mi+1)).0";; patch) next="$ma.$mi.$((pa+1))";;
esac
tag="huanngdev--v$next"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "tag $tag already exists"

notes=$(awk '/^## \[Unreleased\]/{f=1;next} /^## \[/{f=0} /^\[/{f=0} f' CHANGELOG.md | sed '/^[[:space:]]*$/d')
[ -n "$notes" ] || die "CHANGELOG.md [Unreleased] is empty — describe the changes first"

echo "Release $cur → $next ($cmd)"; echo "$notes"
$dry && { echo "(dry run, nothing changed)"; exit 0; }

branch="release/v$next"
git switch -q -c "$branch"

today=$(date +%Y-%m-%d)
if [ "$cur" = 0.0.0 ]; then compare="$repo_url/releases/tag/$tag"; else compare="$repo_url/compare/huanngdev--v$cur...$tag"; fi
tmp=$(mktemp)
jq --arg v "$next" '.version=$v' "$manifest" >"$tmp" && mv "$tmp" "$manifest"
awk -v v="$next" -v d="$today" -v t="$tag" -v c="$compare" -v u="$repo_url" '
  /^## \[Unreleased\]/ { print; print ""; print "## [" v "] - " d; next }
  /^\[Unreleased\]:/   { print "[Unreleased]: " u "/compare/" t "...HEAD"; print "[" v "]: " c; next }
  { print }' CHANGELOG.md >"$tmp" && mv "$tmp" CHANGELOG.md

git add "$manifest" CHANGELOG.md
git commit -q -m "chore(release): v$next"
git push -q -u origin "$branch"
body=$(printf 'Release v%s\n\n%s\n\nAfter merge, on main: scripts/release.sh tag' "$next" "$notes")
gh pr create --base main --head "$branch" --title "chore(release): v$next" --body "$body"
echo "✓ release PR opened. After merge: git switch main && git pull && scripts/release.sh tag"
