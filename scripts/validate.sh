#!/usr/bin/env bash
# Validate skills/ against the Agent Skills spec and AGENTS.md rules (§2–§5).
# Usage: scripts/validate.sh   (exit 1 on any error; warnings don't fail)
# Needs: bun (YAML parsing), awk, grep.
set -euo pipefail
cd "$(dirname "$0")/.."

MAX_BODY_LINES=${MAX_BODY_LINES:-150}   # spec allows 500; we aim far lower
MAX_TOPIC_LINES=${MAX_TOPIC_LINES:-100}
MAX_DESC=1024
errors=0; warnings=0; total_desc=0
err()  { echo "  ✗ $1"; errors=$((errors+1)); }
warn() { echo "  ! $1"; warnings=$((warnings+1)); }
shopt -s nullglob
command -v bun >/dev/null || { echo "✗ bun is required (YAML parsing)"; exit 1; }

index=skills/hd-index/SKILL.md
registry=skills/hd-index/references/docs-sources.md
skill_files=(skills/*/SKILL.md)
[ ${#skill_files[@]} -gt 0 ] || echo "(no skills yet)"

# ---------- skill map in hd-index: path-aware (skill, topic) pairs ----------
# Rows: | `hd-x` | `topic.md` | … |   or continuation rows: | | `topic.md` | … |
map_pairs=""
if [ -f "$index" ]; then
  map_pairs=$(awk -F'|' '
    /^\| *Skill *\|/ {t=1; next}
    t && /^\|/ {
      s=$2; f=$3; gsub(/[ `]/, "", s); gsub(/[ `]/, "", f)
      if (s ~ /^-+$/) next
      if (s != "") cur=s
      print cur "\t" f
      next }
    t {t=0}' "$index")
fi
in_map() { printf '%s\n' "$map_pairs" | grep -qxF "$1"$'\t'"$2"; }
skill_in_map() { printf '%s\n' "$map_pairs" | cut -f1 | grep -qxF "$1"; }

echo "• skill map"
bun scripts/sync-map.ts --check || err "skill map out of date (bun scripts/sync-map.ts)"
while IFS=$'\t' read -r s f; do
  [ -n "$s" ] || continue
  [ -d "skills/$s" ] || { err "map lists unknown skill '$s'"; continue; }
  [ "$f" = "—" ] || [ -f "skills/$s/references/$f" ] || err "map lists $s/$f but skills/$s/references/$f does not exist"
done <<<"$map_pairs"

planned=()
for d in skills/*/; do
  n=$(basename "$d")
  if [ ! -f "$d/SKILL.md" ]; then
    planned+=("$n")
    for r in "$d"references/*.md; do grep -q '<!-- TODO' "$r" || err "planned $n: $(basename "$r") must be a <!-- TODO --> stub until SKILL.md exists"; done
  fi
  [ -f "$index" ] && ! skill_in_map "$n" && err "$n not listed in $index skill map"
  for r in "$d"references/*.md; do
    rn=$(basename "$r")
    [ -f "$index" ] && ! in_map "$n" "$rn" && err "$n/references/$rn not listed under $n in $index"
    if [ -f "$d/SKILL.md" ] && ! grep -qF "references/$rn" "$d/SKILL.md"; then err "$n/references/$rn not linked from SKILL.md (orphan)"; fi
  done
done
[ ${#planned[@]} -eq 0 ] || echo "planned (no SKILL.md yet): ${planned[*]}"

# ---------- frontmatter (real YAML) + body ----------
# Prints one JSON object per file: {ok, error?, keys, name, description}
read_frontmatter() {
  bun -e '
    const text = await Bun.file(process.argv[1]).text();
    const m = /^---\n([\s\S]*?)\n---\n/.exec(text);
    if (!m) { console.log(JSON.stringify({ ok: false, error: "frontmatter must start and end with a --- line" })); process.exit(0); }
    try {
      const fm = Bun.YAML.parse(m[1]);
      if (!fm || typeof fm !== "object" || Array.isArray(fm)) throw new Error("frontmatter is not a mapping");
      const str = (v) => (typeof v === "string" ? v : null);
      const types = Object.entries({ name: "string", description: "string", license: "string", compatibility: "string", metadata: "object", "allowed-tools": "string" })
        .filter(([k, type]) => k in fm && typeof fm[k] !== type).map(([k]) => k);
      console.log(JSON.stringify({ ok: true, keys: Object.keys(fm), badTypes: types, name: str(fm.name), description: str(fm.description), license: str(fm.license), author: str(fm.metadata?.author) }));
    } catch (e) { console.log(JSON.stringify({ ok: false, error: String(e.message ?? e) })); }
  ' "$1"
}
json() { bun -e 'const o = JSON.parse(process.argv[1]); const v = o[process.argv[2]]; console.log(Array.isArray(v) ? v.join(" ") : v ?? "")' "$1" "$2"; }

allowed_keys=" name description license compatibility metadata allowed-tools "
for f in ${skill_files[@]+"${skill_files[@]}"}; do
  dir=$(basename "$(dirname "$f")")
  echo "• $dir"
  fm=$(read_frontmatter "$f")
  if [ "$(json "$fm" ok)" != true ]; then err "invalid frontmatter: $(json "$fm" error)"; continue; fi
  name=$(json "$fm" name); desc=$(json "$fm" description)
  for k in $(json "$fm" keys); do
    [[ "$allowed_keys" == *" $k "* ]] || err "frontmatter key '$k' not allowed (AGENTS.md §3)"
  done
  bad=$(json "$fm" badTypes); [ -z "$bad" ] || err "wrong YAML type for: $bad"
  [ -n "$(json "$fm" author)" ] || err "metadata.author missing"
  [ "$(json "$fm" license)" = MIT ] || err "license must be MIT (matches LICENSE)"
  [ "$name" = "$dir" ] || err "name '$name' != dir '$dir'"
  [[ "$name" =~ ^hd-[a-z0-9]+(-[a-z0-9]+)*$ ]] && [ ${#name} -le 64 ] || err "name must be hd-<lowercase-hyphen>, <=64 chars"
  [ -n "$desc" ] || err "missing description"
  [ ${#desc} -le $MAX_DESC ] || err "description ${#desc} chars > $MAX_DESC"
  { [ ${#desc} -ge 200 ] && [ ${#desc} -le 350 ]; } || warn "description ${#desc} chars, target 200–350"
  [[ "$desc" == *"Use when"* ]] || err "description should say 'Use when …' (trigger)"
  [[ "$desc" =~ \<|\> ]] && err "no XML/angle brackets in description"

  body_lines=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' "$f" | wc -l | tr -d ' ')
  [ "$body_lines" -le "$MAX_BODY_LINES" ] || err "body $body_lines lines > $MAX_BODY_LINES"

  # SKILL.md links to references/, assets/, scripts/ must exist
  while IFS= read -r ref; do
    [ -e "skills/$dir/$ref" ] || err "broken link in SKILL.md: $ref"
  done < <(grep -oE '(references|assets|scripts)/[A-Za-z0-9._/-]*[A-Za-z0-9_]' "$f" | sort -u)

  # topic files: size, no chains to other topic files, assets/ links exist
  for r in skills/"$dir"/references/*.md; do
    rl=$(wc -l <"$r" | tr -d ' ')
    [ "$rl" -le "$MAX_TOPIC_LINES" ] || err "$(basename "$r") $rl lines > $MAX_TOPIC_LINES (split the topic)"
    if [ "$r" != "$registry" ] && sed -E 's/\]\((\.\.\/)?assets\/[^)]*\)//g' "$r" | grep -qE 'references/|\]\([^)]*\.md\)'; then
      err "$(basename "$r") links another topic file (one level deep only; assets/ links are fine)"
    fi
    while IFS= read -r ref; do
      [ -e "skills/$dir/$ref" ] || err "broken link in $(basename "$r"): $ref"
    done < <(grep -oE 'assets/[A-Za-z0-9._/-]*[A-Za-z0-9_]' "$r" | sort -u)
  done

  words=$(wc -w < "$f" | tr -d ' ')
  total_desc=$((total_desc + ${#desc}))
  echo "  desc=${#desc}ch  body=${body_lines}L  ~$((words*13/10)) tokens when loaded"
done

# ---------- structured assets parse (JSON / TOML / YAML) ----------
asset_files=()
while IFS= read -r a; do asset_files+=("$a"); done < <(find skills -path '*/assets/*' -type f \( -name '*.json' -o -name '*.toml' -o -name '*.yml' -o -name '*.yaml' \) | sort)
if [ ${#asset_files[@]} -gt 0 ]; then
  echo "• assets (${#asset_files[@]} structured files)"
  # shellcheck disable=SC2016  # JS source, not shell
  bad_assets=$(bun -e '
    let bad = 0;
    for (const f of process.argv.slice(1)) {
      const text = await Bun.file(f).text();
      try {
        if (f.endsWith(".json")) JSON.parse(text);
        else if (f.endsWith(".toml")) Bun.TOML.parse(text);
        else Bun.YAML.parse(text);
      } catch (e) { console.log(`${f}: ${String(e.message ?? e).split("\n")[0]}`); bad++; }
    }
  ' "${asset_files[@]}")
  if [ -n "$bad_assets" ]; then
    while IFS= read -r line; do err "asset does not parse: $line"; done <<<"$bad_assets"
  fi
fi

# ---------- docs sources live only in hd-index (AGENTS.md §5) ----------
if leaks=$(grep -rnE 'mcpServers|"type": *"http"|skills add ' skills --include='*.md' | grep -vF "$registry:"); then
  echo "• docs sources"; echo "$leaks" | head -5 | sed 's/^/  /'; err "MCP config / skill install commands belong only in $registry"
fi
for f in ${skill_files[@]+"${skill_files[@]}"}; do
  case $f in skills/hd-index/*) continue;; esac
  grep -q '^Docs: hd-index docs sources (' "$f" || { echo "• $(basename "$(dirname "$f")")"; err "missing line 'Docs: hd-index docs sources (<Tech>, …).'"; }
done

# ---------- English only under skills/ and templates/ (AGENTS.md §2) ----------
vi_chars='[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]'
if hits=$(grep -rnE "$vi_chars" skills templates); then
  echo "• language"; echo "$hits" | head -5 | sed 's/^/  /'; err "Vietnamese text found under skills/ or templates/ (must be English)"
fi

echo
echo "Always-loaded metadata: ~$((total_desc/4)) tokens across all descriptions"
[ "$warnings" -eq 0 ] || echo "$warnings warning(s)"
if [ "$errors" -ne 0 ]; then echo "$errors error(s)"; exit 1; fi
echo "OK"
