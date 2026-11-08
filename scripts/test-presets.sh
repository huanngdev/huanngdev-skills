#!/usr/bin/env bash
# Consumer test for skills/hd-infra/assets/config: a temp monorepo uses the presets the way
# init.md says; good fixtures must pass tsc + oxlint + oxfmt, bad fixtures must fail.
# Usage: scripts/test-presets.sh   (needs bun + network for the tool install)
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
fails=0
ok()  { echo "✓ $1"; }
bad() { echo "✗ $1"; fails=$((fails+1)); }

cd "$work"
mkdir -p packages apps/web/src packages/lib/src
cp -R "$repo/skills/hd-infra/assets/config" packages/config
cp "$repo/skills/hd-infra/assets/init/bunfig.toml" .
sed -i.bak 's/"@scope\/config"/"@t\/config"/' packages/config/package.json && rm packages/config/package.json.bak
cat > package.json <<'JSON'
{ "name": "t", "private": true, "workspaces": ["apps/*", "packages/*"] }
JSON
cat > packages/lib/package.json <<'JSON'
{ "name": "@t/lib", "private": true, "type": "module", "devDependencies": { "@t/config": "workspace:*" } }
JSON
cat > apps/web/package.json <<'JSON'
{ "name": "@t/web", "private": true, "type": "module", "devDependencies": { "@t/config": "workspace:*" } }
JSON
echo '{ "extends": "@t/config/tsconfig/package.json", "include": ["src"] }' > packages/lib/tsconfig.json
echo '{ "extends": "@t/config/tsconfig/vite-react.json", "include": ["src"] }' > apps/web/tsconfig.json
echo '{ "extends": ["../../packages/config/oxlint/node.json"] }' > packages/lib/.oxlintrc.json
echo '{ "extends": ["../../packages/config/oxlint/react.json"] }' > apps/web/.oxlintrc.json
bun add -d typescript@7 oxlint oxlint-tsgolint oxfmt @types/bun vite vitest @types/react >/dev/null

# good fixtures
cat > packages/lib/src/index.ts <<'TS'
export const add = (a: number, b: number): number => a + b;
export const read = (path: string): ReturnType<typeof Bun.file> => Bun.file(path);
TS
cat > apps/web/src/app.tsx <<'TS'
export const Logo = (): React.JSX.Element => <img src="/logo.svg" alt="Logo" />;
TS
check() { # name, dir, expect(pass|fail), [diagnostic that must appear when failing]
  local res=pass log="$work/check.log"
  (cd "$2" && bunx tsc --noEmit -p . && bunx oxlint --type-aware --deny-warnings) >"$log" 2>&1 || res=fail
  if [ "$res" != "$3" ]; then bad "$1 (expected $3, got $res)"; sed 's/^/    /' "$log" | tail -20; return; fi
  if [ -n "${4:-}" ] && ! grep -qF "$4" "$log"; then bad "$1 (failed, but without '$4')"; sed 's/^/    /' "$log" | tail -20; return; fi
  ok "$1"
}
check "package preset accepts valid code" packages/lib pass
check "react preset accepts valid code" apps/web pass
if bunx oxfmt --check -c packages/config/oxfmt.json packages/lib/src apps/web/src >"$work/fmt.log" 2>&1 || { sed "s/^/    /" "$work/fmt.log"; false; }; then ok "oxfmt config loads"; else bad "oxfmt config loads"; fi
if bun -e 'const m = await import("./packages/config/vitest/base.ts"); if (!m.base?.test) process.exit(1)'; then ok "vitest base exports base"; else bad "vitest base exports base"; fi

# bad fixtures: each must be rejected
expect_reject() { # name, dir, file, content, diagnostic
  local f="$2/src/$3"; printf '%s\n' "$4" > "$f"; check "$1" "$2" fail "$5"; rm "$f"
}
expect_reject "missing return type (isolatedDeclarations)" packages/lib bad.ts 'export const f = (a: number) => a;' TS9007
expect_reject "explicit any" packages/lib bad.ts 'export const x: any = 1;' no-explicit-any
expect_reject "default export" packages/lib bad.ts 'const y = 1; export default y;' no-default-export
expect_reject "non-null assertion" packages/lib bad.ts 'export const z = (a?: string): string => a!;' no-non-null-assertion
expect_reject "img without alt" apps/web bad.tsx 'export const I = (): React.JSX.Element => <img src="/a.png" />;' alt-text

if [ "$fails" -ne 0 ]; then echo "$fails failure(s)"; exit 1; fi
echo OK
