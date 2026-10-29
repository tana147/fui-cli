-- ===================================================================================
-- MIGRATION V3: HOLISTIC SNAPSHOT ARCHITECTURE (FACT VAULT)
-- Database: eSignature
-- Mục tiêu: 
-- 1. Xóa bỏ hoàn toàn hardcode trong spAPI_KPI_GetOperationsSummary
-- 2. Tách nhỏ các cấu trúc CRM & Safety thành các bảng chuyên biệt linh hoạt
-- 3. Hỗ trợ mở rộng đa kỳ (Tháng 9, Tháng 10...), đa cơ sở (Holding)
-- ===================================================================================

-- 1. BẢNG SNAPSHOT AN TOÀN HỌC ĐƯỜNG & ỨNG DỤNG ME SCHOOL (Result Set 0)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_Safety_Me')
BEGIN
    CREATE TABLE tblKPI_Snap_Safety_Me (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,           -- '2026-09', '2026-10'
        ScopeID VARCHAR(50) NOT NULL DEFAULT 'ALL', -- 'ALL', 'MNTB', 'MNLK', 'TH', 'THCS', 'THPT'
        FoodPoisoningCases INT DEFAULT 0,         -- Số vụ ngộ độc thực phẩm (Chỉ tiêu: 0)
        AccidentCases INT DEFAULT 0,              -- Số vụ tai nạn thương tích (Chỉ tiêu: 0)
        BoardingRate DECIMAL(9,2) DEFAULT 0,      -- Tỷ lệ học sinh ăn bán trú (%)
        BoardingStudents INT DEFAULT 0,           -- Số học sinh ăn bán trú
        MeAppInstallRate DECIMAL(9,2) DEFAULT 0,  -- Tỷ lệ cài đặt ME School (%)
        MeAppInstallParents INT DEFAULT 0,        -- Số phụ huynh cài đặt app ME
        NewsInteractions INT DEFAULT 0,           -- Lượt tương tác bản tin / tháng
        FaceIdCheckins INT DEFAULT 0,             -- Lượt điểm danh FaceID
        SatisfactionRate DECIMAL(9,2) DEFAULT 0,  -- Tỷ lệ phụ huynh hài lòng (%)
        Note NVARCHAR(500) NULL,
        UpdatedAt DATETIME DEFAULT GETDATE(),
        CONSTRAINT UQ_KPI_Snap_Safety_Me UNIQUE (PeriodKey, ScopeID)
    );
    CREATE INDEX IX_KPI_Snap_Safety_Me ON tblKPI_Snap_Safety_Me(PeriodKey, ScopeID);
    PRINT 'Đã tạo bảng tblKPI_Snap_Safety_Me thành công.';
END;

-- 2. BẢNG SNAPSHOT HIỆU QUẢ KÊNH TIẾP CẬN MARKETING / CRM (Result Set 2)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_Channels')
BEGIN
    CREATE TABLE tblKPI_Snap_CRM_Channels (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL DEFAULT 'ALL',
        ChannelName NVARCHAR(250) NOT NULL,       -- Facebook, Người quen, Vãng lai, Zalo...
        LeadsCount INT NOT NULL DEFAULT 0,        -- Số leads tiếp cận
        LeadsPct DECIMAL(9,2) NULL,               -- Tỷ trọng (%)
        EnrolledCount INT NOT NULL DEFAULT 0,     -- Số nhập học thực tế
        ConvRatePct DECIMAL(9,2) NULL,            -- Tỷ lệ chuyển đổi kênh (%)
        RankOrder INT DEFAULT 1,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_KPI_Snap_CRM_Channels ON tblKPI_Snap_CRM_Channels(PeriodKey, ScopeID);
    PRINT 'Đã tạo bảng tblKPI_Snap_CRM_Channels thành công.';
END;

-- 3. BẢNG SNAPSHOT PIPELINE ỨNG VIÊN / KH TIỀM NĂNG HẸN KỲ SAU (Result Set 3)
-- Thay thế cho KittyPipelineJson cứng, dùng cho mọi chiến dịch & cấp học
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_Prospects')
BEGIN
    CREATE TABLE tblKPI_Snap_CRM_Prospects (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL DEFAULT 'ALL',
        CampaignCode VARCHAR(100) DEFAULT 'ALL',  -- 'KITTY_HK2', 'CAP_1_LEN_2', 'OPEN_DAY'...
        Stt INT NULL,
        MonthLabel NVARCHAR(50) NULL,             -- 'T08/2026', 'T09/2026'
        ParentName NVARCHAR(200) NOT NULL,        -- Tên phụ huynh
        ClassOrTarget NVARCHAR(100) NULL,         -- Lớp / Đối tượng (Kitty, Lớp 1...)
        StudentName NVARCHAR(200) NOT NULL,       -- Tên học sinh / Năm sinh
        StatusDescription NVARCHAR(500) NULL,     -- Tình trạng (Chờ đủ tuổi, đã cọc...)
        AppointmentNote NVARCHAR(500) NULL,       -- Lịch hẹn (Liên hệ lại T11, hẹn Open Day...)
        RankOrder INT DEFAULT 1,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_KPI_Snap_CRM_Prospects ON tblKPI_Snap_CRM_Prospects(PeriodKey, ScopeID, CampaignCode);
    PRINT 'Đã tạo bảng tblKPI_Snap_CRM_Prospects thành công.';
END;

-- 4. BẢNG SNAPSHOT NGUYÊN NHÂN RỚT HỒ SƠ TUYỂN SINH (Result Set 4)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_DropReasons')
BEGIN
    CREATE TABLE tblKPI_Snap_CRM_DropReasons (
        RecordID BIGINT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(50) NOT NULL DEFAULT 'ALL',
        ReasonText NVARCHAR(500) NOT NULL,        -- Khoảng cách xa, Học phí, Không phản hồi...
        ReasonCount INT NOT NULL DEFAULT 0,       -- Số lượng leads rớt vì lý do này
        ReasonPct DECIMAL(9,2) NULL,              -- Tỷ trọng (%)
        SolutionAction NVARCHAR(500) NULL,        -- Giải pháp khắc phục đề xuất
        RankOrder INT DEFAULT 1,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_KPI_Snap_CRM_DropReasons ON tblKPI_Snap_CRM_DropReasons(PeriodKey, ScopeID);
    PRINT 'Đã tạo bảng tblKPI_Snap_CRM_DropReasons thành công.';
END;

-- 5. ĐẢM BẢO tblKPI_Snap_CRM_Pipeline CÓ CỘT ScopeID
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_Pipeline')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblKPI_Snap_CRM_Pipeline') AND name = 'ScopeID')
    BEGIN
        ALTER TABLE tblKPI_Snap_CRM_Pipeline ADD ScopeID VARCHAR(50) NOT NULL DEFAULT 'ALL';
        PRINT 'Đã bổ sung cột ScopeID cho tblKPI_Snap_CRM_Pipeline.';
    END;
END;
