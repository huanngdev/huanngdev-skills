# huanngdev-skills

Skills cá nhân chứa style làm việc của huanngdev, dùng được ở mọi project và mọi agent theo chuẩn [Agent Skills](https://agentskills.io) (Claude Code, Codex, Cursor, OpenCode, Gemini CLI…). Nội dung skill viết bằng tiếng Anh để tiết kiệm token.

> **Trạng thái:** chưa release (version `0.0.0`). Đừng cài plugin cho tới bản `0.1.0`.

`hd-index` là file index: rules chung cho mọi task + bản đồ "task nào → skill nào → file nào". Ít skill, nhiều file: mỗi nhóm một skill, mỗi chủ đề một file trong `references/` (agent chỉ đọc file cần).

| Skill | Files trong `references/` | Trạng thái |
|---|---|---|
| `hd-index` | — (rules chung + bản đồ) | ✅ |
| `hd-core` | workflow, git, docs, typescript, testing, security (+ `assets/AGENTS.template.md`) | ✅ |
| `hd-frontend` | react, state, ui, a11y | ✅ |
| `hd-backend` | api, data, storage | ✅ |
| `hd-validate` | schemas, env, forms | ✅ |
| `hd-auth` | setup, permissions | ✅ |
| `hd-ai` | — (một file) | ✅ |
| `hd-infra` | monorepo, packages, docker, ci (+ `assets/gen-env.ts`) | ✅ |

Không có skill cho dịch vụ bên thứ ba (Vercel, Cloudflare, Neon…) — dùng skill official của vendor. Ngoại lệ: Zod, Better Auth, AI SDK có skill riêng nhưng chỉ ghi quy ước của mình + MCP docs.

## Cài đặt

Chọn **một** cách. Cài 2 cách cùng lúc thì Claude Code sẽ thấy skill bị trùng.

### Cách A — Dev local, dùng ngay (khuyên dùng trên máy của bạn)
Symlink vào thư mục skill global, sửa repo là mọi project nhận ngay, không cần push:
```sh
scripts/link.sh            # -> ~/.claude/skills/hd-*  và  ~/.agents/skills/hd-*
scripts/link.sh --unlink   # gỡ
```

### Cách B — Claude Code plugin (máy khác / chia sẻ)
Cần push repo lên GitHub trước. Trong Claude Code:
```
/plugin marketplace add huanngdev/huanngdev-skills
/plugin install huanngdev@huanngdev-skills
```
Skill sẽ có tên `huanngdev:hd-index`, `huanngdev:hd-core`… Cập nhật: `/plugin marketplace update huanngdev-skills`.
Thử từ local trước khi push: `/plugin marketplace add /đường/dẫn/tới/huanngdev-skills`.

### Cách C — Mọi agent qua skills.sh CLI
```sh
npx skills add huanngdev/huanngdev-skills -g --all              # global, mọi agent
npx skills add huanngdev/huanngdev-skills -s hd-frontend        # một skill, chỉ project hiện tại
npx skills add huanngdev/huanngdev-skills@<sha> -g --all        # pin commit
npx skills add . -g --all                                       # từ repo local, trước khi push
npx skills update -g                                            # cập nhật
npx skills ls -g                                                # xem đã cài gì
```

### Global hay theo project?
- **Global** (`~/.claude/skills`, `-g`): style chung, dùng ở mọi repo. Đây là mặc định cho các `hd-*`.
- **Project** (`.claude/skills`, `.agents/skills` trong repo): khi muốn team dùng chung, hoặc pin version cho repo đó. Commit thư mục này vào repo.

### Kiểm tra đã cài đúng
Trong Claude Code gõ `/skills` (hoặc hỏi "what skills do you have?") → phải thấy `hd-*`.
`claude plugin details huanngdev` cho biết chi phí token (cách B).

## Dùng trong project
Trong AGENTS.md của project, chỉ ghi phần riêng và trỏ tới skills:
```md
- Shared style: hd-* skills (start with `hd-index`). This file wins on conflict.
```
Hoặc bảo agent: "dùng hd-core (docs.md + `assets/AGENTS.template.md`) để rút gọn AGENTS.md này".

## Thêm / sửa skill
Rules đầy đủ ở [AGENTS.md](AGENTS.md) (agent tự đọc khi làm việc trong repo này). Tóm tắt:
1. Copy `templates/SKILL.template.md` → `skills/hd-<topic>/SKILL.md`, viết tiếng Anh
2. Description ngắn, có `Use when …`; body ≤ 150 dòng; chi tiết dài để trong `references/`
3. Ghi một dòng dưới `## [Unreleased]` trong `CHANGELOG.md`
4. `scripts/validate.sh` và `claude plugin validate .` phải pass (cần `bun`; sửa validator thì chạy thêm `scripts/test-validate.sh`) → commit (chưa bump version)

## Release (deploy)
Kênh deploy chính là **Claude Code plugin**: push lên `main` = phát hành. Version chỉ nằm ở `.claude-plugin/plugin.json`.

| Loại | Khi nào |
|---|---|
| `major` | Xoá/đổi tên skill, đảo ngược một rule |
| `minor` | Thêm skill, thêm rule, thêm reference |
| `patch` | Sửa chữ, làm rõ, sửa link — không đổi hành vi |

`main` bị khoá: chỉ merge qua PR, CI phải xanh. Làm việc trên nhánh `feat/*`, `fix/*`.

```sh
scripts/release.sh minor --dry-run   # xem trước
scripts/release.sh minor             # tạo nhánh release/vX.Y.Z + bump + changelog + mở PR
# merge PR trên GitHub, rồi:
git switch main && git pull
scripts/release.sh tag               # tag huanngdev--vX.Y.Z + push → tự tạo GitHub Release
``` Máy đã bật auto-update nhận bản mới ở lần mở Claude Code tiếp theo; nếu không thì chạy `claude plugin marketplace update huanngdev-skills && claude plugin update huanngdev@huanngdev-skills`.

CI (`.github/workflows/ci.yml`) chạy mỗi PR/push: validate skills (YAML thật, map, link, độ dài), self-test validator, `claude plugin validate` (version pin), version ↔ changelog, PR sửa skill phải thêm dòng changelog mới; shellcheck + actionlint; chạy lại validator trên macOS (bash 3.2).
