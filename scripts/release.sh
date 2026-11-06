#!/usr/bin/env bash
# Release the huanngdev plugin. main is protected, so a release is two steps:
#   scripts/release.sh patch|minor|major [--dry-run]
#       on main → branch release/vX.Y.Z, bump plugin.json, move CHANGELOG [Unreleased], push, open PR
#   scripts/release.sh tag [--dry-run]
#       after the release PR is merged → on main, tag the release commit huanngdev--vX.Y.Z and push it
#       (the tag triggers .github/workflows/release.yml → GitHub Release)
set -euo pipefail
cd "$(dirname "$0")/.."

manifest=.claude-plugin/plugin.json
repo_url=https://github.com/huanngdev/huanngdev-skills
die() { echo "✗ $1" >&2; exit 1; }
usage() { echo "usage: $0 patch|minor|major [--dry-run] | tag [--dry-run]" >&2; exit 2; }

# ---------- arguments: validated before anything is fetched or changed ----------
[ $# -ge 1 ] && [ $# -le 2 ] || usage
cmd=$1; dry=false
if [ $# -eq 2 ]; then [ "$2" = --dry-run ] || usage; dry=true; fi
[[ $cmd =~ ^(patch|minor|major|tag)$ ]] || usage

for tool in git jq gh claude; do command -v "$tool" >/dev/null || die "$tool is required"; done

require_clean_synced_main() {
  [ "$(git branch --show-current)" = main ] || die "run from main"
  [ -z "$(git status --porcelain)" ] || die "working tree not clean"
  git fetch -q origin main --tags
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || die "main is not in sync with origin/main (git pull)"
}

# ---------- step 2: tag ----------
if [ "$cmd" = tag ]; then
  require_clean_synced_main
  v=$(jq -r .version "$manifest")
  [ "$v" != 0.0.0 ] || die "nothing released yet (version 0.0.0)"
  tag="huanngdev--v$v"
  git rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "tag $tag already exists"
  grep -q "^## \[$v\] - " CHANGELOG.md || die "CHANGELOG.md has no section for $v"
  # The release commit is the last commit on main's first-parent line that changed the manifest
  # (the squash commit, or the merge commit of a merged PR); nothing may land after it.
  release_sha=$(git log -1 --first-parent --format=%H -- "$manifest")
  [ "$(git rev-parse HEAD)" = "$release_sha" ] ||
    die "main has commits after the release commit ${release_sha:0:7}; tag it by hand (git tag -a $tag $release_sha) or cut a new release"
  ci=$(gh run list --commit "$release_sha" --workflow ci.yml --json conclusion --jq '.[0].conclusion // ""')
  [ "$ci" = success ] || die "CI on ${release_sha:0:7} is '${ci:-not run}', need success"
  if $dry; then echo "would tag ${release_sha:0:7} as $tag and push (dry run)"; exit 0; fi
  claude plugin tag . -m "huanngdev v%s" --push
  echo "✓ tagged and pushed $tag — auto-update users get it on next start"
  exit 0
fi

# ---------- step 1: release PR ----------
require_clean_synced_main
scripts/validate.sh >/dev/null || die "scripts/validate.sh failed (run it for details)"
claude plugin validate . >/dev/null || die "claude plugin validate failed"
ls skills/*/SKILL.md >/dev/null 2>&1 || die "no skills to release"

cur=$(jq -r .version "$manifest")
[[ $cur =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || die "plugin.json version '$cur' is not plain X.Y.Z"
ma=${BASH_REMATCH[1]}; mi=${BASH_REMATCH[2]}; pa=${BASH_REMATCH[3]}
case $cmd in
  major) next="$((ma+1)).0.0";; minor) next="$ma.$((mi+1)).0";; patch) next="$ma.$mi.$((pa+1))";;
esac
tag="huanngdev--v$next"
branch="release/v$next"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "tag $tag already exists"
git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1 && die "branch $branch already exists on origin (open PR? delete it first)"
git rev-parse -q --verify "refs/heads/$branch" >/dev/null && die "local branch $branch already exists"

notes=$(awk '/^## \[Unreleased\]/{f=1;next} /^## \[/{f=0} /^\[/{f=0} f' CHANGELOG.md | sed '/^[[:space:]]*$/d')
[ -n "$notes" ] || die "CHANGELOG.md [Unreleased] is empty — describe the changes first"

echo "Release $cur → $next ($cmd)"; echo "$notes"
$dry && { echo "(dry run, nothing changed)"; exit 0; }

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
