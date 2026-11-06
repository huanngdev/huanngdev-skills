# AGENTS.md — huanngdev-skills

Personal, portable Agent Skills (https://agentskills.io) holding huanngdev's engineering style. Distributed as a Claude Code plugin marketplace and via `npx skills`. These rules apply to every change in this repo.

## 1. Layout (do not change without asking)
```
.claude-plugin/plugin.json       # plugin "huanngdev" (bump version on release)
.claude-plugin/marketplace.json  # marketplace "huanngdev-skills", source "./"
skills/hd-index/SKILL.md         # entry point: global rules + skill map
skills/hd-<domain>/SKILL.md      # short router for the domain
skills/hd-<domain>/references/   # one file per topic, loaded on demand
skills/hd-<domain>/assets/       # optional templates/files the skill outputs
skills/hd-<domain>/scripts/      # optional executables (run, not read)
templates/SKILL.template.md      # starting point for new skills
scripts/validate.sh              # must pass before commit (needs bun for YAML parsing)
scripts/test-validate.sh         # self-test: injects defects, expects validate.sh to fail
scripts/release.sh               # the only way to bump version + tag (§8)
scripts/link.sh                  # local symlinks (don't combine with the plugin install)
CHANGELOG.md                     # Keep a Changelog
LICENSE                          # MIT (declared in plugin.json and every SKILL.md)
.github/workflows/               # ci.yml (checks), release.yml (GitHub Release on tag)
```
Nothing else goes inside `skills/` — every folder there is installed for users. A folder without `SKILL.md` is a **planned** skill: its topic files exist as `<!-- TODO -->` stubs and are listed in `hd-index`.

`skills/hd-index/SKILL.md` is the entry point: global rules for every task + the map of which skill to load when. It is the only skill meant to load on nearly every task, so keep it short.

## 2. Language
- Everything under `skills/` and `templates/` is **English** (cheaper in tokens, same compliance). `validate.sh` rejects Vietnamese diacritics there.
- `README.md` is Vietnamese (for the human owner). This file is English.

## 3. Frontmatter (portable across agents)
- Only standard fields: `name`, `description`, `license`, `compatibility`, `metadata` (`author`), `allowed-tools`. No per-skill version (see §7).
- Frontmatter must be valid YAML: always write `description: "…"` in double quotes (a bare `: ` inside it breaks parsers). `validate.sh` parses it with Bun's YAML parser.
- `name`: equals folder name, `hd-` prefix, lowercase-hyphen, ≤ 64 chars.
- `description`: third person, what it does + `Use when …` with concrete triggers (tech names, file types, user verbs). Target 200–350 chars, hard max 1024. No `<` `>`.
- Claude-only fields (e.g. `disable-model-invocation: true` for manual-only skills) only with a stated reason.

## 4. Body
- ≤ 150 lines (spec allows 500). Aim for the smallest body that changes behavior.
- Only what the model would not do by default: decisions, thresholds, names, commands. No generic advice ("write clean code", "handle errors").
- Imperative, one rule per bullet, grouped under short `##` headings.
- First line after the title: `Project rules (AGENTS.md) win on conflict.` for style skills.
- Long detail → `references/<file>.md`, linked one level deep from SKILL.md with a condition ("Read … only when …"). Never chain references.
- Deterministic checks/transforms → `scripts/`; the skill says to run them and read only the output.
- Relative paths only; never hardcode `~/.claude` or absolute paths.
- Don't duplicate a rule across skills; link to the owning skill by name instead.

## 5. Naming & scope
- **Few skills, many files.** Current skills: `hd-index`, `hd-core` (cross-cutting), `hd-frontend`, `hd-backend`, `hd-infra`, `hd-validate`, `hd-auth`, `hd-ai`. Add a new skill only for a genuinely new domain; otherwise add a topic file.
- Skills are flat (`skills/<name>/SKILL.md`); agents don't discover nested skill folders.
- `SKILL.md` of a domain skill = shared rules for the whole domain (a few lines) + a table linking every `references/<topic>.md` with "read when …". Every topic file must be linked there and listed in `hd-index` (`validate.sh` enforces both).
- Topic files: one topic each, ≤ 100 lines (enforced; split the topic when it grows), no links to other topic files (no `references/…` paths inside them). Mentioning another skill by name (`hd-backend` data.md) is fine.
- No skills for third-party services (Vercel, Cloudflare, Neon, …) — those come from vendors' official skills.
- Exception: a library used in every project (Zod, Better Auth, AI SDK) may get an `hd-*` skill, limited to **our conventions** plus how to reach its docs (docs MCP entry for `.mcp.json`, official skill install command). Never restate its API docs.
- Docs sources live only in `skills/hd-index/references/docs-sources.md` (one row per tech: MCP key, official skill, llms.txt; MCP JSON block). Other skills reference it with the exact line `Docs: hd-index docs sources (<Tech>, …).` — never embed MCP configs or install commands elsewhere. New rows need a verified URL/command.
- Facts about tools (flags, config keys, API names) must be verified — run them or read current docs — before they go into a skill.
- Global rules that apply to every task go in `hd-index`, not repeated in other skills.
- One coherent trigger per skill. Split when two halves load for different tasks (UI vs backend); merge when they always load together.
- Each extra skill costs ~80 tokens of always-loaded metadata — don't create one for < ~10 lines of rules.
- Portable style only. Anything true for just one project belongs in that project's AGENTS.md, not here.
- Rules must come from real corrections or existing project rules, not invention. When unsure, ask the owner.

## 6. Changing a skill
1. New topic: add `skills/hd-<domain>/references/<topic>.md`, link it from that `SKILL.md`, add a row to the map in `skills/hd-index/SKILL.md`. New domain skill (rare): copy `templates/SKILL.template.md`, then also update `README.md`.
2. Edit; keep wording terse.
3. Add one line under `## [Unreleased]` in `CHANGELOG.md` (`### Added|Changed|Removed|Fixed`, prefixed with the skill name).
4. Run `scripts/validate.sh` and `claude plugin validate .` — both must pass. Changed `validate.sh`? Also run `scripts/test-validate.sh` and add a case for each new check.
5. Conventional Commit, e.g. `feat(hd-frontend): require reduced-motion check`. Do **not** bump the version here — that happens only in a release (§8).

## 7. Versioning
- **Single source of truth:** `version` in `.claude-plugin/plugin.json`. No version in `marketplace.json` or in skill frontmatter. Claude Code caches installs by this version: content pushed without a bump does not reach users who already installed.
- SemVer for skills (the "API" is agent behavior + skill names):
  - **major** — skill removed or renamed, or a rule reversed (agents will now do the opposite).
  - **minor** — new skill, new rule, new reference/asset, broader trigger.
  - **patch** — wording, typo, clarification, narrower trigger, link fix; no behavior change intended.
- While `0.x`, breaking changes may go in a minor; go to `1.0.0` once the skill set is stable across projects.
- Tags: `huanngdev--vX.Y.Z` (format of `claude plugin tag`). Never move or delete a pushed tag.
- `CHANGELOG.md` follows Keep a Changelog; every release has a dated section.

## 8. Branches & releasing
- `main` is protected: changes land only via PR with green CI. No direct pushes, no force-push. Work on `feat/*`, `fix/*`, `docs/*` branches.
- `main` is the release channel (Claude Code pulls the marketplace from the default branch), so keep it always releasable.
- Version `0.0.0` = nothing released; the plugin is not announced/installed until the first release.

Release = two steps:
```sh
scripts/release.sh minor --dry-run   # preview
scripts/release.sh minor             # from main: branch release/vX.Y.Z, bump + changelog, push, open PR
# merge the PR on GitHub, then:
git switch main && git pull
scripts/release.sh tag               # tag huanngdev--vX.Y.Z and push it → GitHub Release
```
Step 1 refuses unless: arguments are exactly as above, on `main`, clean, in sync with origin, validators pass, at least one skill, `[Unreleased]` non-empty, the release branch doesn't exist yet. Step 2 (`tag`, also has `--dry-run`) refuses unless HEAD is the merged release commit (last commit touching `plugin.json`) and CI on it succeeded. Only the owner releases — agents run `--dry-run` at most and ask before the real run.

## 9. CI
`.github/workflows/ci.yml` on every PR and push to `main` (also runnable manually):
- **Skills & manifests** (required): JSON manifests valid, `validate.sh`, `test-validate.sh`, `claude plugin validate` (Claude Code version pinned in the workflow `env`, bumped deliberately), version/changelog consistency, and on PRs "skills changed ⇒ a **new** `[Unreleased]` line vs the base branch". `release/v*` PRs may touch only `plugin.json` + `CHANGELOG.md`.
- **Scripts & workflows** (required): `shellcheck scripts/*.sh`, `actionlint` on workflows.
- **Scripts on macOS (bash 3.2)**: runs the validators with `/bin/bash` on macOS (portability).

Job names are the required status checks on `main`; renaming one means updating branch protection.

Run the same locally before pushing: `scripts/validate.sh && scripts/test-validate.sh && claude plugin validate . && shellcheck scripts/*.sh && actionlint`. Never weaken these checks to get green.

## 10. Review checklist
- [ ] English only under `skills/`
- [ ] Description triggers would match the intended tasks and not unrelated ones
- [ ] Every line is non-obvious and actionable
- [ ] References linked with a load condition; links resolve
- [ ] No project-specific facts, secrets, or personal data
- [ ] `CHANGELOG.md` `[Unreleased]` updated; validators pass
