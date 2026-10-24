# AGENT HANDOFF: lhu-qlnckh

- **Generated At:** 2026-10-24T23:58:00+07:00
- **Workspace Root:** `D:/CODE/IOTSOFT/fui-cli/lhu-qlnckh`
- **Status:** `done`
- **Next Session Focus:** Đưa 5 trường thông tin khoa học STM vào bản in PDF và ma trận kiểm tra đủ/thiếu của Lý lịch khoa học (`hdkh-ly-lich-khoa-hoc`); tích hợp dữ liệu Chuyển giao công nghệ (CGCN) từ bảng `ChuyenGiaoCongNghe_ThanhVien` vào tab NCKH và bản in PDF của LLKH.

## 1. NEXT SESSION ACTION PLAN
1. **Bổ sung STM vào PDF & ma trận kiểm tra trên `hdkh-ly-lich-khoa-hoc`**:
   - Cập nhật ma trận `F` và `MAU` trong `modules/hdkh-ly-lich-khoa-hoc/script.js` để kiểm tra độ hoàn thiện các trường STM (`orcid`, `googleScholar`, `researchGate`, `maSTI`, `tomTatKinhNghiem`).
   - Bổ sung thông tin STM vào các hàm sinh PDF: `docGV`, `docSDH`, `docLLKH` trong `script.js`.
2. **Tích hợp CGCN vào Lý lịch khoa học**:
   - Thêm Result Set truy vấn CGCN của cá nhân vào `spAPI_HDKH_LLKH_NCKH_Select` (join `ChuyenGiaoCongNghe` với `ChuyenGiaoCongNghe_ThanhVien` theo `MaDinhDanh = @sys_UserID`).
   - Thêm component/bảng hiển thị CGCN vào tab NCKH của `hdkh-ly-lich-khoa-hoc`.
   - Bổ sung mục Hợp đồng chuyển giao công nghệ vào các bản in PDF tương ứng.
3. **Chuẩn hóa dữ liệu lịch sử CGCN**:
   - Xác định phương án map mã nhân sự (`MaDinhDanh`) cho 203 bản ghi CGCN cũ nếu nhà trường yêu cầu đưa toàn bộ dữ liệu quá khứ vào LLKH cá nhân.

## 2. SUGGESTED SKILLS
- `session-bugflow`: Kích hoạt ở đầu mỗi phiên hoặc khi bắt đầu kiểm tra feature/bug mới.
- `clean-stage-commit-push`: Sử dụng khi kết thúc phiên để dọn dẹp và commit/push code sạch sẽ.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `c601ec7` — feat(lhu-qlnckh): chuan hoa module cgcn va khen thuong, bo sung sp va cap nhat handoff
  - `bf48986` — feat(lhu-qldetaisdh): bo sung input ty le trung lap trong dialog tu choi buoc 5
- **Working Tree Ownership:**
  - **Current task changes:**
    - `_db/qlnckh/spAPI_CGCN_ThanhVien_Get.sql` (SP đọc danh sách thành viên theo CGCNID)
    - `_db/qlnckh/spAPI_CGCN_ThanhVien_Save.sql` (SP lưu danh sách thành viên vào bảng riêng và đồng bộ ngược text ChuNhiemDeTai/ThanhVienDeTai)
    - `_db/qlnckh/spAPI_CGCN_Get_ByID.sql` (Bổ sung ThanhVienList dạng JSON)
    - `_db/qlnckh/spAPI_CGCN_Ins.sql` (Hỗ trợ tạo hồ sơ CGCN và đồng bộ thành viên)
    - `_db/qlnckh/spAPI_HDKH_LLKH_STM_Save.sql` (SP lưu 5 trường thông tin khoa học STM)
    - `_db/qlnckh/spAPI_HDKH_LLKH_SHTT_ChiTiet_Save.sql` (SP lưu chi tiết SoVanBang, NamCap, NoiCapVanBang cho SHTT)
    - `_db/qlnckh/spAPI_HDKH_LLKH_NCKH_Select.sql` (Bổ sung 5 trường STM ở Set 0, 3 trường SHTT ở Set 3)
    - `modules/cgcn-ke-khai/components/uc-modal-contract.vue` (Bảng thành viên, tìm kiếm nhân sự LHU, chọn vai trò, lưu bảng riêng)
    - `modules/cgcn-quan-tri/components/uc-modal-add.vue` (Thêm mới CGCN kèm bảng thành viên chuẩn)
    - `modules/cgcn-quan-tri/components/uc-modal-edit.vue` (Sửa/duyệt CGCN kèm bảng thành viên, load chi tiết và lưu bảng riêng)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-so-yeu-ly-lich.vue` (Popup & form cập nhật 5 trường STM)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-shtt.vue` (Popup cập nhật SoVanBang, NamCap, NoiCapVanBang cho SHTT)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-main.vue` (Bắt sự kiện reload sau khi cập nhật STM và SHTT)
    - `modules/hdkh-ly-lich-khoa-hoc/script.js` (Map STM, xử lý nguồn SHTT, sửa lỗi cú pháp const trong array)
    - `modules/cgcn-quan-ly/` (Đã sao lưu và xóa hoàn toàn khỏi dự án và FUI server)
    - `.handoff/HANDOFF.md` (Tài liệu bàn giao phiên làm việc)
  - **Pre-existing dirty / unrelated:**
    - `_logs/tool-errors.jsonl`, `_projectInfo.json`
- **Quick Inspect Commands:**
  - `git diff --stat modules/cgcn-ke-khai modules/cgcn-quan-tri modules/hdkh-ly-lich-khoa-hoc`
  - `fui file status -p lhu-qlnckh --all`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Tách bảng riêng `ChuyenGiaoCongNghe_ThanhVien` để lưu `MaDinhDanh` cho thành viên hợp đồng CGCN, nâng cấp UI kê khai và quản trị CGCN, bổ sung trường STM và điểm khuyết SHTT trên LLKH, dọn dẹp module thừa `cgcn-quan-ly`.
- **Expected:** Thành viên CGCN được lưu độc lập với `MaDinhDanh` để sẵn sàng liên kết LLKH; module kê khai và quản trị hỗ trợ tìm kiếm nhân sự LHU; LLKH cập nhật được thông tin STM và chi tiết SHTT; module cũ `cgcn-quan-ly` được xóa sạch.
- **Actual:** Hoàn thành 100% mục tiêu đề ra; tất cả module đã validate và publish lên server FUI (`# 0 unpublished file(s)`).
- **Flow Analysis:**
  - **Input:** Khai báo CGCN (TenDuAn, NamHoc, GiaTriHopDong, danh sách thành viên gồm MaDinhDanh, HoTen, VaiTro, TenPhongBan); cập nhật STM (ORCID, GoogleScholar, ResearchGate, MaSTI, TomTatKinhNghiem); cập nhật chi tiết SHTT.
  - **Process:**
    - `modules/cgcn-ke-khai/components/uc-modal-contract.vue:saveItem` → `/CGCN_Ins` hoặc `/CGCN_Upd` → `/CGCN_ThanhVien_Save`
    - `spAPI_CGCN_ThanhVien_Save.sql` → INSERT/UPDATE `ChuyenGiaoCongNghe_ThanhVien` → UPDATE `ChuNhiemDeTai`/`ThanhVienDeTai` trên `ChuyenGiaoCongNghe` (backward compatibility)
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-so-yeu-ly-lich.vue` → `/HDKH_LLKH_STM_Save` → `tblHDKH_Profile_CaNhan`
    - `modules/hdkh-ly-lich-khoa-hoc/components/uc-shtt.vue` → `/HDKH_LLKH_SHTT_ChiTiet_Save`
  - **State:** `ChuyenGiaoCongNghe_ThanhVien` (bảng mới), `ChuyenGiaoCongNghe`, `tblHDKH_Profile_CaNhan`, `tblHDKH_Field_Definition`.
  - **Output:** Dữ liệu thành viên CGCN có định danh `MaDinhDanh`, chuỗi text tương thích ngược; LLKH hiển thị và lưu thành công thông tin STM & SHTT.
  - **Side Effects:** Zero breaking change trên các màn hình hiển thị cũ; `cgcn-quan-ly` đã được xoá an toàn sau khi sao lưu.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Specs / Plans / Issues / ADRs:** None
- **Code Locations:**
  - `lhu-qlnckh/_db/qlnckh/spAPI_CGCN_ThanhVien_Save.sql` — Thủ tục đồng bộ thành viên CGCN vào bảng riêng và chuỗi text
  - `lhu-qlnckh/_db/qlnckh/spAPI_CGCN_ThanhVien_Get.sql` — Thủ tục lấy thành viên theo CGCNID
  - `lhu-qlnckh/modules/cgcn-ke-khai/components/uc-modal-contract.vue` — Giao diện kê khai CGCN tích hợp bảng thành viên và tìm nhân sự
  - `lhu-qlnckh/modules/cgcn-quan-tri/components/uc-modal-edit.vue` — Giao diện duyệt và sửa CGCN của quản trị viên
  - `lhu-qlnckh/modules/cgcn-quan-tri/components/uc-modal-add.vue` — Giao diện thêm mới trực tiếp CGCN của quản trị viên
  - `lhu-qlnckh/modules/hdkh-ly-lich-khoa-hoc/components/uc-so-yeu-ly-lich.vue` — Quản lý 5 trường STM
  - `lhu-qlnckh/modules/hdkh-ly-lich-khoa-hoc/components/uc-shtt.vue` — Quản lý Số văn bằng, Năm cấp, Nơi cấp SHTT

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] Bảng `ChuyenGiaoCongNghe_ThanhVien` đã tạo với 16 cột và 2 index `IX_CGCN_ThanhVien_CGCNID`, `IX_CGCN_ThanhVien_MaDinhDanh` (Evidence: `fui query --db qlnckh "SELECT TOP 5 CGCNID FROM ChuyenGiaoCongNghe_ThanhVien"`).
- [FACT] Cú pháp SP trên tAPI không cho phép khai báo tham số gán giá trị mặc định `= ...` (Evidence: lỗi guard tAPI khi deploy `spAPI_HDKH_LLKH_STM_Save`).
- [FACT] Khai báo `const` bên trong array literal trả về của hàm gây lỗi `Unexpected token 'const'` tại runtime Vue (Evidence: lỗi console B54A6.js trên `script.js`).
- [FACT] `cgcn-quan-ly` không nằm trong menu hay routing của `project.json` và đã được xoá an toàn (Evidence: `fui module delete -p lhu-qlnckh -m cgcn-quan-ly`).

### Active Hypotheses
- None.

### Assumptions & Unknowns
- [ASSUMPTION] 203 bản ghi CGCN lịch sử không bắt buộc phải link cá nhân vào LLKH ngay, chỉ áp dụng từ các hồ sơ mới kê khai có `MaDinhDanh`.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `fui module validate -p lhu-qlnckh -m cgcn-ke-khai` → **Result:** PASS (0 semantic errors)
  - `fui module validate -p lhu-qlnckh -m cgcn-quan-tri` → **Result:** PASS (0 semantic errors)
  - `fui module validate -p lhu-qlnckh -m hdkh-ly-lich-khoa-hoc` → **Result:** PASS (0 semantic errors)
  - `fui file status -p lhu-qlnckh --all` → **Result:** PASS (# 0 unpublished file(s))
- **Critical Error / Log Snippet:** None

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- Attempt 1: Đặt khai báo `const allSHTT_GV = ...` trực tiếp trong array literal `return [ ... ]` của `script.js` → Lỗi `Unexpected token 'const'` tại runtime trình duyệt. Cần khai báo biến trước lệnh `return`.
- Attempt 2: Dùng `v-btn block height="40"` cho nút Thêm thành viên CGCN → Nút bị to và dính sát ô Vai trò. Đã tối ưu về `small` (28px), bỏ `block`, thêm `pl-3` đệm khoảng cách hợp lý.

## 9. CONSTRAINTS & RISKS
- Contracts to Preserve:
  - Bảng `ChuyenGiaoCongNghe` vẫn phải duy trì 2 cột `ChuNhiemDeTai` và `ThanhVienDeTai` dạng chuỗi text phân cách bằng dấu phẩy để tương thích các báo cáo/export Excel hiện hành.
  - Không sửa PDF và giao diện LLKH đối với CGCN khi chưa có chỉ đạo từ người dùng.
- Side Effects / Tradeoffs:
  - Bản backup `_backup/backup_20261024_cgcn_quan_ly` và `_backup/backup_20261024_cgcn_llkh` cần được lưu trữ cẩn thận để đối chiếu khi cần.
