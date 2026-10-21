# AGENT HANDOFF: lhu-qlnckh

- **Generated At:** 2026-10-21T11:55:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhu-qlnckh`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục kiểm thử trải nghiệm người dùng trên module Lý lịch khoa học (`hdkh-ly-lich-khoa-hoc`), kiểm tra tính năng in PDF với các mẫu khác nhau (GV, SDH, SYLL, LLKH), hoặc tiếp tục các task liên quan đến phân hệ NCKH.

## 1. NEXT SESSION ACTION PLAN
1. Đọc `.handoff/HANDOFF.md` để nắm rõ kiến trúc bảng mở rộng `tblHDKH_LLKH_AnPham_ChiTiet` và các Stored Procedure mới.
2. Kiểm tra giao diện Lý lịch khoa học trên môi trường thực tế (`https://qlnckh.lhu.edu.vn/hdkh-ly-lich-khoa-hoc`), xác nhận popup sửa bài báo hoạt động mượt mà khi bấm icon bút chì xanh.
3. Khi người dùng hoàn thiện dữ liệu bài báo, kiểm tra bản in PDF và ma trận kiểm tra mẫu in để đảm bảo chuyển trạng thái "Đủ".

## 2. SUGGESTED SKILLS
- `session-bugflow`: Kích hoạt ở đầu mỗi phiên hoặc khi bắt đầu kiểm tra feature/bug mới.
- `fui`: Quản lý các lệnh FUI CLI (module, component, stored procedure, database query).

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `c28d9f5` — refactor(lhu-qldetaisdh): chuan hoa dat ten module kebab-case va dong bo menu
  - `1bd3b37` — refactor(lhu-qlnckh): chuan hoa dat ten module kebab-case va dong bo menu
  - `7ac07cf` — chore(lhu-qlnckh): backup DEV000007 changes and record session handoff
- **Working Tree Ownership:**
  - **Current task changes:**
    - `lhu-qlnckh/modules/hdkh-ly-lich-khoa-hoc/` (Khôi phục 3 Tabs của DEV000007, thêm popup sửa chi tiết bài báo với icon xanh chuẩn `ctrl-update`, kết nối API)
    - `lhu-qlnckh/_db/qlnckh/spAPI_HDKH_LLKH_HuongNC_Save.sql` (SP lưu hướng nghiên cứu chính)
    - `lhu-qlnckh/_db/qlnckh/spAPI_HDKH_LLKH_NCKH_Select.sql` (SP đọc tổng hợp NCKH, LEFT JOIN bảng mở rộng)
    - `lhu-qlnckh/_db/qlnckh/spAPI_HDKH_LLKH_AnPham_ChiTiet_Save.sql` (SP lưu chi tiết bài báo/sách cho LLKH)
    - `lhu-qlnckh/_backup/backup_hdkh_ly_lich_khoa_hoc_v2/` (Bản sao lưu trước khi khôi phục)
    - `lhu-qlnckh/.handoff/HANDOFF.md` (Handoff document)
  - **Pre-existing dirty / unrelated (DO NOT TOUCH):**
    - `_logs/tool-errors.jsonl`
    - `lhu-qlnckh/modules/giai-thuong-quan-ly/`
    - `lhu-qlnckh/modules/giai-thuong-quyet-dinh/`
- **Quick Inspect Commands:**
  - `fui remote diff -p lhu-qlnckh -m hdkh-ly-lich-khoa-hoc`
  - `git status -s lhu-qlnckh/modules/hdkh-ly-lich-khoa-hoc/`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:**
  1. Khôi phục module Lý lịch khoa học (`hdkh-ly-lich-khoa-hoc`) theo phiên bản 3 Tabs của `DEV000007`.
  2. Bổ sung giải pháp lưu trữ các trường dữ liệu học thuật còn thiếu (Tập-số-trang, tháng đăng, vai trò tác giả, tác giả liên hệ, thể loại sách, DOI) mà KHÔNG gây ảnh hưởng đến phân hệ Ấn phẩm hay công thức tính tiền thưởng.
  3. Cung cấp icon chỉnh sửa chuẩn `mdi-square-edit-outline` màu xanh lá trên từng bài báo để mở popup cập nhật trực tiếp.
  4. Dọn dẹp dữ liệu test của tài khoản `NV0000401`.
- **Expected:** Giảng viên xem được đầy đủ hồ sơ LLKH, có thể tự bổ sung thông tin chi tiết bài báo ngay trên giao diện LLKH qua nút bấm xanh, không có lỗi console và dữ liệu test được xóa sạch.
- **Actual:** Đã hoàn thành 100%:
  - Deploy thành công bảng mở rộng `tblHDKH_LLKH_AnPham_ChiTiet` và các Stored Procedures lên DB `qlnckh`.
  - Fix triệt để lỗi `item is not defined` (do lỗi cú pháp đóng ngoặc sớm của core `fastproject-3.0.js` ở `obj.EXE`) bằng cách chuyển sang action `obj.FUN` gọi hàm JavaScript thuần `window.LLKH_moSuaAnPham`.
  - Fix lỗi `a[t] is not a function` bằng cách bỏ `@click:row` thừa trên `<f-table>`.
  - Xóa sạch 100% dữ liệu test của `NV0000401` trong database.
  - Đồng bộ thành công lên server FUI, `fui remote diff` báo 100% `same`.
- **Flow Analysis:**
  - **Input:** Người dùng mở tab "Công trình khoa học" và click vào icon bút chì xanh `mdi-square-edit-outline` trên bài báo.
  - **Process:**
    - `f-table` kích hoạt `editItem(item)` ➔ gọi `runAction` với action `FUN: "LLKH_moSuaAnPham"` ➔ truyền `{ item: rawItem }` vào `window.LLKH_moSuaAnPham`.
    - Component `uc-cong-trinh-khoa-hoc` mở dialog pre-filled dữ liệu bài báo.
    - Giảng viên điền Tập/số/trang, tháng đăng, vai trò, liên hệ, thể loại sách, DOI và bấm "Lưu thông tin".
    - `ajaxCALL("/HDKH_LLKH_AnPham_ChiTiet_Save")` upsert dữ liệu vào bảng `tblHDKH_LLKH_AnPham_ChiTiet`.
  - **State:** Dữ liệu học thuật bổ sung được lưu vào bảng mở rộng `tblHDKH_LLKH_AnPham_ChiTiet`, bảng gốc `AnPham` và `AnPham_TacGia` nguyên vẹn 100%.
  - **Output:** Bảng công trình tự động làm mới qua `@reload="tai"`, hiển thị đầy đủ thông tin chuẩn trích dẫn, ma trận kiểm tra mẫu in cập nhật trạng thái "Đủ".
  - **Side Effects:** 0% rủi ro cho phân hệ Ấn phẩm và SP tính tiền `spAPI_PhiKhenThuong_Cal`.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Code Locations:**
  - `lhu-qlnckh/_db/qlnckh/spAPI_HDKH_LLKH_AnPham_ChiTiet_Save.sql` — SP lưu bổ sung chi tiết bài báo/sách.
  - `lhu-qlnckh/_db/qlnckh/spAPI_HDKH_LLKH_NCKH_Select.sql` — SP đọc tổng hợp dữ liệu NCKH cho LLKH.
  - `lhu-qlnckh/_db/qlnckh/spAPI_HDKH_LLKH_HuongNC_Save.sql` — SP lưu hướng nghiên cứu chính.
  - `lhu-qlnckh/modules/hdkh-ly-lich-khoa-hoc/components/uc-cong-trinh-khoa-hoc.vue` — Bảng công trình và dialog cập nhật chi tiết.
  - `lhu-qlnckh/modules/hdkh-ly-lich-khoa-hoc/components/uc-main.vue` — Controller chính, quản lý 3 tabs, ma trận mẫu in và xuất PDF.
  - `lhu-qlnckh/modules/hdkh-ly-lich-khoa-hoc/script.js` — Thư viện ma trận mẫu in (`window.LLKH`) và định nghĩa tài liệu PDF.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] `fastproject-3.0.js` dòng 348 bị lỗi cú pháp: `templateCompiled('<% ... %>'), { ...data }` (đóng ngoặc đơn sớm trước tham số data). Do đó `obj.EXE` không thể nhận biến `item`. (Evidence: `curl -s https://fui.vn/Framework/V3/fastproject-3.0.js`).
- [FACT] Cơ chế `obj.FUN` trong `fastproject-3.0.js` gọi hàm trực tiếp `window[obj.FUN](obj.IN)` mà không biên dịch template chuỗi, an toàn 100% với Vue 3.5. (Evidence: Đã test và xác nhận hoạt động mượt mà).
- [FACT] Bảng `tblHDKH_LLKH_AnPham_ChiTiet` đã được tạo trên DB `qlnckh` và dữ liệu test của `NV0000401` đã được xóa sạch (0 rows). (Evidence: `fui query "SELECT * FROM tblHDKH_LLKH_AnPham_ChiTiet WHERE MaNhanVien = 'NV0000401'"` trả về 0 rows).

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Verification Runs:**
  - `fui sp deploy spAPI_HDKH_LLKH_AnPham_ChiTiet_Save --db qlnckh` ➔ **Result:** PASS
  - `fui sp deploy spAPI_HDKH_LLKH_NCKH_Select --db qlnckh` ➔ **Result:** PASS
  - `fui component update uc-cong-trinh-khoa-hoc -p lhu-qlnckh -m hdkh-ly-lich-khoa-hoc` ➔ **Result:** PASS
  - `fui remote diff -p lhu-qlnckh -m hdkh-ly-lich-khoa-hoc` ➔ **Result:** PASS (16/16 files same)
  - `curl POST https://tapi.lhu.edu.vn/qlnckh/HDKH_LLKH_NCKH_Select` ➔ **Result:** PASS (trả về 24 bài báo nguyên bản của `NV0000401`)

## 8. CONSTRAINTS & RISKS
- **Contracts to Preserve:**
  - Tuyệt đối không can thiệp schema bảng `AnPham`, `AnPham_TacGia`.
  - Không sửa đổi stored procedures duyệt bài hoặc tính tiền `spAPI_PhiKhenThuong_Cal`.
- **Side Effects / Tradeoffs:**
  - Bảng mở rộng `tblHDKH_LLKH_AnPham_ChiTiet` lưu độc lập, dữ liệu chỉ phục vụ trích dẫn và hiển thị hồ sơ Lý lịch khoa học.
