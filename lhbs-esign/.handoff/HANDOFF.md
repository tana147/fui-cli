# AGENT HANDOFF: lhbs-esign

- **Generated At:** 2026-10-30T17:14:30+07:00
- **Workspace Root:** `d:\code\fui-cli\lhbs-esign`
- **Status:** `done`
- **Next Session Focus:** Kiểm thử thực tế trên trình duyệt (`https://kyso.lhbs.vn/kpi-ops-dashboard`) toàn bộ Cockpit 3 Tầng, 3 Tab HĐQT (`Khung 60 KPI`, `Radar Rủi ro`, `Kiểm toán`) và 6 Phân hệ chuyên sâu sau nâng cấp True Visual Chart Cockpit (Option A).

## 1. NEXT SESSION ACTION PLAN
1. Mở `https://kyso.lhbs.vn/kpi-ops-dashboard` kiểm tra tương tác bấm chọn `KPI 1`..`KPI 6` ở Tầng 1 và xác nhận Tầng 2 + Tầng 3 (`1. Radar & 5 Cơ Sở`, `2. Chuỗi Nhân Quả`, `3. Độ Vênh Kiểm Toán`) cập nhật đồng bộ.
2. Kiểm tra trực quan 3 Tab HĐQT (`Khung 60 KPI` 4-Pillar Board, `Radar Rủi ro` 5-Campus + SVG Radar, `Kiểm toán` Dumbbell Workbench) và 6 Phân hệ chuyên sâu (`Sĩ số`, `Rút học`, `LMS`, `CLB`, `Y tế`, `CRM`) ở cả 2 chế độ `Biểu đồ` và `Bảng chi tiết`.
3. Khi Giai đoạn 2 có bảng dữ liệu vận hành mới trên `esign` (ví dụ khảo sát PHHS/CSAT, tỷ lệ sử dụng phòng chức năng), bổ sung nguồn tính động vào `_db/esign/spAPI_KPI_Get3TierDashboardData.sql` thay cho trạng thái `PENDING_API`.

## 2. SUGGESTED SKILLS
- `ux-ui-upgrade-review`: Dùng khi cần tinh chỉnh thêm chi tiết hiển thị hoặc mật độ thông tin sau khi user trải nghiệm thực tế trên trình duyệt.
- `bug-root-cause-analysis`: Dùng nếu phát hiện lệch số liệu hoặc lỗi tương tác ở bất kỳ phân hệ nào.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `9ed4576` — `feat(lhbs-esign): restructure kpi-ops-dashboard 3-tier UI with in-context diagnostic panel (WIP, partially hardcoded)`
  - `19e4b4d` — `feat(lhbs-esign): upgrade kpi-ops-dashboard to 3-tier architecture with strategic scorecard and deep-dive drilldown`
  - `32e0376` — `feat(lhbs-esign): enterprise executive cockpit, 60 kpi heatmap grid, dumbbell variance chart and 1-1 fact reconciliation`
- **Working Tree Ownership:**
  - **Current task changes:**
    - `_db/esign/spAPI_KPI_Get3TierDashboardData.sql` (SP v5.0: loại bỏ hardcode trong RS2/RS3/RS4, bổ sung `CampusActualValue`, `CampusTargetValue`, `CampusMetricUnit`, `CampusKpiInsight` động theo `@ActiveMasterKpi`)
    - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue` (Nâng cấp Option A True Visual Chart Cockpit cho `COMMAND`, `RISK`, `AUDIT`, `FRAMEWORK` và `page === 1, 2, 4, 5, 6, 7`)
    - `modules/kpi-ops-dashboard/style.css` (Hệ thống CSS `.uc-kpi3t__*` cho Cockpit 3 Tầng, SVG Radar, Bullet Chart, Dumbbell Chart, 4-Pillar Board và 6 phân hệ)
  - **Pre-existing dirty / unrelated:** `../_logs/tool-errors.jsonl` (File log hệ thống ngoài thư mục `lhbs-esign` — DO NOT commit)
  - **Unknown ownership:** `None`
- **Quick Inspect Commands:**
  - `git show --stat HEAD`
  - `git diff HEAD~1 -- modules/kpi-ops-dashboard/ _db/esign/spAPI_KPI_Get3TierDashboardData.sql`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Loại bỏ hoàn toàn dữ liệu hardcode trong Stored Procedure `spAPI_KPI_Get3TierDashboardData` và nâng cấp toàn bộ giao diện `kpi-ops-dashboard` (Cockpit 3 Tầng, 3 Tab HĐQT, 6 Phân hệ chuyên sâu) từ bố cục nhiều bảng chữ/box lặp sang kiến trúc **True Visual Chart Cockpit (Option A)**.
- **Expected:**
  - Dữ liệu Tầng 1, Tầng 2, Tầng 3 (Radar 5 cơ sở, Chuỗi nhân quả 3 nút, Độ vênh kiểm toán, 4 thẻ hệ lụy tài chính VNĐ) được tính toán 100% từ CSDL `esign` theo kỳ báo cáo, cơ sở và `@ActiveMasterKpi`.
  - Khi chọn `KPI 1`..`KPI 6` ở Tầng 1, cả Tầng 2 lẫn Tầng 3 Tab 1 (`1. Radar & 5 Cơ Sở`) đổi trục Radar nhấn mạnh, đổi số liệu thực tế/chỉ tiêu của 5 cơ sở theo đúng miền KPI và tự động focus vào cơ sở có rủi ro cao nhất của miền đó.
  - Các tab `Khung 60 KPI`, `Radar Rủi ro`, `Kiểm toán` và `page === 1, 2, 4, 5, 6, 7` ưu tiên biểu đồ trực quan (`Bullet`, `SVG Radar`, `Dumbbell`, `4-Pillar Board`, `Stacked Bar`), đẩy bảng chi tiết vào chế độ toggle.
- **Actual:** Đã hoàn tất, deploy SP lên `esign`, publish component + CSS qua `fui-mcp`, và pass `module_validate`.
- **Flow Analysis:**
  - **Input:** Bộ lọc kỳ (`selectedMonth`, `selectedSchoolYear`), cấp học/cơ sở (`selectedGradeLevel`), KPI chiến lược đang chọn (`activeTier1Kpi` = `KPI_1`..`KPI_6`), tab điều hành (`executiveTab`) và phân hệ (`page`).
  - **Process:** `uc-kpi-ops.vue:selectTier1Kpi` / `fetch3TierDashboard` → gọi `spAPI_KPI_Get3TierDashboardData` trên DB `esign` → trả về 5 Result Sets (`RS0`..`RS4`) → mapper trong `uc-kpi-ops.vue` chuẩn hóa vào `dbTier1Cards`, `dbTier2Drivers`, `dbCampusRiskRows`, `dbCausalLoops`, `dbAuditDiscrepancies`, `dbImpactSummary`.
  - **State:** Reactive state trong `uc-kpi-ops.vue` (`activeTier1Kpi`, `selectedTier2MetricCode`, `selectedRadarCampusCode`, `tier3ActiveTab`, `frameworkViewMode`, `subPageViewMode`).
  - **Output:** Giao diện Cockpit trực quan (SVG Sparkline, Horizontal Bullet Chart, SVG 4-Axis Radar Polygon, 5-Campus Comparative Bars, SVG 3-Node Causal Flow, Normalized Dumbbell Chart, 4-Pillar 60-KPI Board).
  - **Side Effects:** SP đã được deploy trực tiếp lên CSDL `esign`; `uc-kpi-ops.vue` (ComID `13057`) và `style.css` đã được publish lên server qua `fui-mcp`.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Specs / Plans / Issues / ADRs:**
  - `.md/AGENTS.md`
  - `.md/DESIGN.md`
  - `.md/lessons.md`
- **Code Locations:**
  - `_db/esign/spAPI_KPI_Get3TierDashboardData.sql:1-695` (`spAPI_KPI_Get3TierDashboardData`) — Stored Procedure trả về 5 Result Sets động hoàn toàn từ `KPI_Results_Framework_Metric_Catalog`, `KPI_Fact_Enrollment_Grade_Snapshot`, `KPI_Fact_Admission_CRM_Monthly`, `KPI_Fact_Service_Boarding_Monthly`, `KPI_Fact_Club_Revenue_Monthly`, `KPI_Fact_Operational_Snapshot`, `KPI_Action_Governance_Log`.
  - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue:120-803` (`executiveTab === 'COMMAND'`) — Cockpit 3 Tầng (Tầng 1 SVG Sparkline, Tầng 2 Bullet Chart + Focus Bar, Tầng 3 SVG Radar + 5 Cơ sở + SVG Nhân quả + Dumbbell Audit).
  - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue:805-1984` (`RISK`, `AUDIT`, `FRAMEWORK`) — 3 Tab điều hành HĐQT đã nâng cấp sang Visual Workbench & 4-Pillar Board.
  - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue:1986-2720` (`page === 1, 2, 4, 5, 6, 7`) — 6 Phân hệ chuyên sâu chuẩn hóa theo bố cục 4-Card Impact Strip + 2-Column Visual Chart Workbench.
  - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue:3450-3560` (`activeRadarAxisMeta`, `getCampusBarWidthPct`, `getCampusBarToneClass`, `getCampusSubMetricText`) — Logic đồng bộ Tầng 3 Tab 1 (`1. Radar & 5 Cơ Sở`) khi chọn `KPI_1`..`KPI_6` ở Tầng 1.
  - `modules/kpi-ops-dashboard/style.css:1850-3030` (`.uc-kpi3t__*`) — Toàn bộ hệ thống class CSS của kiến trúc Cockpit mới.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] `spAPI_KPI_Get3TierDashboardData` đã được deploy và thực thi thành công trên DB `esign` cho cả 6 giá trị `@ActiveMasterKpi` (`KPI_1`..`KPI_6`), trả về đầy đủ `CampusActualValue`, `CampusTargetValue`, `CampusMetricUnit`, `CampusKpiInsight` ở Result Set 2 (Evidence: `fui-mcp/db_sp_deploy` & `fui-mcp/db_sql_execute`).
- [FACT] `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue` cân bằng thẻ tuyệt đối (`div`: 737/737, `svg`: 8/8, `table`: 16/16, `template`: 2/2), pass kiểm tra cú pháp `<script>` và 81/81 class `.uc-kpi3t__*` đều có trong `style.css` (Evidence: `context-mode/ctx_execute` verification script).
- [FACT] `uc-kpi-ops` (ComID `13057`) và `style.css` đã được đồng bộ sang `D:\code\FUI-MCP\lhbs-esign` và publish/validate thành công qua `fui-mcp/component_update`, `fui-mcp/module_publish_css`, `fui-mcp/module_validate`.

### Active Hypotheses
- `None`

### Assumptions & Unknowns
- [ASSUMPTION] Đơn giá bình quân năm học dùng để ước tính hệ lụy tài chính trong SP (`spAPI_KPI_Get3TierDashboardData`) được suy dẫn từ cấu hình học phí/bán trú hiện hành trong bảng Fact.
- [UNKNOWN] Các chỉ số Giai đoạn 2 chưa có bảng Fact trên `esign` (như CSAT phụ huynh tự động, sử dụng phòng chức năng) vẫn giữ trạng thái `PENDING_API` cho đến khi có bảng nguồn mới.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `EXEC dbo.spAPI_KPI_Get3TierDashboardData @SchoolYear='2026-2027', @Month=9, @CampusCode='ALL', @ActiveMasterKpi='KPI_1'..'KPI_6'` → **Result:** `PASS` (5 Result Sets trả về đúng cấu trúc và biến thiên theo từng KPI) | **Proves:** SP hoạt động động 100% trên DB `esign` | **Does NOT prove:** Tương tác chuột thực tế trên trình duyệt.
  - `node_tag_and_syntax_check (ctx_execute)` → **Result:** `PASS` (`div` 737/737, `svg` 8/8, `missingClasses: []`) | **Proves:** Không lỗi thẻ đóng/mở HTML, không lỗi cú pháp JS, đủ CSS class | **Does NOT prove:** Visual pixel rendering trên màn hình nhỏ.
  - `fui-mcp/module_validate (kpi-ops-dashboard)` → **Result:** `PASS` (`module.json hợp lệ — không phát hiện lỗi ngữ nghĩa`) | **Proves:** Module hợp lệ trên hệ thống FUI | **Does NOT prove:** Trải nghiệm người dùng cuối.
- **Critical Error / Log Snippet:**
```text
None
```

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- **Attempt 1:** Cố định cột 5 cơ sở ở Tầng 3 Tab 1 (`1. Radar & 5 Cơ Sở`) theo `CurrentEnrollment / PlannedCapacity` (`CapacityRate`).
  - **Result:** Khi user bấm chuyển `KPI 2`..`KPI 6` ở Tầng 1, Tầng 3 Tab 1 không đổi số liệu khiến user tưởng Tầng 3 bị đơ.
  - **Conclusion:** Đã sửa ở cả SP (`CampusActualValue`, `CampusTargetValue`, `CampusMetricUnit`, `CampusKpiInsight`) và Vue (`activeRadarAxisMeta`, `selectTier1Kpi`) để Tầng 3 Tab 1 luôn đổi theo KPI Tầng 1 đang chọn.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:**
  - Giữ nguyên tên và chữ ký tham số của `dbo.spAPI_KPI_Get3TierDashboardData` (`@SchoolYear`, `@Month`, `@CampusCode`, `@ActiveMasterKpi`, `@AutoSnapshot`) và thứ tự 5 Result Sets (`RS0`..`RS4`).
  - Không thêm thẻ `<style>` vào `uc-kpi-ops.vue`; toàn bộ CSS phải đặt trong `modules/kpi-ops-dashboard/style.css`.
  - Mọi thay đổi ở `d:\code\fui-cli\lhbs-esign` phải được copy sang `D:\code\FUI-MCP\lhbs-esign` trước khi gọi tool `fui-mcp`.
- **Side Effects / Tradeoffs:**
  - Chế độ mặc định của các tab đã chuyển sang Visual Chart Workbench; người dùng cần bấm nút `Bảng tra cứu` / `Bảng chi tiết` ở góc phải từng khung nếu muốn xem bảng nhiều cột truyền thống.
