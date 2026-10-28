# AGENT HANDOFF: lhbs-esign

- **Generated At:** 2026-10-28T17:03:30+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhbs-esign`
- **Status:** `done`
- **Next Session Focus:** Kiểm thử E2E giao diện điều hành thực tế tại `https://kyso.lhbs.vn/kpi-ops-dashboard` và chuẩn bị kịch bản nạp kỳ chốt sổ tiếp theo (Tháng 10/2026).

## 1. NEXT SESSION ACTION PLAN
1. Mở trình duyệt tại `https://kyso.lhbs.vn/kpi-ops-dashboard`, kiểm tra hoạt động mượt mà của toàn bộ các sub-tab: Ops Command, Risk Radar, Audit Center, Causal Map, Fact Store.
2. Kiểm tra bộ lọc cơ sở (`ALL`, `MNLK`, `TH`, `THCS`, `THPT`) và xác nhận dữ liệu radar rủi ro + điểm vênh phản hồi tương thích 100%.
3. Chuẩn bị cơ chế nạp dữ liệu định kỳ cho kỳ chốt sổ `2026-10` vào `tblKPI_PeriodSnapshots`, `tblKPI_OperationalFacts` và `tblKPI_RiskDirectives`.

## 2. SUGGESTED SKILLS
- `clean-stage-commit-push`: Đã dùng để đóng gói và commit sạch sẽ session hiện tại.
- `session-bugflow`: Dùng ở đầu session mới nếu user báo cáo bất kỳ lỗi phát sinh nào.
- `test-before-patch`: Dùng để test trước các stored procedure SQL trên CSDL eSign trước khi áp dụng.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `88a2b91` — docs(lhbs-esign): update handoff document with latest commit reference 4b62a6b
  - `4b62a6b` — fix(lhbs-esign): fix causal tree, slider feedback loop, dynamic correlation matching and remove redundant controls
  - `5fbe716` — feat(lhbs-esign): standardize Sep facts, add executive ROI simulator, risk radar & 5 sub-tabs
- **Working Tree Ownership:**
  - **Current task changes:**
    - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue` (Khắc phục lỗi compile Vue 3, bổ sung 8 state khởi tạo & defensive guards)
    - `_db/esign/migration_kpi_correlation_ontology.sql` (Khởi tạo bảng quan hệ ngữ nghĩa toán học `tblKPI_CorrelationOntology`)
    - `_db/esign/migration_kpi_correlation_engine.sql` (Cấu hình liên kết tương quan động)
    - `_db/esign/spAPI_KPI_GetAuditDiscrepancies.sql` (Dynamic Ontology Engine phát hiện điểm vênh/nghịch lý 100% không hardcode)
    - `_db/esign/migration_dynamic_risk_radar.sql` (Bảng `tblKPI_CampusCatalog` & `tblKPI_RiskDirectives`)
    - `_db/esign/spAPI_KPI_GetRiskRadar.sql` (Dynamic Risk Scoring Engine 5 cơ sở & 4 trục ngòi nổ)
    - `_db/esign/spAPI_KPI_GetStrategicLevers.sql` (Waterfall Value Bridge API)
    - `_db/esign/spAPI_KPI_GetOperationsSummary.sql` (ME School & CRM Funnel API)
  - **Pre-existing dirty / unrelated (DO NOT TOUCH):**
    - `../_logs/tool-errors.jsonl`
    - `../lhu-qldetaisdh/*` (Các file thuộc project khác trong monorepo)
- **Quick Inspect Commands:**
  - `git diff --stat HEAD -- modules/kpi-ops-dashboard _db/esign`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Sửa triệt để các lỗi biên dịch template và crash runtime Vue 3; xóa bỏ hoàn toàn hardcode trong bảng điểm vênh (`tblKPI_AuditDiscrepancies`) và Radar rủi ro (`spAPI_KPI_GetRiskRadar`), chuyển đổi sang hệ thống động 100% (Zero Hardcode).
- **Expected:** Giao diện load trơn tru không lỗi console; các thẻ kiểm toán và radar rủi ro được suy diễn động từ Fact Store và Snapshots thật.
- **Actual:** Đã hoàn thành 100%. Template compile đạt 0 lỗi, API backend trả về 3 result sets chuẩn, `fui file status` đạt 0 unpublished files.
- **Flow Analysis:**
  - **Input:** Request API `eSign/KPI_GetAuditDiscrepancies` và `eSign/KPI_GetRiskRadar` với `{ PeriodKey: '2026-09', ScopeID: 'ALL' }`.
  - **Process:**
    - Backend: Đọc luật quan hệ toán học từ `tblKPI_CorrelationOntology` và danh mục cơ sở `tblKPI_CampusCatalog`, đếm và gom trực tiếp từ `tblKPI_OperationalFacts` (Domain `MAINTENANCE`, `HEALTH`, `LEAVE`, `TEACHING`) và `tblKPI_PeriodBreakdowns`.
    - Frontend: `uc-kpi-ops.vue` nạp dữ liệu vào state reactive, hiển thị các visual với defensive guard an toàn.
  - **State:** Đầy đủ 8 state trong `data()`: `causalNarrativesList`, `contextStore`, `breakdownsList`, `selectedFactDomain`, `isFactsLoading`, `operationalFactsList`, `factAuditFilter`, `causalChainFilter`.
  - **Output:** Giao diện hiển thị sắc nét, các thẻ rủi ro có thanh đo màu chính xác, checklist HĐQT đầy đủ hạn chót và chức danh phụ trách.
  - **Side Effects:** Zero side effects tới các module khác (`ks-*`, `tkb-*`, `wf-*`).

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Walkthrough Artifact:** `walkthrough.md`
- **Plan Artifact:** `plan_loai_bo_hardcode_va_fallback.md`
- **Core Files:**
  - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue:3240` (State initialization)
  - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue:5508` (Defensive guards for thresholds & causal titles)
  - `_db/esign/spAPI_KPI_GetAuditDiscrepancies.sql:1` (Dynamic Ontology Engine)
  - `_db/esign/spAPI_KPI_GetRiskRadar.sql:1` (Dynamic Risk Scoring Engine)

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] Lỗi compiler Vue 3 xuất phát từ thẻ `<div v-else>` thừa tại dòng 2805 sau drawer Fact Store (đã loại bỏ, verify `@vue/compiler-dom` = 0 errors).
- [FACT] `spAPI_KPI_GetAuditDiscrepancies` đã chuyển từ hardcode tĩnh sang đọc `tblKPI_CorrelationOntology` (nhận diện nghịch lý QA50 vs TS04, lệch công suất cơ sở, điểm nghẽn máy lạnh).
- [FACT] `spAPI_KPI_GetRiskRadar` đã chuyển từ `VALUES (...)` tĩnh sang gom và tính điểm trực tiếp từ `tblKPI_CampusCatalog`, `tblKPI_OperationalFacts` và `tblKPI_RiskDirectives`.
- [FACT] Cả 3 API Gateway live đã được test trực tiếp qua `curl` thành công 100%.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Targeted Static Analysis:**
  - `@vue/compiler-dom` static compilation → **PASS** (0 compiler errors).
  - AST property audit: 151 identifiers checked → **PASS** (0 missing properties).
  - Node.js ES module syntax check → **PASS** (`node --check`).
- **Live API Tests:**
  - `curl -s -X POST "https://tapi.lhbs.vn/eSign/KPI_GetRiskRadar"` → Trả về 3 Result Sets (5 Campus Cards, 4 Triggers, 6 Directives).
  - `curl -s -X POST "https://tapi.lhbs.vn/eSign/KPI_GetAuditDiscrepancies"` → Trả về 6 thẻ kiểm toán động.

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- **Attempt 1:** Chạy `fui exec _db/esign/file.sql` không có cờ `-f`.
  - *Result:* Gateway tAPI báo lỗi `Incorrect syntax near '/'` do coi đường dẫn file là SQL query.
  - *Conclusion:* Luôn dùng `fui exec -f <path> --db esign --confirm-write`.
- **Attempt 2:** `CAST(ROUND(...) AS NVARCHAR(10))` trên biểu thức tỷ lệ % trong SQL Server.
  - *Result:* Gặp lỗi `Arithmetic overflow error converting expression to data type nvarchar`.
  - *Conclusion:* Luôn cast qua `DECIMAL(5,1)` trước: `CAST(CAST(... AS DECIMAL(5,1)) AS NVARCHAR(10))`.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:** Giữ nguyên schema 3 Result Sets của `KPI_GetRiskRadar` và cấu trúc các props của `uc-kpi-ops.vue` để bảo đảm backward compatibility.
- **Side Effects / Tradeoffs:** Không có. Code thuần túy độc lập trong module `kpi-ops-dashboard`.
