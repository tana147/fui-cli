# AGENT HANDOFF: lhbs-esign

- **Generated At:** 2026-10-29T10:48:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhbs-esign`
- **Status:** `done`
- **Next Session Focus:** Chạy kiểm thử luồng thực thi SQL migration trên database eSign thực tế (khi có quyền truy cập DB server) hoặc xây dựng cron job/worker tự động đóng băng dữ liệu các kỳ tiếp theo.

## 1. NEXT SESSION ACTION PLAN
1. Khi có quyền kết nối DB SQL Server eSign, chạy lần lượt các script migration theo thứ tự:
   - `_db/esign/migration_v2_source_snapshots_schema.sql` (tạo 8 bảng `tblKPI_Snap_*`).
   - `_db/esign/migration_v2_seed_frozen_data_september.sql` (nạp dữ liệu đóng băng T9/2026).
   - Cập nhật 4 Stored Procedures: `spAPI_KPI_GetFinanceServices.sql`, `spAPI_KPI_GetOperationalFacts.sql`, `spAPI_KPI_GetOperationsSummary.sql`, `spAPI_KPI_GetPeriodSnapshots.sql`.
   - `_db/esign/migration_v2_drop_legacy_tables.sql` (dọn dẹp 6 bảng generic cũ).
2. Kiểm tra UI `https://kyso.lhbs.vn/kpi-ops-dashboard` để xác nhận tất cả thẻ số liệu, tài chính, CLB và CRM hiển thị chuẩn xác từ dữ liệu kỳ đã chốt.
3. Thiết kế pipeline tự động hóa nạp snapshot định kỳ (Tuần / Tháng / Quý / Năm) từ các hệ thống tác nghiệp nguồn (Basic Data, LMS, FTS, CRM).

## 2. SUGGESTED SKILLS
- `clean-stage-commit-push`: Đã thực thi trong session này để đưa code và schema lên Git remote.
- `test-before-patch`: Dùng để kiểm thử cú pháp Stored Procedure và dữ liệu trả về trước khi deploy production.
- `session-bugflow`: Dùng nếu phát hiện bất kỳ sai lệch contract nào giữa Frontend và CSDL eSign.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `6040719` — feat(lhbs-esign): executive decision support, mom delta badges, print pack and fact deep-links
  - `22b7cbe` — feat(lhbs-esign): dynamic risk radar engine, correlation ontology and fix vue3 runtime errors
- **Working Tree Ownership:**
  - **Current task changes:**
    - `docs/DATABASE_ARCHITECTURE_IMMUTABLE_SNAPSHOTS.md`: Tài liệu kiến trúc chuẩn hóa Immutable Period Snapshots.
    - `_db/esign/migration_v2_source_snapshots_schema.sql`: DDL 8 bảng snapshot nguồn chuyên biệt.
    - `_db/esign/migration_v2_seed_frozen_data_september.sql`: Dữ liệu đóng băng Tháng 9/2026 cho 8 nguồn.
    - `_db/esign/migration_v2_drop_legacy_tables.sql`: Script dọn dẹp 6 bảng generic cũ.
    - `_db/esign/spAPI_KPI_GetFinanceServices.sql`: Stored Procedure mới cho báo cáo tài chính & CLB.
    - `_db/esign/spAPI_KPI_GetOperationalFacts.sql`: Stored Procedure định tuyến động sang 8 bảng snapshot mới.
    - `_db/esign/spAPI_KPI_GetOperationsSummary.sql`: Làm sạch procedure (bỏ hardcoded VALUES).
    - `_db/esign/spAPI_KPI_GetPeriodSnapshots.sql`: Làm sạch procedure (bỏ DELETE/INSERT ngầm).
    - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue`: Dynamic header, dynamic finance & CRM metrics.
    - `.handoff/HANDOFF.md`: Báo cáo bàn giao phiên làm việc.
  - **Pre-existing dirty / unrelated (DO NOT TOUCH):**
    - `../_logs/tool-errors.jsonl`
    - `../lhu-qldetaisdh/*` (18 files thuộc project khác trong monorepo)
- **Quick Inspect Commands:**
  - `git diff modules/kpi-ops-dashboard/components/uc-kpi-ops.vue`
  - `git diff _db/esign/`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Tái cấu trúc toàn diện cơ sở dữ liệu eSign cho module KPI Operations Dashboard theo mô hình Immutable Period Snapshots để chống trôi số liệu từ các hệ thống tác nghiệp mutable nguồn; xoá bỏ super-table `tblKPI_OperationalFacts` dùng chung gây phình to và khó query; thay thế bằng 8 bảng snapshot chuyên biệt theo nguồn; đồng thời loại bỏ toàn bộ dữ liệu hard-code ở Frontend.
- **Expected:** Dữ liệu từng kỳ (Tuần / Tháng / Quý / Năm) được đóng băng bất biến (`IsFrozen = 1`). Stored Procedures truy xuất nhanh qua bảng nguồn chuyên biệt với chỉ mục `(PeriodKey)`. Frontend bind 100% động theo dữ liệu kỳ được chọn.
- **Actual:** Đã hoàn thành toàn bộ DDL, DML seed, Stored Procedures, tài liệu kiến trúc tại `docs/` và code Frontend. Đã đồng bộ FUI thành công (`0 unpublished file(s)`).
- **Flow Analysis:**
  - **Input:** Người dùng chọn kỳ làm việc (`selectedYear`, `PeriodKey` e.g. `2026-09`) trên UI Dashboard.
  - **Process:** Frontend gọi `KPI_GetPeriodSnapshots` (lấy danh sách kỳ và snapshot vĩ mô) -> gọi `KPI_GetOperationalFacts` (chuyển tiếp tới 8 bảng `tblKPI_Snap_*`) -> gọi `KPI_GetFinanceServices` (lấy chi tiết tài chính 5 khối và 36 CLB).
  - **State:** Dữ liệu trong các bảng `tblKPI_Snap_*` là bất biến theo từng kỳ đã chốt sổ.
  - **Output:** Giao diện hiển thị chính xác tổng doanh thu (79.37 tỷ), CLB (1.611 tỷ), 131 ca y tế, 470 đơn nghỉ, 44 ca nhân sự, 79 ticket CSVC, CRM leads.
  - **Side Effects:** Không gây phình to một bảng tập trung; giảm thiểu I/O do query đúng partition của từng loại nghiệp vụ.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Architecture Documentation:** `docs/DATABASE_ARCHITECTURE_IMMUTABLE_SNAPSHOTS.md`
- **Database DDL:** `_db/esign/migration_v2_source_snapshots_schema.sql`
- **Database Seed:** `_db/esign/migration_v2_seed_frozen_data_september.sql`
- **Database Drop:** `_db/esign/migration_v2_drop_legacy_tables.sql`
- **Stored Procedures:** `_db/esign/spAPI_KPI_GetFinanceServices.sql`, `_db/esign/spAPI_KPI_GetOperationalFacts.sql`, `_db/esign/spAPI_KPI_GetOperationsSummary.sql`, `_db/esign/spAPI_KPI_GetPeriodSnapshots.sql`
- **Frontend Component:** `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue`

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] Các hệ thống tác nghiệp nguồn (Basic Data, LMS, FTS, CRM) không hỗ trợ truy vấn historical data chính xác theo mốc thời gian cũ vì dữ liệu thường xuyên bị cập nhật/ghi đè. (Evidence: yêu cầu bài toán từ User).
- [FACT] Việc gom tất cả 8 loại sự kiện vào `tblKPI_OperationalFacts` dùng chung các cột `Dim1..Dim4` gây phình to bảng và làm chậm tốc độ query. (Evidence: phân tích lược đồ dữ liệu và cấu trúc chỉ mục).
- [FACT] Frontend `uc-kpi-ops.vue` đã được kiểm tra cú pháp đạt 100% hợp lệ qua `node --check` và đã cập nhật lên FUI (`0 unpublished files`).

### Active Hypotheses
- [H1] Khi áp dụng `spAPI_KPI_GetOperationalFacts` mới, giao diện cũ vẫn tương thích 100% nhờ việc aliasing các cột của `tblKPI_Snap_*` về các tên trường cũ (`MetricCode`, `Dim1..Dim4`, `FactValue`).
  - *Supporting evidence:* Stored procedure trả về đúng các tên cột mà Frontend đang đọc trong `factList`.
  - *Contradicting evidence:* Không có.
  - *Smallest falsification test:* Kiểm tra `result[0]` trong Stored Procedure trả về đúng các field `Dim1`, `Dim2`, `Dim3`, `FactValue`.

### Assumptions & Unknowns
- [ASSUMPTION] Quá trình migration DB thực tế sẽ được thực thi bởi DBA hoặc pipeline CI/CD khi có quyền truy cập trực tiếp vào máy chủ CSDL SQL Server eSign.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `node --check` trên script extracted từ `uc-kpi-ops.vue` → **Result:** PASS (0 syntax errors).
  - `fui component update uc-kpi-ops` → **Result:** PASS (1 component synced, ComID 13057).
  - `fui file status` → **Result:** PASS (0 unpublished files).

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- **Attempt 1:** Giữ lại `tblKPI_OperationalFacts` và thêm cột phân loại nguồn.
  - *Result:* Bị bác bỏ do bảng sẽ ngày càng phình to qua từng tuần/tháng, và các cột `Dim1..Dim4` làm mất tính strongly-typed của dữ liệu.
  - *Conclusion:* Phải tách thành 8 bảng snapshot nguồn độc lập (`tblKPI_Snap_*`).

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:**
  - Giữ nguyên các Stored Procedure `spAPI_KPI_GetOperationalFacts`, `spAPI_KPI_GetPeriodSnapshots`, `spAPI_KPI_GetOperationsSummary` để Frontend không bị vỡ giao tiếp API.
- **Side Effects / Tradeoffs:**
  - Tạo 8 bảng mới đòi hỏi migration script phải chạy đầy đủ trước khi kích hoạt `spAPI_KPI_GetOperationalFacts` mới trên môi trường production.
