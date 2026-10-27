# AGENT HANDOFF: lhu-qlnckh

- **Generated At:** 2026-10-27T09:31:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhu-qlnckh`
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
  - `b5e2152` — feat(lhu-qldetaisdh): tich hop huy hoi dong, tra cuu lich su va toi uu api hoi dong
  - `4fbf573` — feat(lhu-qlnckh): nang cap thanh vien cgcn bang rieng, them stm va xoa cgcn-quan-ly
  - `c601ec7` — feat(lhu-qlnckh): chuan hoa module cgcn va khen thuong, bo sung sp va cap nhat handoff
- **Working Tree Ownership:**
  - **Current task changes:**
    - `modules/an-pham-khen-thuong/components/uc-table-tac-gia.vue` (Sửa lỗi đảo ngược Họ và Tên tác giả khi tìm kiếm/nhập mã nhân viên LHU)
    - `_db/qlnckh/schema.json` (Đồng bộ schema và store procedures mới nhất từ database `qlnckh`)
    - `modules/_modules.json` (Làm mới danh sách 31 module từ server FUI)
    - `modules/*/_moduleInfo.json` (Làm mới metadata cache các module sau khi sync)
    - `.handoff/HANDOFF.md` (Tài liệu bàn giao phiên làm việc)
  - **Pre-existing dirty / unrelated:**
    - `../_logs/tool-errors.jsonl`
- **Quick Inspect Commands:**
  - `git diff modules/an-pham-khen-thuong/components/uc-table-tac-gia.vue`
  - `fui file status -p lhu-qlnckh -m an-pham-khen-thuong`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Sửa lỗi hiển thị và lưu đảo ngược Họ và Tên tác giả trong dialog Thêm mới tác giả của module `an-pham-khen-thuong`; đồng bộ schema/SP và danh sách module từ hệ thống.
- **Expected:** Khi tìm kiếm hoặc nhập mã nhân viên, ô "Họ tác giả" nhận đúng Họ và tên đệm (VD: `Trương Lê`), ô "Tên tác giả" nhận đúng Tên chính (VD: `Hoàng`); bảng danh sách tác giả render `{{ item.HoTacGia }} {{ item.TenTacGia }}` đúng thứ tự tự nhiên `Trương Lê Hoàng`.
- **Actual:** Hoàn thành 100%; module `an-pham-khen-thuong` đã validate và publish lên server FUI (`# 0 unpublished file(s)`).
- **Flow Analysis:**
  - **Input:** Chọn nhân viên từ autocomplete `v-autocomplete` (`this.model` từ `/TaiKhoan_Seach`) hoặc nhập mã nhân viên vào textfield `MaNhanVien` (`blurMaNhanVien`).
  - **Process:**
    - `changeNhanVien()`: Gán trực tiếp `HoNV` vào `HoTacGia` và `TenNV` vào `TenTacGia` từ `this.model`, đồng thời điền email, phòng ban, thông tin ngân hàng.
    - `NhanVien_Get(UserID)`: Gán đúng `data[0].FirstName` vào `HoTacGia` và `data[0].LastName` vào `TenTacGia` khi nhận phản hồi từ `https://tapi.lhu.edu.vn/acc/UserInfo_ByID`.
  - **State:** `this.editedItem` trong component `uc-table-tac-gia.vue`.
  - **Output:** Giao diện dialog hiển thị đúng Họ và Tên ở hai ô input riêng biệt; bảng tác giả hiển thị đúng thứ tự; `spAPI_AnPhamTacGia_INS` / `spAPI_AnPhamTacGia_Udp` lưu đúng hai cột `HoTacGia` và `TenTacGia` vào bảng `AnPham_TacGia`.
  - **Side Effects:** Zero breaking change, giữ nguyên API và schema.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Specs / Plans / Issues / ADRs:** None
- **Code Locations:**
  - `modules/an-pham-khen-thuong/components/uc-table-tac-gia.vue:502-553` — Hàm `changeNhanVien`, `TaiKhoanNH_Get`, `NhanVien_Get`
  - `_db/qlnckh/spAPI_TaiKhoan_Seach.sql` — SP tìm kiếm nhân viên kèm tài khoản, trả về `HoNV`, `TenNV`, `HoTen`

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] API `https://tapi.lhu.edu.vn/acc/UserInfo_ByID?UserID=${UserID}` trả về `FirstName` là phần họ/chữ lót và `LastName` là từ tên chính cuối cùng (Evidence: so sánh đối chiếu với dữ liệu `TaiKhoan` và `NhanVien` trong database `qlnckh`).
- [FACT] `spAPI_TaiKhoan_Seach` trả về đối tượng có sẵn các trường `HoNV`, `TenNV`, `HoTen`, `Email`, `TenPhongBan`, `SoTaiKhoan`, `NganHang`, `TenChuTaiKhoan` (Evidence: `_db/qlnckh/spAPI_TaiKhoan_Seach.sql`).
- [FACT] Module `an-pham-khen-thuong` đã publish thành công lên server FUI (Evidence: `fui file status -p lhu-qlnckh -m an-pham-khen-thuong` ra `# 0 unpublished file(s)`).

### Active Hypotheses
- None.

### Assumptions & Unknowns
- [ASSUMPTION] Các bản ghi tác giả cũ đã lưu ngược trước đây trong bảng `AnPham_TacGia` trên môi trường production có thể chạy script UPDATE hoán đổi nếu nhà trường yêu cầu chuẩn hóa toàn diện dữ liệu lịch sử.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `fui module validate -p lhu-qlnckh -m an-pham-khen-thuong` → **Result:** PASS (0 semantic errors)
  - `fui file status -p lhu-qlnckh -m an-pham-khen-thuong` → **Result:** PASS (# 0 unpublished file(s))
- **Critical Error / Log Snippet:** None

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- Không có.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên contract gọi `spAPI_AnPhamTacGia_INS` và `spAPI_AnPhamTacGia_Udp` với cấu trúc `AuthorsObjArr` chứa `HoTacGia` và `TenTacGia`.
- **Side Effects / Tradeoffs:** Không có.
