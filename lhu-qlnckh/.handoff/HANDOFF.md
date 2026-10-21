# AGENT HANDOFF: lhu-qlnckh

- **Generated At:** 2026-10-21T10:44:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhu-qlnckh`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục phát triển và hoàn thiện các tính năng nghiệp vụ trong phân hệ DEV (`dev-*`) hoặc phân hệ NCKH, chuẩn bị tích hợp khi có yêu cầu.

## 1. NEXT SESSION ACTION PLAN
1. Đọc `.handoff/HANDOFF.md` để nắm rõ toàn cảnh 32 modules đã được chuẩn hóa kebab-case và tiền tố phân hệ.
2. Kiểm tra nghiệp vụ trong 4 module DEV (`dev-cgcn-quan-tri`, `dev-cgcn-ke-khai`, `dev-khen-thuong-de-xuat`, `dev-khen-thuong-duyet`).
3. Khi hoàn thành kiểm thử các module DEV, đưa lại vào menu `project.json` nếu có yêu cầu.

## 2. SUGGESTED SKILLS
- `session-bugflow`: Sử dụng khi bắt đầu kiểm tra hoặc debug các tính năng của module.
- `minimal-feature-implementation`: Sử dụng khi phát triển tính năng mới cho các phân hệ DEV.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `7ac07cf` — chore(lhu-qlnckh): backup DEV000007 changes and record session handoff
  - `53f2d20` — chore(lhu-qldetaisdh): clean up unused modules, stored procedures, snapshot tables and orphan files
- **Working Tree Ownership:**
  - **Current task changes:**
    - `lhu-qlnckh/.handoff/HANDOFF.md` (tài liệu handoff cập nhật)
    - `lhu-qlnckh/project.json` (cập nhật đồng bộ menu với ModuleID mới, bỏ phân hệ DEV khỏi menu)
    - `lhu-qlnckh/modules/_modules.json` (danh mục 32 modules sau chuẩn hóa)
    - `lhu-qlnckh/modules/*/` (23 modules đổi tên qua `git mv`, 32 file `_moduleInfo.json` cập nhật)
    - `lhu-qlnckh/modules/dashboard/components/uc-anpham-khenthuong.vue` (link `/an-pham-bai-bao`)
    - `lhu-qlnckh/modules/hdkh-bieu-mau-nhiem-vu/script.js` (link `/hdkh-truong-du-lieu`)
    - `lhu-qlnckh/modules/hdkh-truong-du-lieu/script.js` (link `/hdkh-quy-tac-tinh-gio`)
    - `lhu-qlnckh/modules/an-pham-to-trinh/components/uc-table-to-trinh-khen-thuong.vue` (link `/an-pham-in-to-trinh`)
  - **Pre-existing dirty / unrelated (DO NOT TOUCH):**
    - `_logs/tool-errors.jsonl`
    - `lhu-qldetaisdh/*`
- **Quick Inspect Commands:**
  - `git status -s lhu-qlnckh/`
  - `fui module list -p lhu-qlnckh`
  - `fui file status`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Chuẩn hóa toàn bộ ModuleID và ModuleName của hệ thống sang kebab-case thuần tiếng Việt không dấu, gom nhóm theo tiền tố phân hệ (`de-tai-*`, `an-pham-*`, `giai-thuong-*`, `cgcn-*`, `dev-*`, `hdkh-*`), cập nhật đồng bộ Menu `project.json` (bỏ DEV khỏi menu) và mã nguồn liên kết nội bộ, sau đó publish thành công lên server `qlnckh.lhu.edu.vn`.
- **Expected:** Toàn bộ 32 modules tuân thủ đúng chuẩn đặt tên, không còn tiếng Anh lai tạp hay lỗi chính tả; menu hiển thị đúng và đồng bộ; server production nhận diện đúng 100%.
- **Actual:** Đã hoàn thành 100%:
  - Đổi tên 23 thư mục module qua `git mv`.
  - Cập nhật 32 file `_moduleInfo.json` và `modules/_modules.json`.
  - Cập nhật 4 file mã nguồn chứa hardcoded routes.
  - Cập nhật `project.json` và publish thành công (`fui project publish-config`).
  - Publish đổi ID và ModuleName cho toàn bộ các module lên server (`fui module update`).
  - Publish component và script cập nhật.
  - Sau đó theo yêu cầu user, đã loại bỏ "Phân hệ DEV" khỏi menu `project.json` và publish lại lên server.
- **Flow Analysis:**
  - **Input:** Danh sách 32 modules cũ và yêu cầu chuẩn hóa kebab-case theo tiền tố phân hệ.
  - **Process:** Refactor local (`git mv` ➔ metadata update ➔ code update ➔ `project.json` update) ➔ Recheck & Validate (`fui module validate`) ➔ Publish lên server (`fui module update` + `fui project publish-config` + `fui component update` + `fui module publish script`).
  - **State:** 32 modules trên live server đều mang ModuleID và ModuleName chuẩn, 0 unpublished files.
  - **Output:** Hệ thống chuẩn chỉ, menu 7 nhóm rõ ràng, không còn module DEV trên menu người dùng cuối.
  - **Side Effects:** Đổi ModuleID làm thay đổi URL truy cập tương ứng trên server, nhưng toàn bộ menu và link nội bộ đã được đồng bộ nên không gây broken link.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Code Locations:**
  - `lhu-qlnckh/modules/_modules.json` — Danh mục 32 modules hệ thống.
  - `lhu-qlnckh/project.json` — Cấu hình menu và routes của project.
  - `lhu-qlnckh/modules/dashboard/components/uc-anpham-khenthuong.vue:3` — Link xem chi tiết bài báo.
  - `lhu-qlnckh/modules/hdkh-bieu-mau-nhiem-vu/script.js:2` — Link cấu hình trường dữ liệu.
  - `lhu-qlnckh/modules/hdkh-truong-du-lieu/script.js:18` — Link cấu hình quy tắc tính giờ.
  - `lhu-qlnckh/modules/an-pham-to-trinh/components/uc-table-to-trinh-khen-thuong.vue:225` — Link in tờ trình.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] Toàn bộ 32 modules đã được đổi tên và cập nhật đồng bộ trên live server `qlnckh.lhu.edu.vn`. (Evidence: `fui module list -p lhu-qlnckh` trả về 32 modules mới lúc 10:40:35).
- [FACT] `fui file status` trả về `0 unpublished file(s)`.
- [FACT] 32/32 modules đều vượt qua kiểm tra `fui module validate` không có semantic error nào.
- [FACT] Menu `project.json` có 7 nhóm chính, mục "Phân hệ DEV" đã được loại bỏ theo yêu cầu của user.

### Assumptions & Unknowns
- [ASSUMPTION] Các module phân hệ DEV (`dev-*`) sẽ được gọi trực tiếp qua URL hoặc tích hợp lại vào menu trong các đợt phát triển tiếp theo.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Validation Runs:**
  - `fui module validate -p lhu-qlnckh -m <all 32 modules>` → **Result:** PASS (0 errors trên tất cả 32 modules).
  - `fui resolve <all menu urls>` → **Result:** PASS (tất cả các route đều resolve trúng thư mục module tương ứng).
  - `fui file status` → **Result:** PASS (`0 unpublished file(s)`).

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- Nhóm DEV ban đầu được đưa vào menu ở vị trí số 8, nhưng user yêu cầu bỏ khỏi menu để tránh lộ trên giao diện chung ➔ Đã gỡ bỏ và publish lại config.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên quy ước tiền tố phân hệ (`de-tai-`, `an-pham-`, `giai-thuong-`, `cgcn-`, `dev-`, `hdkh-`, `dashboard`).
- **Side Effects / Tradeoffs:** Bất kỳ bookmark cũ nào trên trình duyệt trỏ vào URL cũ (ví dụ `/approve-request` hay `/my-papers`) sẽ cần chuyển sang URL mới (`/an-pham-cho-duyet`, `/an-pham-cua-toi`).
