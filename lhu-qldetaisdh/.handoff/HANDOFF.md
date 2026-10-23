# AGENT HANDOFF: lhu-qldetaisdh

- **Generated At:** 2026-10-23T09:39:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhu-qldetaisdh`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục kiểm tra nghiệp vụ trên giao diện thực tế đối với quy trình quản lý file quyết định và duyệt tiến độ luận văn; hỗ trợ người dùng nghiệm thu các module Thạc sĩ và Tiến sĩ.

## 1. NEXT SESSION ACTION PLAN
1. Đăng nhập kiểm tra màn hình Quản lý quyết định (`/ths-quan-ly-quyet-dinh`): Xác nhận Quyết định 2039/QĐ-ĐHLH hiển thị đúng ngày 15/10/2026 và tag file màu xanh tải về bình thường.
2. Thử nghiệm tải file trong modal Cấp SQĐ, kiểm tra tính năng lưu giữ file và tính năng tự động xóa file rác khi bấm Hủy/Đóng.
3. Rà soát kiểm tra các luồng nộp bài và duyệt tiến độ tại màn hình Học viên (`/ths-luan-van-cua-toi`) và Duyệt tiến độ (`/ths-duyet-tien-do`).

## 2. SUGGESTED SKILLS
- `change-set-review`: Khi cần rà soát lại các thay đổi git commit trước khi chuyển giao.
- `session-bugflow`: Khi user báo phát sinh lỗi mới cần phân tích root cause trước khi patch.

## 3. GIT & COMMIT STATE
- **Branch:** `main` (tracking `origin/main`)
- **Relevant Recent Commits:**
  - `9cd9ba5` — feat(lhu-qldetaisdh): tich hop quy trinh kiem tra dao van va phe duyet tu choi buoc 5
- **Working Tree Ownership:**
  - **Current task changes:**
    - `_db/qldetaisdh/spAPI_Decision_Get_ByStatus.sql`: sửa ghép chuỗi năm quyết định hiển thị đúng `15/10/2026`.
    - `modules/ths-quan-ly-quyet-dinh/components/uc-modal-give-sqd.vue`: sửa bug reset file về null khi bấm Lưu; tách hàm dọn file rác khi hủy.
    - `modules/ths-hoi-dong/components/dialog-give-sqd.vue`: sửa bug xóa nhầm file cũ khi không đổi file; dọn file rác khi đóng modal.
    - `modules/ths-quan-ly-hoc-vien/components/dialog-upd-task.vue`: xóa cờ `unsavedUploadedFiles` khi lưu/duyệt thành công tránh xóa nhầm file đã lưu khi đóng modal.
    - `modules/ths-duyet-tien-do/components/uc-detail-flow.vue`: tự động dọn file rác khi đổi học viên, chuyển bước hoặc rời trang; bảo lưu file khi Lưu/Duyệt/Từ chối.
    - `modules/ts-hoi-dong/components/uc-modal-give-sqd.vue`: bổ sung dọn file rác khi đóng modal mà không lưu.
    - `modules/ths-quan-ly-giang-vien/components/dialog-update-teacher.vue`: xóa file cũ bị thay thế; xóa file tạm khi hủy.
    - `modules/ths-quan-ly-giang-vien/components/dialog-add-single-teacher.vue`: tự động xóa file rác nếu đóng modal mà không thêm giảng viên.
    - `modules/ths-luan-van-cua-toi/components/file-comp.vue`: quản lý file upload tạm, xóa file rác khi học viên xóa chip.
    - `modules/ths-luan-van-cua-toi/components/master-route.vue`: tự động dọn file rác khi rời trang không nộp; giải phóng cờ khi nộp bài.
    - `.handoff/HANDOFF.md`: tài liệu bàn giao phiên làm việc.
  - **Pre-existing dirty / unrelated:**
    - `../lhu-qlnckh/` (các file thuộc phân hệ NCKH độc lập, DO NOT touch/revert)
    - `../_logs/tool-errors.jsonl` (log CLI hệ thống)
    - `../_history/` (các file rollback backup sinh ra từ fui CLI)
- **Quick Inspect Commands:**
  - `git diff .`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Kiểm tra và khôi phục dữ liệu file upload cho Quyết định 2039/QĐ-ĐHLH (15/10/2026 Cao Học); xác định root cause tại sao người dùng upload nhiều lần nhưng hệ thống vẫn báo "Chưa có file QĐ"; đồng thời rà soát toàn bộ hệ thống để đảm bảo quy tắc "Upload lên mà không lưu thì phải xóa, tránh sinh file rác trong database".
- **Expected:**
  - Quyết định 2039/QĐ-ĐHLH liên kết đúng file PDF đã tải lên (`2039-QĐ-ĐHLH Quyet dinh giao de tai 2025.3 (1).pdf`), hiển thị đúng ngày 15/10/2026.
  - Khi người dùng upload file và nhấn Lưu: file được bảo lưu 100%, ghi nhận đúng vào DB.
  - Khi người dùng upload file nhưng bấm Đóng/Hủy hoặc rời trang: hệ thống tự động xóa file tạm trên máy chủ, không sinh file rác.
- **Actual:**
  - Đã khôi phục liên kết file cho Quyết định 2039 (ID: 4397) trong bảng `Decision` và `Decision_Detail`.
  - Đã deploy SP `spAPI_Decision_Get_ByStatus` sửa lỗi hiển thị ngày `15/10/2026`.
  - Đã rà soát và vá đồng bộ 9 component liên quan đến upload file trên toàn hệ thống, push thành công lên FUI server.
- **Flow Analysis:**
  - **Input:** Người dùng tải file lên qua `<f-file-upload>` hoặc `<c-file-comp>`.
  - **Process:** File được ghi vào `FileData` $\rightarrow$ component ghi nhận File_ID vào `window.unsavedUploadedFiles` hoặc `tempUploadedFileIds` $\rightarrow$ Khi bấm Lưu: dữ liệu file được gửi qua API lưu trữ DB, gỡ khỏi danh sách tạm $\rightarrow$ Khi bấm Đóng/Hủy hoặc unmount: gọi `/FILE_FileDeleteMulti` dọn dẹp các file tạm chưa lưu.
  - **State:** `Decision.DecisionFile_ID` giữ mã file đã lưu; `FileData` chỉ giữ các file đang được tham chiếu bởi các bảng nghiệp vụ.
  - **Output:** Giao diện hiển thị đúng link file đã lưu, dữ liệu sạch không phát sinh rác.
  - **Side Effects:** Không ảnh hưởng đến các bảng dữ liệu khác.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Code Locations:**
  - `_db/qldetaisdh/spAPI_Decision_Get_ByStatus.sql:19` — sửa `Decision_ThangQD` thành `Decision_NamQD`.
  - `modules/ths-quan-ly-quyet-dinh/components/uc-modal-give-sqd.vue:240` — tách `deleteTempFiles()` và loại bỏ reset state trong `handleSave()`.
  - `modules/ths-hoi-dong/components/dialog-give-sqd.vue:168, 208, 240` — sửa guard xóa file cũ và bổ sung xóa file tạm khi đóng.
  - `modules/ths-quan-ly-hoc-vien/components/dialog-upd-task.vue:1338, 1511, 1590` — reset `unsavedUploadedFiles` sau khi lưu.
  - `modules/ths-duyet-tien-do/components/uc-detail-flow.vue:389, 415, 592, 697, 764` — tích hợp dọn file rác khi unmount/chuyển bước.
  - `modules/ts-hoi-dong/components/uc-modal-give-sqd.vue:225, 305` — dọn file tạm khi hủy modal.
  - `modules/ths-quan-ly-giang-vien/components/dialog-update-teacher.vue:255, 275` — dọn file tạm và file cũ bị thay thế.
  - `modules/ths-quan-ly-giang-vien/components/dialog-add-single-teacher.vue:210, 246` — dọn file tạm khi đóng modal.
  - `modules/ths-luan-van-cua-toi/components/file-comp.vue:105, 146` — quản lý file tạm và xóa file khi hủy chip.
  - `modules/ths-luan-van-cua-toi/components/master-route.vue:400, 485, 915` — dọn file rác khi rời trang không nộp.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] File `FD3EE98ED91641E88F40E29A7202FA56` (`2039-QĐ-ĐHLH Quyet dinh giao de tai 2025.3 (1).pdf`) đã được người dùng upload lúc 07:56:59 sáng 23/10/2026, dung lượng 1,592,107 bytes, còn nguyên vẹn trong `FileData`.
- [FACT] Quyết định 2039/QĐ-ĐHLH (ID: 4397) có 16 học viên lớp 25CQ913, ngành Quản trị kinh doanh.
- [FACT] `uc-modal-give-sqd.vue` trong `ths-quan-ly-quyet-dinh` trước đó gọi `cleanupTempFiles()` trong `handleSave()`, hàm này đặt lại `localDecision.DecisionFile_ID = null` trước khi emit ra ngoài.
- [FACT] `dialog-give-sqd.vue` trong `ths-hoi-dong` trước đó xóa file cũ ngay cả khi không thay đổi file (`if($this.cloneData.DecisionFile_ID)` thiếu kiểm tra khác nhau).
- [FACT] `dialog-upd-task.vue` trong `ths-quan-ly-hoc-vien` có `closeModal` xóa file trong `window.unsavedUploadedFiles`, nhưng `onSave` và `onCheckAll` không clear mảng này, dẫn đến đóng modal xóa nhầm file vừa lưu.

### Active Hypotheses
- None.

### Assumptions & Unknowns
- [ASSUMPTION] File PDF `2039-QĐ-ĐHLH Quyet dinh giao de tai 2025.3 (1).pdf` upload lúc 07:56:59 là bản quyết định chuẩn cuối cùng của Sau đại học.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test Runs:**
  - `EXEC spAPI_Decision_Get_ByStatus @Decision_Status = 0, @sys_SystemRight = 9` $\rightarrow$ **Result:** PASS, bản ghi 4397 trả về ngày `15/10/2026` và File_Url `/FileData/FD3EE98ED91641E88F40E29A7202FA56`.
  - `SELECT DecisionFile_ID, DecisionFile_Url, DecisionFile_Name FROM Decision WHERE Decision_ID = 4397` $\rightarrow$ **Result:** PASS, dữ liệu cập nhật đầy đủ.
  - `fui file status` $\rightarrow$ **Result:** PASS, `0 unpublished file(s)`.

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- `fui sp deploy _db/qldetaisdh/spAPI_Decision_Get_ByStatus.sql`: Lệnh yêu cầu tên SP (`fui sp deploy spAPI_Decision_Get_ByStatus`), không truyền đường dẫn file.

## 9. CONSTRAINTS & RISKS
- Contracts to Preserve: Giữ nguyên hợp đồng API `/Decision_Upd_SoQD`, `/HoiDong_Upd_SoQD`, `/FlowDetail_UpdateMulti`, `/FILE_FileDelete`, `/FILE_FileDeleteMulti`.
- Phân hệ độc lập cần tránh: Tuyệt đối không commit hoặc stash nhầm các file thay đổi trong thư mục `../lhu-qlnckh/`.
