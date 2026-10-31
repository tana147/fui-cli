# AGENT HANDOFF: lhu-qldetaisdh

- **Generated At:** 2026-10-31T15:16:30+07:00
- **Workspace Root:** `D:\CODE\IOTSOFT\fui-cli\lhu-qldetaisdh`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục kiểm tra các module quy trình sau đại học hoặc hỗ trợ người dùng vận hành các đợt lập hội đồng bảo vệ luận văn tiếp theo.

## 1. NEXT SESSION ACTION PLAN
1. Sẵn sàng nhận phản hồi từ người dùng thực tế sau khi họ nạp file Excel danh sách đợt bảo vệ.
2. Nếu có học viên mới cần cấp hoặc điều chỉnh Số QĐ / Ngày QĐ, kiểm tra trực tiếp qua SP `spAPI_HoiDong_DeTai_Get`.
3. Kiểm tra tính toàn vẹn của các quyết định tại module `ths-quan-ly-quyet-dinh` nếu người dùng yêu cầu in quyết định hàng loạt.

## 2. SUGGESTED SKILLS
- `session-bugflow`: Sử dụng khi bắt đầu debug hoặc nhận diện bug mới phát sinh trong quy trình hội đồng.
- `clean-stage-commit-push`: Sử dụng khi kết thúc phiên làm việc để giữ git sạch sẽ.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `38fd417` — feat(lhbs-esign): upgrade kpi-ops-dashboard to True Visual Chart Cockpit (Option A) and dynamic 3-tier SP
  - `33dd5e0` — feat: dong bo toan bo 505 module va 1491 stored procedures trong workspace
  - `c28d9f5` — refactor(lhu-qldetaisdh): chuan hoa dat ten module kebab-case va dong bo menu
- **Working Tree Ownership:**
  - **Current task changes:**
    - `modules/ths-hoi-dong/components/dialog-add-council-by-excel.vue`: Sửa guard chặn ghi đè Số QĐ rỗng/placeholder `/QĐ-ĐHLH`, tự động dò dòng Header và cột dữ liệu linh hoạt, loại bỏ Moment.js loose mode gây đơ browser, pre-calculate trạng thái render.
    - `modules/ths-hoi-dong/components/dialog-give-sqd.vue`: Xóa placeholder ngày tháng có dấu chấm `' .'`, `' .'`, `' 20.'` khi mở modal và trước khi lưu lên DB.
    - `modules/ths-hoi-dong/components/_components.json`: Đồng bộ cấu trúc component sau khi patch.
  - **Pre-existing dirty / unrelated:**
    - `../_logs/tool-errors.jsonl` (File log ở thư mục cha `fui-cli`, không stage).
- **Quick Inspect Commands:**
  - `git diff modules/ths-hoi-dong/components/dialog-add-council-by-excel.vue`
  - `git diff modules/ths-hoi-dong/components/dialog-give-sqd.vue`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Sửa lỗi lập hội đồng bằng file Excel bị mất Số QĐ và Ngày QĐ của học viên, sửa lỗi trình duyệt bị đơ/crash khi upload file Excel, và reset toàn bộ dữ liệu test của học viên Nguyễn Duy Hiền (922000094).
- **Expected:** Khi nạp Excel có Số QĐ và Ngày QĐ, hệ thống cập nhật đúng vào bảng `Decision` và `HoiDong`, hiển thị tức thì không đơ trình duyệt; học viên sau khi test được trả về trạng thái sạch sẽ.
- **Actual (Trước khi sửa):** 
  - Số QĐ bị SP trả về placeholder `            /QĐ-ĐHLH` khiến guard logic hiểu nhầm là đã có Số QĐ và bỏ qua lệnh `onUpdateSQD`.
  - Code cũ hardcode `jsonData.splice(0, 7)` và `jsonHeader.splice(0, 6)`, khi file ít hơn 7 dòng gây crash `Cannot read properties of undefined (reading 'length')`.
  - Template gọi hàm `getStudentStatus` trong v-chip làm re-render loop và nghẽn luồng chính.
- **Flow Analysis:**
  - **Input:** File Excel (`.xlsx`, `.xls`) chứa danh sách hội đồng kèm cột Số QĐ và Ngày QĐ.
  - **Process:** FileReader đọc ArrayBuffer -> `XLSX.read` -> tự động dò tìm dòng Header chứa `MSHV` / `STT` -> tự động ánh xạ cột -> pre-calculate trạng thái -> `onAddHDSQD` -> `insHoiDongApi` -> `onGetDeTai` -> `onUpdateSQD` (`/HoiDong_Upd_SoQD`).
  - **State:** Bảng `HoiDong` (Is_Xoa = 0), `HoiDongThanhVien`, `Decision` (`Decision_SoQD`, `Decision_NgayQD`, `Decision_ThangQD`, `Decision_NamQD`).
  - **Output:** Hội đồng được lập kèm Số QĐ và Ngày QĐ hiển thị trên bảng.
  - **Side Effects:** Đã xóa sạch toàn bộ 2 hội đồng cũ test (2715, 2716), 10 thành viên hội đồng, và 2 quyết định (4402, 4403) của học viên 922000094 khỏi database.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Code Locations:**
  - `modules/ths-hoi-dong/components/dialog-add-council-by-excel.vue:209-234` (`parseExcelDate`) — Regex parser ngày tháng thuần, không dùng Moment đa format.
  - `modules/ths-hoi-dong/components/dialog-add-council-by-excel.vue:415-445` (`onAddHDSQD`) — Guard nhận diện placeholder `/QĐ-ĐHLH` và split ngày/tháng với `padStart(2, '0')`.
  - `modules/ths-hoi-dong/components/dialog-add-council-by-excel.vue:580-685` (`loadExcelGVInfo`) — Tự động nhận diện header và map cột linh hoạt.
  - `modules/ths-hoi-dong/components/dialog-give-sqd.vue:350-370` — Xóa placeholder dấu chấm của ngày tháng trước khi mở modal và khi lưu.
  - `_db/qldetaisdh/spAPI_HoiDong_Get_ByHoiDongID.sql:39` — SP trả về placeholder `N'            /QĐ-ĐHLH'`.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] `Decision_SoQD` mặc định trong SP `spAPI_HoiDong_Get_ByHoiDongID` trả về `N'            /QĐ-ĐHLH'` thay vì chuỗi rỗng.
- [FACT] Code cũ `dialog-add-council-by-excel.vue` kiểm tra `currentDetail.Decision_SoQD.trim() !== ''` nên bị match chuỗi placeholder và bỏ qua hoàn toàn cập nhật Số QĐ.
- [FACT] Đã deploy component mới lên server FUI thành công (ComID 11435 và ComID 11453).
- [FACT] Người dùng đã nạp file thành công, sinh ra `HoiDongID = 2716` và `Decision_ID = 4403` có đầy đủ Số QĐ `2154/QĐ-ĐHLH` và Ngày QĐ `31/10/2026`.
- [FACT] Toàn bộ dữ liệu hội đồng của học viên 922000094 đã được dọn sạch khỏi DB (HoiDong, HoiDongThanhVien, Decision), trả về trạng thái ban đầu.

### Active Hypotheses
- Không còn active hypothesis nào.

### Assumptions & Unknowns
- [ASSUMPTION] Người dùng thực tế sẽ sử dụng file Excel theo mẫu đợt bảo vệ của trường hoặc file tự chuẩn bị bắt đầu từ dòng 1/dòng 7; cả 2 trường hợp hiện đều được hỗ trợ tự động.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - Test nạp Excel mô phỏng cả 2 trường hợp (có 6 dòng header và bắt đầu từ dòng 1): **Result:** PASS | **Proves:** Parser tự dò header hoạt động chính xác cả 2 case.
  - Test gọi `spAPI_HoiDong_History_Get` cho học viên 922000094: **Result:** PASS (0 row) | **Proves:** Popup Lịch sử hội đồng đã sạch 100%.
- **Critical Error / Log Resolved:**
```text
4ABE8.js:2258 jsonHeader Array(0)
4ABE8.js:2521 Error loading Excel file: TypeError: Cannot read properties of undefined (reading 'length')
    at reader.onload (4ABE8.js:2278:80)
```

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- **Attempt 1:** Dùng SheetJS nodejs tạo file test OpenXML `.xlsx` tự động.
  - *Result:* Microsoft Excel trên Windows báo popup "We found a problem with some content...".
  - *Conclusion:* Không nên sinh file `.xlsx` tự động bằng SheetJS CLI nếu máy người dùng có Excel bảo mật nghiêm ngặt. Thay vào đó dùng định dạng nhị phân `.xls` hoặc để người dùng tự tạo file từ Microsoft Excel.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên contract API `/HoiDong_Upd_SoQD`, `/HoiDong_Ins`, `/HoiDong_History_Get` và các props của component `dialog-add-council-by-excel`.
- **Side Effects / Tradeoffs:** Không có side effect tiêu cực; hiệu năng render tăng lên đáng kể do pre-calculate trạng thái học viên.
