# AGENT HANDOFF: fui-cli

- **Generated At:** 2026-10-23T14:37:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục phát triển và hoàn thiện các module nghiệp vụ Chuyển giao công nghệ (CGCN) và Khen thưởng trên dự án `lhu-qlnckh`, kiểm tra tính nhất quán dữ liệu giữa database MSSQL và giao diện Vue.

## 1. NEXT SESSION ACTION PLAN
1. Đọc `.handoff/HANDOFF.md` và kiểm tra `git status` để nắm các module đã commit và đồng bộ lên remote.
2. Kiểm tra các Stored Procedure của CGCN (`spAPI_CGCN_*`) trên môi trường MSSQL thông qua `fui sp` hoặc `fui query`.
3. Kiểm tra hoạt động của 4 module nghiệp vụ chính thức (`cgcn-ke-khai`, `cgcn-quan-tri`, `khen-thuong-de-xuat`, `khen-thuong-duyet`).

## 2. SUGGESTED SKILLS
- `session-bugflow`: Kích hoạt ở đầu mỗi phiên hoặc khi bắt đầu kiểm tra feature/bug mới.
- `fui`: Quản lý các lệnh FUI CLI (module, project, sp, database).

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `bf48986` — feat(lhu-qldetaisdh): bo sung input ty le trung lap trong dialog tu choi buoc 5
  - `bb25340` — fix(lhu-qldetaisdh): xu ly luu file quyet dinh va don dep file rac toan he thong
- **Working Tree Ownership:**
  - **Current task changes:**
    - Loại bỏ 4 module tiền tố dev (`dev-cgcn-ke-khai`, `dev-cgcn-quan-tri`, `dev-khen-thuong-de-xuat`, `dev-khen-thuong-duyet`).
    - Thêm 4 module chính thức (`cgcn-ke-khai`, `cgcn-quan-tri`, `khen-thuong-de-xuat`, `khen-thuong-duyet`).
    - Bổ sung 8 Stored Procedure CGCN (`spAPI_CGCN_*.sql`).
    - Cập nhật 9 Stored Procedure liên quan Ấn phẩm & Cuộc thi KHCN (`spAPI_AnPham*`, `spAPI_ThiKHCN*`).
    - Cập nhật các Vue components tác giả và banner khen thưởng.
    - Cập nhật cấu hình dự án (`project.json`, `_modules.json`, `schema.json`).
  - **Pre-existing dirty / unrelated:**
    - `_history/`: Lưu trữ snapshot các file bị ghi đè trước đó.
    - `_logs/tool-errors.jsonl`: Nhật ký lỗi công cụ.
  - **Unknown ownership:** None
- **Quick Inspect Commands:**
  - `git status`
  - `git diff -w --stat`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Chuẩn hóa toàn bộ thay đổi mã nguồn dự án `lhu-qlnckh` (chuyển giao công nghệ, khen thưởng, cập nhật SPs), tạo handoff và thực hiện commit - push sạch sẽ lên remote repository.
- **Expected:** Toàn bộ file thay đổi có chủ đích được stage và commit; các file line endings không cần thiết được hoàn nguyên để giữ git diff sạch.
- **Actual:** Đã hoàn nguyên 188 file chỉ đổi CRLF/LF, giữ lại đúng 89 file thay đổi code và các file/folder nghiệp vụ mới.
- **Flow Analysis:**
  - **Input:** Lệnh `/handoff sau do /clean-stage-commit-push` từ người dùng.
  - **Process:**
    - Kiểm tra và phân loại thay đổi (`git status`, `git diff -w`).
    - Khôi phục các file chỉ đổi kết thúc dòng CRLF/LF không có code change.
    - Tạo tài liệu bàn giao `.handoff/HANDOFF.md`.
    - Stage các module, stored procedure, cấu hình và lịch sử tương ứng.
    - Tạo semantic commit và đẩy lên remote `origin/main`.
  - **State:** Working tree sạch sẽ sau commit và push, remote `origin/main` đồng bộ với local.
  - **Output:** Báo cáo chi tiết commit và push cho người dùng.
  - **Side Effects:** Cập nhật repository remote GitHub.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Specs / Plans / Issues / ADRs:** None
- **Code Locations:**
  - `lhu-qlnckh/modules/cgcn-ke-khai/` — Giao diện kê khai chuyển giao công nghệ
  - `lhu-qlnckh/modules/cgcn-quan-tri/` — Giao diện quản trị chuyển giao công nghệ
  - `lhu-qlnckh/modules/khen-thuong-de-xuat/` — Giao diện đề xuất khen thưởng
  - `lhu-qlnckh/modules/khen-thuong-duyet/` — Giao diện duyệt khen thưởng
  - `lhu-qlnckh/_db/qlnckh/spAPI_CGCN_*.sql` — Nhóm stored procedure xử lý CGCN

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] 4 module tiền tố `dev-` đã được chuyển đổi thành các module chính thức không còn tiền tố `dev-` trong cấu hình `_modules.json` và `project.json`. (Evidence: `git diff lhu-qlnckh/modules/_modules.json`)
- [FACT] 188 file SQL ban đầu chỉ khác biệt về kết thúc dòng CRLF/LF (không có thay đổi code nào) và đã được hoàn nguyên an toàn. (Evidence: `git diff -w`)

### Active Hypotheses
None

### Assumptions & Unknowns
- [ASSUMPTION] Các thư mục `_history/` và `_backup/` được commit cùng theo quy ước lưu trữ backup của repo này (tương tự commit `cc75995`).

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `git diff -w` → **Result:** PASS | **Proves:** Chỉ còn các file có code changes thực tế.
- **Critical Error / Log Snippet:** None

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- Không commit toàn bộ hàng trăm file SQL chỉ do đổi CRLF/LF nhằm tránh làm ô nhiễm commit history.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên cấu trúc các SP MSSQL và format metadata FUI CLI (`project.json`, `_modules.json`).
- **Side Effects / Tradeoffs:** Không xóa các bản ghi lịch sử `_history/` để hỗ trợ rollback khi cần.
