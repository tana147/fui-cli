-- Migration: Create tblKPI_StrategicLevers
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_StrategicLevers')
BEGIN
    CREATE TABLE tblKPI_StrategicLevers (
        LeverID INT IDENTITY(1,1) PRIMARY KEY,
        PeriodKey VARCHAR(20) NOT NULL,
        SortOrder INT NOT NULL DEFAULT 1,
        Title NVARCHAR(250) NOT NULL,
        Description NVARCHAR(500) NOT NULL,
        TargetKpiCode VARCHAR(20) NOT NULL DEFAULT 'TS01',
        StudentsGain INT NOT NULL,
        RevenueGainMillion DECIMAL(18,2) NOT NULL,
        IsPriority BIT NOT NULL DEFAULT 0,
        OwnerRole NVARCHAR(150) NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );

    INSERT INTO tblKPI_StrategicLevers (PeriodKey, SortOrder, Title, Description, TargetKpiCode, StudentsGain, RevenueGainMillion, IsPriority, OwnerRole)
    VALUES
        ('2026-09', 1, N'1. Chặn rò rỉ & Gom tuyến xe bus', N'Bảo toàn học sinh nguy cơ chuyển trường vì khoảng cách địa lý', 'TS04', 15, 978.0, 1, N'Quản trị CSVC & Xe Bus'),
        ('2026-09', 2, N'2. Tuyển sinh Mầm non Kitty 18–36 tháng', N'Tuyển bổ sung quanh năm lấp đầy các phòng học còn trống', 'TS06', 35, 1300.0, 0, N'BGH Mầm non & TVTS'),
        ('2026-09', 3, N'3. Liên thông chuyển cấp nội bộ (Lá lên 1, Khối 5 lên 6)', N'Nâng tỷ lệ chuyển tiếp nội bộ đạt mục tiêu đề ra', 'TS01', 65, 3220.0, 0, N'BGH Tiểu học & THCS'),
        ('2026-09', 4, N'4. Tuyển chọn lọc Khối 10 HK2 & Học bổng', N'Tuyển bổ sung học sinh trùng tổ hợp môn GDPT 2018', 'TS06', 10, 652.0, 0, N'Phòng Tuyển Sinh & TVTS');
END;
