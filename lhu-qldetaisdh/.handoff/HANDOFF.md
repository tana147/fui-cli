# AGENT HANDOFF: lhu-qldetaisdh

- **Generated At:** 2026-10-21T10:58:30+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhu-qldetaisdh`
- **Status:** `done`
- **Next Session Focus:** Kiểm tra vận hành thực tế giao diện và phân quyền sau khi chuẩn hóa 32 module sang kebab-case tiếng Việt và đồng bộ Menu; rà soát các module/báo cáo nghiệp vụ tiếp theo nếu có yêu cầu.

## 1. NEXT SESSION ACTION PLAN
1. Kiểm tra đăng nhập với các vai trò người dùng (Học viên ThS, Nghiên cứu sinh TS, Giảng viên, Quản trị) trên web live để kiểm tra router và phân quyền menu mới.
2. Kiểm tra tính năng in ấn các biểu mẫu (quyết định, danh sách bảo vệ, tem bưu điện) để đảm bảo các URL báo cáo mới hoạt động trơn tru.
3. Nếu phát sinh nhu cầu, bổ sung phân quyền tĩnh `sys_FunctionRight` cho các ModuleID mới nếu có cấu hình quyền đặc thù trên hệ thống SSO/acc.

## 2. SUGGESTED SKILLS
- `code-review-pragmatic`: Khi cần kiểm tra lại logic nghiệp vụ hoặc các component sau refactor.
- `change-set-review`: Khi cần review git diff trước khi merge hoặc triển khai tiếp.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `1bd3b37` — refactor(lhu-qlnckh): chuan hoa dat ten module kebab-case va dong bo menu
  - `53f2d20` — chore(lhu-qldetaisdh): clean up unused modules, stored procedures, snapshot tables and orphan files
- **Working Tree Ownership:**
  - **Current task changes:**
    - `lhu-qldetaisdh/modules/`: 32 module đã được đổi tên thư mục sang chuẩn `kebab-case` (`ths-*` cho Thạc sĩ, `ts-*` cho Tiến sĩ) và publish lên server.
    - `lhu-qldetaisdh/modules/_modules.json`: Cập nhật metadata 32 module mới.
    - `lhu-qldetaisdh/project.json`: Đồng bộ toàn bộ URL và tên menu sang URL mới.
    - `lhu-qldetaisdh/_projectInfo.json`: Cập nhật router mặc định `ths-tong-quan`.
    - `lhu-qldetaisdh/.handoff/HANDOFF.md`: Handoff ghi lại toàn bộ ngữ cảnh phiên làm việc.
  - **Pre-existing dirty / unrelated:**
    - `lhu-qlnckh/`: Thay đổi đang dở dang ở module `hdkh-ly-lich-khoa-hoc` (KHÔNG động vào/revert).
    - `_history/lhu-qlnckh/`: Metadata lịch sử của `lhu-qlnckh`.
- **Quick Inspect Commands:**
  - `git status -s lhu-qldetaisdh/`
  - `fui module list -p lhu-qldetaisdh`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Chuẩn hóa toàn bộ ModuleID và ModuleName sang `kebab-case` tiếng Việt theo 2 phân hệ rõ ràng (Tiến sĩ: `ts-`, Thạc sĩ: `ths-`), đồng bộ lại menu hệ thống, cập nhật các URL chuyển hướng/in ấn nội bộ, và publish cấu hình lên máy chủ FUI.
- **Expected:** Toàn bộ 32 module có ID và tên chuẩn ngữ nghĩa, khắc phục lỗi chính tả cũ, menu điều hướng khớp chính xác với router, không còn link gãy.
- **Actual:** Đã hoàn thành 100%. 32 module đã được cập nhật trên server (`fui module update`), thư mục mã nguồn được đổi tên, 6 vị trí mã nguồn gọi URL tĩnh đã được sửa và đẩy lên server (`fui file push`), cấu hình `project.json` đã được đẩy lên server (`fui project publish-config`).
- **Flow Analysis:**
  - **Input:** Yêu cầu người dùng refactor kebab-case tiếng Việt, gom nhóm Thạc sĩ (`ths-`) và Tiến sĩ (`ts-`).
  - **Process:** Phân tích toàn bộ 32 module -> Thống kê đề xuất -> User xác nhận -> Chạy `fui module update` đổi ID/tên trên server và đổi tên folder local -> Cập nhật URL trong .vue/.js -> `fui file push` -> Cập nhật menu `project.json` -> `fui project publish-config`.
  - **State:** Server FUI và local workspace đồng bộ 32 module mới.
  - **Output:** URL chuẩn hóa dạng `qldetaisdh.lhu.edu.vn/ths-...` và `qldetaisdh.lhu.edu.vn/ts-...`.
  - **Side Effects:** Đã cập nhật tất cả các URL tĩnh nội bộ gọi tới module cũ để tránh lỗi 404 khi người dùng bấm in ấn hoặc chuyển trang.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Project Config:**
  - `lhu-qldetaisdh/project.json:7-324` (Cấu trúc menu điều hướng mới)
  - `lhu-qldetaisdh/_projectInfo.json:9` (`Router: "ths-tong-quan"`)
- **Key Code Modifications:**
  - `lhu-qldetaisdh/modules/ths-tong-quan/script.js:33` (Redirect `/ths-luan-van-cua-toi`)
  - `lhu-qldetaisdh/modules/ths-hoi-dong/script.js:8,704` (In quyết định & danh sách bảo vệ)
  - `lhu-qldetaisdh/modules/ths-hoi-dong/components/dialog-tem-buu-kien.vue:166` (In tem bưu điện)
  - `lhu-qldetaisdh/modules/ths-hoi-dong/components/dialog-detai-thanhvien.vue:599` (In tem dán)
  - `lhu-qldetaisdh/modules/ths-quan-ly-quyet-dinh/components/uc-main-page.vue:187` (In quyết định giao đề tài)
  - `lhu-qldetaisdh/modules/ths-moi-giang-vien/script.js:3` & `select-student-dialog.vue:120` (In thư mời)
  - `lhu-qldetaisdh/modules/ths-luan-van-cua-toi/components/student-container.vue:49,60` & `master-route.vue:424` (Redirect `/ts-luan-an-cua-toi`)
  - `lhu-qldetaisdh/modules/ts-luan-an-cua-toi/components/uc-main-page.vue:203` (Redirect `/ths-luan-van-cua-toi`)
  - `lhu-qldetaisdh/modules/ths-gia-han-de-tai/components/extend-time-topic.vue:90` (Redirect `/ths-luan-van-cua-toi`)
  - `lhu-qldetaisdh/modules/ths-doi-de-tai/components/change-topic-container.vue:138` (Redirect `/ths-luan-van-cua-toi`)

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] 32 module đã được cập nhật thành công trên máy chủ FUI (Evidence: `fui module list -p lhu-qldetaisdh` trả về 32 module tiền tố `ths-` và `ts-`).
- [FACT] Toàn bộ 32 thư mục module cục bộ đã được đổi tên tương ứng (Evidence: `ls -1 modules | grep -E "^(ths|ts)-" | wc -l` = 32).
- [FACT] Cấu hình menu và router mặc định trong `project.json` đã được publish lên máy chủ (Evidence: `fui project publish-config` exit 0).
- [FACT] Toàn bộ các component và script sửa đổi đã được publish thành công lên máy chủ (Evidence: `fui file push` exit 0).

### Active Hypotheses
- None.

### Assumptions & Unknowns
- [ASSUMPTION] Các tài khoản người dùng cũ truy cập qua menu hoặc router mặc định sẽ không bị ảnh hưởng bởi thay đổi URL vì toàn bộ menu và liên kết nội bộ đã được cập nhật.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `fui module list -p lhu-qldetaisdh` → **Result:** PASS (32/32 modules updated on server)
  - `fui project publish-config -p lhu-qldetaisdh` → **Result:** PASS (project.json published)
  - `fui project sync -p lhu-qldetaisdh` → **Result:** PASS (modules 32, project components 13, project imports 6)
- **Critical Error / Log Snippet:**
```text
None (All CLI operations exited with code 0)
```

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- **Attempt 1:** Phân loại ban đầu thành 4 nhóm (Thạc sĩ, Tiến sĩ, Báo cáo/In, Dùng chung).
  - **Result:** Người dùng yêu cầu gom toàn bộ các module ngoài Tiến sĩ về Thạc sĩ (`ths-`).
  - **Conclusion:** Đã điều chỉnh toàn bộ 25 module còn lại thống nhất dùng tiền tố `ths-`.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên các hàm `ajaxCALL`, component props, định dạng payload tAPI/MSSQL trong các module.
- **Side Effects / Tradeoffs:** Người dùng nếu có bookmark URL cũ (ví dụ `/my-thesis`) trên trình duyệt cá nhân sẽ cần chuyển sang dùng URL mới `/ths-luan-van-cua-toi` hoặc truy cập qua trang chủ `/ths-tong-quan`.
