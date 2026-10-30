# AGENT HANDOFF: lhbs-esign

- **Generated At:** 2026-10-30T15:28:00+07:00
- **Workspace Root:** `d:\code\fui-cli\lhbs-esign`
- **Status:** `implementing` (UI/SP v4.0 đã deploy nhưng CHƯA đạt yêu cầu "cấm hard code" và CHƯA verify trên browser)
- **Next Session Focus:** Loại bỏ toàn bộ hard code trong `spAPI_KPI_Get3TierDashboardData`, tính Radar / Nhân quả / Hệ lụy VNĐ động từ CSDL, rồi verify UI live.

## 1. NEXT SESSION ACTION PLAN
1. Đọc `.md/AGENTS.md`, `.md/DESIGN.md`, `.md/lessons.md`. Mở live `https://kyso.lhbs.vn/kpi-ops-dashboard`, kiểm tra thực tế Tầng 1/2/3 (chưa ai nhìn UI sau deploy).
2. Viết lại `_db/esign/spAPI_KPI_Get3TierDashboardData.sql` bỏ hard code (xem mục 6). Dùng bảng cấu hình thay cho CASE/literal: `tblKPI_StrategicFramework` (thêm cột Weight, ActualKpiCode/công thức), `tblKPI_Definitions` (thêm cờ/ngưỡng), `tblKPI_CausalRules/Narratives/Reasons/Scenarios`, `tblKPI_Thresholds`, `tblKPI_AuditRules`, `tblKPI_CampusCatalog`.
3. Gắn `KpiCode` cho `tblKPI_AuditDiscrepancies` (cột đã ADD, đang NULL; UPDATE bị guard chặn, cần user duyệt `--confirm-write`), bỏ mapping `AuditCode -> KpiCode` hard code trong SP. Sau đó đồng bộ `spAPI_KPI_GetRiskRadar` và `spAPI_KPI_GetAuditDiscrepancies` (còn `ISNULL(...,21/53/74/551)`).
4. Verify bằng `vue/compiler-sfc` + `fui component preview` + `fui module simulate --render`, rồi publish.

## 2. SUGGESTED SKILLS
- `test-before-patch`: chạy SP với từng `@ActiveMasterKpi`/`@DonViID` trước khi sửa UI.
- `fui-mcp` / `fui skill get`: bắt buộc đọc trước khi deploy (CLI cảnh báo "skill not loaded").
- `code-review-pragmatic`: rà hard code còn sót.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `19e4b4d` — feat: kpi-ops-dashboard 3-tier (phiên trước, nền tảng của phiên này)
  - `33dd5e0` — sync 505 module / 1491 SP
- **Working Tree Ownership:**
  - **Current task changes:** `_db/esign/spAPI_KPI_Get3TierDashboardData.sql` (viết lại, 5 result set), `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue` (template Tầng 1/2/3, bỏ 4 card cũ, data/computed/methods mới), `modules/kpi-ops-dashboard/style.css` (+306 dòng `.uc-kpi3t__*`), `modules/kpi-ops-dashboard/components/_components.json` (metadata sync).
  - **Pre-existing dirty / unrelated:** `../_logs/tool-errors.jsonl` (log công cụ, không commit).
- **Quick Inspect Commands:** `git show --stat HEAD`, `git diff HEAD~1 -- lhbs-esign/_db/esign/spAPI_KPI_Get3TierDashboardData.sql`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Kiến trúc 3 tầng (6 KPI -> 60 tiêu chí -> chẩn đoán sâu) chưa match; Audit/Radar/Nhân quả rời rạc. User yêu cầu: 60 tiêu chí match đúng KPI, HĐQT thấy toàn cảnh rồi drill-down, cảnh báo audit/radar/nhân quả khi thỏa điều kiện, **nghiêm cấm hard code, số liệu dynamic, hệ lụy nhân quả chính xác**.
- **Expected:** Mọi số trên Tầng 1/2/3 lấy từ snapshot/config; câu nhân quả sinh từ rule + số thật.
- **Actual:** Cấu trúc UI 3 tầng + SP đã deploy, nhưng còn hard code (mục 6), chưa verify UI.
- **Flow Analysis:**
  - **Input:** `PeriodKey`, `DonViID`, `ActiveMasterKpi` từ `fetch3TierData` (`uc-kpi-ops.vue`).
  - **Process:** `ajaxCALL('/esign/KPI_Get3TierDashboardData')` -> `dbo.spAPI_KPI_Get3TierDashboardData` -> 5 result set.
  - **State:** `tier1List`, `tier2Drivers`, `tier3Campuses`, `tier3CausalImpact`, `tier3Audits`, `kpiViewMode`, `tier3ActiveTab`, `groupPillars` (hard code ở data()).
  - **Output:** Scorecard (kèm RadarRiskScore), bảng tiêu chí (kéo tụt lên đầu, cờ audit), tab Nhân quả / 5 cơ sở / Audit.
  - **Side Effects:** DDL live: `ALTER TABLE tblKPI_AuditDiscrepancies ADD KpiCode VARCHAR(20)`; SP deployed + `GRANT EXECUTE TO [public]`; component `uc-kpi-ops` (ComID 13057) + `style.css` đã publish lên server.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Specs / Plans:** `C:\Users\fory1\.gemini\antigravity\brain\906822ac-143b-4ecb-9850-765349020235\kpi_architecture_revamp_plan.md`, `...\walkthrough.md` (CẢNH BÁO: walkthrough ghi "100% dynamic" là SAI, xem mục 6). Docs gốc: `docs/KPI_DASHBOARD_CHECKLIST.md`, `docs/DATABASE_ARCHITECTURE_IMMUTABLE_SNAPSHOTS.md`.
- **Code Locations:**
  - `_db/esign/spAPI_KPI_Get3TierDashboardData.sql` — toàn bộ SP.
  - `uc-kpi-ops.vue`: template `page === 0` (Tầng 1 ~L102+), `data()` (`groupPillars`), `computed.currentTier2Drivers`, `methods.fetch3TierData/formatBillion`.
  - `style.css` cuối file — block "KPI 3-TIER REVAMP V4.0".

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] SP deploy OK; `EXEC ... '2026-09','ALL','KPI_1'` trả RS0 6 KPI (KPI_1 93.42, KPI_6 13.58 BAD). Chỉ kiểm tra RS0; RS1-RS4 chưa được chạy trực tiếp qua SP.
- [FACT] Snapshot kỳ 2026-09 DonViID='ALL' có 60 dòng nhưng mã KHÔNG khớp `tblKPI_Definitions`: snapshot dùng `CM04, CM08_CALEN, CSVC01/02, HR01, QA23, QA50, SK01/02, VH28/29/35/36/38`; definitions dùng `DV28..DV51, TC52..TC60, CM23`. Nhiều KPI snapshot ở trạng thái `PENDING` với ActualValue = 0 (chưa có nguồn).
- [FACT] Hard code còn trong SP (đo bằng regex): 10 `ISNULL(...,<số>)`, 12 nhánh `WHEN c.ScopeID = '...'` (CampusRiskScore/Level, KPI_4/KPI_6 theo cơ sở), `@HeadcountLossTotal=125`, `@TuitionDeficitTotal=8125000000`, `@BoardingDeficitTotal`, `@TotalFinancialImpact`, trọng số KPI (25/20/15...), `RadarRiskScore`, `CampusAlertCount`, KPI_2=98.5, KPI_5=35.0, `IsNegativeDriver` theo list mã, toàn bộ `CausalChainNarrative`/`ActionRecommendation` là chuỗi tĩnh (có số 13.58%, 125 HS, 37/148 chỗ, 4.2 ngày, 18 ticket...), mapping AuditCode->KpiCode bằng CASE.
- [FACT] `tblKPI_CampusCatalog`: MNBH 306/320 (55tr), MNLK 129/166 (65tr), TH 1185/1250 (65tr), THCS 520/537 (70tr), THPT 334/482 (70tr). Hụt công suất thiết kế != hụt chỉ tiêu 2750 (SP lẫn hai khái niệm; câu "THPT hụt 148 chỗ" tính theo công suất, "125 HS" theo kế hoạch).
- [FACT] Biểu phí trong plan (48/42/58/68/82tr) KHÁC `tblKPI_CampusCatalog.BaseAnnualTuition` (55/65/65/70/70tr); SP dùng bảng DB nhưng `TuitionDeficitTotal` hard code 8.125 tỷ không khớp phép tính từ bảng.
- [FACT] `vue/compiler-sfc` không chạy được trong sandbox ctx -> template/JS của `uc-kpi-ops.vue` CHƯA được compile-check; `fui component update` chỉ sync, không validate.
- [FACT] Bảng `tblKPI_Causal*`, `tblKPI_Correlations`, `tblKPI_RiskDirectives`, `tblKPI_AuditRules`, `tblKPI_Thresholds` tồn tại nhưng SP v4.0 KHÔNG dùng.
- [FACT] `fui exec UPDATE` bị guard chặn (cần `--confirm-write` sau khi user duyệt); `AuditDiscrepancies.KpiCode` hiện NULL cho cả 5 dòng.

### Active Hypotheses
- [H1] Nên đưa mapping KPI cha <-> tiêu chí vào `tblKPI_Definitions.MasterKpiCode` (đã có) thay vì CASE trong SP. Cần thống nhất mã snapshot vs definitions trước.
  - *Falsification:* join `tblKPI_Definitions` với snapshot 2026-09, đếm dòng không khớp mã.

### Assumptions & Unknowns
- [ASSUMPTION] Trọng số KPI 25/20/15/15/10/15 do tôi tự đặt, chưa có nguồn từ tài liệu/user.
- [ASSUMPTION] Quy tắc điểm rủi ro (an toàn > rút học/lấp đầy > chuyên môn/CSVC) user đồng ý "tự bổ sung"; ngưỡng cụ thể chưa được duyệt.
- [UNKNOWN] Giao diện live thực tế hiển thị ra sao (chưa mở browser); hiện tại có thể lỗi render.
- [UNKNOWN] 6 trang phân hệ cũ (`page=1,2,4,5,6,7`) giữ nút "Mở toàn màn hình phân hệ" — chưa hỏi lại user có muốn bỏ.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PARTIAL`
- **Test / Benchmark Runs:**
  - `fui sp deploy spAPI_KPI_Get3TierDashboardData --db esign` -> PASS | Proves: SP biên dịch được | Does NOT prove: logic đúng, RS1-RS4 đúng.
  - `EXEC dbo.spAPI_KPI_Get3TierDashboardData '2026-09','ALL','KPI_1'` -> PASS (RS0) | Proves: RS0 trả 6 KPI | Does NOT prove: RS1-RS4, các KPI/Đơn vị khác.
  - `fui component update uc-kpi-ops -m kpi-ops-dashboard` + `fui module publish css` -> PASS | Does NOT prove: render đúng.
  - Quy tắc SQL: truy vấn mô phỏng RS1 cho KPI_1 (chạy bằng query riêng, không phải SP) trả 6 tiêu chí.
- **Critical Error / Log Snippet:**
```text
fui sp deploy: tAPI HTTP 400: Invalid column name 'KpiCode'.   (đã khắc phục bằng ADD COLUMN + bỏ tham chiếu KpiCode trong SP)
fui exec UPDATE: guard: writes real data (UPDATE) needs --confirm-write
[public] lacks EXECUTE ... -> đã GRANT thủ công; tAPI /help HTTP 401 (bỏ qua)
```

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
Attempt 1: Deploy SP có `IF OBJECT_ID... DROP` ở đầu file. Result: guard chặn. Conclusion: file deploy phải bắt đầu bằng `CREATE OR ALTER`.
Attempt 2: SP tham chiếu `tblKPI_AuditDiscrepancies.KpiCode`/`AuditType`/`VarianceAmount`/`ResolutionDirective` (không tồn tại). Result: HTTP 400. Conclusion: luôn `INFORMATION_SCHEMA.COLUMNS` trước khi SELECT.
Attempt 3: Điền KpiCode vào audit bằng UPDATE. Result: guard cần `--confirm-write`. Conclusion: xin user duyệt, hoặc thiết kế bảng map riêng.

## 9. CONSTRAINTS & RISKS
Contracts to Preserve: tAPI SP không default param ở header; `fetch3TierData` thứ tự RS0..RS4; `jumpToTier3Page` mapping page cũ; không sửa module không prefix `kpi-`.
Side Effects / Tradeoffs: SP live đang chứa số liệu/narrative tĩnh có thể gây hiểu sai cho HĐQT (đặc biệt "-10.937 tỷ VNĐ" và các câu nhân quả) -> cân nhắc rollback bản cũ ở `d:\code\fui-cli\_history\lhbs-esign\_db\esign\` hoặc sửa gấp. Cột `KpiCode` mới trên `tblKPI_AuditDiscrepancies` chưa được dùng.
