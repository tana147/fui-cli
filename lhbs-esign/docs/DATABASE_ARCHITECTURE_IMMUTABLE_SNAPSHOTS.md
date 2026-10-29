# KIẾN TRÚC DỮ LIỆU ĐÓNG BĂNG ĐỊNH KỲ (IMMUTABLE PERIOD SNAPSHOT VAULT)
## HỆ THỐNG KPI WORKSPACE & OPS DASHBOARD · LHBS

> **Phiên bản:** 2.0 (Tháng 10/2026)  
> **Căn cứ tài liệu:** `docs/2026.10.19_Phương án xây dựng Dashboard vận hành.docx`  
> **Mục tiêu:** Xử lý triệt để bài toán trôi số liệu lịch sử của các hệ thống nguồn vận hành bằng mô hình lưu trữ đóng băng bất biến theo Tuần / Tháng / Quý / Năm.

---

## 1. BỐI CẢNH & NGUYÊN LÝ THIẾT KẾ

### 1.1. Vấn đề thực tế của các Hệ thống Nguồn (Source Systems)
Các hệ thống vận hành tác nghiệp hàng ngày của nhà trường bao gồm:
1. **Basic Data** (`https://basicdata.lhbs.vn/`): Quản lý học sinh, lớp, cơ cấu sĩ số, học sinh rút học / chuyển đến.
2. **Kế toán FTS** (`https://hocphi.lhbs.vn/`): Học phí, dịch vụ Bán trú & Ăn sáng, xe bus đưa rước, CLB bổ trợ, chi phí và lợi nhuận gộp.
3. **Y tế học đường** (`https://yte.lhbs.vn/`): Sức khỏe học sinh, sổ y tế, ca bệnh học đường, tai nạn thương tích.
4. **Đảm bảo chất lượng QA** (`https://qa.lhbs.vn/`): Khảo sát mức độ hài lòng PHHS, đồng phục, chất lượng dịch vụ.
5. **LMS Học tập** (`https://lms.lhbs.vn/` - CSDL `LMS-LHBS`): Học liệu số giáo viên, tỷ lệ hoàn thành bài tập, tiến độ tiết dạy Calen.
6. **HRM & Tuyển sinh CRM** (Tracking TVTS & Nhân sự): Leads tuyển sinh, phễu chuyển đổi, biến động nhân sự, ngày công nghỉ phép.

> **Đặc điểm cốt tử:**
> - Các hệ thống trên là hệ thống **OLTP (Online Transaction Processing)**, chỉ lưu **trạng thái hiện tại (Mutable State)**.
> - Chúng **không có cơ chế Historical Versioning theo tuần/tháng/quý**. 
> - Số liệu có thể bị trôi: Sĩ số hôm nay xem là 2.625, nhưng tuần sau có học sinh chuyển lớp/rút hồ sơ thì số liệu tháng trước bị ghi đè; bài tập LMS hôm sau học sinh nộp bù thì tỷ lệ tuần trước bị thay đổi; nhân viên vào sửa ticket CSVC thì số lượng tồn của kỳ trước biến mất.

### 1.2. Nguyên lý Đóng băng Bất biến (Immutable Period Freeze)
- Hệ thống KPI Workspace đóng vai trò là **Executive Analytical Mart / Historical Vault**.
- Cứ đến chu kỳ chốt (cuối tuần / cuối tháng / cuối quý / cuối năm), hệ thống sẽ kích hoạt tiến trình ETL kéo toàn bộ ảnh chụp dữ liệu thô tại thời điểm đó về, đóng dấu thời gian, gán nhãn kỳ (`PeriodKey`, ví dụ: `2026-09`, `2026-W41`) và **khóa vĩnh viễn (`IsFrozen = 1`)**.
- Kể từ thời điểm đó, dù hệ thống nguồn bên dưới có sửa đổi hay sai lệch, số liệu báo cáo của kỳ đó trên Dashboard KPI vẫn giữ nguyên vẹn 100% để phục vụ trách nhiệm giải trình trước Hội đồng trường.

---

## 2. KIẾN TRÚC TỔNG THỂ 4 TẦNG

```text
┌───────────────────────────────────────────────────────────────────────────────────────────────────┐
│                        KIẾN TRÚC DỮ LIỆU ĐÓNG BĂNG ĐỊNH KỲ (PERIOD FREEZE ARCHITECTURE)           │
└───────────────────────────────────────────────────────────────────────────────────────────────────┘

  TẦNG 1: QUẢN TRỊ KỲ & METADATA (Cấu hình & Từ điển dùng chung)
  ├── tblKPI_Periods                      (Quản lý các mốc đóng băng: 2026-09, 2026-10, 2026-W41...)
  ├── tblKPI_CampusCatalog                (Danh mục chuẩn hóa 5 cơ sở: ALL, MNTB, MNLK, TH, THCS, THPT)
  ├── tblKPI_Definitions                  (Từ điển chuẩn 60 chỉ tiêu theo tài liệu họp 19/10)
  ├── tblKPI_Thresholds                   (Ngưỡng Đạt/Cảnh báo theo từng kỳ & cơ sở)
  └── tblKPI_Parameters                   (Biểu phí, Định biên, Sĩ số kế hoạch, Công suất thiết kế)

  TẦNG 2: BẢN CHỤP VĨ MÔ CHO DASHBOARD (Single Source of Truth - 60 KPI)
  └── tblKPI_PeriodSnapshots              (Lưu đúng 60 con số chốt của kỳ để Frontend load tức thì < 50ms)

  TẦNG 3: BẢN CHỤP NGUỒN CHUYÊN BIỆT & EVENT LOGS (Lưu trực tiếp dữ liệu thô, chi tiết của từng nguồn)
  ├── tblKPI_Snap_BasicData_Students      (Sĩ số từng lớp, danh sách học sinh rút học / chuyển đến)
  ├── tblKPI_Snap_LMS_Academics           (Học liệu số, bài tập LMS, lịch phân công dạy thay)
  ├── tblKPI_Snap_Finance_Services        (Sổ P&L 5 dịch vụ bán trú/xe bus & Doanh thu 36 môn CLB)
  ├── tblKPI_Snap_Healthcare              (Sổ y tế học đường, chi tiết 131 ca bệnh)
  ├── tblKPI_Snap_HRM_Leave               (Chi tiết 470 đơn nghỉ phép của từng NV)
  ├── tblKPI_Snap_HRM_Turnover            (Chi tiết 44 ca biến động nhân sự, tuyển mới, nghỉ việc)
  ├── tblKPI_Snap_Maintenance             (Chi tiết 79 ticket sửa chữa CSVC, tiến độ bảo trì máy lạnh)
  └── tblKPI_Snap_CRM_Pipeline            (Diễn biến Leads, kênh tuyển sinh, 15 hồ sơ hẹn HK2 Kitty)

  TẦNG 4: BẢN THỂ HỌC NHÂN QUẢ & ĐIỀU HÀNH HĐQT (Causal Ontology & Directives)
  ├── tblKPI_CorrelationOntology          (Ma trận liên kết 15 mắt xích nhân quả & Hệ số co giãn)
  ├── tblKPI_PeriodBreakdowns             (Phân rã đa chiều: Lý do rút học FAR/ECO, Kênh TVTS...)
  ├── tblKPI_AuditDiscrepancies           (Kết quả tự động phát hiện lệch số liệu & cảnh báo rủi ro)
  └── tblKPI_RiskDirectives               (Nghị quyết & Chỉ đạo khẩn cấp của HĐQT theo từng cơ sở)
```

---

## 3. DANH MỤC CÁC BẢNG NGUỒN CHUYÊN BIỆT (TẦNG 3)

Thay vì dùng Super Table generic `tblKPI_OperationalFacts` (bị phình to dữ liệu và cột mơ hồ `Dim1..Dim4`), dữ liệu chi tiết của 6 nguồn được lưu trực tiếp vào các bảng strongly-typed:

### 3.1. `tblKPI_Snap_Finance_Services` (Nguồn: Kế toán FTS)
- **Mục đích:** Đóng băng báo cáo tài chính 5 mảng dịch vụ (Chỉ tiêu 55) và doanh thu 36 môn CLB bổ trợ (Chỉ tiêu 56).
- **Cấu trúc:** `PeriodKey, ScopeID, CategoryType (OPERATION_SERVICE / CLUB), ItemCode, ItemName, NetRevenue, DirectCost, GrossProfit, GrossMarginPct, StudentCount, UnitPricePerPeriod, RevenueSharePct, PlanTargetRevenue, PlanAchievedPct, Note`.

### 3.2. `tblKPI_Snap_Healthcare` (Nguồn: Y tế học đường)
- **Mục đích:** Đóng băng toàn bộ ca bệnh, khám sức khỏe học sinh (ví dụ: 131 ca tháng 9).
- **Cấu trúc:** `PeriodKey, ScopeID, StudentCode, StudentName, ClassName, DiseaseGroup (SOT, MAT, RANG...), DiseaseType (Cúm A, Sốt phát ban...), Diagnosis, TreatmentAction, OccurredDate, SeverityLevel, Status`.

### 3.3. `tblKPI_Snap_HRM_Leave` (Nguồn: Nhân sự HRM)
- **Mục đích:** Đóng băng toàn bộ đơn xin nghỉ phép của cán bộ/giáo viên/nhân viên (ví dụ: 470 đơn, 551 ngày công tháng 9).
- **Cấu trúc:** `PeriodKey, ScopeID, EmployeeCode, EmployeeName, Department, LeaveType, LeaveDays (0.5, 1.0, 2.0), FromDate, ToDate, Reason, Status`.

### 3.4. `tblKPI_Snap_HRM_Turnover` (Nguồn: Nhân sự HRM)
- **Mục đích:** Đóng băng biến động nhân sự, tuyển dụng, nghỉ việc (ví dụ: 44 ca tháng 9).
- **Cấu trúc:** `PeriodKey, ScopeID, EmployeeCode, EmployeeName, Department, JobTitle, ChangeType (RESIGNED / HIRED / TRANSFERRED), EffectiveDate, Reason`.

### 3.5. `tblKPI_Snap_Maintenance` (Nguồn: Quản lý CSVC)
- **Mục đích:** Đóng băng danh mục ticket sửa chữa bảo trì (ví dụ: 79 ticket tháng 9).
- **Cấu trúc:** `PeriodKey, ScopeID, TicketCode, Category, Location (Khu B, C...), IssueDescription, ReportedDate, CompletedDate, Status (COMPLETED / PENDING), IsOverdue`.

### 3.6. `tblKPI_Snap_BasicData_Students` (Nguồn: Basic Data)
- **Mục đích:** Đóng băng sĩ số từng lớp và danh sách học sinh rút học / chuyển đến.
- **Cấu trúc:** `PeriodKey, ScopeID, GradeID, GradeName, ClassID, ClassName, StudentCount, CapacityMax, RecordType (ACTIVE / WITHDRAW / TRANSFER_IN), StudentCode, StudentName, EventDate, WithdrawReasonCode (FAR / ECO / OTHER), WithdrawReasonText`.

### 3.7. `tblKPI_Snap_LMS_Academics` (Nguồn: LMS & Calen)
- **Mục đích:** Đóng băng tỷ lệ học liệu số, bài tập và tiết dạy thay.
- **Cấu trúc:** `PeriodKey, ScopeID, RecordType (HOC_LIEU / BAI_TAP / DAY_THAY), CapHocID, GradeName, SubjectName, TeacherName, TotalMaterials, ContentMaterials, TotalAssigned, TotalSubmitted, TotalGraded, SubstituteLessons, SubstituteReason`.

### 3.8. `tblKPI_Snap_CRM_Pipeline` (Nguồn: CRM TVTS)
- **Mục đích:** Đóng băng diễn biến Leads 3 tháng, kênh tiếp cận và danh sách 15 bé Kitty hẹn HK2.
- **Cấu trúc:** `PeriodKey, ReportMonth, PtlcLeads, MnbhLeads, MnlkLeads, TotalLeads, EnrolledStudents, ConversionRatePct, ChannelDetailsJson, DropReasonsJson, KittyPipelineJson`.

---

## 4. DANH MỤC BẢNG CŨ ĐÃ LOẠI BỎ (DEPRECATED & DROPPED)

Để giữ database sạch sẽ, các bảng cũ sau đây đã được dọn dẹp:
1. **`tblKPI_OperationalFacts`**: Bảng Super Table generic cũ với các cột `Dim1..Dim4` (đã chuyển giao dữ liệu sang 8 bảng `tblKPI_Snap_*`).
2. **`tblKPI_DimensionTypes` & `tblKPI_DimensionMembers`**: Danh mục chiều generic cũ.
3. **`tblKPI_Correlations` & `tblKPI_CorrelationRules`**: Bảng quan hệ phẳng cũ (đã có `tblKPI_CorrelationOntology` thay thế).
4. **`tblKPI_PeriodNarratives`**: Bảng nhận định cũ (đã có `tblKPI_CausalNarratives` thay thế).

---

## 5. QUY ƯỚC ĐỊNH TUYẾN TRUY VẤN (QUERY ROUTING)

Frontend giữ nguyên contract gọi API để không làm xáo trộn UI:

- **Dashboard vĩ mô (60 KPI):** 
  Gọi `eSign/KPI_GetPeriodSnapshots` ➔ Stored Procedure đọc trực tiếp từ `tblKPI_PeriodSnapshots`.
- **Slide Drawer tra cứu chi tiết (Drill-down):** 
  Gọi `eSign/KPI_GetOperationalFacts(@DomainCode, @PeriodKey)` ➔ Stored Procedure định tuyến thông minh:
  - `@DomainCode = 'HEALTH'` ➔ `SELECT FROM tblKPI_Snap_Healthcare`
  - `@DomainCode = 'LEAVE'` ➔ `SELECT FROM tblKPI_Snap_HRM_Leave`
  - `@DomainCode = 'MAINTENANCE'` ➔ `SELECT FROM tblKPI_Snap_Maintenance`
  - `@DomainCode = 'HR_TURNOVER'` ➔ `SELECT FROM tblKPI_Snap_HRM_Turnover`
  - `@DomainCode = 'TEACHING'` ➔ `SELECT FROM tblKPI_Snap_LMS_Academics`
- **Báo cáo Tài chính Dịch vụ & CLB:**
  Gọi `eSign/KPI_GetFinanceServices(@PeriodKey, @ScopeID)` ➔ Stored Procedure đọc trực tiếp từ `tblKPI_Snap_Finance_Services`.
