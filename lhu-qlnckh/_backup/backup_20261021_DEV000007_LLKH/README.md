# BẢN SAO LƯU THAY ĐỔI CỦA DEV000007 (HUỲNH CAO TUẤN)
- **Thời gian sao lưu:** 2026-10-21T09:53:00+07:00
- **Thời gian tác giả thực hiện trên hệ thống:** 2026-10-21 từ 04:18:31 đến 05:34:09
- **Người thực hiện:** Huỳnh Cao Tuấn (`DEV000007`)
- **Mục đích thay đổi ban đầu:** Triển khai tính năng liên thông dữ liệu phục vụ phân hệ Lý lịch khoa học (LLKH) vào Ấn phẩm, Cuộc thi & SHTT, và tái cấu trúc Menu hệ thống.

---

## 1. Danh sách các file trong bản sao lưu

### A. Cấu hình dự án & Menu
- `project.json`: Menu hệ thống đã được tái cấu trúc (đưa nhóm Cá nhân lên đầu).
- `_projectInfo.json`: Metadata dự án tại thời điểm 04:18:31.

### B. Modules (3 modules)
1. `modules/hdkh-profile/`:
   - Giao diện Lý lịch khoa học.
   - Thêm ô nhập và lưu "Hướng nghiên cứu chính" (`spAPI_HDKH_LLKH_HuongNC_Save`).
   - Thiết kế lại modal xem/in PDF bố cục 2 cột (iframe + danh sách kiểm tra thiếu).
   - Cải tiến logic docDefinition in PDF trong `script.js`.
2. `modules/papers-reward/`:
   - Form khai báo ấn phẩm `uc-form-an-pham.vue`: Thêm tập/số/trang, tháng đăng, thể loại sách.
   - Bảng tác giả `uc-table-tac-gia.vue`: Thêm chọn vai trò tác giả, tác giả liên hệ.
3. `modules/___khen-thuong-khcn/`:
   - Form khen thưởng cuộc thi & SHTT `uc-form-an-pham.vue`: Thêm nơi cấp văn bằng SHTT.

### C. Stored Procedures (`_db/qlnckh/`)
1. **2 SP tạo mới:**
   - `spAPI_HDKH_LLKH_HuongNC_Save.sql`: Lưu hướng nghiên cứu cá nhân.
   - `spAPI_HDKH_LLKH_NCKH_Select.sql`: Tổng hợp dữ liệu NCKH cho LLKH.
2. **10 SP cập nhật:**
   - `spAPI_AnPham_Get_ByAnPhamID.sql`
   - `spAPI_AnPham_INS_Obj.sql`
   - `spAPI_AnPham_Udp_Obj.sql`
   - `spAPI_AnPhamTacGia_Get_ByAnPhamID.sql`
   - `spAPI_AnPhamTacGia_INS.sql`
   - `spAPI_AnPhamTacGia_Udp.sql`
   - `spAPI_ThiKHCN_Get_ByID.sql`
   - `spAPI_ThiKHCN_Get_ByNhanVienSubmit.sql`
   - `spAPI_ThiKHCN_INS_Obj.sql`
   - `spAPI_ThiKHCN_Udp_Obj.sql`
3. **Cấu trúc Schema:**
   - `schema.json`: Schema snapshot tại thời điểm 2026-10-21.

---

## 2. Hướng dẫn khôi phục lại bản backup này (nếu cần re-apply)
1. Copy các file `.sql` từ `_backup/backup_20261021_DEV000007_LLKH/_db/qlnckh/` về `_db/qlnckh/`.
2. Chạy `fui sp deploy <name> --db qlnckh` cho từng SP.
3. Copy các thư mục module về `modules/` và dùng `fui file push` hoặc `fui module preview` / `publish` để đẩy lên server.
4. Copy `project.json` về root và chạy `fui project publish-config`.
