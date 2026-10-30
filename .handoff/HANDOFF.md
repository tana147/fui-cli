# AGENT HANDOFF: fui-cli

- **Generated At:** 2026-10-30T09:32:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục phát triển, cấu hình hoặc kiểm thử các module và API/SP trên các dự án FUI sau khi đã kéo toàn bộ 505 module và 1,491 Stored Procedures về local.

## 1. NEXT SESSION ACTION PLAN
1. Chạy `fui use <project/module>` để chọn module cần làm việc (ví dụ `lhu-qldetaisdh/ths-hoi-dong` hoặc `lhbs-esign/kpi-ops-dashboard`).
2. Chạy `fui module validate` hoặc `fui sp verify` trước khi triển khai thay đổi mới.
3. Kiểm tra các module mới tải về (`lhbs-lms/modules/bc-thong-ke-xep-loai`, `lhbs-lms/modules/log-hoc-lieu-so`) nếu có kế hoạch tích hợp tiếp theo.

## 2. SUGGESTED SKILLS
- `fui`: Thao tác trực tiếp với low-code platform FUI (module, component, SP, deploy, publish).
- `session-bugflow`: Tuân thủ quy trình debug / feature khi tiếp nhận yêu cầu mới.
- `clean-stage-commit-push`: Đảm bảo git hygiene khi hoàn tất phiên làm việc.

## 3. GIT & COMMIT STATE
- **Branch:** `main` (tracking `origin/main`)
- **Relevant Recent Commits:**
  - `32e0376` — feat(lhbs-esign): enterprise executive cockpit, 60 kpi heatmap grid, dumbbell variance chart and 1-1 fact reconciliation
  - `8dcbd89` — refactor(lhbs-esign): compact KPI Ops Dashboard UI, prune redundant data and tighten CSS spacing
  - `c8adeff` — refactor(lhbs-esign): streamline KPI Ops Dashboard, isolate frozen period data and preserve Impact Zone
- **Working Tree Ownership:**
  - **Current task changes:**
    - Toàn bộ 505 modules cho 6 dự án (`lhu-qldetaisdh`, `lhu-qlnckh`, `lhbs-esign`, `lhbs-lms`, `danh-muc`, `zen-eorder`).
    - Toàn bộ Stored Procedures (`1,491` files `.sql` trong `_db/`).
    - File cấu hình dự án: `project.json`, `_projectInfo.json`, `_modules.json`.
  - **Pre-existing dirty / unrelated:** Không có (các file local thay đổi trước đó đã được backup vào `_history/` theo thỏa thuận với user).
  - **Unknown ownership:** Không có.
- **Quick Inspect Commands:**
  - `git status -s`
  - `git diff --stat`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Đồng bộ và kéo toàn bộ các module UI (`module.json`, `components`, `script.js`, `style.css`) và các Stored Procedures (SPs trong `_db/`) của toàn bộ 6 dự án trong workspace (`lhu-qldetaisdh`, `lhu-qlnckh`, `lhbs-esign`, `lhbs-lms`, `danh-muc`, `zen-eorder`).
- **Expected:** Toàn bộ module và Stored Procedure có mặt tại local workspace, khớp với server và schema.
- **Actual:** Đã kéo thành công 505/505 module và 1,491 SPs.
- **Flow Analysis:**
  - **Input:** Lệnh yêu cầu từ user ("Lấy toàn bộ module, store của toàn bộ dự án về").
  - **Process:** `fui project sync` cho 6 projects -> `fui schema pull` & tạo placeholder batch pull SPs -> `fui module get` đồng loạt cho 505 module qua `ThreadPoolExecutor`.
  - **State:** File local được cập nhật đồng bộ từ server, các file sửa dở trước đó được backup vào `_history/`.
  - **Output:** 505 module directories đầy đủ, 1,491 file `.sql` trong `_db/`.
  - **Side Effects:** Ghi đè các file local cũ (đã có backup trong `_history/`).

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Code Locations:**
  - `lhu-qldetaisdh/modules/` (32 modules)
  - `lhu-qlnckh/modules/` (31 modules)
  - `lhbs-esign/modules/` (59 modules)
  - `lhbs-lms/modules/` (190 modules)
  - `danh-muc/modules/` (49 modules)
  - `zen-eorder/modules/` (144 modules)
  - `lhu-qldetaisdh/_db/qldetaisdh/` (115 SPs)
  - `lhu-qlnckh/_db/qlnckh/` (233 SPs)
  - `lhbs-esign/_db/esign/` (362 SPs)
  - `lhbs-esign/_db/lms/` (781 SPs)

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] `fui schema pull` hỗ trợ batch load nội dung SP khi file `.sql` rỗng đã tồn tại trong thư mục kết nối.
- [FACT] `fui module get` nhận target dạng `<project>/<moduleId>` (hoặc `-p <project> -m <moduleId>`). Nếu truyền `-m <project>/<moduleId>` sẽ bị lỗi do duplicate tên project.
- [FACT] Workspace quản lý 6 dự án chính: `lhu-qldetaisdh`, `lhu-qlnckh`, `lhbs-esign`, `lhbs-lms`, `danh-muc`, `zen-eorder`.

### Active Hypotheses
- Không có (toàn bộ tác vụ là thao tác đồng bộ I/O đã hoàn tất và được kiểm chứng).

### Assumptions & Unknowns
- [ASSUMPTION] Người dùng đã xác nhận ghi đè các file local chưa commit trước đó, hệ thống đã lưu backup tự động vào `_history/`.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `fui schema pull`: 1,491 file SQL đầy đủ.
  - `fui module get`: 505/505 modules completed thành công (exit code 0).

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
Attempt 1: Gọi `fui module get -p <project> -m <item['id']>` khi `item['id']` đã chứa prefix `<project>/`.
Result: Báo lỗi module không tồn tại.
Conclusion: Dùng trực tiếp target `fui module get <target>` hoặc bóc tách `item['ModuleID']`.

## 9. CONSTRAINTS & RISKS
Contracts to Preserve: Schema FUI metadata, tAPI route naming conventions (`spAPI_*`, `spAPIFILE_*`).
Side Effects / Tradeoffs: Thư mục `_history/` lưu lại các bản trước đó của file bị ghi đè.
