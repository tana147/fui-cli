# AGENT HANDOFF: lhu-qldetaisdh

- **Generated At:** 2026-10-22T11:12:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhu-qldetaisdh`
- **Status:** `done`
- **Next Session Focus:** Kiểm tra vận hành thực tế quy trình kiểm tra đạo văn và duyệt/từ chối Bước 5 trên môi trường live giữa chuyên viên SDH và học viên thực tế; mở rộng hoặc kiểm tra các bước tiếp theo nếu có yêu cầu.

## 1. NEXT SESSION ACTION PLAN
1. Theo dõi chuyên viên SDH thao tác thực tế tại module `ths-duyet-tien-do` ở Bước 5: tải file luận văn (PDF/WORD) về kiểm tra đạo văn, upload file kết quả kiểm tra đạo văn và thực hiện duyệt hoặc từ chối.
2. Kiểm tra tài khoản học viên thực tế tại `ths-luan-van-cua-toi`: khi bị từ chối nhận thông báo màu đỏ kèm lý do, xem được lịch sử các lần nộp trước, và chỉ cần nộp lại file PDF/WORD mới.
3. Khi học viên nộp lại, xác nhận phía SDH thấy mục kết quả kiểm tra đạo văn đã tự động reset về trống và sẵn sàng upload file kiểm tra của phiên mới.

## 2. SUGGESTED SKILLS
- `code-review-pragmatic`: Khi cần kiểm tra lại logic nghiệp vụ hoặc các component sau triển khai.
- `change-set-review`: Khi cần review git diff trước khi merge hoặc triển khai tiếp.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `9ae0cec` — feat(lhu-qlnckh): mo rong du lieu nckh va toi uu ly lich khoa hoc
  - `c28d9f5` — refactor(lhu-qldetaisdh): chuan hoa dat ten module kebab-case va dong bo menu
- **Working Tree Ownership:**
  - **Current task changes:**
    - `lhu-qldetaisdh/_db/qldetaisdh/spAPI_SDH_Reject_Defend_Thesis.sql`: Stored procedure xử lý từ chối Bước 5, snapshot vào `Flow_Detail_His`, reset file 5.6/5.7, validate bắt buộc file check đạo văn.
    - `lhu-qldetaisdh/_db/qldetaisdh/spAPI_FlowDetail_UpdateMulti.sql`: Tự động reset file kiểm tra đạo văn khi học viên nộp lại luận văn mới; chặn học viên ghi đè trường của SDH.
    - `lhu-qldetaisdh/_db/qldetaisdh/spAPI_Get_RootFlow.sql`: Bỏ ánh xạ hardcode `GV0000611 -> 924000233`.
    - `lhu-qldetaisdh/_db/qldetaisdh/spAPI_SDH_Get_FlowDetail_His.sql`: Lấy danh sách lịch sử nộp kèm `LyDo` và `NgayTaoLichSu`.
    - `lhu-qldetaisdh/modules/ths-duyet-tien-do/components/uc-detail-flow.vue`: Nút Từ chối và Lịch sử nộp chỉ hiện ở Bước 5; dialog từ chối kèm validate bắt buộc upload file đạo văn; dialog lịch sử nộp; chip trạng thái 'R'.
    - `lhu-qldetaisdh/modules/ths-luan-van-cua-toi/components/master-route.vue`: Cảnh báo từ chối và nút Lịch sử nộp chỉ hiện ở Bước 5; sửa lỗi tàng hình tiêu đề Bước 5 bằng cách gán `case 'R': return 'red darken-2'`.
    - `lhu-qldetaisdh/modules/ths-luan-van-cua-toi/components/file-comp.vue`: Bảo vệ file đạo văn không cho học viên xóa hoặc upload đè.
    - `lhu-qldetaisdh/modules/ths-quan-ly-hoc-vien/components/dialog-upd-task.vue`: Bổ sung cảnh báo từ chối, nút Lịch sử nộp và dialog lịch sử cho Admin.
    - `lhu-qldetaisdh/.handoff/HANDOFF.md`: Tài liệu bàn giao ngữ cảnh.
  - **Pre-existing dirty / unrelated:**
    - `../lhu-qlnckh/`: Thay đổi đang dở dang ở phân hệ NCKH (DO NOT touch/revert).
    - `../_logs/tool-errors.jsonl`: Log CLI.
    - `../_history/`: Backup lịch sử tự động của fui CLI.
- **Quick Inspect Commands:**
  - `git diff lhu-qldetaisdh/`
  - `fui file status -p lhu-qldetaisdh --all`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Bổ sung quy trình kiểm tra đạo văn và phê duyệt/từ chối tại Bước 5 (Đăng ký bảo vệ Luận văn / Đồ án ThS). Khi từ chối, lưu snapshot phiên nộp vào lịch sử, reset 2 file luận văn (PDF/WORD) để học viên nộp lại. Khi học viên nộp lại, tự động reset file kiểm tra đạo văn. Sinh tiêu chí cho toàn bộ 457 học viên chưa hoàn thành bước 5 và tích hợp vào quy trình tạo mới.
- **Expected:** SDH tải file luận văn về check đạo văn -> upload file kết quả -> duyệt hoặc từ chối. Học viên thấy lý do từ chối và lịch sử nộp -> nộp lại file mới. Khi nộp lại, file đạo văn cũ được reset về trống để SDH kiểm tra phiên mới.
- **Actual:** Hoàn thành 100%. Đã test đầy đủ các kịch bản (duyệt tất cả, từ chối kèm file đạo văn, chặn từ chối khi thiếu file, reset file khi HV nộp lại, khắc phục lỗi dup lịch sử cũ và lỗi tên đề tài). Đã sinh dữ liệu cho 457 học viên và xóa sạch dữ liệu test.
- **Flow Analysis:**
  - **Input:** File luận văn của HV (5.6 PDF, 5.7 WORD), file kết quả kiểm tra đạo văn của SDH (`fileCheckDaoVan`), lý do từ chối.
  - **Process:**
    - SDH Từ chối: `spAPI_SDH_Reject_Defend_Thesis` -> Validate có file đạo văn -> Snapshot vào `Flow_Detail_His` -> Reset 5.6 & 5.7 -> `Flow_Status = 'R'`.
    - HV Nộp lại: `onSave` -> `spAPI_FlowDetail_UpdateMulti` -> Nhận file mới -> Reset `fileCheckDaoVan` -> `Flow_Status = 'P'`.
    - SDH Duyệt tất cả: `onCheckAll` -> `spAPI_FlowDetail_UpdateMulti` với `IsApproveAll = 1` -> Kiểm tra khớp tên đề tài -> Hoàn thành bước 5 (`Flow_Status = 'C'`) -> Auto-next bước 6.
  - **State:** `Flow_Status` chuyển đổi linh hoạt: `P` (chờ duyệt) <-> `R` (từ chối nộp lại) -> `C` (hoàn thành).
  - **Output:** Giao diện trực quan màu đỏ (`red darken-2`) khi bị từ chối; xem chi tiết từng phiên nộp qua popup lịch sử.
  - **Side Effects:** Đã cô lập hoàn toàn: chỉ lưu lịch sử và reset mục 5.6 và 5.7, toàn bộ các tiêu chí khác (Lý lịch khoa học, Đơn đăng ký, Nhận xét GVHD, Học phí, Điểm...) giữ nguyên 100%.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Database Procedures:**
  - `_db/qldetaisdh/spAPI_SDH_Reject_Defend_Thesis.sql` (Thủ tục từ chối Bước 5)
  - `_db/qldetaisdh/spAPI_FlowDetail_UpdateMulti.sql` (Cập nhật dữ liệu & tự động reset file đạo văn khi HV nộp lại)
  - `_db/qldetaisdh/spAPI_SDH_Get_FlowDetail_His.sql` (Lấy dữ liệu lịch sử nộp)
  - `_db/qldetaisdh/spAPI_Get_RootFlow.sql` (Cây quy trình chính)
- **Frontend Components:**
  - `modules/ths-duyet-tien-do/components/uc-detail-flow.vue` (Màn hình duyệt của SDH)
  - `modules/ths-luan-van-cua-toi/components/master-route.vue` (Màn hình tiến trình của Học viên)
  - `modules/ths-luan-van-cua-toi/components/file-comp.vue` (Component upload file của Học viên)
  - `modules/ths-quan-ly-hoc-vien/components/dialog-upd-task.vue` (Màn hình cập nhật tiến trình của Admin)

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] Toàn bộ 457 học viên chưa hoàn thành Bước 5 đã có tiêu chí `fileCheckDaoVan` trong `Flow_Detail` (177 học viên `Flow_Status = 'P'`, 280 học viên `Flow_Status = 'W'`).
- [FACT] `Task_Detail` đã có sẵn `fileCheckDaoVan` cho `Task_ID = 4` (`Task_Detail_ID = 284`) và `Task_ID = 22` (`Task_Detail_ID = 283`) với `USE_YN = 1`. Mọi học viên mới được tạo qua `spAPI_Process_Student_Ins` sẽ tự động sinh tiêu chí này.
- [FACT] Dữ liệu test của `GV0000611` đã được xóa sạch hoàn toàn khỏi tất cả các bảng (0 bản ghi).
- [FACT] Tất cả 4 stored procedures đã deploy thành công qua `fui sp deploy`.
- [FACT] Tất cả các component .vue sửa đổi đã được push lên server FUI (`fui file status`: 0 unpublished files).

### Active Hypotheses
- None.

### Assumptions & Unknowns
- None.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `fui file status -p lhu-qldetaisdh --all` → **Result:** PASS (0 unpublished files)
  - `fui sp deploy -p lhu-qldetaisdh spAPI_FlowDetail_UpdateMulti` → **Result:** PASS (exit code 0)
  - `fui sp deploy -p lhu-qldetaisdh spAPI_SDH_Reject_Defend_Thesis` → **Result:** PASS (exit code 0)
  - `fui sp deploy -p lhu-qldetaisdh spAPI_SDH_Get_FlowDetail_His` → **Result:** PASS (exit code 0)
  - `fui sp deploy -p lhu-qldetaisdh spAPI_Get_RootFlow` → **Result:** PASS (exit code 0)
- **Critical Error / Log Snippet:**
```text
None (All CLI operations exited with code 0)
```

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- **Attempt 1:** Ghi snapshot vào bảng `Flow_His` khi từ chối hồ sơ Bước 5.
  - **Result:** Làm lẫn lộn với tính năng *"Xác nhận Đăng ký mới"* của `spAPI_Reset_Student_Process`, gây ra lỗi duplicate Bước 5 trong popup *"Dữ liệu đăng ký cũ"*.
  - **Conclusion:** Đã xóa bỏ `INSERT INTO Flow_His` khỏi `spAPI_SDH_Reject_Defend_Thesis`. Lịch sử các phiên nộp/từ chối chỉ lưu vào bảng chuyên trách `Flow_Detail_His`.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên các tham số của `spAPI_FlowDetail_UpdateMulti` và `spAPI_Get_RootFlow`; giữ nguyên các hàm `ajaxCALLPromise`, props của component.
- **Side Effects / Tradeoffs:** Không có. File kiểm tra của các phiên nộp cũ luôn được bảo toàn trong `Flow_Detail_His`.
