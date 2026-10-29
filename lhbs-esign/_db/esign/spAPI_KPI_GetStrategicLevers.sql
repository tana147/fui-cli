-- ===================================================================================
-- STORED PROCEDURE: spAPI_KPI_GetStrategicLevers
-- Mô tả: Dynamic Strategic Levers & Value Bridge Waterfall Data (100% Calculated)
-- Tính toán lộ trình bù hụt sĩ số và lượng hóa 4 đòn bẩy chiến lược từ CSDL
-- Database: eSignature
-- ===================================================================================

CREATE   PROCEDURE spAPI_KPI_GetStrategicLevers
    @PeriodKey VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    -- Lấy Sĩ số thực tế và Chỉ tiêu từ Snapshots của kỳ báo cáo
    DECLARE @BaseVal INT = 0;
    DECLARE @PlanVal INT = 0;

    SELECT 
        @BaseVal = ISNULL(MAX(CASE WHEN KpiCode = 'TS01' THEN CAST(ActualValue AS INT) END), 2625),
        @PlanVal = ISNULL(MAX(CASE WHEN KpiCode = 'TS01' THEN CAST(TargetValue AS INT) END), 2750)
    FROM tblKPI_PeriodSnapshots
    WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL';

    -- RESULT SET 0: WATERFALL BARS SPEC (Tính toán lũy kế động từ tblKPI_StrategicLevers)
    ;WITH LeversOrdered AS (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY SortOrder) AS BarIdx,
            Title AS BarName,
            StudentsGain AS StepDelta,
            RevenueGainMillion,
            N'+' + CAST(CAST(ROUND(RevenueGainMillion / 1000.0, 2) AS DECIMAL(6,2)) AS NVARCHAR(10)) + N' tỷ' AS MoneyText,
            CASE 
                WHEN TargetKpiCode = 'TS04' THEN N'Gom bus'
                WHEN Title LIKE N'%Kitty%' THEN N'MN Kitty'
                WHEN Title LIKE N'%Liên thông%' THEN N'Chuyển cấp'
                ELSE N'Khối 10 HK2'
            END AS Line1,
            N'+' + CAST(StudentsGain AS NVARCHAR(10)) + N' HS' AS Line2
        FROM tblKPI_StrategicLevers
        WHERE PeriodKey = @PeriodKey
    ),
    RunningSum AS (
        SELECT 
            l.BarIdx,
            l.BarName,
            l.StepDelta,
            @BaseVal + SUM(l.StepDelta) OVER (ORDER BY l.BarIdx) AS CumulativeVal,
            'up' AS BarType,
            l.MoneyText,
            l.Line1,
            l.Line2
        FROM LeversOrdered l
    )
    SELECT 
        0 AS BarIndex,
        N'Sĩ số hiện tại' AS BarName,
        0 AS StepDelta,
        @BaseVal AS CumulativeVal,
        'total' AS BarType,
        CAST(@BaseVal AS NVARCHAR(10)) + N' HS' AS MoneyText,
        N'Sĩ số kỳ' AS Line1,
        CAST(@BaseVal AS NVARCHAR(10)) + N' HS' AS Line2
    UNION ALL
    SELECT 
        BarIdx AS BarIndex,
        BarName,
        StepDelta,
        CumulativeVal,
        BarType,
        MoneyText,
        Line1,
        Line2
    FROM RunningSum
    UNION ALL
    SELECT 
        (SELECT COUNT(*) + 1 FROM LeversOrdered) AS BarIndex,
        N'Kế hoạch HĐQT' AS BarName,
        0 AS StepDelta,
        @PlanVal AS CumulativeVal,
        'end' AS BarType,
        N'100% KH' AS MoneyText,
        N'Kế hoạch' AS Line1,
        CAST(@PlanVal AS NVARCHAR(10)) + N' HS' AS Line2
    ORDER BY BarIndex;

    -- RESULT SET 1: CÁC THẺ ĐÒN BẨY CHIẾN LƯỢC LƯỢNG HÓA DOANH THU (Đọc từ tblKPI_StrategicLevers)
    SELECT 
        LeverID,
        Title,
        Description,
        N'+' + CAST(StudentsGain AS NVARCHAR(10)) + N' HS' AS StudentsGain,
        N'+' + CAST(CAST(ROUND(RevenueGainMillion, 0) AS INT) AS NVARCHAR(20)) + N' tr/năm' AS RevenueGainText,
        IsPriority,
        OwnerRole
    FROM tblKPI_StrategicLevers
    WHERE PeriodKey = @PeriodKey
    ORDER BY SortOrder;
END;
