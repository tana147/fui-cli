-- =========================================================================
-- MIGRATION: DYNAMIC RISK RADAR ENGINE (ZERO HARDCODE)
-- Tạo bảng tblKPI_CampusCatalog & tblKPI_RiskDirectives
-- Phục vụ tính điểm rủi ro và checklist chỉ đạo HĐQT động
-- Database: eSignature (esign)
-- =========================================================================

-- 1. BẢNG DANH MỤC CƠ SỞ & CÔNG SUẤT: tblKPI_CampusCatalog
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_CampusCatalog')
BEGIN
    CREATE TABLE tblKPI_CampusCatalog (
        ScopeID VARCHAR(20) PRIMARY KEY,
        CampusName NVARCHAR(150) NOT NULL,
        ShortName NVARCHAR(50) NOT NULL,
        PlannedCapacity INT NOT NULL,
        CurrentEnrollment INT NOT NULL,
        BaseAnnualTuition DECIMAL(18,2) DEFAULT 65000000,
        SortOrder INT DEFAULT 1,
        IsActive BIT DEFAULT 1
    );

    INSERT INTO tblKPI_CampusCatalog 
        (ScopeID, CampusName, ShortName, PlannedCapacity, CurrentEnrollment, BaseAnnualTuition, SortOrder)
    VALUES
        ('MNLK', N'Mầm non Long Khánh', N'MN Long Khánh', 166, 129, 65000000, 1),
        ('TH',   N'Tiểu Học',           N'Tiểu Học',     1250, 1185, 65000000, 2),
        ('THPT', N'THPT',               N'THPT',          482,  334, 70000000, 3),
        ('THCS', N'THCS',               N'THCS',          537,  520, 70000000, 4),
        ('MNBH', N'Mầm non Tân Biên',   N'MN Tân Biên',   320,  306, 55000000, 5);
END;

-- 2. BẢNG CHECKLIST CHỈ ĐẠO ĐIỀU HÀNH HĐQT: tblKPI_RiskDirectives
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_RiskDirectives')
BEGIN
    CREATE TABLE tblKPI_RiskDirectives (
        DirectiveID INT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        ScopeID VARCHAR(20) NOT NULL DEFAULT 'ALL',
        DirectiveTitle NVARCHAR(250) NOT NULL,
        SubText NVARCHAR(500) NOT NULL,
        OwnerRole NVARCHAR(150) NOT NULL,
        DeadlineDate VARCHAR(30) NOT NULL,
        StatusBadge NVARCHAR(50) NOT NULL,
        StatusClass VARCHAR(30) NOT NULL DEFAULT 'is-urgent',
        SortOrder INT DEFAULT 1,
        CreatedAt DATETIME DEFAULT GETDATE()
    );

    CREATE INDEX IX_RiskDirectives_Period ON tblKPI_RiskDirectives(PeriodKey, ScopeID);

    INSERT INTO tblKPI_RiskDirectives
        (PeriodKey, ScopeID, DirectiveTitle, SubText, OwnerRole, DeadlineDate, StatusBadge, StatusClass, SortOrder)
    VALUES
        (
            '2026-09', 'MNLK',
            N'Mở Tuyến Bus 16 Chỗ Long Khánh & Trục Trảng Dài',
            N'Khảo sát luồng 21 HS rút vì xa trường; ký HĐ xe trung chuyển hoặc mở tuyến đưa đón chuyên biệt trước ngày 05/10.',
            N'Trưởng ban Vận hành CSVC & Xe Bus',
            '05/10/2026', N'Khẩn cấp', 'is-urgent', 1
        ),
        (
            '2026-09', 'TH',
            N'Xử Lý Dứt Điểm 4 Máy Lạnh Khu B & Thang Máy MNLK',
            N'Thay block điều hòa phòng học B201, B204; nghiệm thu kiểm định an toàn thang máy MNLK; không để tồn quá 48h.',
            N'Tổ trưởng Bảo trì & CSVC',
            '02/10/2026', N'Khẩn cấp', 'is-urgent', 2
        ),
        (
            '2026-09', 'TH',
            N'Khử Khuẩn Toàn Bộ Khối 4-5 & Kế Hoạch Bù Bài Cúm A',
            N'Phun khử khuẩn Cloramin B cuối tuần; GVCN gửi video bài giảng LMS cho 53 HS nghỉ ốm; tổ chức phụ đạo tuần đầu T10.',
            N'Hiệu trưởng TH & Y tế trường',
            '04/10/2026', N'Hành động ngay', 'is-action', 3
        ),
        (
            '2026-09', 'MNLK',
            N'Kiểm Toán Sĩ Số MN Long Khánh (129 vs 122 HS)',
            N'Đối soát chốt sổ Basic Data 129 HS với danh sách điểm danh thực tế 122 HS; làm rõ tình trạng 7 HS bảo lưu/chờ nhập.',
            N'Trưởng phòng TVTS & Kế toán',
            '03/10/2026', N'Hành động ngay', 'is-action', 4
        ),
        (
            '2026-09', 'THPT',
            N'Kế Hoạch Bù Đắp 148 Chỉ Tiêu Tuyển Sinh Lớp 10 THPT',
            N'Xây dựng chính sách ưu đãi tuyển bổ sung học sinh chuyển trường giữa kỳ; học bổng tài năng HK2; làm việc với đối tác.',
            N'Giám đốc TVTS & Hiệu trưởng THPT',
            '10/10/2026', N'Theo dõi', 'is-watch', 5
        ),
        (
            '2026-09', 'MNLK',
            N'Định Biên Lại Giáo Viên & Giảm Tải Dạy Thay MNLK',
            N'Cử 1 GV cơ động từ TH chi viện MNLK; tuyển thêm 1 bảo mẫu cơ hữu; rà soát chế độ phụ cấp dạy thay 288 tiết.',
            N'Trưởng phòng Nhân sự & Đào tạo',
            '08/10/2026', N'Theo dõi', 'is-watch', 6
        );
END;
