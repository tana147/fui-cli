-- ===================================================================================
-- MIGRATION V2: SOURCE SNAPSHOTS & PERIOD FREEZE SCHEMA
-- Mục đích: Thiết lập kho lưu trữ đóng băng bất biến cho 6 hệ thống nguồn
-- Database: eSignature (SQL Server)
-- ===================================================================================
SET NOCOUNT ON;

-- 1. BẢNG QUẢN TRỊ KỲ ĐÓNG BĂNG (tblKPI_Periods)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Periods')
BEGIN
    CREATE TABLE tblKPI_Periods (
        PeriodKey VARCHAR(20) PRIMARY KEY,      -- '2026-09', '2026-10', '2026-W41'
        PeriodName NVARCHAR(100) NOT NULL,      -- 'Tháng 09/2026 (Chốt sổ)', 'Tuần 41 (12/10 - 18/10)'
        PeriodType VARCHAR(20) NOT NULL,        -- 'MONTH', 'WEEK', 'QUARTER', 'SEMESTER', 'YEAR'
        SchoolYear VARCHAR(20) NOT NULL,        -- '2026-2027'
        StartDate DATE NOT NULL,
        EndDate DATE NOT NULL,
        IsFrozen BIT DEFAULT 0,                 -- 1: Đã chốt sổ đóng băng, 0: Kỳ mở/Live
        DataSourceType VARCHAR(50) DEFAULT 'EXCEL_STAGING', -- 'EXCEL_STAGING', 'LIVE_API', 'HYBRID'
        FreezeDate DATETIME NULL,
        FrozenBy NVARCHAR(100) NULL,
        Note NVARCHAR(500) NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    PRINT 'Đã tạo bảng tblKPI_Periods.';
END;

-- 2. BẢNG TỔNG HỢP VĨ MÔ CHO DASHBOARD (tblKPI_PeriodSnapshots)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_PeriodSnapshots')
BEGIN
    CREATE TABLE tblKPI_PeriodSnapshots (
        SnapshotID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        DonViID VARCHAR(20) NOT NULL,           -- 'ALL', 'MNTB', 'MNLK', 'TH', 'THCS', 'THPT'
        KpiCode VARCHAR(50) NOT NULL,           -- 'TS01', 'TS02', 'TC55', 'CM04'...
        KpiName NVARCHAR(250) NOT NULL,
        KpiGroup NVARCHAR(100) NULL,            -- Nhóm 1..Nhóm 4
        FrameworkLevel VARCHAR(50) NULL,        -- Activity, Output, Outcome, Impact
        FrameworkRef VARCHAR(50) NULL,          -- KPI 1, KPI 3, KPI 4...
        ActualValue DECIMAL(18,2) NULL,
        TargetValue DECIMAL(18,2) NULL,
        Unit NVARCHAR(50) NULL,
        Rate DECIMAL(9,2) NULL,
        Status VARCHAR(20) NULL,                -- 'GOOD', 'WARN', 'BAD'
        DataSourceType VARCHAR(50) NULL,
        SpecCode VARCHAR(50) NULL,
        FinancialImpact NVARCHAR(500) NULL,
        OperationalInsight NVARCHAR(1000) NULL,
        IsFrozen BIT DEFAULT 0,
        CreatedAt DATETIME DEFAULT GETDATE(),
        CONSTRAINT UQ_Period_Scope_Kpi UNIQUE (PeriodKey, DonViID, KpiCode)
    );
    CREATE INDEX IX_PeriodSnapshots_Lookup ON tblKPI_PeriodSnapshots (PeriodKey, DonViID);
    PRINT 'Đã tạo bảng tblKPI_PeriodSnapshots.';
END;

-- 3. BẢNG SNAPSHOT TÀI CHÍNH DỊCH VỤ & CLB (tblKPI_Snap_Finance_Services)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_Finance_Services')
BEGIN
    CREATE TABLE tblKPI_Snap_Finance_Services (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL,           -- 'ALL', 'MNTB', 'MNLK', 'TH', 'THCS', 'THPT'
        CategoryType VARCHAR(30) NOT NULL,      -- 'OPERATION_SERVICE' (5 dịch vụ) hoặc 'CLUB' (36 môn CLB)
        ItemCode VARCHAR(50) NULL,
        ItemName NVARCHAR(250) NOT NULL,        -- Học phí chính khóa, Tiền ăn, Xe đưa đón, STEM Robot...
        NetRevenue DECIMAL(18,2) NOT NULL,      -- Doanh thu thuần (VNĐ)
        DirectCost DECIMAL(18,2) NOT NULL,      -- Chi phí trực tiếp (VNĐ)
        GrossProfit DECIMAL(18,2) NOT NULL,     -- Lợi nhuận gộp (VNĐ)
        GrossMarginPct DECIMAL(9,2) NOT NULL,   -- Tỷ suất LN gộp (%)
        StudentCount INT NULL,                  -- Số học sinh tham gia
        UnitPricePerPeriod DECIMAL(18,2) NULL,  -- Đơn giá/kỳ (VNĐ)
        RevenueSharePct DECIMAL(9,2) NULL,      -- Tỷ trọng doanh thu (%)
        PlanTargetRevenue DECIMAL(18,2) NULL,   -- Mục tiêu kế hoạch (VNĐ)
        PlanAchievedPct DECIMAL(9,2) NULL,      -- % đạt kế hoạch (%)
        Note NVARCHAR(500) NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_Finance_Query ON tblKPI_Snap_Finance_Services (PeriodKey, ScopeID, CategoryType);
    PRINT 'Đã tạo bảng tblKPI_Snap_Finance_Services.';
END;

-- 4. BẢNG SNAPSHOT Y TẾ HỌC ĐƯỜNG (tblKPI_Snap_Healthcare)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_Healthcare')
BEGIN
    CREATE TABLE tblKPI_Snap_Healthcare (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL,
        StudentCode VARCHAR(50) NULL,
        StudentName NVARCHAR(200) NULL,
        ClassName NVARCHAR(50) NULL,
        DiseaseGroup NVARCHAR(150) NOT NULL,    -- Nhiễm khuẩn, Mắt, Tai mũi họng, Tiêu hóa...
        DiseaseType NVARCHAR(200) NOT NULL,     -- Cúm A, Sốt phát ban, Cận thị, Viêm họng...
        Diagnosis NVARCHAR(500) NULL,
        TreatmentAction NVARCHAR(500) NULL,     -- Uống thuốc, báo PHHS, chuyển viện...
        OccurredDate VARCHAR(50) NULL,
        SeverityLevel VARCHAR(20) DEFAULT 'NORMAL', -- NORMAL, WARN, CRITICAL
        Status VARCHAR(50) DEFAULT 'TREATED',   -- TREATED, MONITORING, HOSPITALIZED
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_Health_Query ON tblKPI_Snap_Healthcare (PeriodKey, ScopeID, DiseaseGroup);
    PRINT 'Đã tạo bảng tblKPI_Snap_Healthcare.';
END;

-- 5. BẢNG SNAPSHOT NGHỈ PHÉP NHÂN SỰ (tblKPI_Snap_HRM_Leave)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_HRM_Leave')
BEGIN
    CREATE TABLE tblKPI_Snap_HRM_Leave (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL,
        EmployeeCode VARCHAR(50) NOT NULL,      -- NV0001104...
        EmployeeName NVARCHAR(200) NOT NULL,
        Department NVARCHAR(200) NOT NULL,      -- Bộ Phận Bếp, Khối Mầm Non, Tổ Ngoại Ngữ...
        LeaveType NVARCHAR(150) NOT NULL,       -- Nghỉ phép năm, Khám bệnh, Nghỉ không lương...
        LeaveDays DECIMAL(9,2) NOT NULL,        -- 0.5, 1.0, 2.0 ngày công
        FromDate VARCHAR(50) NULL,
        ToDate VARCHAR(50) NULL,
        Reason NVARCHAR(500) NULL,
        Status VARCHAR(50) DEFAULT 'APPROVED',
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_Leave_Query ON tblKPI_Snap_HRM_Leave (PeriodKey, ScopeID, Department);
    PRINT 'Đã tạo bảng tblKPI_Snap_HRM_Leave.';
END;

-- 6. BẢNG SNAPSHOT BIẾN ĐỘNG NHÂN SỰ (tblKPI_Snap_HRM_Turnover)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_HRM_Turnover')
BEGIN
    CREATE TABLE tblKPI_Snap_HRM_Turnover (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL,
        EmployeeCode VARCHAR(50) NOT NULL,
        EmployeeName NVARCHAR(200) NOT NULL,
        Department NVARCHAR(200) NOT NULL,
        JobTitle NVARCHAR(150) NULL,
        ChangeType VARCHAR(50) NOT NULL,        -- RESIGNED (Nghỉ việc), HIRED (Tuyển mới), TRANSFERRED (Điều chuyển)
        EffectiveDate VARCHAR(50) NULL,
        Reason NVARCHAR(500) NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_Turnover_Query ON tblKPI_Snap_HRM_Turnover (PeriodKey, ScopeID, ChangeType);
    PRINT 'Đã tạo bảng tblKPI_Snap_HRM_Turnover.';
END;

-- 7. BẢNG SNAPSHOT BẢO TRÌ CSVC (tblKPI_Snap_Maintenance)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_Maintenance')
BEGIN
    CREATE TABLE tblKPI_Snap_Maintenance (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL,
        TicketCode VARCHAR(50) NOT NULL,
        Category NVARCHAR(150) NOT NULL,        -- Máy lạnh, Điện nước, Bàn ghế, Thiết bị CNTT...
        Location NVARCHAR(200) NOT NULL,        -- Khu B, Khu C, Phòng học 4.1...
        IssueDescription NVARCHAR(500) NOT NULL,
        ReportedDate VARCHAR(50) NULL,
        CompletedDate VARCHAR(50) NULL,
        Status VARCHAR(50) NOT NULL,            -- COMPLETED (Đã xử lý), PENDING (Tồn đọng)
        IsOverdue BIT DEFAULT 0,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_Maint_Query ON tblKPI_Snap_Maintenance (PeriodKey, ScopeID, Status);
    PRINT 'Đã tạo bảng tblKPI_Snap_Maintenance.';
END;

-- 8. BẢNG SNAPSHOT BASIC DATA: SĨ SỐ & RÚT HỌC (tblKPI_Snap_BasicData_Students)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_BasicData_Students')
BEGIN
    CREATE TABLE tblKPI_Snap_BasicData_Students (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL,           -- MNBH, MNLK, TH, THCS, THPT
        GradeID INT NOT NULL,
        GradeName NVARCHAR(100) NOT NULL,
        ClassID INT NULL,
        ClassName NVARCHAR(100) NULL,
        StudentCount INT NOT NULL,
        CapacityMax INT NULL,
        RecordType VARCHAR(50) DEFAULT 'ACTIVE', -- ACTIVE, WITHDRAW (Rút học), TRANSFER_IN (Chuyển đến)
        StudentCode VARCHAR(50) NULL,
        StudentName NVARCHAR(200) NULL,
        EventDate VARCHAR(50) NULL,
        WithdrawReasonCode VARCHAR(50) NULL,    -- FAR, ECO, OTHER
        WithdrawReasonText NVARCHAR(500) NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_BasicData_Query ON tblKPI_Snap_BasicData_Students (PeriodKey, ScopeID, RecordType);
    PRINT 'Đã tạo bảng tblKPI_Snap_BasicData_Students.';
END;

-- 9. BẢNG SNAPSHOT LMS & CHUYÊN MÔN (tblKPI_Snap_LMS_Academics)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_LMS_Academics')
BEGIN
    CREATE TABLE tblKPI_Snap_LMS_Academics (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL,
        RecordType VARCHAR(50) NOT NULL,        -- 'HOC_LIEU', 'BAI_TAP', 'DAY_THAY'
        CapHocID INT NULL,
        GradeName NVARCHAR(100) NULL,
        SubjectName NVARCHAR(150) NULL,
        TeacherName NVARCHAR(200) NULL,
        TotalMaterials INT NULL,
        ContentMaterials INT NULL,
        TotalAssigned INT NULL,
        TotalSubmitted INT NULL,
        TotalGraded INT NULL,
        SubstituteLessons INT NULL,
        SubstituteReason NVARCHAR(500) NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_LMS_Query ON tblKPI_Snap_LMS_Academics (PeriodKey, ScopeID, RecordType);
    PRINT 'Đã tạo bảng tblKPI_Snap_LMS_Academics.';
END;

-- 10. BẢNG SNAPSHOT CRM & PHỄU TUYỂN SINH (tblKPI_Snap_CRM_Pipeline)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_Pipeline')
BEGIN
    CREATE TABLE tblKPI_Snap_CRM_Pipeline (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ReportMonth NVARCHAR(50) NOT NULL,      -- Tháng 7/2026, Tháng 8/2026, Tháng 9/2026
        PtlcLeads INT NOT NULL,
        MnbhLeads INT NOT NULL,
        MnlkLeads INT NOT NULL,
        TotalLeads INT NOT NULL,
        EnrolledStudents INT NOT NULL,
        ConversionRatePct DECIMAL(9,2) NOT NULL,
        ChannelDetailsJson NVARCHAR(MAX) NULL,
        DropReasonsJson NVARCHAR(MAX) NULL,
        KittyPipelineJson NVARCHAR(MAX) NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_CRM_Query ON tblKPI_Snap_CRM_Pipeline (PeriodKey);
    PRINT 'Đã tạo bảng tblKPI_Snap_CRM_Pipeline.';
END;
