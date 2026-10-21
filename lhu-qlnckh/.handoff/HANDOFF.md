# AGENT HANDOFF: lhu-qlnckh

- **Generated At:** 2026-10-21T12:06:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhu-qlnckh`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục kiểm thử, bảo trì phân hệ Giải thưởng hoặc phát triển các module NCKH tiếp theo khi có yêu cầu.

## 1. NEXT SESSION ACTION PLAN
1. Đọc `.handoff/HANDOFF.md` và kiểm tra lại trạng thái live của 2 module `giai-thuong-quan-ly` và `giai-thuong-quyet-dinh`.
2. Kiểm tra nghiệp vụ người dùng trên web: kiểm thử tạo mới đề tài, liên kết số quyết định, quản lý minh chứng đính kèm.
3. Nếu cần mở rộng: xem xét đồng bộ thêm các tính năng xuất báo cáo khen thưởng hoặc thống kê nâng cao.

## 2. SUGGESTED SKILLS
- `session-bugflow`: Sử dụng khi bắt đầu kiểm tra hoặc debug các tính năng mới của module.
- `clean-stage-commit-push`: Sử dụng khi hoàn thành task để dọn dẹp và push git sạch sẽ.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `702da48` — feat(lhu-qlnckh): khoi phuc ly lich khoa hoc 3 tabs va tich hop sua chi tiet an pham
  - `1bd3b37` — refactor(lhu-qlnckh): chuan hoa dat ten module kebab-case va dong bo menu
- **Working Tree Ownership:**
  - **Current task changes:**
    - `modules/giai-thuong-quan-ly/module.json` (mount uc-main-page)
    - `modules/giai-thuong-quan-ly/script.js` (clear legacy code)
    - `modules/giai-thuong-quan-ly/style.css` (scoped custom css)
    - `modules/giai-thuong-quan-ly/components/_components.json` (sync 7 components ComID 12598-12604)
    - `modules/giai-thuong-quan-ly/components/uc-main-page.vue` (entry point logic, fix falsy selectedLoaiGiaiThuongId=0)
    - `modules/giai-thuong-quan-ly/components/uc-main-view.vue` (bảng dữ liệu, search, excel, filter dropdown)
    - `modules/giai-thuong-quan-ly/components/uc-stats.vue` (thẻ thống kê giải thưởng)
    - `modules/giai-thuong-quan-ly/components/uc-modal-reward-type.vue` (modal thêm loại giải thưởng)
    - `modules/giai-thuong-quan-ly/components/uc-modal-reward.vue` (modal thêm/sửa giải thưởng)
    - `modules/giai-thuong-quan-ly/components/uc-modal-proofs.vue` (modal quản lý tập tin minh chứng)
    - `modules/giai-thuong-quan-ly/components/uc-modal-decision-detail.vue` (modal xem thông tin quyết định đính kèm)
    - `modules/giai-thuong-quyet-dinh/module.json` (mount uc-main-page)
    - `modules/giai-thuong-quyet-dinh/script.js` (clear legacy code)
    - `modules/giai-thuong-quyet-dinh/style.css` (scoped custom css)
    - `modules/giai-thuong-quyet-dinh/components/_components.json` (sync 5 components ComID 12605-12609)
    - `modules/giai-thuong-quyet-dinh/components/uc-main-page.vue` (entry point logic quyết định khen thưởng)
    - `modules/giai-thuong-quyet-dinh/components/uc-main-view.vue` (bảng quyết định, search, excel, thống kê đề tài)
    - `modules/giai-thuong-quyet-dinh/components/uc-stats.vue` (thẻ thống kê quyết định)
    - `modules/giai-thuong-quyet-dinh/components/uc-modal-decision.vue` (modal thêm/sửa quyết định)
    - `modules/giai-thuong-quyet-dinh/components/uc-modal-files.vue` (modal quản lý file scan quyết định)
    - `.handoff/HANDOFF.md` (tài liệu handoff cập nhật)
  - **Pre-existing dirty / unrelated:** None
- **Quick Inspect Commands:**
  - `git diff --stat`
  - `fui file status`
  - `fui module validate -p lhu-qlnckh -m giai-thuong-quan-ly`
  - `fui module validate -p lhu-qlnckh -m giai-thuong-quyet-dinh`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Chuẩn hóa toàn bộ 2 module `giai-thuong-quan-ly` và `giai-thuong-quyet-dinh` từ legacy `module.json` sang SFC Options API theo chuẩn `AGENTS.md`, nâng cấp giao diện chuẩn hệ thống, fix lỗi hiển thị 0 record tại bảng giải thưởng và publish lên live server `qlnckh.lhu.edu.vn`.
- **Expected:** Giao diện hiện đại có stats cards, thanh tìm kiếm gạch chân, nút Excel thu gọn, bảng dữ liệu fixed-header; nạp đủ 335 giải thưởng khi chọn "Tất cả" (ID=0); hiển thị chuẩn xác số lượng đề tài liên kết tại bảng quyết định.
- **Actual:** Đã hoàn thành 100%:
  - Tách thành 12 SFC components chuẩn mực tại 2 thư mục `components/`.
  - Cập nhật 2 file `module.json` chỉ mount `uc-main-page`, làm trống 2 file `script.js`.
  - Đã đăng ký 12 components lên server và publish toàn bộ code mới.
  - Fix triệt để bug falsy `!this.selectedLoaiGiaiThuongId` đối với ID `0`, nạp đủ 335 giải thưởng từ CSDL.
- **Flow Analysis:**
  - **Input:** Người dùng mở module qua URL `/giai-thuong-quan-ly` hoặc `/giai-thuong-quyet-dinh`.
  - **Process:** Gọi API `/LoaiGiaiThuong_Get_All` -> mặc định chọn "Tất cả" (`LoaiGiaiThuongID: 0`) -> gọi `/GiaiThuong_Get_ByLoaiGiaiThuongID` -> hiển thị 335 giải thưởng. Tại module quyết định, gọi `/GiaiThuong_QuyetDinh_Get_All` (`LoaiQD: 1`) -> hiển thị 70 quyết định kèm số lượng đề tài liên kết (`SoGiaiThuong`).
  - **State:** Component cha quản lý state tập trung, không dùng `vueData` trong component con.
  - **Output:** Giao diện đồng bộ, tốc độ tải mượt, dữ liệu hiển thị chính xác.
  - **Side Effects:** Không làm thay đổi contract API/DB backend.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Code Locations:**
  - `modules/giai-thuong-quan-ly/components/uc-main-page.vue:144` — Logic gọi `fetchRewards` với `LoaiGiaiThuongID`.
  - `modules/giai-thuong-quan-ly/components/uc-main-view.vue:18` — Dropdown chọn loại giải thưởng và xuất file Excel.
  - `modules/giai-thuong-quyet-dinh/components/uc-main-page.vue:75` — Gọi `fetchDecisions` nạp quyết định khen thưởng.
  - `_db/qlnckh/spAPI_GiaiThuong_Get_ByLoaiGiaiThuongID.sql:25` — Logic lọc giải thưởng theo `LoaiGiaiThuongID`.
  - `_db/qlnckh/spAPI_GiaiThuong_QuyetDinh_Get_All.sql:19` — Subquery đếm số đề tài khen thưởng theo quyết định.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] Bảng `dbo.GiaiThuong` có 335 bản ghi còn hiệu lực, 100% do Võ Ngọc Vinh (`NV0000602`) tạo. (Evidence: `fui query "SELECT COUNT(*) FROM dbo.GiaiThuong WHERE Is_Xoa = 0"`).
- [FACT] Bảng `dbo.QuyetDinh` (`LoaiQD = 1`) có 70 bản ghi quyết định, 295 đề tài đã được liên kết `QDID`. (Evidence: `fui query "SELECT COUNT(*) FROM dbo.GiaiThuong WHERE QDID > 0"`).
- [FACT] Lỗi 0 record ở trang giải thưởng do `!this.selectedLoaiGiaiThuongId` đánh giá `!0 === true` trong JavaScript, đã sửa thành so sánh tường minh `=== null || === undefined`.
- [FACT] `fui file status` trả về `0 unpublished file(s)` và 32/32 modules đều PASS validation.

### Assumptions & Unknowns
- [ASSUMPTION] 40 giải thưởng còn lại trong CSDL chưa có `QDID` sẽ được quản trị viên gán bổ sung khi có quyết định liên quan.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Validation Runs:**
  - `fui module validate -p lhu-qlnckh -m giai-thuong-quan-ly` → **Result:** PASS (0 errors).
  - `fui module validate -p lhu-qlnckh -m giai-thuong-quyet-dinh` → **Result:** PASS (0 errors).
  - `fui file status` → **Result:** PASS (`0 unpublished file(s)`).

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- Không dùng `!selectedLoaiGiaiThuongId` để kiểm tra tồn tại của ID danh mục vì ID `0` đại diện cho mục "Tất cả" (`ALL`) trong stored procedure.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên các tham số gọi API `/LoaiGiaiThuong_*`, `/GiaiThuong_*`, `/GiaiThuong_QuyetDinh_*`.
- **Side Effects / Tradeoffs:** Không có breaking change.
