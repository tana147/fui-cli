# AGENT HANDOFF: lhu-qldetaisdh

- **Generated At:** 2026-10-22T16:07:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhu-qldetaisdh`
- **Status:** `done`
- **Next Session Focus:** Kiểm tra nghiệm thu quy trình kiểm tra đạo văn và phê duyệt/từ chối Bước 5 trên môi trường staging/live; hỗ trợ Sau đại học thực hiện tải file kết quả đạo văn và duyệt tiến độ cho 5 học viên vừa khôi phục.

## 1. NEXT SESSION ACTION PLAN
1. Đăng nhập tài khoản Sau đại học vào màn hình Duyệt tiến độ (`/ths-duyet-tien-do`), kiểm tra hiển thị 5 học viên ngành Ngôn ngữ Anh vừa được khôi phục về Bước 5.
2. Thử nghiệm tải lên file kết quả kiểm tra đạo văn (đảm bảo file `.pdf` được chấp nhận, các file đuôi khác bị chặn).
3. Thực hiện thao tác Duyệt hoặc Từ chối đối với hồ sơ Bước 5 và xác nhận dữ liệu cập nhật chính xác trên giao diện Học viên (`/ths-luan-van-cua-toi`).

## 2. SUGGESTED SKILLS
- `change-set-review`: Khi cần rà soát lại các thay đổi git commit trước khi chuyển giao.
- `session-bugflow`: Khi user báo phát sinh lỗi mới cần phân tích root cause trước khi patch.

## 3. GIT & COMMIT STATE
- **Branch:** `main` (tracking `origin/main`)
- **Relevant Recent Commits:**
  - `9cd9ba5` — feat(lhu-qldetaisdh): tich hop quy trinh kiem tra dao van va phe duyet tu choi buoc 5
- **Working Tree Ownership:**
  - **Current task changes:**
    - `lhu-qldetaisdh/_db/qldetaisdh/spAPI_SDH_Get_DetailProcessing.sql` (bổ sung AllowFileType và Task_Help vào SELECT)
    - `lhu-qldetaisdh/_db/qldetaisdh/spAPI_SDH_Reject_Defend_Thesis.sql` (bổ sung kiểm tra đuôi .pdf cho File_Name_DaoVan)
    - `lhu-qldetaisdh/components/c-file-comp.vue` (bổ sung guard validate extension trong onFileUpload)
    - `lhu-qldetaisdh/modules/ths-duyet-tien-do/components/uc-detail-flow.vue` (bổ sung validate file .pdf cho fileCheckDaoVan ở onSave, onCheckAll, openRejectDialog, confirmReject)
    - `lhu-qldetaisdh/.handoff/HANDOFF.md` (tài liệu handoff cập nhật)
  - **Pre-existing dirty / unrelated:**
    - `../lhu-qlnckh/` (các file thuộc phân hệ NCKH độc lập, DO NOT touch/revert)
    - `../_logs/tool-errors.jsonl` (log CLI hệ thống)
- **Quick Inspect Commands:**
  - `git diff lhu-qldetaisdh/`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Đảm bảo tiêu chí `fileCheckDaoVan` chỉ chấp nhận định dạng PDF ở cả 4 tầng (bộ lọc file picker, validate component upload, validate action duyệt/từ chối FE, và validate Stored Procedure BE); đồng thời bổ sung tiêu chí này và khôi phục về Bước 5 cho 5 học viên ngành Ngôn ngữ Anh đã có lịch bảo vệ Hội đồng.
- **Expected:**
  - Tiêu chí `fileCheckDaoVan` chỉ cho phép chọn và tải file `.pdf`. Nếu người dùng cố tình tải file định dạng khác, hệ thống phải báo lỗi và chặn lại.
  - 5 học viên (Trần Đình Bảo, Nguyễn Hữu Thịnh, Nguyễn Tiến Đạt, Nguyễn Thị Hải Yến, Đoàn Ngọc Sang) được khôi phục về Bước 5 (`Flow_Status = 'P'`), có sẵn ô upload file kết quả kiểm tra đạo văn PDF, giữ nguyên 100% hồ sơ cũ và thông tin Hội đồng bảo vệ.
- **Actual:** Đã hoàn thành 100%, deploy đầy đủ SP lên database, push component lên FUI server và kiểm tra runtime đều PASS.
- **Flow Analysis:**
  - **Input:** SDH chọn file tải lên tiêu chí `fileCheckDaoVan` hoặc nhấn nút Từ chối / Lưu / Duyệt.
  - **Process:** `c-file-comp:fileRules` lọc đuôi `.pdf` dựa trên `itemDes.AllowFileType` từ `spAPI_SDH_Get_DetailProcessing` $\rightarrow$ `c-file-comp:onFileUpload` kiểm tra extension file $\rightarrow$ `uc-detail-flow:openRejectDialog/confirmReject/onSave/onCheckAll` validate tên file kết thúc bằng `.pdf` $\rightarrow$ `spAPI_SDH_Reject_Defend_Thesis` kiểm tra `@File_Name_DaoVan` có đuôi `.pdf`.
  - **State:** `Flow_Detail.File_Type = 'application/pdf'`, `Flow_Detail.Flow_Detail_Status = 'C'` khi duyệt, hoặc snapshot vào `Flow_Detail_His` và reset về `'W'` khi từ chối.
  - **Output:** Ghi nhận kết quả đạo văn hợp lệ, cho phép duyệt hoặc từ chối đúng quy trình.
  - **Side Effects:** Đã tạo bảng backup `dbo.Flow_Backup_20261022_RestoreStep5` và `dbo.Flow_Detail_Backup_20261022_RestoreStep5` để khôi phục tức thời nếu cần.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Code Locations:**
  - `lhu-qldetaisdh/_db/qldetaisdh/spAPI_SDH_Get_DetailProcessing.sql:30` — bổ sung `AllowFileType` và `Task_Help`.
  - `lhu-qldetaisdh/_db/qldetaisdh/spAPI_SDH_Reject_Defend_Thesis.sql:32` — kiểm tra `@File_Name_DaoVan` có đuôi `.pdf`.
  - `lhu-qldetaisdh/components/c-file-comp.vue:118` — guard validate extension trong `onFileUpload`.
  - `lhu-qldetaisdh/modules/ths-duyet-tien-do/components/uc-detail-flow.vue:533, 638, 656, 769` — validate tên file `.pdf` cho `fileCheckDaoVan`.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] `Task_Detail` có `AllowFileType = 'PDF'` cho cả Task 4 (ID 284) và Task 22 (ID 283).
- [FACT] `spAPI_SDH_Get_DetailProcessing` trước đó không SELECT `AllowFileType`, dẫn đến component fallback về mọi loại đuôi file.
- [FACT] 5 học viên (`922000098`, `925000005`, `925000009`, `925000010`, `925000020`) đã có Quyết định Hội đồng bảo vệ vào ngày 30/10/2026 và trước đó đã xong Bước 5 nên chưa có tiêu chí đạo văn.
- [FACT] Đã tạo 2 bảng backup `dbo.Flow_Backup_20261022_RestoreStep5` (47 rows) và `dbo.Flow_Detail_Backup_20261022_RestoreStep5` (333 rows).
- [FACT] Đã chèn 5 dòng `fileCheckDaoVan` vào `Flow_Detail` (`Flow_Detail_Status = 'W'`) và cập nhật 15 bản ghi `Flow` (Bước 5: `'P'`, Bước 6 & 7: `'W'`). Không có bất kỳ dòng dữ liệu nào bị xóa.

### Active Hypotheses
- None.

### Assumptions & Unknowns
- [ASSUMPTION] Thời gian bảo vệ ngày 30/10/2026 của Hội đồng vẫn giữ nguyên sau khi SDH hoàn tất kiểm tra đạo văn và duyệt lại Bước 5.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test Runs:**
  - `EXEC spAPI_SDH_Get_DetailProcessing @Flow_ID = 12681, @sys_SystemRight = 9` $\rightarrow$ **Result:** PASS, trả về đúng `AllowFileType = 'PDF'`.
  - `EXEC spAPI_SDH_Reject_Defend_Thesis ... @File_Name_DaoVan = N'ketqua.docx'` $\rightarrow$ **Result:** PASS, báo lỗi HTTP 400: `File kết quả kiểm tra đạo văn bắt buộc phải là định dạng PDF (.pdf)`.
  - `EXEC spAPI_SDH_Get_DetailProcessing @Flow_ID = 25593, @sys_SystemRight = 9` (học viên Nguyễn Hữu Thịnh) $\rightarrow$ **Result:** PASS, xuất hiện tiêu chí `fileCheckDaoVan` với `AllowFileType = 'PDF'`.

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- `DROP TABLE` bị guard FUI chặn: Không dùng lệnh `DROP TABLE`, sử dụng trực tiếp `SELECT * INTO` cho tên bảng backup mới chưa tồn tại.

## 9. CONSTRAINTS & RISKS
- Contracts to Preserve: Giữ nguyên các tham số của `spAPI_SDH_Get_DetailProcessing`, `spAPI_SDH_Reject_Defend_Thesis`, không thay đổi props của `c-file-comp.vue`.
- Phân hệ độc lập cần tránh: Tuyệt đối không commit hoặc stash nhầm các file thay đổi trong thư mục `../lhu-qlnckh/`.
