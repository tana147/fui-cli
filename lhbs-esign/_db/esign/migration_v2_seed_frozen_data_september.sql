-- ===================================================================================
-- MIGRATION V2: SEED FROZEN DATA SEPTEMBER 2026 (PERIOD 2026-09)
-- Bóc tách và đóng băng 100% dữ liệu chuẩn kỳ Tháng 9/2026 vào các bảng Snapshot chuyên biệt
-- Database: eSignature
-- ===================================================================================
SET NOCOUNT ON;

-- 1. NẠP / CẬP NHẬT DANH MỤC KỲ CHỐT (tblKPI_Periods)
IF NOT EXISTS (SELECT 1 FROM tblKPI_Periods WHERE PeriodKey = '2026-09')
    INSERT INTO tblKPI_Periods (PeriodKey, PeriodName, PeriodType, SchoolYear, StartDate, EndDate, IsFrozen, DataSourceType, FreezeDate, FrozenBy, Note)
    VALUES ('2026-09', N'Tháng 09/2026 (Chốt sổ)', 'MONTH', '2026-2027', '2026-09-01', '2026-09-30', 1, 'EXCEL_STAGING', '2026-09-30 17:00:00', N'HĐQT & Ban Giám Hiệu', N'Dữ liệu chốt sổ chính thức toàn trường Tháng 9');
ELSE
    UPDATE tblKPI_Periods
    SET PeriodName = N'Tháng 09/2026 (Chốt sổ)',
        PeriodType = 'MONTH',
        SchoolYear = '2026-2027',
        StartDate = '2026-09-01',
        EndDate = '2026-09-30',
        IsFrozen = 1,
        DataSourceType = 'EXCEL_STAGING',
        FreezeDate = '2026-09-30 17:00:00',
        FrozenBy = N'HĐQT & Ban Giám Hiệu',
        Note = N'Dữ liệu chốt sổ chính thức toàn trường Tháng 9'
    WHERE PeriodKey = '2026-09';

IF NOT EXISTS (SELECT 1 FROM tblKPI_Periods WHERE PeriodKey = '2026-10')
    INSERT INTO tblKPI_Periods (PeriodKey, PeriodName, PeriodType, SchoolYear, StartDate, EndDate, IsFrozen, DataSourceType, FreezeDate, FrozenBy, Note)
    VALUES ('2026-10', N'Tháng 10/2026 (Kỳ Live)', 'MONTH', '2026-2027', '2026-10-01', '2026-10-31', 0, 'LIVE_API', NULL, NULL, N'Kỳ vận hành hiện tại đang thu thập dữ liệu');
ELSE
    UPDATE tblKPI_Periods
    SET PeriodName = N'Tháng 10/2026 (Kỳ Live)',
        PeriodType = 'MONTH',
        SchoolYear = '2026-2027',
        StartDate = '2026-10-01',
        EndDate = '2026-10-31',
        IsFrozen = 0,
        DataSourceType = 'LIVE_API',
        FreezeDate = NULL,
        FrozenBy = NULL,
        Note = N'Kỳ vận hành hiện tại đang thu thập dữ liệu'
    WHERE PeriodKey = '2026-10';

-- 2. NẠP DỮ LIỆU TÀI CHÍNH DỊCH VỤ & CLB (tblKPI_Snap_Finance_Services)
DELETE FROM tblKPI_Snap_Finance_Services WHERE PeriodKey = '2026-09';

-- 2.1. 5 Mảng Dịch Vụ Vận Hành Hợp Nhất (Chỉ tiêu 55: Tỷ suất LN gộp 48.4%)
INSERT INTO tblKPI_Snap_Finance_Services 
(PeriodKey, ScopeID, CategoryType, ItemCode, ItemName, NetRevenue, DirectCost, GrossProfit, GrossMarginPct, StudentCount, UnitPricePerPeriod, RevenueSharePct, PlanTargetRevenue, PlanAchievedPct, Note)
VALUES
('2026-09', 'ALL', 'OPERATION_SERVICE', 'TC_HP', N'Học phí chính khóa', 65400000000, 32700000000, 32700000000, 50.0, 2625, 24900000, 82.4, 66000000000, 99.1, N'Theo biểu phí năm học 2026-2027'),
('2026-09', 'ALL', 'OPERATION_SERVICE', 'TC_BT', N'Tiền ăn & Bán trú', 8250000000, 5360000000, 2890000000, 35.0, 2354, 3500000, 10.4, 8500000000, 97.1, N'Tỷ lệ đăng ký bán trú đạt 94.2%'),
('2026-09', 'ALL', 'OPERATION_SERVICE', 'TC_BUS', N'Xe đưa đón học sinh', 3100000000, 2050000000, 1050000000, 33.9, 420, 7380000, 3.9, 3200000000, 96.9, N'2 tuyến xe bus Biên Hòa & Long Khánh'),
('2026-09', 'ALL', 'OPERATION_SERVICE', 'TC_DP', N'Đồng phục & Giáo trình', 1820000000, 730000000, 1090000000, 59.9, 2625, 693000, 2.3, 1800000000, 101.1, N'Đợt phát hành đầu năm học'),
('2026-09', 'ALL', 'OPERATION_SERVICE', 'TC_NG', N'Dịch vụ ngoài giờ & Trông muộn', 800000000, 110000000, 690000000, 86.3, 310, 2580000, 1.0, 800000000, 100.0, N'Dịch vụ trông muộn sau 17h00');

-- 2.2. Danh Mục 36 Môn CLB Bổ Trợ (Chỉ tiêu 56: Doanh thu 1.611 tỷ, 596 HS)
INSERT INTO tblKPI_Snap_Finance_Services 
(PeriodKey, ScopeID, CategoryType, ItemCode, ItemName, NetRevenue, DirectCost, GrossProfit, GrossMarginPct, StudentCount, UnitPricePerPeriod, RevenueSharePct, PlanTargetRevenue, PlanAchievedPct, Note)
VALUES
('2026-09', 'ALL', 'CLUB', 'CLB_STEM', N'STEM & Robot Huna', 454400000, 181760000, 272640000, 60.0, 142, 3200000, 28.2, 450000000, 101.0, N'Khối Tiểu học & THCS'),
('2026-09', 'ALL', 'CLUB', 'CLB_SWIM', N'Bơi lội & Kỹ năng nước', 470400000, 235200000, 235200000, 50.0, 168, 2800000, 29.2, 480000000, 98.0, N'Hồ bơi cơ sở Biên Hòa'),
('2026-09', 'ALL', 'CLUB', 'CLB_ENG', N'Tiếng Anh giao tiếp bản ngữ', 437500000, 218750000, 218750000, 50.0, 125, 3500000, 27.2, 450000000, 97.2, N'Giáo viên nước ngoài cơ hữu'),
('2026-09', 'ALL', 'CLUB', 'CLB_BASKET', N'Bóng rổ & Vận động', 172800000, 69120000, 103680000, 60.0, 96, 1800000, 10.7, 200000000, 86.4, N'Nhà đa năng cơ sở Long Khánh & BH'),
('2026-09', 'ALL', 'CLUB', 'CLB_CHESS', N'Cờ vua & Tư duy logic', 78000000, 31200000, 46800000, 60.0, 65, 1200000, 4.8, 80000000, 97.5, N'Khối Mầm non & Tiểu học');

-- 3. NẠP DỮ LIỆU CRM PHỄU TUYỂN SINH (tblKPI_Snap_CRM_Pipeline)
DELETE FROM tblKPI_Snap_CRM_Pipeline WHERE PeriodKey = '2026-09';

INSERT INTO tblKPI_Snap_CRM_Pipeline 
(PeriodKey, ReportMonth, PtlcLeads, MnbhLeads, MnlkLeads, TotalLeads, EnrolledStudents, ConversionRatePct, ChannelDetailsJson, DropReasonsJson, KittyPipelineJson)
VALUES
('2026-09', N'Tháng 7/2026', 6, 25, 58, 89, 6, 6.74, NULL, NULL, NULL),
('2026-09', N'Tháng 8/2026', 42, 168, 149, 359, 31, 8.64, NULL, NULL, NULL),
('2026-09', N'Tháng 9/2026', 15, 68, 79, 162, 21, 12.96, 
N'[{"Channel":"Người quen / PH hiện hữu giới thiệu","Leads":82,"Pct":"13.4%","Enrolled":42,"ConvRate":"51.2%"},{"Channel":"Facebook Ads & Fanpage","Leads":285,"Pct":"46.7%","Enrolled":8,"ConvRate":"2.8%"},{"Channel":"Phụ huynh vãng lai đến trường trực tiếp","Leads":114,"Pct":"18.7%","Enrolled":5,"ConvRate":"4.4%"},{"Channel":"Sự kiện / Ngày hội trải nghiệm Open Day","Leads":79,"Pct":"13.0%","Enrolled":2,"ConvRate":"2.5%"},{"Channel":"Treo băng rôn / Tờ rơi / Kênh khác","Leads":50,"Pct":"8.2%","Enrolled":1,"ConvRate":"2.0%"}]',
N'[{"Reason":"Khoảng cách xa / không có tuyến xe bus","Count":184,"Pct":"33.3%","Action":"Mở rộng 2 tuyến xe bus Long Khánh & Trảng Dài"},{"Reason":"Học phí vượt ngân sách gia đình","Count":142,"Pct":"25.7%","Action":"Gói đóng giãn kỳ & ưu đãi chuyển cấp nội bộ"},{"Reason":"Chọn trường công lập gần nhà","Count":115,"Pct":"20.8%","Action":"Tập trung truyền thông chương trình Tiếng Anh & Bán trú"},{"Reason":"Chờ bé đủ tuổi nhà trẻ (dưới 18 tháng)","Count":68,"Pct":"12.3%","Action":"Nuôi dưỡng trong nhóm Zalo Kitty chờ HK2"},{"Reason":"Lý do khác (chuyển công tác, gia đình)","Count":43,"Pct":"7.8%","Action":"Lưu trữ hồ sơ chăm sóc định kỳ hàng quý"}]',
N'[{"stt":1,"parent":"Lê Thị Hương","phone":"0918.234.xxx","child":"Nguyễn Bảo Nam (22th)","status":"Chờ đủ tuổi T11/2026","date":"25/10/2026","note":"Hẹn gọi lại sau khi bé đủ 24 tháng"},{"stt":2,"parent":"Trần Văn Long","phone":"0903.888.xxx","child":"Trần Minh Khang (20th)","status":"Hẹn HK2 (T01/2027)","date":"15/11/2026","note":"Mời tham gia Open Day ngày 15/11"},{"stt":3,"parent":"Nguyễn Thị Mai","phone":"0987.654.xxx","child":"Đỗ An Nhiên (18th)","status":"Đang gửi bà, hẹn T12","date":"Hàng tuần","note":"Chăm sóc Zalo, gửi thực đơn dinh dưỡng"},{"stt":4,"parent":"Phạm Hoàng Quân","phone":"0912.333.xxx","child":"Phạm Gia Hưng (24th)","status":"Đã cọc giữ chỗ 2 triệu","date":"01/11/2026","note":"Nhập học chính thức ngày 01/11/2026"},{"stt":5,"parent":"Đặng Thu Thảo","phone":"0938.111.xxx","child":"Vũ Khánh Linh (19th)","status":"Chờ chuyển nhà về LK","date":"05/11/2026","note":"Chờ hoàn thiện nhà ở Long Khánh"},{"stt":6,"parent":"Hoàng Minh Tuấn","phone":"0979.222.xxx","child":"Hoàng Phúc An (21th)","status":"Hẹn tham quan T10","date":"31/10/2026","note":"Book lịch thứ 7 tuần này tham quan cơ sở"}]'
);

-- 4. CHUYỂN GIAO TOÀN BỘ 131 CA Y TẾ VÀO tblKPI_Snap_Healthcare
DELETE FROM tblKPI_Snap_Healthcare WHERE PeriodKey = '2026-09';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_OperationalFacts')
BEGIN
    INSERT INTO tblKPI_Snap_Healthcare (PeriodKey, ScopeID, StudentCode, StudentName, ClassName, DiseaseGroup, DiseaseType, Diagnosis, TreatmentAction, OccurredDate, SeverityLevel, Status)
    SELECT 
        PeriodKey, ScopeID, EntityCode, EntityName, 
        ISNULL(Dim1, N'Khối Tiểu học'), 
        ISNULL(Dim2, N'Bệnh thông thường'), 
        ISNULL(Dim3, EntityName), 
        Dim3, N'Theo dõi tại phòng y tế', OccurredDate,
        CASE WHEN Dim3 LIKE N'%Sốt%' OR Dim3 LIKE N'%Cúm%' THEN 'WARN' ELSE 'NORMAL' END,
        ISNULL(Status, 'TREATED')
    FROM tblKPI_OperationalFacts
    WHERE PeriodKey = '2026-09' AND DomainCode = 'HEALTH';
    PRINT N'Đã nạp ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' ca y tế vào tblKPI_Snap_Healthcare.';
END;

-- 5. CHUYỂN GIAO TOÀN BỘ 470 ĐƠN NGHỈ PHÉP VÀO tblKPI_Snap_HRM_Leave
DELETE FROM tblKPI_Snap_HRM_Leave WHERE PeriodKey = '2026-09';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_OperationalFacts')
BEGIN
    INSERT INTO tblKPI_Snap_HRM_Leave (PeriodKey, ScopeID, EmployeeCode, EmployeeName, Department, LeaveType, LeaveDays, FromDate, ToDate, Reason, Status)
    SELECT 
        PeriodKey, ScopeID, EntityCode, EntityName, 
        ISNULL(Dim1, N'Chưa phân loại'), 
        ISNULL(Dim2, N'Nghỉ phép năm'), 
        ISNULL(MetricCount, 1.0),
        OccurredDate, OccurredDate,
        Dim3,
        ISNULL(Status, 'APPROVED')
    FROM tblKPI_OperationalFacts
    WHERE PeriodKey = '2026-09' AND DomainCode = 'LEAVE';
    PRINT N'Đã nạp ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' đơn nghỉ phép vào tblKPI_Snap_HRM_Leave.';
END;

-- 6. CHUYỂN GIAO TOÀN BỘ 44 CA BIẾN ĐỘNG NHÂN SỰ VÀO tblKPI_Snap_HRM_Turnover
DELETE FROM tblKPI_Snap_HRM_Turnover WHERE PeriodKey = '2026-09';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_OperationalFacts')
BEGIN
    INSERT INTO tblKPI_Snap_HRM_Turnover (PeriodKey, ScopeID, EmployeeCode, EmployeeName, Department, JobTitle, ChangeType, EffectiveDate, Reason)
    SELECT 
        PeriodKey, ScopeID, EntityCode, EntityName, 
        ISNULL(Dim1, N'Chưa phân loại'), 
        ISNULL(Dim2, N'Giáo viên'), 
        ISNULL(Dim3, 'RESIGNED'),
        OccurredDate,
        Dim4
    FROM tblKPI_OperationalFacts
    WHERE PeriodKey = '2026-09' AND DomainCode = 'HR_TURNOVER';
    PRINT N'Đã nạp ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' ca nhân sự vào tblKPI_Snap_HRM_Turnover.';
END;

-- 7. CHUYỂN GIAO TOÀN BỘ TICKET BẢO TRÌ CSVC VÀO tblKPI_Snap_Maintenance
DELETE FROM tblKPI_Snap_Maintenance WHERE PeriodKey = '2026-09';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_OperationalFacts')
BEGIN
    INSERT INTO tblKPI_Snap_Maintenance (PeriodKey, ScopeID, TicketCode, Category, Location, IssueDescription, ReportedDate, CompletedDate, Status, IsOverdue)
    SELECT 
        PeriodKey, ScopeID, EntityCode, 
        ISNULL(Dim1, N'Cơ sở vật chất'), 
        ISNULL(Dim2, N'Khuôn viên trường'), 
        ISNULL(Dim3, EntityName),
        OccurredDate, OccurredDate,
        ISNULL(Status, 'COMPLETED'),
        CASE WHEN Dim4 LIKE N'%tồn%' OR Status = 'PENDING' THEN 1 ELSE 0 END
    FROM tblKPI_OperationalFacts
    WHERE PeriodKey = '2026-09' AND DomainCode = 'MAINTENANCE';
    PRINT N'Đã nạp ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' ticket bảo trì vào tblKPI_Snap_Maintenance.';
END;

-- 8. CHUYỂN GIAO TIẾT DẠY THAY VÀO tblKPI_Snap_LMS_Academics
DELETE FROM tblKPI_Snap_LMS_Academics WHERE PeriodKey = '2026-09';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_OperationalFacts')
BEGIN
    INSERT INTO tblKPI_Snap_LMS_Academics (PeriodKey, ScopeID, RecordType, CapHocID, GradeName, SubjectName, TeacherName, SubstituteLessons, SubstituteReason)
    SELECT 
        PeriodKey, ScopeID, 'DAY_THAY', 1, 
        ISNULL(Dim1, N'Tiểu học'), 
        ISNULL(Dim2, N'Chuyên môn'), 
        EntityName,
        ISNULL(MetricCount, 1),
        Dim3
    FROM tblKPI_OperationalFacts
    WHERE PeriodKey = '2026-09' AND DomainCode = 'TEACHING';
    PRINT N'Đã nạp ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' tiết dạy thay vào tblKPI_Snap_LMS_Academics.';
END;
