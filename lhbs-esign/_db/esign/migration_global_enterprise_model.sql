-- ========================================================
-- MIGRATION: GLOBAL ENTERPRISE OPERATIONS DATA ARCHITECTURE
-- Hỗ trợ đa miền nghiệp vụ (Granular Fact Store) & Quản lý điểm vênh
-- DB: eSignature (esign)
-- ========================================================

-- 1. TẦNG DANH MỤC CHIỀU ĐỘNG: tblKPI_DimensionTypes & tblKPI_DimensionMembers
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_DimensionTypes')
BEGIN
    CREATE TABLE tblKPI_DimensionTypes (
        DimensionType VARCHAR(50) PRIMARY KEY,
        DimensionName NVARCHAR(150) NOT NULL,
        Description NVARCHAR(300) NULL,
        IsActive BIT DEFAULT 1
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_DimensionMembers')
BEGIN
    CREATE TABLE tblKPI_DimensionMembers (
        MemberID INT IDENTITY(1,1) PRIMARY KEY,
        DimensionType VARCHAR(50) NOT NULL,
        MemberCode VARCHAR(50) NOT NULL,
        MemberName NVARCHAR(250) NOT NULL,
        ParentCode VARCHAR(50) NULL,
        SortOrder INT DEFAULT 1,
        IsActive BIT DEFAULT 1
    );
    CREATE INDEX IX_Dim_Type_Code ON tblKPI_DimensionMembers(DimensionType, MemberCode);
END;

-- 2. TẦNG FACT VẬN HÀNH HỢP NHẤT: tblKPI_OperationalFacts (Global Granular Fact Store)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_OperationalFacts')
BEGIN
    CREATE TABLE tblKPI_OperationalFacts (
        FactID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        SchoolYear VARCHAR(20) NOT NULL,
        DomainCode VARCHAR(50) NOT NULL, -- ENROLLMENT, CLUB, TEACHING, HEALTH, LEAVE, MAINTENANCE, HR_TURNOVER, CRM_LEAD
        ScopeID VARCHAR(50) NOT NULL,    -- ALL, MNBH, MNLK, TH, THCS, THPT
        EntityCode VARCHAR(100) NULL,    -- Mã NV (NV0001104), Mã HS, Mã môn CLB, Mã thiết bị...
        EntityName NVARCHAR(250) NULL,   -- Họ tên GV/HS, Tên môn CLB, Tên thiết bị...
        Dim1 NVARCHAR(150) NULL,         -- Mapping linh hoạt: Phòng ban / Khu vực (Khu B, C) / Cấp học
        Dim2 NVARCHAR(150) NULL,         -- Khối lớp / Nhóm bệnh / Loại nghỉ phép / Kênh tiếp cận
        Dim3 NVARCHAR(150) NULL,         -- Loại bệnh / Loại thiết bị / Tư vấn viên / Buổi học
        Dim4 NVARCHAR(150) NULL,         -- Thuộc tính phụ
        MetricCount DECIMAL(18,2) NULL,  -- Số lượt, số ca, số ngày nghỉ (0.5, 1.0), số tiết
        MetricAmount DECIMAL(18,2) NULL, -- Doanh thu, chi phí, học phí
        MetricRate DECIMAL(9,2) NULL,    -- Tỷ lệ %
        Status VARCHAR(50) NULL,         -- Hoàn thành, Chờ xử lý, Đạt, Không đạt...
        OccurredDate VARCHAR(50) NULL,   -- Ngày phát sinh sự kiện
        PayloadJson NVARCHAR(MAX) NULL,  -- Chứa toàn bộ thuộc tính mở rộng dạng JSON
        SourceSystem VARCHAR(50) DEFAULT 'EXCEL_STAGING',
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_Fact_Query ON tblKPI_OperationalFacts(PeriodKey, DomainCode, ScopeID);
END;

-- 3. TẦNG BẢNG TỔNG HỢP PHÂN RÃ CHIỀU: tblKPI_PeriodBreakdowns
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_PeriodBreakdowns')
BEGIN
    CREATE TABLE tblKPI_PeriodBreakdowns (
        BreakdownID INT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        DonViID VARCHAR(20) NOT NULL,
        KpiCode VARCHAR(50) NOT NULL,
        DimensionType VARCHAR(50) NOT NULL, -- REASON, CHANNEL, GRADE, SERVICE, ASSET, LEAVE_DEPT
        DimensionCode VARCHAR(50) NOT NULL,
        DimensionName NVARCHAR(250) NOT NULL,
        ActualCount INT NULL,
        ActualValue DECIMAL(18,2) NULL,
        Rate DECIMAL(9,2) NULL,
        ResponsibleOwner NVARCHAR(150) NULL,
        Note NVARCHAR(500) NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_Breakdowns ON tblKPI_PeriodBreakdowns(PeriodKey, DonViID, KpiCode);
END;

-- 4. TẦNG QUẢN LÝ ĐIỂM VÊNH & KIỂM TOÁN SỐ LIỆU: tblKPI_AuditDiscrepancies
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_AuditDiscrepancies')
BEGIN
    CREATE TABLE tblKPI_AuditDiscrepancies (
        DiscrepancyID INT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL,
        AuditCode VARCHAR(50) NOT NULL,
        Category VARCHAR(50) NOT NULL, -- MISMATCH, BOTTLENECK, PARADOX
        Title NVARCHAR(250) NOT NULL,
        PrimarySource NVARCHAR(250) NOT NULL,
        PrimaryValue NVARCHAR(250) NOT NULL,
        SecondarySource NVARCHAR(250) NOT NULL,
        SecondaryValue NVARCHAR(250) NOT NULL,
        VarianceAnalysis NVARCHAR(MAX) NOT NULL,
        ActionOwner NVARCHAR(150) NOT NULL,
        VerificationStatus VARCHAR(50) DEFAULT 'PENDING_VERIFY', -- PENDING_VERIFY, CONFIRMED, RESOLVED
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END;

-- 5. TẦNG BÁO CÁO ĐỊNH TÍNH & CHỈ ĐẠO BGH: tblKPI_PeriodNarratives
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_PeriodNarratives')
BEGIN
    CREATE TABLE tblKPI_PeriodNarratives (
        NarrativeRecordID INT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        DomainCode VARCHAR(50) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL,
        Heading NVARCHAR(250) NOT NULL,
        ContentText NVARCHAR(MAX) NOT NULL,
        DirectiveAction NVARCHAR(500) NULL,
        Author NVARCHAR(100) DEFAULT 'Ban Giám Hiệu',
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END;
