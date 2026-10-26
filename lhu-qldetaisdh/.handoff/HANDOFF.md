# AGENT HANDOFF: lhu-qldetaisdh

- **Generated At:** 2026-10-26T10:47:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhu-qldetaisdh`
- **Status:** `done`
- **Next Session Focus:** Thử nghiệm bấm nút "Hủy hội đồng" trên học viên Nguyễn Hữu Thịnh (`925000005`) trên giao diện, kiểm tra khôi phục nếu cần (`_db/restore_student_925000005.sql`), hoặc xử lý xóa mềm 7 hội đồng bản sao cũ.

## 1. NEXT SESSION ACTION PLAN
1. Đăng nhập module `ths-hoi-dong`, tìm học viên `[925000005] Nguyễn Hữu Thịnh`, bấm "Xem & Cập nhật" -> bấm "Hủy hội đồng", nhập lý do hủy/hoãn để kiểm tra luồng soft-delete và reset bước 6.
2. Bấm nút "Lịch sử HĐ" trên dòng của học viên để kiểm tra card màu đỏ hiển thị lý do hủy, thông tin QĐ và danh sách 5 thành viên cũ.
3. Nếu muốn khôi phục lại trạng thái ban đầu của Thịnh: chạy `fui exec -f _db/restore_student_925000005.sql --confirm-write`.
4. (Tùy chọn) Xóa mềm 7 hội đồng bản sao cũ (`HoiDongID IN (2460, 2461, 2462, 2463, 2464, 2465, 2612)`).

## 2. SUGGESTED SKILLS
- `session-bugflow`: Tuân thủ quy trình 2 pha khi nhận bug/feature mới.
- `clean-stage-commit-push`: Đảm bảo git hygiene khi hoàn tất phiên làm việc.

## 3. GIT & COMMIT STATE
- **Branch:** `main` (tracking `origin/main`)
- **Relevant Recent Commits:**
  - `4fbf573` — feat(lhu-qlnckh): nang cap thanh vien cgcn bang rieng, them stm va xoa cgcn-quan-ly
  - `c601ec7` — feat(lhu-qlnckh): chuan hoa module cgcn va khen thuong, bo sung sp va cap nhat handoff
  - `bf48986` — feat(lhu-qldetaisdh): bo sung input ty le trung lap trong dialog tu choi buoc 5
- **Working Tree Ownership:**
  - **Current task changes:**
    - `modules/ths-hoi-dong/script.js`: Tích hợp dialog Lịch sử HĐ ở cột table, format điểm float, lọc thành viên active, 5 trạng thái HĐ.
    - `modules/ths-hoi-dong/style.css`: Thêm class viền màu cho card HĐ failed và inactive.
    - `modules/ths-hoi-dong/components/dialog-update-council.vue`: Bổ sung nút Hủy hội đồng, popup xác nhận, textarea lý do hủy.
    - `_db/qldetaisdh/spAPI_HoiDong_Cancel.sql`: SP hủy HĐ (soft-delete HoiDong & TVHD, reset Task 5 và 6).
    - `_db/qldetaisdh/spAPI_HoiDong_History_Get.sql`: SP lấy lịch sử các lần HĐ và thành viên.
    - `_db/qldetaisdh/spAPI_HoiDong_DeTai_Get.sql`: Tối ưu Parameter Sniffing WITH RECOMPILE, khử trùng lặp `#TMPSTU`.
    - `_db/backup_student_925000005.json`: File snapshot backup dữ liệu học viên 925000005.
    - `_db/restore_student_925000005.sql`: File SQL khôi phục dữ liệu học viên 925000005.
    - `.handoff/HANDOFF.md`: Cập nhật tài liệu bàn giao.
  - **Pre-existing dirty / unrelated:**
    - `_logs/tool-errors.jsonl` (log CLI hệ thống)
    - `_projectInfo.json`, `modules/_modules.json`, các `_moduleInfo.json` (metadata tự sinh khi đồng bộ)
- **Quick Inspect Commands:**
  - `git diff modules/ths-hoi-dong/`
  - `git diff _db/qldetaisdh/spAPI_HoiDong_DeTai_Get.sql`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:**
  1. Thêm chức năng hủy riêng hội đồng của một học viên khi đã có lịch bảo vệ (lưu vết soft-delete, lưu lý do hủy, reset bước 6).
  2. Bổ sung nút tra cứu lịch sử hội đồng tại cột Hội đồng trên bảng.
  3. Khắc phục triệt để lỗi chạy chậm ~16.8s của API `HoiDong_DeTai_Get`.
  4. Sửa lỗi sai số dấu phẩy động hiển thị điểm số (float precision `8.780000000000001`) và lặp thành viên trong lịch sử.
- **Expected:**
  - Bấm hủy hội đồng: Cập nhật `Is_Xoa = 1`, lưu `LyDoHuy`, reset bước 5 về `P` và bước 6 về `W`.
  - Trên bảng: Nút "Lịch sử HĐ" luôn sẵn sàng dưới nút thao tác chính, mở popup xem chi tiết các lần HĐ, lý do hủy, bảng thành viên kèm điểm chi tiết.
  - API `HoiDong_DeTai_Get` phản hồi dưới 1 giây.
- **Actual:** Đã hoàn thành, kiểm chứng thực tế và publish toàn bộ lên FUI server.
- **Flow Analysis:**
  - **Input:**
    - Hủy HĐ: `HoiDong_ID`, `Student_ID`, `LyDoHuy`.
    - Lấy lịch sử: `Student_ID`.
    - Danh sách đề tài: `NganhID`, `sys_SystemRight`, `BacDaoTao`.
  - **Process:**
    - `spAPI_HoiDong_Cancel`: `UPDATE HoiDong SET Is_Xoa = 1, LyDoHuy = ...`, `UPDATE HoiDongThanhVien SET Is_Xoa = 1`, cập nhật `Flow_Detail` Task 5 và 6.
    - `spAPI_HoiDong_History_Get`: `SELECT` từ `HoiDong` (kể cả `Is_Xoa = 1`) và `HoiDongThanhVien`.
    - `spAPI_HoiDong_DeTai_Get`: `WITH RECOMPILE` triệt tiêu Parameter Sniffing, lọc `Is_Xoa = 0 OR Is_Xoa IS NULL`.
  - **State:** `HoiDong.Is_Xoa = 1`, `HoiDong.LyDoHuy`, `Flow_Detail.Flow_Detail_Status = 'W'`.
  - **Output:** Dữ liệu chuẩn, phản hồi < 1s, hiển thị phân loại 5 trạng thái với màu sắc trực quan.
  - **Side Effects:** Giữ nguyên 100% schema output và API contracts.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Code Locations:**
  - `_db/qldetaisdh/spAPI_HoiDong_Cancel.sql` — Stored Procedure xử lý hủy và reset tiến trình.
  - `_db/qldetaisdh/spAPI_HoiDong_History_Get.sql` — Stored Procedure lấy dữ liệu lịch sử hội đồng.
  - `_db/qldetaisdh/spAPI_HoiDong_DeTai_Get.sql` — Stored Procedure lấy danh sách hội đồng đề tài (đã tối ưu `WITH RECOMPILE`).
  - `modules/ths-hoi-dong/components/dialog-update-council.vue` — Dialog cập nhật kèm nút hủy HĐ và popup xác nhận.
  - `modules/ths-hoi-dong/script.js` — Template cột Hội đồng, dialog xem lịch sử, hàm `getHoiDongStatus`, `formatScore`, `getHistoryMembers`.
  - `modules/ths-hoi-dong/style.css` — Định dạng viền màu cho từng loại thẻ hội đồng trong lịch sử.
  - `_db/restore_student_925000005.sql` — Script khôi phục dữ liệu học viên Nguyễn Hữu Thịnh khi cần.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] Đã chạy DDL bổ sung cột `LyDoHuy NVARCHAR(500) NULL` vào cả `HoiDong` và `HoiDong_Old` trên database `qldetaisdh`.
- [FACT] `spAPI_HoiDong_DeTai_Get` giảm thời gian thực thi từ **16.813 ms (~16,8 giây)** xuống còn **656 ms (~0,65 giây)** sau khi thêm `WITH RECOMPILE`.
- [FACT] Có 61 hội đồng trong DB có điểm trung bình dạng float precision dài ngoặc (`8.780000000000001`, `7.666666666666667`...), đã được giải quyết bằng `formatScore`.
- [FACT] Có 151 hội đồng từng cập nhật thành viên tạo ra bản ghi cũ `Is_Xoa = 1`, đã được lọc sạch qua `getHistoryMembers`.
- [FACT] Có 7 học viên bị bấm tạo 2 hội đồng trùng cách nhau 13-22s (`HoiDong_Status = 0`), hiện hiển thị nhãn xám "Chưa kích hoạt / Bản sao".

### Assumptions & Unknowns
- [ASSUMPTION] 7 hội đồng bản sao cũ tạm thời giữ nguyên trong database để lưu vết lịch sử; người dùng có thể yêu cầu xóa mềm khi cần.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `EXEC spAPI_HoiDong_DeTai_Get 0, 9, 'THS'` → **Result:** PASS (656 ms).
  - `EXEC spAPI_HoiDong_DeTai_Get 102, 9, 'THS'` → **Result:** PASS (839 ms).
  - `EXEC spAPI_HoiDong_History_Get '925000005', 'test', 9` → **Result:** PASS (15 ms).
  - `fui file status` → **Result:** `0 unpublished file(s)`.

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- **Attempt 1:** Đặt nút "Lịch sử HĐ" bên trong `dialog-update-council.vue`.
  - *Result:* Sau khi hủy hội đồng, học viên không còn `HoiDongID` hiệu lực nên table chỉ hiện nút "Lập Hội Đồng", mất lối vào dialog cập nhật để xem lịch sử.
  - *Conclusion:* Chuyển nút "Lịch sử HĐ" ra trực tiếp cột Hội đồng trên table để truy cập được ở mọi trạng thái.
- **Attempt 2:** Dùng `@LyDoHuy NVARCHAR(500) = NULL` trong stored procedure.
  - *Result:* Bị guard của `tAPI` chặn deploy (tAPI không hỗ trợ default parameter).
  - *Conclusion:* Bỏ `= NULL`, khai báo `@LyDoHuy NVARCHAR(500)`.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên toàn bộ schema trả về và input params của các API SP.
- **Side Effects / Tradeoffs:** Thêm `WITH RECOMPILE` tốn khoảng 10-20ms biên dịch lại plan, nhưng đổi lại giảm 16 giây nghẽn execution plan.
