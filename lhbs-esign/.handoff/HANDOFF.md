# AGENT HANDOFF: lhbs-esign

- **Generated At:** 2026-10-28T11:13:30+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhbs-esign`
- **Status:** `done`
- **Next Session Focus:** Kiểm thử UAT trên môi trường thực tế với người dùng cuối, hoặc mở rộng thêm các kịch bản chuỗi nhân quả và tham số đặc thù cho các năm học tiếp theo nếu có yêu cầu.

## 1. NEXT SESSION ACTION PLAN
1. Trải nghiệm trực quan trên giao diện thực tế của 2 module: `/kpi-ops-dashboard` và `/kpi-causal-config`.
2. Kiểm tra thao tác sửa ngưỡng, điều chỉnh tham số biểu phí cơ sở và xác nhận kiểm toán M&E trên Live Preview Sandbox.
3. Nếu bổ sung thêm chỉ tiêu KPI mới trong tương lai, chỉ cần insert vào `tblKPI_Definitions` và thiết lập baseline trong `tblKPI_Thresholds` mà không cần sửa code.

## 2. SUGGESTED SKILLS
- `session-bugflow`: Khởi động session mới theo quy trình chuẩn và kiểm tra project instructions.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `d792564` — feat(lhbs-esign): cau hinh dong chuoi nhan qua kpi ops, responsive da man hinh va bo sung mau cau tu docs
  - `b5f3a32` — feat(lhbs-esign): tai thiet ke kpi-ops-dashboard, tich hop causal config va dong bo 100% database
- **Working Tree Ownership:**
  - **Current task changes:**
    - `_db/esign/migration_seed_60_kpis.sql` (Seed 60 KPI chuẩn hóa, ngưỡng đa tầng và tham số biểu phí 5 cơ sở)
    - `_db/esign/migration_enhance_5_points.sql` (Bổ sung ApplicableScopes, ValueFormat, chuẩn hóa Target TS06=30%, cân đối Sĩ số - Công suất và kịch bản Nghịch lý/Kiểm toán)
    - `_db/esign/migration_dynamic_kpi_engine.sql` (Migration nền tảng bảng Thresholds, Parameters, Narratives)
    - `_db/esign/spAPI_KPI_GetCausalEngineData.sql` (SP trả 7 Result Sets phục vụ màn hình cấu hình)
    - `_db/esign/spAPI_KPI_GetCorrelations.sql` (SP trả RS2 Narratives, RS3 ContextStore 89 biến phẳng, RS4 Thresholds)
    - `_db/esign/spAPI_KPI_SaveNarrative.sql` (SP lưu mẫu câu biểu thức, scenario type và prompt kiểm toán)
    - `_db/esign/spAPI_KPI_SaveParameter.sql` (SP lưu tham số biểu phí và quy mô cơ sở)
    - `_db/esign/spAPI_KPI_SaveThreshold.sql` (SP lưu cấu hình ngưỡng đa tầng Baseline & Overrides)
    - `modules/kpi-causal-config/components/uc-kpi-causal-config.vue` (Tái cấu trúc 3 Không Gian Nghiệp Vụ, hỗ trợ N/A scopes, Variable Chips tinh giản, M&E checklist)
    - `modules/kpi-causal-config/style.css` (Giao diện Compact UI, thu gọn gap/padding, bổ sung badge và style mới)
    - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue` (Tích hợp Token Expression Engine, badge ngưỡng động và nội suy câu What-If)
  - **Pre-existing dirty / unrelated:**
    - `../lhu-qldetaisdh/` (Dự án riêng biệt, không thuộc scope task này)
    - `../_logs/tool-errors.jsonl` (File log môi trường, không commit)
- **Quick Inspect Commands:**
  - `git diff modules/kpi-causal-config/`
  - `git diff modules/kpi-ops-dashboard/`
  - `git diff _db/esign/`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Chuyển đổi toàn bộ hệ thống KPI & Diễn giải Chuỗi nhân quả LHBS từ trạng thái hard-code sang Dynamic 100%, scale cho 60 tiêu chí x 5 cơ sở trường, có cơ chế kế thừa đa tầng và giao diện cấu hình trực quan 3 Không Gian Nghiệp Vụ.
- **Expected:** Bỏ rẽ nhánh cứng trong SQL/Vue; tự động kế thừa baseline và cho phép ghi đè đặc thù; biểu thức tính toán linh hoạt `{TS04.Reason.FAR * PARAM.TuitionAnnual | currency}`; nhận diện đúng phạm vi cấp học (N/A); hỗ trợ kiểm toán dữ liệu và M&E confirm; giao diện compact hiển thị nhiều thông tin.
- **Actual:** Hệ thống đã hoàn thành trọn vẹn, kiểm thử qua tAPI xác nhận trả về đầy đủ 60 chỉ tiêu, 5 cơ sở trường, nội suy câu chính xác, đã publish lên FUI server (`# 0 unpublished file(s)`).
- **Flow Analysis:**
  - **Input:** CSDL `tblKPI_Definitions`, `tblKPI_Thresholds`, `tblKPI_Parameters`, `tblKPI_CausalNarratives`.
  - **Process:** Stored Procedures nạp ContextStore phẳng 89 biến -> `Token Expression Evaluator` trong Vue giải toán & format -> Live Preview Sandbox render câu thời gian thực -> Ghi nhận xác nhận kiểm toán M&E -> Hiển thị trên Dashboard.
  - **State:** Lưu trữ đồng bộ trên database `eSignature` qua tAPI.
  - **Output:** Giao diện Ma trận ngang 60 KPI x 5 cơ sở, Hồ sơ tham số 5 cơ sở, Visual Studio với Variable Chips tinh giản.
  - **Side Effects:** Giữ nguyên Result Sets 0 và 1 của các SP cũ, bảo toàn tương thích ngược 100%.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Specs / Plans:** `dynamic-kpi-causal-config-scale-plan.md`, `walkthrough.md`.
- **Code Locations:**
  - `modules/kpi-causal-config/components/uc-kpi-causal-config.vue`: Component Quản trị cấu hình (3 không gian).
  - `modules/kpi-causal-config/style.css`: Toàn bộ CSS Compact UI.
  - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue`: Dashboard Vận hành (Expression Engine).
  - `_db/esign/spAPI_KPI_GetCorrelations.sql`: Stored Procedure cấp dữ liệu tương quan và ContextStore.
  - `_db/esign/spAPI_KPI_GetCausalEngineData.sql`: Stored Procedure cấp 7 result sets cấu hình.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] tAPI không hỗ trợ default parameter trong khai báo SP header (`@Param = '...'`), phải bỏ giá trị mặc định khỏi header để tAPI router nhận diện.
- [FACT] Cần chạy `GRANT EXECUTE ON [dbo].[spAPI_...] TO [public] AS [dbo]` để tAPI có quyền gọi các stored procedure mới.
- [FACT] Quy mô 60 KPI gồm 4 nhóm: 7 TS, 20 CM, 24 DV, 9 TC; 5 cơ sở: MNTB, MNLK, TH, THCS, THPT.
- [FACT] Tổng Sĩ số KH 2.873 HS cân đối chuẩn với công suất 3.200 HS toàn hệ thống; Tiểu học Sĩ số 1.020 HS / Công suất 1.150 HS.

### Assumptions & Unknowns
- [ASSUMPTION] Dữ liệu snapshot hàng tháng của 5 cơ sở sẽ tiếp tục được đồng bộ định kỳ vào `tblKPI_PeriodSnapshots`.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test Runs:**
  - Kiểm tra cú pháp Vue SFC & cân bằng thẻ HTML (`Divs balance: 112/112`) -> **PASS**
  - Kiểm tra tAPI `eSign/KPI_GetCausalEngineData` (7 Result Sets) -> **PASS**
  - Kiểm tra tAPI `eSign/KPI_GetCorrelations` (ContextStore 89 biến) -> **PASS**
  - Kiểm tra tAPI 3 API Save (`SaveThreshold`, `SaveParameter`, `SaveNarrative`) -> **PASS**
  - Kiểm tra nội suy câu cho 5 cơ sở trường và kịch bản Nghịch lý/Kiểm toán -> **PASS**
  - Kiểm tra FUI publish ledger (`# 0 unpublished file(s)`) -> **PASS**

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- *Attempt:* Khai báo `@ThresholdID INT = NULL` trong header của Stored Procedure `spAPI_KPI_SaveThreshold`.
  - *Result:* tAPI guard báo lỗi và tAPI router trả về `The function doesn't exist`.
  - *Conclusion:* Luôn khai báo tham số thuần không có `= default` trong SP header; đưa logic gán mặc định vào trong thân `BEGIN ... END`.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên Result Sets 0 và 1 của `spAPI_KPI_GetCorrelations` để không phá vỡ các biểu đồ hoặc màn hình cũ đang gọi procedure này.
- **Side Effects / Tradeoffs:** Không có. Toàn bộ mã nguồn đã đồng bộ trên FUI.
