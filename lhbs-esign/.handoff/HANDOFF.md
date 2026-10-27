# AGENT HANDOFF: lhbs-esign

- **Generated At:** 2026-10-27T11:34:30+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhbs-esign`
- **Status:** `done`
- **Next Session Focus:** Thực thi các module liên quan đến KPI (FE và SQL) theo chuẩn AGENTS.md và DESIGN.md

## 1. NEXT SESSION ACTION PLAN
1. Đọc kỹ `.md/AGENTS.md` (Hard rule: chỉ sửa KPI scope) và `.md/DESIGN.md` (Executive Fluent palette, 4 tầng Results Framework, component patterns, tabular-nums).
2. Kiểm tra nghiệp vụ module KPI cần triển khai (từ tài liệu `docs/2026.10.19_Phương án xây dựng Dashboard vận hành.docx` hoặc yêu cầu từ user).
3. Triển khai FE components trong `modules/kpi-*/components/` (sử dụng helper `ajaxCALLPromise` / `ajaxGETCALLPromise` từ `global-util-js`) và các Stored Procedure backend SQL Server (`spAPI_KPI_*`).

## 2. SUGGESTED SKILLS
- `minimal-feature-implementation`: Triển khai các tính năng mới hoặc view KPI với minimal diff và đúng contract.
- `session-bugflow`: Kiểm tra và xác thực luồng khi xử lý bug.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `9da7eb0` — fix(lhu-qlnckh): sua loi dao nguoc ho ten tac gia va dong bo schema module
  - `b5e2152` — feat(lhu-qldetaisdh): tich hop huy hoi dong, tra cuu lich su va toi uu api hoi dong
- **Working Tree Ownership:**
  - **Current task changes:**
    - `lhbs-esign/.md/AGENTS.md`: Quy định cứng cho agent (KPI-only scope, cấu trúc thực tế, API helpers, pattern chuẩn).
    - `lhbs-esign/.md/DESIGN.md`: Design system toàn diện cho tất cả module `kpi-*` (Executive Fluent palette, 4 tầng Results Framework, component patterns, tabular-nums).
    - `lhbs-esign/imports/global-util-js-WF001.js`: Thư viện global utility chứa `ajaxCALLPromise` và `ajaxGETCALLPromise`.
    - `lhbs-esign/imports/_imports.json`: Đăng ký import toàn cục cho `global-util-js`.
  - **Pre-existing dirty / unrelated:**
    - `../_logs/tool-errors.jsonl` (DO NOT touch/revert)
    - `../lhu-qldetaisdh/*` (DO NOT touch/revert)
- **Quick Inspect Commands:**
  - `git status lhbs-esign/`
  - `git diff lhbs-esign/`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Chuẩn bị hạ tầng phát triển cho domain KPI: hoàn thiện quy chuẩn AGENTS.md, hệ thống thiết kế DESIGN.md cho toàn bộ module `kpi-*`, và bổ sung helper `global-util-js` phục vụ gọi API dạng Promise.
- **Expected:** File quy tắc sát thực tế repo với hard rule KPI-only; DESIGN.md chuẩn hóa theo `kpi-results-framework`; helper `ajaxCALLPromise` và `ajaxGETCALLPromise` hoạt động ở phạm vi global.
- **Actual:** Đã hoàn thành 100% yêu cầu.
- **Flow Analysis:**
  - **Input:** Yêu cầu từ user: viết lại AGENTS.md từ example, viết DESIGN.md áp dụng cho mọi module kpi-*, tạo global util với 2 hàm Promise.
  - **Process:** Khảo sát cấu trúc thực tế của repo `lhbs-esign` → Viết lại AGENTS.md với hard rule KPI-only → Phân tích toàn bộ 91KB CSS thực tế trong `uc-kpi-rf.vue` để viết DESIGN.md → Tạo file `global-util-js-WF001.js` và cập nhật `_imports.json`.
  - **State:** Toàn bộ file tài liệu và code tiện ích đã được lưu và kiểm tra hợp lệ.
  - **Output:** `.md/AGENTS.md`, `.md/DESIGN.md`, `imports/global-util-js-WF001.js`, `imports/_imports.json`.
  - **Side Effects:** Không gây ảnh hưởng đến các module `ks-*`, `tkb-*`, `wf-*`.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Specs / Plans / Issues / ADRs:**
  - `lhbs-esign/.md/AGENTS.md`
  - `lhbs-esign/.md/DESIGN.md`
  - `lhbs-esign/docs/2026.10.19_Phương án xây dựng Dashboard vận hành.docx`
- **Code Locations:**
  - `lhbs-esign/imports/global-util-js-WF001.js:1-48` (`ajaxCALLPromise`, `ajaxGETCALLPromise`) — Promise-based API utility helpers.
  - `lhbs-esign/modules/kpi-results-framework/components/uc-kpi-rf.vue` — Component tham chiếu chuẩn của KPI Results Framework.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] `lhbs-esign/modules/kpi-results-framework/style.css` là file trống; toàn bộ 1226 dòng CSS thực tế nằm trong thẻ `<style scoped>` của `uc-kpi-rf.vue` (Evidence: line 4384 `uc-kpi-rf.vue`).
- [FACT] Hệ màu chuẩn của KPI là Microsoft Fluent palette tông trầm (`--bg: #f3f2f1`, `--accent2: #1B365D`, `--ink: #252423`) và bắt buộc `font-variant-numeric: tabular-nums` cho số liệu KPI (Evidence: lines 4385-4420 `uc-kpi-rf.vue`).
- [FACT] Database backend kết nối SQL Server tại `58.187.42.172`, database `eSignature` (Evidence: `_connections.json`).

### Active Hypotheses
- None.

### Assumptions & Unknowns
- [ASSUMPTION] Các module KPI tiếp theo sẽ triển khai theo cấu trúc chuẩn `modules/kpi-[slug]/` với entry point `uc-main-page.vue` hoặc kế thừa layout từ `uc-kpi-rf.vue`.
- [UNKNOWN] Danh sách các stored procedure backend mới sẽ được xác định theo yêu cầu nghiệp vụ cụ thể của từng module KPI.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - File format & imports check: Đã xác thực cú pháp JS của `global-util-js-WF001.js` và JSON của `_imports.json`.

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- Attempt 1: Đặt `Design.md` trong thư mục module `modules/kpi-results-framework/.md/`.
  - Result: User yêu cầu đổi thành `DESIGN.md` tại root `.md/` và áp dụng cho toàn bộ module có prefix `kpi-`.
  - Conclusion: Luôn duy trì `DESIGN.md` tại root `.md/` làm tài liệu chuẩn chung.
- Attempt 2: Đặt tên util file là `wf-util-js-WF001.js`.
  - Result: User yêu cầu đổi thành `global-util`.
  - Conclusion: Đặt tên file là `global-util-js-WF001.js`.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:**
  - Scope constraint: Chỉ được sửa code và SQL liên quan đến KPI (không đụng vào `ks-*`, `tkb-*`, `wf-*`).
  - Signature `ajaxCALLPromise(url, params)` và `ajaxGETCALLPromise(url, params)` trả trực tiếp dữ liệu và tự handle toast lỗi.
  - Border radius của UI KPI tối đa là 2px (`rounded-xs`).
