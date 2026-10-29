# AGENT HANDOFF: lhbs-esign

- **Generated At:** 2026-10-29T17:18:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhbs-esign`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục theo dõi phản hồi thực tế từ ban lãnh đạo khi trải nghiệm Heatmap Grid 60 KPI, Dumbbell Variance Chart và luồng đối soát Fact Store 1-1; tối ưu hóa thêm các filter đa chiều (nếu ban giám hiệu yêu cầu bổ sung slice theo từng khối lớp hoặc phòng ban).

## 1. NEXT SESSION ACTION PLAN
1. Mở dashboard trên môi trường web test/production, kiểm tra các thao tác chuyển đổi view:
   - Tab 3 (Danh mục 60 KPI): Chuyển đổi giữa `[Lưới Ô Nhiệt]` (Heatmap Grid) và `[Dạng Bảng]` (Table), hover xem tooltip và click từng ô để mở Fact Modal tương ứng.
   - Tab 2 (Kiểm toán & Đối soát): Chuyển đổi giữa `[Biểu Đồ Độ Lệch]` (Dumbbell Gap Chart), `[Dạng Thẻ]` và `[Dạng Bảng]`.
   - Tab 0 (Điều hành tổng thể): Xác nhận hiển thị 4 Trụ Cột Doanh Nghiệp Cân Bằng, Funnel Tuyển Sinh CRM 4 tầng và Cơ cấu Doanh thu Dịch vụ FTS.
2. Kiểm tra Modal Fact Store: click xem fact của từng tiêu chí bất kỳ (TS01, TS02, TS04, CM08, DV28, TC52...) để đảm bảo 100% hiển thị đúng dữ liệu domain/kpi tương ứng, không bị lẫn lộn giữa Sĩ số/Công suất và Rút học.

## 2. SUGGESTED SKILLS
- `test-before-patch`: Sử dụng khi cần kiểm tra các SP mới hoặc query dữ liệu fact trước khi cập nhật.
- `context-mode`: Luôn sử dụng `ctx_execute` / `ctx_execute_file` để thao tác và phân tích SFC hoặc SP SQL.
- `clean-stage-commit-push`: Sử dụng khi kết thúc session để đảm bảo git hygiene.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `c8adeff` — refactor(lhbs-esign): streamline KPI Ops Dashboard, isolate frozen period data and preserve Impact Zone
  - `84b3b05` — feat(lhbs-esign): dynamic data-driven KPI Ops Dashboard and fix tab rendering
- **Working Tree Ownership:**
  - **Current task changes to commit:**
    - `.md/lessons.md` (Ghi nhận bài học về Fact Store mapping và FUI whitespace normalization)
    - `.handoff/HANDOFF.md` (Universal Agent Handoff tài liệu chuyển giao)
    - `_db/esign/schema.json` (Cập nhật schema CSDL)
    - `_db/esign/spAPI_KPI_GetOperationalFacts.sql` (Root cause fix cho fact store mismatch: tách ENROLLMENT vs WITHDRAWAL, direct 60 KPI routing)
    - `_db/esign/spAPI_KPI_GetRiskRadar.sql` (Cập nhật dữ liệu Radar Rủi ro)
    - `_db/esign/spAPI_KPI_GetPeriodSnapshots.sql` (Đồng bộ snapshot chu kỳ)
    - `_db/esign/spAPI_KPI_GetStrategicLevers.sql` (Đòn bẩy chiến lược)
    - `_db/esign/spAPI_KPI_GetOperationsSummary.sql` (Tổng quan vận hành)
    - `_db/esign/spAPI_KPI_GetAuditDiscrepancies.sql` (Đối soát dữ liệu kiểm toán)
    - `_db/esign/spAPI_KPI_FreezePeriodData.sql` (Đóng băng chu kỳ dữ liệu)
    - `_db/esign/migration_kpi_audit_rules_engine.sql` (Migration engine luật kiểm toán)
    - `_db/esign/migration_seed_bus_withdrawal_facts.sql` (Migration seed bus/rút học)
    - `_db/esign/migration_seed_full_60_kpis_snapshots.sql` (Migration seed 60 KPI snapshots)
    - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue` (Cockpit điều hành 4 trụ cột, Funnel Tuyển sinh, FTS Stacked Bar, Heatmap Grid 60 KPI, Dumbbell Gap Chart, Fact Modal context banner)
    - `modules/kpi-ops-dashboard/style.css` (Style Heatmap Grid, Dumbbell Chart, Funnel, FTS Bar, Top-line scorecard)
  - **Pre-existing dirty / unrelated (DO NOT TOUCH):**
    - `../lhu-qldetaisdh/*` (Phân hệ thuộc dự án khác)
    - `../_logs/tool-errors.jsonl` (File log shared của CLI tool)

## 4. PROBLEM & SYSTEM FLOW
- **Objective:**
  1. Khắc phục lỗi sai dữ liệu Fact Store (xem fact tiêu chí A ra dữ liệu tiêu chí B).
  2. Nâng cấp Tab 0 từ góc nhìn micro-ops local thành Executive Cockpit toàn diện của toàn bộ doanh nghiệp.
  3. Thay thế các bảng số liệu tĩnh (Table) bằng các dạng trực quan hóa chuyên dụng (Heatmap Grid 60 KPI, Dumbbell Gap Chart).
  4. Xác nhận trạng thái publish và đảm bảo đồng bộ hoàn toàn với server FUI.
- **Expected:**
  - Fact modal hiển thị chính xác 1-1 dữ liệu của KPI đang xem kèm banner context nhận diện tiêu chí, phân tách rõ Sĩ số/Công suất (Basic Data) và Rút học (SIS).
  - Tab 0 thể hiện bức tranh vĩ mô: 4 Trụ Cột Doanh Nghiệp (Tài chính, Lấp đầy, Học thuật, An toàn), Funnel Tuyển Sinh CRM 4 tầng, Cơ cấu Doanh thu Dịch vụ FTS và Value Bridge 4.076 tỷ.
  - Tab 3 hiển thị Heatmap Grid 60 ô trực quan; Tab 2 hiển thị Dumbbell Gap Chart độ lệch giữa Báo cáo và Fact Store.
  - Đã publish 100% lên server FUI, 0 unpublished files, 0 error.
- **Actual:** Hoàn thành 100%, đã test, build, deploy SP, publish component/css và verify normalized diff trùng khớp 100%.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Code Locations:**
  - `_db/esign/spAPI_KPI_GetOperationalFacts.sql`: Tuyến phân luồng dữ liệu fact store 60 KPI.
  - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue`: Logic Vue, Heatmap, Dumbbell, Funnel, Fact Modal.
  - `modules/kpi-ops-dashboard/style.css`: CSS responsive, color scales, animation cho biểu đồ.

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] `spAPI_KPI_GetOperationalFacts` trước đây gom toàn bộ học sinh vào domain `WITHDRAWAL`, gây lỗi xem Sĩ số/Lớp học nhưng chỉ hiển thị 21 học sinh rút học.
- [FACT] Bổ sung domain `ENROLLMENT` truy vấn `tblKPI_Snap_BasicData_Students` (`RecordType != 'WITHDRAWAL'`) trả về chính xác 1,324 học sinh / 1,600 chỗ (82.8% lấp đầy).
- [FACT] `fui module check -p lhbs-esign -m kpi-ops-dashboard` và `fui file status` xác nhận 0 unpublished files, mã hash trùng khớp 100% với server FUI.
- [FACT] FUI CLI tự động normalize loại bỏ dòng trắng đầu file `style.css` khi push lên server.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Verification Runs:**
  - `fui sp verify spAPI_KPI_GetOperationalFacts`: PASS (SP hợp lệ, đã triển khai trên DB eSignature).
  - `fui module check -p lhbs-esign -m kpi-ops-dashboard`: PASS (0 errors, 0 warnings).
  - `fui file status`: PASS (`0 unpublished file(s)`).
  - `fui remote diff -p lhbs-esign -m kpi-ops-dashboard`: PASS (Normalized content matches 100%).

## 8. CONSTRAINTS & RISKS
- CSDL eSignature và contracts tAPI được bảo toàn tuyệt đối.
- Tuyệt đối không can thiệp hoặc stage các file thuộc `lhu-qldetaisdh`.
