#!/usr/bin/env bash
# Validate every skills/*/SKILL.md against the Agent Skills spec + token budget.
# Usage: scripts/validate.sh   (exit 1 on any error)
set -euo pipefail
cd "$(dirname "$0")/.."

MAX_BODY_LINES=${MAX_BODY_LINES:-150}   # spec allows 500; we aim far lower
MAX_DESC=1024
errors=0; total_desc=0
shopt -s nullglob
skill_files=(skills/*/SKILL.md)
[ ${#skill_files[@]} -gt 0 ] || echo "(no skills yet)"

err() { echo "  ✗ $1"; errors=$((errors+1)); }

for f in ${skill_files[@]+"${skill_files[@]}"}; do
  dir=$(basename "$(dirname "$f")")
  echo "• $dir"
  [ "$(head -1 "$f")" = "---" ] || { err "missing frontmatter"; continue; }
  fm=$(awk 'NR==1{next} /^---$/{exit} {print}' "$f")
  name=$(printf '%s\n' "$fm" | sed -n 's/^name: *//p')
  desc=$(printf '%s\n' "$fm" | sed -n 's/^description: *//p')
  body_lines=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' "$f" | wc -l | tr -d ' ')

  [ "$name" = "$dir" ] || err "name '$name' != dir '$dir'"
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] && [ ${#name} -le 64 ] || err "name must be lowercase-hyphen, <=64 chars"
  [ -n "$desc" ] || err "missing description"
  [ ${#desc} -le $MAX_DESC ] || err "description ${#desc} chars > $MAX_DESC"
  [[ "$desc" == *"Use when"* ]] || err "description should say 'Use when …' (trigger)"
  [[ "$desc" =~ \<|\> ]] && err "no XML/angle brackets in description"
  [ "$body_lines" -le "$MAX_BODY_LINES" ] || err "body $body_lines lines > $MAX_BODY_LINES"

  # every referenced local file must exist (references/, assets/, scripts/)
  while IFS= read -r ref; do
    [ -e "skills/$dir/$ref" ] || err "broken link: $ref"
  done < <(grep -oE '(references|assets|scripts)/[A-Za-z0-9._/-]+' "$f" | sort -u)

  words=$(wc -w < "$f" | tr -d ' ')
  total_desc=$((total_desc + ${#desc}))
  echo "  desc=${#desc}ch  body=${body_lines}L  ~$((words*13/10)) tokens when loaded"
done

# English only under skills/ and templates/ (AGENTS.md §2)
vi_chars='[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]'
if hits=$(grep -rnE "$vi_chars" skills templates); then
  echo "• language"; echo "$hits" | head -5 | sed 's/^/  /'; err "Vietnamese text found under skills/ or templates/ (must be English)"
fi

echo
echo "Always-loaded metadata: ~$((total_desc/4)) tokens across all descriptions"
if [ "$errors" -ne 0 ]; then echo "$errors error(s)"; exit 1; fi
echo "OK"
