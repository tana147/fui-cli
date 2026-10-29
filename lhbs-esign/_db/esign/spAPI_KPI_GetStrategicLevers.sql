-- ===================================================================================
-- STORED PROCEDURE: spAPI_KPI_GetStrategicLevers
-- Mô tả: Dynamic Strategic Levers & Value Bridge Waterfall Data
-- Tính toán lộ trình bù hụt sĩ số và lượng hóa 4 đòn bẩy chiến lược
-- Database: eSignature
-- ===================================================================================

CREATE   PROCEDURE spAPI_KPI_GetStrategicLevers
    @PeriodKey VARCHAR(20) = '2026-09'
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    -- Lấy Sĩ số thực tế và Chỉ tiêu từ Snapshots của kỳ báo cáo
    DECLARE @BaseVal INT = 2625;
    DECLARE @PlanVal INT = 2750;

    SELECT 
        @BaseVal = ISNULL(MAX(CASE WHEN KpiCode = 'TS01' THEN CAST(ActualValue AS INT) END), 2625),
        @PlanVal = ISNULL(MAX(CASE WHEN KpiCode = 'TS01' THEN CAST(TargetValue AS INT) END), 2750)
    FROM tblKPI_PeriodSnapshots
    WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL';

    -- RESULT SET 0: WATERFALL BARS SPEC
    SELECT 
        BarIndex,
        BarName,
        StepDelta,
        CumulativeVal,
        BarType,
        MoneyText,
        Line1,
        Line2
    FROM (
        VALUES
        (0, N'Sĩ số T9', 0, @BaseVal, 'total', CAST(@BaseVal AS NVARCHAR(10)) + N' HS', N'Sĩ số T9', CAST(@BaseVal AS NVARCHAR(10)) + N' HS'),
        (1, N'Gom tuyến bus', 15, @BaseVal + 15, 'up', N'+0.98 tỷ', N'Gom bus', N'+15 HS'),
        (2, N'MN Kitty', 35, @BaseVal + 15 + 35, 'up', N'+1.30 tỷ', N'MN Kitty', N'+35 HS'),
        (3, N'Liên thông cấp', 65, @BaseVal + 15 + 35 + 65, 'up', N'+3.22 tỷ', N'Chuyển cấp', N'+65 HS'),
        (4, N'Khối 10 HK2', 10, @PlanVal, 'up', N'+0.65 tỷ', N'Khối 10 HK2', N'+10 HS'),
        (5, N'Kế hoạch HĐQT', 0, @PlanVal, 'end', N'100% KH', N'Kế hoạch', CAST(@PlanVal AS NVARCHAR(10)) + N' HS')
    ) AS w (BarIndex, BarName, StepDelta, CumulativeVal, BarType, MoneyText, Line1, Line2);

    -- RESULT SET 1: 4 THẺ ĐÒN BẨY CHIẾN LƯỢC LƯỢNG HÓA DOANH THU
    SELECT 
        LeverID,
        Title,
        Description,
        StudentsGain,
        RevenueGainText,
        IsPriority,
        OwnerRole
    FROM (
        VALUES
        (
            1,
            N'1. Chặn rò rỉ & Gom tuyến xe bus',
            N'Bảo toàn 15 HS nguy cơ chuyển trường xa · Đầu mối: Quản trị CSVC',
            N'+15 HS',
            N'+978 tr/năm',
            1,
            N'Quản trị CSVC & Xe Bus'
        ),
        (
            2,
            N'2. Tuyển sinh Mầm non Kitty 18–36 tháng',
            N'Tuyển bổ sung quanh năm lấp phòng trống · Đầu mối: BGH Mầm non',
            N'+35 HS',
            N'+1.30 tỷ/năm',
            0,
            N'BGH Mầm non & TVTS'
        ),
        (
            3,
            N'3. Liên thông chuyển cấp nội bộ (Lá lên 1, Khối 5 lên 6)',
            N'Nâng tỷ lệ chuyển tiếp nội bộ đạt 92% · Đầu mối: BGH TH & THCS',
            N'+65 HS',
            N'+3.22 tỷ/năm',
            0,
            N'BGH Tiểu học & THCS'
        ),
        (
            4,
            N'4. Tuyển chọn lọc Khối 10 HK2 & Học bổng',
            N'Tuyển bổ sung học sinh trùng tổ hợp GDPT 2018 · Đầu mối: Tuyển sinh',
            N'+10 HS',
            N'+652 tr/năm',
            0,
            N'Phòng Tuyển Sinh & TVTS'
        )
    ) AS l (LeverID, Title, Description, StudentsGain, RevenueGainText, IsPriority, OwnerRole);
END;
