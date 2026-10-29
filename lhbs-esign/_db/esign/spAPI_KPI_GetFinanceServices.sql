-- ===================================================================================
-- STORED PROCEDURE: spAPI_KPI_GetFinanceServices
-- Mô tả: Cung cấp dữ liệu Báo cáo Tài chính Dịch vụ (Chỉ tiêu 55) & Doanh thu CLB (Chỉ tiêu 56)
-- Đọc trực tiếp từ kho snapshot đóng băng tblKPI_Snap_Finance_Services
-- Database: eSignature
-- ===================================================================================

CREATE   PROCEDURE spAPI_KPI_GetFinanceServices
    @PeriodKey VARCHAR(20),
    @ScopeID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    IF @ScopeID IS NULL OR @ScopeID = ''
        SET @ScopeID = 'ALL';

    -- 1. RESULT SET 0: 5 MẢNG HOẠT ĐỘNG / DỊCH VỤ CHÍNH KHÓA & BÁN TRÚ (Chỉ tiêu 55)
    SELECT 
        RecordID,
        PeriodKey,
        ScopeID,
        ItemName AS [name],
        FORMAT(NetRevenue / 1000000000.0, 'N2') + N' tỷ' AS revenue,
        FORMAT(DirectCost / 1000000000.0, 'N2') + N' tỷ' AS cost,
        FORMAT(GrossProfit / 1000000000.0, 'N2') + N' tỷ' AS grossProfit,
        FORMAT(GrossMarginPct, 'N1') + N'%' AS margin,
        NetRevenue AS rawRevenue,
        DirectCost AS rawCost,
        GrossProfit AS rawGrossProfit,
        GrossMarginPct AS rawMarginPct
    FROM tblKPI_Snap_Finance_Services
    WHERE PeriodKey = @PeriodKey 
      AND ScopeID = @ScopeID
      AND CategoryType = 'OPERATION_SERVICE'
    ORDER BY NetRevenue DESC;

    -- 2. RESULT SET 1: DANH MỤC CÁC CÂU LẠC BỘ BỔ TRỢ (Chỉ tiêu 56)
    SELECT 
        RecordID,
        PeriodKey,
        ScopeID,
        ItemName AS [name],
        StudentCount AS students,
        FORMAT(UnitPricePerPeriod / 1000000.0, 'N1') + N' tr/kỳ' AS fee,
        FORMAT(NetRevenue / 1000000.0, 'N0') + N' triệu' AS revenue,
        FORMAT(RevenueSharePct, 'N1') + N'%' AS share,
        NetRevenue AS rawRevenue,
        StudentCount AS rawStudents
    FROM tblKPI_Snap_Finance_Services
    WHERE PeriodKey = @PeriodKey 
      AND ScopeID = @ScopeID
      AND CategoryType = 'CLUB'
    ORDER BY NetRevenue DESC;

    -- 3. RESULT SET 2: HÀNG TỔNG KẾT HỢP NHẤT (Tự động tính bằng SUM, không hardcode)
    SELECT 
        -- Tổng hợp mảng dịch vụ
        ISNULL(SUM(CASE WHEN CategoryType = 'OPERATION_SERVICE' THEN NetRevenue ELSE 0 END), 0) AS TotalOpRevenue,
        ISNULL(SUM(CASE WHEN CategoryType = 'OPERATION_SERVICE' THEN DirectCost ELSE 0 END), 0) AS TotalOpCost,
        ISNULL(SUM(CASE WHEN CategoryType = 'OPERATION_SERVICE' THEN GrossProfit ELSE 0 END), 0) AS TotalOpGrossProfit,
        CASE 
            WHEN SUM(CASE WHEN CategoryType = 'OPERATION_SERVICE' THEN NetRevenue ELSE 0 END) > 0 
            THEN (SUM(CASE WHEN CategoryType = 'OPERATION_SERVICE' THEN GrossProfit ELSE 0 END) / SUM(CASE WHEN CategoryType = 'OPERATION_SERVICE' THEN NetRevenue ELSE 0 END)) * 100.0 
            ELSE 0 
        END AS TotalOpMarginPct,

        -- Tổng hợp mảng CLB
        ISNULL(SUM(CASE WHEN CategoryType = 'CLUB' THEN StudentCount ELSE 0 END), 0) AS TotalClubStudents,
        ISNULL(SUM(CASE WHEN CategoryType = 'CLUB' THEN NetRevenue ELSE 0 END), 0) AS TotalClubRevenue,
        COUNT(CASE WHEN CategoryType = 'CLUB' THEN 1 END) AS TotalClubSubjects
    FROM tblKPI_Snap_Finance_Services
    WHERE PeriodKey = @PeriodKey 
      AND ScopeID = @ScopeID;
END;
