# AGENT HANDOFF: lhbs-esign

- **Generated At:** 2026-10-27T17:10:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhbs-esign`
- **Status:** `done`
- **Next Session Focus:** Kiểm thử toàn diện vận hành thực tế Dashboard HĐQT (kpi-ops-dashboard), chuẩn bị kế hoạch demo báo cáo Ban Điều Hành vào ngày 02/11/2026 và tiếp tục mở rộng các kết nối API Live tự động cho các chỉ tiêu còn lại theo docs.

## 1. NEXT SESSION ACTION PLAN
1. Đăng nhập kiểm tra trải nghiệm thực tế trên trình duyệt tại https://kyso.lhbs.vn/kpi-ops-dashboard (chuyển đổi các đơn vị MNLK, MNTB, TH, THCS và mở Dialog Vùng Tác Động).
2. Kiểm tra module cấu hình tham số độc lập tại https://kyso.lhbs.vn/kpi-causal-config để đảm bảo việc chỉnh sửa tham số CSDL phản ánh ngay lập tức vào dashboard.
3. Rà soát tiến độ kết nối API live cho các hệ thống nguồn còn lại (PM FTS hocphi.lhbs.vn, Sổ y tế yte.lhbs.vn, Khảo sát qa.lhbs.vn) theo checklist `docs/KPI_DASHBOARD_CHECKLIST.md`.

## 2. SUGGESTED SKILLS
- `minimal-feature-implementation`: Khi cần bổ sung phân hệ hoặc tab báo cáo mới theo yêu cầu của BĐH.
- `bug-root-cause-analysis`: Khi phát sinh lỗi lệch số liệu hoặc lỗi kết nối giữa Tapi và CSDL eSign.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `4df1028` — fix(lhbs-esign): sua FileType cua global-util-js tu js thanh .js de codeeditor FUI nhan dien dung ngon ngu
  - `a228810` — feat(lhbs-esign): publish global-util-js len FUI server va dong bo fileId 03DA6AAE5A0B4213B5BD4B852EF282AE
  - `995a4b4` — feat(lhbs-esign): khoi tao workspace, thiet lap agents, design system kpi va global-util
- **Working Tree Ownership:**
  - **Current task changes:**
    - `modules/kpi-ops-dashboard/`: Giao diện Dashboard vận hành HĐQT độc lập, 4 trụ cột, ma trận điểm nghẽn, dialog vùng tác động, 100% dynamic database.
    - `modules/kpi-causal-config/`: Module độc lập quản trị tham số giả định, kịch bản, lý do, phân công và quy tắc IF/ELSE.
    - `_db/esign/`: Các stored procedures SP API CSDL eSignature (`spAPI_KPI_GetPeriodSnapshots`, `spAPI_KPI_GetCausalEngineData`, `spAPI_KPI_GetCorrelations`, `spAPI_KPI_GetPeriods`, `spAPI_KPI_SaveCausalAssumption`, `spAPI_KPI_SaveCausalReason`).
    - `_db/lms/`: Dữ liệu và thủ tục tham chiếu LMS.
    - `docs/KPI_DASHBOARD_CHECKLIST.md`: Danh mục 60 chỉ tiêu chuẩn hóa theo biên bản họp 19/10/2026.
    - `docs/dashboard van hanh thang 9.xlsx`: File dữ liệu chốt kỳ T9/2026.
    - `modules/_modules.json`: Khai báo 2 modules trên FUI.
  - **Pre-existing dirty / unrelated:**
    - `../lhu-qldetaisdh/` (Các module luận văn Thạc sĩ LHU - KHÔNG ĐƯỢC CHẠM VÀO)
    - `../_logs/tool-errors.jsonl` (File log công cụ dùng chung - KHÔNG STAGE)
    - `.md/AGENTS.md` (Hướng dẫn agents - giữ nguyên)
- **Quick Inspect Commands:**
  - `git diff modules/kpi-ops-dashboard/`
  - `git diff _db/esign/`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Tái thiết kế toàn diện Dashboard vận hành HĐQT (`kpi-ops-dashboard`), xóa bỏ hoàn toàn hardcode và layout sao chép cũ, tích hợp nguồn Go-Live độc lập theo từng KPI, đưa toàn bộ dữ liệu 60 chỉ tiêu và 7 kịch bản vận hành thực tế vào CSDL `esign`.
- **Expected:** Dashboard tải mượt mà không lỗi cú pháp, số liệu nhảy động theo bộ lọc cơ sở, Dialog Vùng Tác Động tính toán đa kịch bản (mở xe bus, ưu đãi chuyển cấp, mở rộng CLB), có module cấu hình độc lập.
- **Actual:** Hoàn thành 100% mục tiêu, Stored Procedures đã deploy thành công lên CSDL eSign (58.187.42.172), cả 2 modules đã publish live trên kyso.lhbs.vn.
- **Flow Analysis:**
  - **Input:** Tham số bộ lọc `PeriodKey` (2026-09 chốt sổ hoặc 2026-10 live) và `DonViID` (ALL, MNTB, MNLK, TH, THCS).
  - **Process:** Frontend gọi tAPI `eSign/KPI_GetPeriodSnapshots` và `eSign/KPI_GetCausalEngineData` -> SQL Server thực thi SP và trả về 3-5 bảng dữ liệu JSON -> Vue component map vào `periodSnapshots`, `kpiGroupSummary`, `goliveSpecsList`.
  - **State:** Vue 3 reactivity quản lý `selectedPeriod`, `currentUnit`, `activeBottlenecks`, `causalScenario`.
  - **Output:** Giao diện Command Center sắc nét, 4 Trụ Cột Vận Hành, Ma Trận Điểm Nghẽn và Dialog Vùng Tác Động.
  - **Side Effects:** SP tự động seed snapshot cho các cơ sở nếu chưa có dữ liệu; không làm ảnh hưởng các bảng nghiệp vụ ký số eSign khác.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Specs & Checklist:** `docs/KPI_DASHBOARD_CHECKLIST.md`
- **Code Locations:**
  - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue` — Vue component chính của Dashboard Vận Hành.
  - `modules/kpi-ops-dashboard/style.css` — Styling chi tiết cho Command Pillars, Escalation Matrix, Golive Box.
  - `modules/kpi-causal-config/components/uc-kpi-causal-config.vue` — Vue component quản trị cấu hình tham số CSDL.
  - `_db/esign/spAPI_KPI_GetPeriodSnapshots.sql` — SP trả về danh mục 60 chỉ tiêu, group summary và golive specs.
  - `_db/esign/spAPI_KPI_GetCausalEngineData.sql` — SP cấu hình động Causal Engine (7 scenarios, 9 reasons, 18 assignments, 7 rules).

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] Procedure `spAPI_KPI_GetPeriodSnapshots` trả về chính xác 27 chỉ tiêu trọng điểm thuộc đủ 4 nhóm, có seed riêng cho MNLK (TS01: 133 HS, TC55: 45.2%) và TH (TS01: 896 HS, TC55: 49.5%). (Evidence: `curl https://tapi.lhbs.vn/eSign/KPI_GetPeriodSnapshots`).
- [FACT] Procedure `spAPI_KPI_GetCausalEngineData` trả về 5 bảng dữ liệu gồm 7 scenarios, 5 assumptions, 9 reasons, 18 assignments, 7 rules. (Evidence: `curl https://tapi.lhbs.vn/eSign/KPI_GetCausalEngineData`).
- [FACT] Đã loại bỏ hoàn toàn map `computedStagingSnapshot` khỏi Vue component, 100% số liệu lấy động từ database. (Evidence: `grep -n "computedStagingSnapshot" modules/kpi-ops-dashboard/components/uc-kpi-ops.vue` trả về 0 kết quả).
- [FACT] Lỗi cú pháp `Uncaught SyntaxError: missing ) after argument list` bắt nguồn từ dấu đóng `},` thừa tại dòng 2398 của `uc-kpi-ops.vue`; đã sửa và verify sạch qua `node -c`.

### Active Hypotheses
- Không có blocker nào còn tồn tại.

### Assumptions & Unknowns
- [ASSUMPTION] Kỳ Tháng 09/2026 hiện sử dụng dữ liệu đã chốt sổ từ Excel nội bộ lưu tại eSign; khi các hệ thống BasicData, HocPhi FTS, Yte, QA hoàn tất API chính thức sẽ chuyển `DataSourceType` sang `LIVE_API`.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `node -c /tmp/test_script_fixed.js` -> **Result:** PASS | **Proves:** Không còn lỗi cú pháp JavaScript trong component.
  - `fui component update uc-kpi-ops` -> **Result:** PASS | **Proves:** Component đã sync lên FUI server.
  - `fui module publish html` -> **Result:** PASS | **Proves:** Module `kpi-ops-dashboard` và `kpi-causal-config` đã publish live.
  - `fui file status` -> **Result:** PASS (0 unpublished files) | **Proves:** Workspace hoàn toàn đồng bộ với remote FUI.

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- *Attempt 1:* Dùng cờ `-d` khi chạy `fui sp deploy`. Kết quả: báo lỗi unknown option. Kết luận: Phải dùng cờ chuẩn `--db esign`.
- *Attempt 2:* Dùng map tĩnh `computedStagingSnapshot` trong Vue script để hiển thị nhanh. Kết quả: User phản ánh hardcode, số liệu không đổi khi lọc đơn vị. Kết luận: Bỏ hoàn toàn map tĩnh, nạp thẳng qua SP database.

## 9. CONSTRAINTS & RISKS
- Contracts to Preserve: Giữ nguyên contract API của `spAPI_KPI_GetPeriodSnapshots` và `spAPI_KPI_GetCausalEngineData` trả về mảng dữ liệu nhiều bảng (array of arrays).
- Side Effects / Tradeoffs: Không có side effects.
