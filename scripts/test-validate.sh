#!/usr/bin/env bash
# Self-test for validate.sh: each case copies the repo, injects one defect and expects a failure.
# Usage: scripts/test-validate.sh
# shellcheck disable=SC2016  # perl expressions are single-quoted on purpose
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
fails=0

fresh() {
  rm -rf "$work/r"; mkdir "$work/r"
  (cd "$repo" && tar --exclude=.git -cf - .) | (cd "$work/r" && tar -xf -)
}
run() { (cd "$work/r" && "$BASH" scripts/validate.sh >"$work/out" 2>&1); }  # same bash as this script
expect_fail() { # name, expected message fragment
  if run; then echo "✗ $1: validate.sh passed"; fails=$((fails+1));
  elif ! grep -qF "$2" "$work/out"; then echo "✗ $1: failed without '$2'"; sed 's/^/    /' "$work/out" | tail -5; fails=$((fails+1));
  else echo "✓ $1"; fi
}
edit() { # file, perl expression
  perl -0pi -e "$2" "$work/r/$1"
}

fresh; if run; then echo "✓ baseline passes"; else echo "✗ baseline fails"; cat "$work/out"; exit 1; fi

fresh; edit skills/hd-ai/SKILL.md 's/^description: "(.*)"$/description: $1/m'
expect_fail "unquoted description with ': '" "invalid frontmatter"

fresh; edit skills/hd-ai/SKILL.md 's/^license: MIT$/license: MIT\nversion: 1.0.0/m'
expect_fail "unknown frontmatter key" "key 'version' not allowed"

fresh; edit skills/hd-ai/SKILL.md 's/^name: hd-ai$/name: ai/m'
expect_fail "name without hd- prefix" "name 'ai' != dir"

fresh; edit skills/hd-ai/SKILL.md 's/\n---\n\n# AI/\n\n# AI/'
expect_fail "missing closing delimiter" "invalid frontmatter"

fresh; echo "# Orphan" >"$work/r/skills/hd-core/references/orphan.md"
expect_fail "orphan topic file" "orphan"

fresh; edit skills/hd-index/SKILL.md 's/\| \| `forms.md` \|/| `hd-auth` | `forms.md` |/'
expect_fail "topic listed under the wrong skill" "hd-validate/references/forms.md not listed under hd-validate"

fresh; echo "See \`assets/missing.ts\`." >>"$work/r/skills/hd-core/references/git.md"
expect_fail "broken assets link in a topic file" "broken link in git.md"

fresh; echo "Also read \`references/testing.md\`." >>"$work/r/skills/hd-core/references/git.md"
expect_fail "topic file chains to another topic" "links another topic file"

fresh; for _ in $(seq 1 120); do echo "- line" >>"$work/r/skills/hd-core/references/git.md"; done
expect_fail "topic file too long" "lines > 100"

fresh; echo "- Viết tiếng Việt." >>"$work/r/skills/hd-core/references/git.md"
expect_fail "Vietnamese text" "Vietnamese text found"

fresh; echo '{"mcpServers":{}}' >>"$work/r/skills/hd-core/references/git.md"
expect_fail "MCP config outside the registry" "belong only in"

[ "$fails" -eq 0 ] || { echo "$fails case(s) failed"; exit 1; }
echo "OK"
