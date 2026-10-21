# AGENT HANDOFF: lhu-qlnckh

- **Generated At:** 2026-10-21T17:00:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhu-qlnckh`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục kiểm thử phân hệ Lý lịch khoa học trên môi trường thực tế, kiểm tra xuất bản in 4 mẫu (GV, SDH, SYLL, LLKH), hoặc nâng cấp liên kết thành viên phân hệ Chuyển giao công nghệ (CGCN) nếu có yêu cầu.

## 1. NEXT SESSION ACTION PLAN
1. Kiểm tra nghiệm thu giao diện Lý lịch khoa học trên `qlnckh.lhu.edu.vn/hdkh-ly-lich-khoa-hoc`:
   - Xác nhận các nút không có chức năng ở tab Thông tin cơ bản (HRM) đã ở trạng thái disabled.
   - Xác nhận chức năng thêm/sửa/xóa đề tài ngoài trường tự khai hoạt động ổn định.
   - Xác nhận việc bổ sung thông tin bài báo/chương sách (Tập số trang, tháng đăng, vai trò, tên sách chứa chương) được lưu vào Single Source of Truth và hiển thị trên bản in SĐH.
2. Kiểm tra bản in 4 mẫu (Mẫu GV, Mẫu SDH đào tạo tiến sĩ, Mẫu SYLL, Mẫu LLKH 5 năm) để đảm bảo không phát sinh lỗi layout hay dữ liệu trống.
3. Nếu nhà trường yêu cầu tích hợp Chuyển giao công nghệ (CGCN) sang LLKH: Tham khảo kiến nghị tạo bảng `CGCN_ThanhVien` lưu `MaNhanVien` để tự link sang LLKH của đồng tác giả.

## 2. SUGGESTED SKILLS
- `session-bugflow`: Sử dụng khi bắt đầu kiểm tra hoặc debug các tính năng mới của module.
- `clean-stage-commit-push`: Sử dụng khi hoàn thành task để dọn dẹp và push git sạch sẽ.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `603fc10` — feat(lhu-qlnckh): chuan hoa giao dien va component cho giai-thuong-quan-ly va giai-thuong-quyet-dinh
  - `702da48` — feat(lhu-qlnckh): khoi phuc ly lich khoa hoc 3 tabs va tich hop sua chi tiet an pham
- **Working Tree Ownership:**
  - **Current task changes:**
    - `_db/qlnckh/spAPI_HDKH_LLKH_AnPham_ChiTiet_Save.sql` (Cập nhật Single Source of Truth cho AnPham và AnPham_TacGia)
    - `_db/qlnckh/spAPI_HDKH_LLKH_NCKH_Select.sql` (Bổ sung TenSachChuaChuong, DeTaiNgoai, NoiCapVanBang)
    - `_db/qlnckh/spAPI_HDKH_LLKH_DeTaiNgoai_Save.sql` (SP CRUD lưu đề tài ngoài trường tự khai)
    - `_db/qlnckh/spAPI_HDKH_LLKH_DeTaiNgoai_Del.sql` (SP xóa mềm đề tài ngoài trường tự khai)
    - `modules/hdkh-ly-lich-khoa-hoc/script.js` (Ma trận kiểm tra F/MAU, bổ sung sachTenChuong, dọn cảnh báo ảo)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-cong-trinh-khoa-hoc.vue` (Modal sửa thông tin bài báo, thêm TenSachChuaChuong, hiển thị bảng)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-de-tai-da-tham-gia.vue` (CRUD đề tài ngoài trường, ẩn nút sửa đề tài cấp trường)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-shtt.vue` (Làm sạch cảnh báo ảo SHTT)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-llkh-muc.vue` (Disabled nút action mặc định khi chưa có handler)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-so-yeu-ly-lich.vue` (Disabled nút Cập nhật, Lịch sử)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-qua-trinh-dao-tao.vue` (Disabled nút Thêm, Lịch sử)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-qua-trinh-cong-tac.vue` (Disabled nút Thêm công tác ngoài, Lịch sử)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-khen-thuong.vue` (Disabled nút Thêm, Lịch sử)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-gia-dinh.vue` (Disabled nút Thêm, Lịch sử)
    - `.handoff/HANDOFF.md` (Tài liệu bàn giao session)
  - **Pre-existing dirty / unrelated:**
    - Các file modules rename/delete từ các task trước (`modules/dev-*`, `modules/an-pham-*`, `modules/cgcn-*`, `modules/khen-thuong-*`).
- **Quick Inspect Commands:**
  - `git diff --stat modules/hdkh-ly-lich-khoa-hoc`
  - `fui file status`
  - `fui module validate -p lhu-qlnckh -m hdkh-ly-lich-khoa-hoc`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:**
  1. Mở rộng dữ liệu NCKH cho module Lý lịch khoa học (`hdkh-ly-lich-khoa-hoc`): hỗ trợ khai báo Tên sách chứa chương sách cho Chương sách quốc tế, cho phép tự khai Đề tài ngoài trường, chuẩn hóa nơi cấp văn bằng SHTT.
  2. Đồng bộ dữ liệu theo kiến trúc Single Source of Truth (không lưu bảng riêng gây phân mảnh dữ liệu).
  3. Vô hiệu hóa (disabled) toàn bộ các nút không có chức năng (thuộc nhóm HRM) để tránh gây hiểu lầm cho người dùng.
  4. Đánh giá tác động (Impact Analysis) trên 4 phân hệ hiện hữu: Ấn phẩm, SHTT, CGCN, HDKH.
- **Expected:** Giao diện hiển thị trực quan, các nút không có chức năng bị disabled; giảng viên có thể bổ sung đầy đủ dữ liệu phục vụ bản in Sau đại học và tự khai đề tài ngoài trường; không làm ảnh hưởng đến các phân hệ cũ.
- **Actual:** Đã hoàn thành 100%:
  - Đã chạy DDL thêm cột `TenSachChuaChuong` trên 2 bảng `AnPham` và `tblHDKH_LLKH_AnPham_ChiTiet`.
  - Đã deploy các SP: `spAPI_HDKH_LLKH_AnPham_ChiTiet_Save`, `spAPI_HDKH_LLKH_NCKH_Select`, `spAPI_HDKH_LLKH_DeTaiNgoai_Save`, `spAPI_HDKH_LLKH_DeTaiNgoai_Del`.
  - Đã đồng bộ và publish toàn bộ component của module `hdkh-ly-lich-khoa-hoc` lên live FUI server.
  - Đã test xác nhận thêm/sửa/xóa đề tài ngoài trường và bổ sung thông tin bài báo hoạt động chuẩn xác.
- **Flow Analysis:**
  - **Input:** Giảng viên đăng nhập, mở module `hdkh-ly-lich-khoa-hoc`, bấm nút chỉnh sửa bài báo hoặc bấm "Thêm đề tài ngoài trường".
  - **Process:**
    - Sửa bài báo: gọi `POST /HDKH_LLKH_AnPham_ChiTiet_Save` cập nhật đồng thời `AnPham` và `AnPham_TacGia`.
    - Đề tài ngoài trường: gọi `POST /HDKH_LLKH_DeTaiNgoai_Save` lưu vào `tblHDKH_Profile_DeTaiDaThamGia`.
    - Tải dữ liệu: gọi `POST /HDKH_LLKH_NCKH_Select` trả về 6 Result Sets tổng hợp đầy đủ.
  - **State:** CSDL MSSQL `qlnckh`, bảo toàn tính toàn vẹn và không ghi đè vai trò của các tác giả khác.
  - **Output:** Dữ liệu hiển thị trực quan trên giao diện và đưa vào cấu trúc định dạng bản in PDF (`docDefinition`).
  - **Side Effects:** Hoàn toàn không phá vỡ hợp đồng dữ liệu của phân hệ Ấn phẩm khen thưởng hay kê khai giờ HDKH.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Database Procedures:**
  - `_db/qlnckh/spAPI_HDKH_LLKH_AnPham_ChiTiet_Save.sql`: Cập nhật trực tiếp `AnPham` & `AnPham_TacGia` (WHERE `MaNhanVien = @sys_UserID`).
  - `_db/qlnckh/spAPI_HDKH_LLKH_NCKH_Select.sql`: Set 1 (Đề tài cơ sở, HĐ NCKH, Đề tài tự khai), Set 2 (Ấn phẩm), Set 4 (SHTT).
  - `_db/qlnckh/spAPI_HDKH_LLKH_DeTaiNgoai_Save.sql`: Lưu/sửa đề tài ngoài trường tự khai.
  - `_db/qlnckh/spAPI_HDKH_LLKH_DeTaiNgoai_Del.sql`: Xóa mềm đề tài ngoài trường tự khai.
- **Frontend Components:**
  - `modules/hdkh-ly-lich-khoa-hoc/script.js`: Cấu hình danh mục kiểm tra `F`, ma trận `MAU`, hàm `normalize`, định nghĩa bản in `docSDH`, `docGV`, `docSYLL`, `docLLKH`.
  - `modules/hdkh-ly-lich-khoa-hoc/components/uc-cong-trinh-khoa-hoc.vue`: Dialog bổ sung thông tin chi tiết ấn phẩm và hiển thị bảng.
  - `modules/hdkh-ly-lich-khoa-hoc/components/uc-de-tai-da-tham-gia.vue`: Dialog quản lý đề tài ngoài trường tự khai.
  - `modules/hdkh-ly-lich-khoa-hoc/components/uc-llkh-muc.vue`: Component wrapper hiển thị tiêu đề và actions (disabled mặc định).

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] `AnPham_TacGia` lưu `MaNhanVien`, tự động link bài báo sang LLKH của đồng tác giả khi họ đăng nhập (Evidence: `spAPI_HDKH_LLKH_NCKH_Select.sql:76`).
- [FACT] `ThiKHCN_ThanhVien` lưu `MaDinhDanh` (= `MaNhanVien`), tự động link SHTT sang LLKH của đồng tác giả (Evidence: `spAPI_HDKH_LLKH_NCKH_Select.sql:133`).
- [FACT] `ChuyenGiaoCongNghe` hiện chỉ lưu tên thành viên dạng chuỗi text gõ tay, chưa có mã nhân viên nên chưa thể tự link sang LLKH (Evidence: `spAPI_ChuyenGiaoCongNghe_Ins.sql` & `ChuyenGiaoCongNghe` schema).
- [FACT] Module `hdkh-ly-lich-khoa-hoc` không sử dụng dữ liệu từ phân hệ CGCN.

### Active Hypotheses
- None.

### Assumptions & Unknowns
- [ASSUMPTION] Nhà trường hiện tại chưa yêu cầu đưa hợp đồng Chuyển giao công nghệ vào 4 mẫu in lý lịch khoa học chuẩn.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **FUI Module Validation:**
  - `fui module validate -p lhu-qlnckh -m hdkh-ly-lich-khoa-hoc` -> **Result:** PASS (0 semantic errors).
- **FUI Component Sync & Publish:**
  - Đã cập nhật thành công 8 components (`uc-llkh-muc`, `uc-so-yeu-ly-lich`, `uc-qua-trinh-dao-tao`, `uc-qua-trinh-cong-tac`, `uc-khen-thuong`, `uc-gia-dinh`, `uc-cong-trinh-khoa-hoc`, `uc-de-tai-da-tham-gia`) và `script.js`.
- **Database Stored Procedures:**
  - `fui exec` và `fui sp deploy` chạy thành công không có lỗi runtime.

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- Không tạo bảng lưu trữ độc lập cho chi tiết ấn phẩm trong LLKH vì sẽ gây phân mảnh và mất tính Single Source of Truth với bảng `AnPham`.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:**
  - Cột `TenSachChuaChuong` phải luôn là `NULL` để không làm đứt gãy luồng nộp ấn phẩm khen thưởng cũ.
  - Phân hệ kê khai giờ HDKH (`tblHDKH_KeKhai_Submission`) lưu độc lập theo năm học phục vụ tính nghĩa vụ giờ, không được nhầm lẫn với dữ liệu hồ sơ khoa học trọn đời.
