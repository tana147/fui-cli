# AGENT HANDOFF: fui-cli

- **Generated At:** 2026-10-20T10:10:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục phát triển các module và stored procedure trên FUI theo yêu cầu người dùng, kiểm tra các thay đổi mới nhất vừa đồng bộ.

## 1. NEXT SESSION ACTION PLAN
1. Đọc `.handoff/HANDOFF.md` để nắm trạng thái codebase và các module đã được đồng bộ mới nhất từ server.
2. Kiểm tra target module/project đang active (`fui use` hoặc `fui file where`).
3. Thực thi các tác vụ tính năng / fix bug tiếp theo theo yêu cầu của người dùng.

## 2. SUGGESTED SKILLS
- `session-bugflow`: Kích hoạt ở đầu mỗi phiên hoặc khi bắt đầu kiểm tra feature/bug mới.
- `fui`: Quản lý các lệnh FUI CLI (module, project, sp, database).

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `cc75995` — chore: track _logs and _history in git backup
  - `2081784` — feat: initial backup of all FUI projects, modules and stored procedures
- **Working Tree Ownership:**
  - **Current task changes:**
    - Toàn bộ 480 modules từ 5 projects (`lhu-qldetaisdh`, `lhu-qlnckh`, `danh-muc`, `lhbs-lms`, `zen-eorder`) được đồng bộ qua `fui module get`.
    - Toàn bộ stored procedures (377 SQL files) cho 2 database MSSQL (`qldetaisdh`, `qlnckh`) được đồng bộ qua `fui schema pull`.
    - File cấu hình và metadata dự án (`project.json`, `_modules.json`, `components/`, `imports/`) được đồng bộ qua `fui project sync`.
    - Các file bị ghi đè được tự động lưu phiên bản cũ tại `_history/`.
  - **Pre-existing dirty / unrelated:** Các file sửa đổi cục bộ trước session này đã được đồng bộ/lưu vào `_history/`.
  - **Unknown ownership:** None
- **Quick Inspect Commands:**
  - `git status`
  - `git diff --stat`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Lấy toàn bộ module và store (stored procedure) mới nhất từ hệ thống về workspace và báo cáo chi tiết cho người dùng.
- **Expected:** Toàn bộ module của các project trong workspace và toàn bộ stored procedure của các project có database được cập nhật mới nhất từ server FUI/tAPI.
- **Actual:** Đã lấy thành công 480/480 module và 377 stored procedure, lưu trữ lịch sử các bản sửa đổi trước đó vào `_history/`.
- **Flow Analysis:**
  - **Input:** Lệnh từ người dùng ("lấy toàn bộ module, store mới nhất từ hệ thống về").
  - **Process:**
    - Bước 1: `fui schema pull --db <ref>` kéo toàn bộ DDL, tables, API endpoints, và body SQL procedures.
    - Bước 2: `fui project sync -p <proj>` cập nhật metadata dự án, components dùng chung và imports.
    - Bước 3: `fui module get -p <proj> -m <mod>` tải lần lượt 480 modules về thư mục cục bộ.
    - Bước 4: Khôi phục session target về `lhu-qldetaisdh/xet-tot-nghiep`.
  - **State:** File hệ thống local cập nhật trạng thái mới nhất từ server; các file khác biệt được lưu vào `_history/`.
  - **Output:** Báo cáo chi tiết số lượng module, store, files thay đổi.
  - **Side Effects:** Cập nhật các file trong workspace, tạo các file sao lưu trong `_history/`.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Specs / Plans / Issues / ADRs:** None
- **Code Locations:**
  - `lhu-qldetaisdh/_db/qldetaisdh/` (140 SPs)
  - `lhu-qlnckh/_db/qlnckh/` (237 SPs)
  - `lhu-qldetaisdh/modules/` (59 modules)
  - `lhu-qlnckh/modules/` (40 modules)
  - `danh-muc/modules/` (49 modules)
  - `lhbs-lms/modules/` (188 modules)
  - `zen-eorder/modules/` (144 modules)

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] `lhu-qldetaisdh` và `lhu-qlnckh` là 2 project duy nhất có cấu hình kết nối DB MSSQL trong `_connections.json`. (Evidence: `fui db list`)
- [FACT] Toàn bộ 480 module thuộc 5 project đã được kéo thành công không còn lỗi. (Evidence: `scratch/sync_results.json` & task log 116)
- [FACT] Khi `fui module get` ghi đè file có nội dung khác với server, bản cũ được tự động chuyển vào `_history/`. (Evidence: CLI output & `_history/`)

### Active Hypotheses
None

### Assumptions & Unknowns
- [ASSUMPTION] Các project `danh-muc`, `lhbs-lms`, `zen-eorder` không dùng MSSQL trực tiếp qua CLI `_db` mà qua tAPI endpoint hoặc chưa cấu hình token.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `fui schema pull --db lhu-qldetaisdh/qldetaisdh` → **Result:** PASS | **Proves:** Schema và 140 bodies đồng bộ thành công.
  - `fui schema pull --db lhu-qlnckh/qlnckh` → **Result:** PASS | **Proves:** Schema và 237 bodies đồng bộ thành công.
  - `fui module get -p <proj> -m <mod>` (x480) → **Result:** PASS (480/480) | **Proves:** Toàn bộ modules được cập nhật đầy đủ.
- **Critical Error / Log Snippet:**
  - `lhbs-lms/tu-quan-15-phut` gặp lỗi fetch file ban đầu (network timeout), retry lần 2 đã thành công hoàn toàn.

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
None

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên quy ước FUI CLI (`_modules.json`, `_projectInfo.json`, `_publishState.json`).
- **Side Effects / Tradeoffs:** Không can thiệp hoặc xoá các file trong `_history/` để người dùng có thể rollback các thay đổi cục bộ nếu cần.
