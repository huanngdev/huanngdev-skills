# huanngdev-skills

Skills cá nhân chứa style làm việc của huanngdev, dùng được ở mọi project và mọi agent theo chuẩn [Agent Skills](https://agentskills.io) (Claude Code, Codex, Cursor, OpenCode, Gemini CLI…). Nội dung skill viết bằng tiếng Anh để tiết kiệm token.

> **Trạng thái:** chưa có skill nào, chưa release (version `0.0.0`). Đừng cài plugin cho tới bản `0.1.0`.

| Skill | Load khi |
|---|---|
| _(chưa có)_ | |

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
Skill sẽ có tên `huanngdev:hd-workflow`… Cập nhật: `/plugin marketplace update huanngdev-skills`.
Thử từ local trước khi push: `/plugin marketplace add /đường/dẫn/tới/huanngdev-skills`.

### Cách C — Mọi agent qua skills.sh CLI
```sh
npx skills add huanngdev/huanngdev-skills -g --all              # global, mọi agent
npx skills add huanngdev/huanngdev-skills -s hd-react-ui        # một skill, chỉ project hiện tại
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
- Shared style: `hd-workflow`, `hd-typescript`, `hd-react-ui`, `hd-backend-api`. This file wins on conflict.
```
Hoặc bảo agent: "dùng hd-agents-md để rút gọn AGENTS.md này".

## Thêm / sửa skill
Rules đầy đủ ở [AGENTS.md](AGENTS.md) (agent tự đọc khi làm việc trong repo này). Tóm tắt:
1. Copy `templates/SKILL.template.md` → `skills/hd-<topic>/SKILL.md`, viết tiếng Anh
2. Description ngắn, có `Use when …`; body ≤ 150 dòng; chi tiết dài để trong `references/`
3. Ghi một dòng dưới `## [Unreleased]` trong `CHANGELOG.md`
4. `scripts/validate.sh` và `claude plugin validate .` phải pass → commit (chưa bump version)

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

CI (`.github/workflows/ci.yml`) chạy mỗi PR/push: validate skills, validate manifest, kiểm version ↔ changelog.
