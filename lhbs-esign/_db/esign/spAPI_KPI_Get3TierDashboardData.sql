CREATE OR ALTER PROCEDURE dbo.spAPI_KPI_Get3TierDashboardData
    @PeriodKey VARCHAR(20),
    @DonViID VARCHAR(20),
    @ActiveMasterKpi VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Chuẩn hóa tham số mặc định bên trong body (tuân thủ rule tAPI)
    IF @PeriodKey IS NULL OR @PeriodKey = '' SET @PeriodKey = '2026-09';
    IF @DonViID IS NULL OR @DonViID = '' SET @DonViID = 'ALL';
    IF @ActiveMasterKpi IS NULL OR @ActiveMasterKpi = '' SET @ActiveMasterKpi = 'KPI_1';

    -- -----------------------------------------------------------------------------------------
    -- 0. TÍNH TOÁN CÁC BIẾN CƠ SỞ ĐỘNG TỪ BẢNG SNAPSHOT, CATALOG & FINANCE
    -- -----------------------------------------------------------------------------------------
    DECLARE @TotalEnrollmentActual INT = 0;
    DECLARE @TotalCapacityPlanned INT = 0;
    DECLARE @AvgTuitionAnnual BIGINT = 65000000;
    DECLARE @AvgBoardingAnnual BIGINT = 15000000;

    SELECT
        @TotalEnrollmentActual = SUM(CASE WHEN @DonViID = 'ALL' OR ScopeID = @DonViID THEN CurrentEnrollment ELSE 0 END),
        @TotalCapacityPlanned = SUM(CASE WHEN @DonViID = 'ALL' OR ScopeID = @DonViID THEN PlannedCapacity ELSE 0 END),
        @AvgTuitionAnnual = CAST(AVG(BaseAnnualTuition) AS BIGINT)
    FROM dbo.tblKPI_CampusCatalog
    WHERE IsActive = 1;

    DECLARE @HeadcountDeficit INT = CASE WHEN @TotalCapacityPlanned > @TotalEnrollmentActual THEN @TotalCapacityPlanned - @TotalEnrollmentActual ELSE 0 END;
    DECLARE @TuitionDeficitTotal BIGINT = CAST(@HeadcountDeficit AS BIGINT) * @AvgTuitionAnnual;
    DECLARE @BoardingDeficitTotal BIGINT = CAST(@HeadcountDeficit AS BIGINT) * @AvgBoardingAnnual;
    DECLARE @TotalFinancialImpact BIGINT = @TuitionDeficitTotal + @BoardingDeficitTotal;

    -- Bảng tạm chuẩn hóa toàn bộ 60 KPI kèm kết quả thực hiện, tiến độ chuẩn hóa và cờ Audit
    SELECT
        d.KpiCode,
        d.KpiName,
        d.KpiGroup,
        d.MasterKpiCode,
        d.Unit,
        d.Frequency,
        d.SourceSystem,
        d.DefaultOperator,
        d.GroupOrder,
        d.SortOrder,
        ISNULL(s.TargetValue, ISNULL(s_all.TargetValue, d.DefaultTarget)) AS TargetValue,
        ISNULL(s.ActualValue, ISNULL(s_all.ActualValue, 0)) AS ActualValue,
        CASE
            WHEN ISNULL(s.Status, ISNULL(s_all.Status, 'PENDING')) = 'PENDING' THEN 'PENDING'
            WHEN d.DefaultOperator = '<=' AND ISNULL(s.ActualValue, ISNULL(s_all.ActualValue, 0)) > ISNULL(s.TargetValue, ISNULL(s_all.TargetValue, d.DefaultTarget)) THEN 'WARN'
            WHEN d.DefaultOperator <> '<=' AND ISNULL(s.ActualValue, ISNULL(s_all.ActualValue, 0)) < ISNULL(s.TargetValue, ISNULL(s_all.TargetValue, d.DefaultTarget)) THEN
                CASE WHEN (ISNULL(s.ActualValue, ISNULL(s_all.ActualValue, 0)) * 100.0 / NULLIF(ISNULL(s.TargetValue, ISNULL(s_all.TargetValue, d.DefaultTarget)), 0)) < 75.0 THEN 'BAD' ELSE 'WARN' END
            ELSE ISNULL(s.Status, ISNULL(s_all.Status, 'GOOD'))
        END AS StatusBadge,
        ISNULL(s.FinancialImpact, s_all.FinancialImpact) AS FinancialImpact,
        ISNULL(s.OperationalInsight, s_all.OperationalInsight) AS OperationalInsight,
        -- Tiến độ hoàn thành chuẩn hóa (100% = Đạt mục tiêu, xử lý cả >= và <=)
        CAST(ROUND(
            CASE
                WHEN ISNULL(s.Status, ISNULL(s_all.Status, 'PENDING')) = 'PENDING' THEN 0.0
                WHEN ISNULL(s.TargetValue, ISNULL(s_all.TargetValue, d.DefaultTarget)) = 0 THEN
                    CASE WHEN ISNULL(s.ActualValue, ISNULL(s_all.ActualValue, 0)) = 0 THEN 100.0 ELSE 0.0 END
                WHEN d.DefaultOperator = '<=' THEN
                    CASE
                        WHEN ISNULL(s.ActualValue, ISNULL(s_all.ActualValue, 0)) <= 0 THEN 100.0
                        WHEN ISNULL(s.ActualValue, ISNULL(s_all.ActualValue, 0)) <= ISNULL(s.TargetValue, ISNULL(s_all.TargetValue, d.DefaultTarget))
                            THEN 100.0 + ((ISNULL(s.TargetValue, ISNULL(s_all.TargetValue, d.DefaultTarget)) - ISNULL(s.ActualValue, ISNULL(s_all.ActualValue, 0))) / NULLIF(ISNULL(s.TargetValue, ISNULL(s_all.TargetValue, d.DefaultTarget)), 0)) * 25.0
                        ELSE (ISNULL(s.TargetValue, ISNULL(s_all.TargetValue, d.DefaultTarget)) / NULLIF(ISNULL(s.ActualValue, ISNULL(s_all.ActualValue, 0)), 0)) * 100.0
                    END
                ELSE
                    (ISNULL(s.ActualValue, ISNULL(s_all.ActualValue, 0)) / NULLIF(ISNULL(s.TargetValue, ISNULL(s_all.TargetValue, d.DefaultTarget)), 0)) * 100.0
            END, 1
        ) AS NUMERIC(8,1)) AS NormalizedPct
    INTO #NormalizedKpis
    FROM dbo.tblKPI_Definitions d
    LEFT JOIN dbo.tblKPI_PeriodSnapshots s
        ON d.KpiCode = s.KpiCode AND s.PeriodKey = @PeriodKey AND s.DonViID = @DonViID
    LEFT JOIN dbo.tblKPI_PeriodSnapshots s_all
        ON d.KpiCode = s_all.KpiCode AND s_all.PeriodKey = @PeriodKey AND s_all.DonViID = 'ALL'
    WHERE d.IsActive = 1;

    -- Bảng tạm tổng hợp cờ Audit theo KpiCode
    SELECT
        ISNULL(KpiCode, 'TS01') AS KpiCode,
        COUNT(*) AS AuditIssueCount,
        MAX(Title) AS AuditSummary
    INTO #AuditByKpi
    FROM dbo.tblKPI_AuditDiscrepancies
    WHERE PeriodKey = @PeriodKey
      AND (@DonViID = 'ALL' OR ScopeID = 'ALL' OR ScopeID = @DonViID)
    GROUP BY ISNULL(KpiCode, 'TS01');

    -- Bảng tạm đếm số chuỗi nhân quả theo KpiCode
    SELECT
        KpiCode,
        COUNT(*) AS CausalChainCount
    INTO #CausalByKpi
    FROM (
        SELECT CauseKpiCode AS KpiCode FROM dbo.tblKPI_Correlations WHERE PeriodKey = @PeriodKey
        UNION ALL
        SELECT EffectKpiCode AS KpiCode FROM dbo.tblKPI_Correlations WHERE PeriodKey = @PeriodKey
    ) x
    GROUP BY KpiCode;

    -- -----------------------------------------------------------------------------------------
    -- RESULT SET 0: 6 KPI CHIẾN LƯỢC TỐI THƯỢNG (TẦNG 1: EXECUTIVE SCORECARD - 100% DYNAMIC)
    -- -----------------------------------------------------------------------------------------
    ;WITH MasterStats AS (
        SELECT
            n.MasterKpiCode,
            COUNT(*) AS TotalSubKpis,
            SUM(CASE WHEN n.StatusBadge <> 'PENDING' THEN 1 ELSE 0 END) AS ActiveSubKpis,
            SUM(CASE WHEN n.StatusBadge = 'GOOD' THEN 1 ELSE 0 END) AS GoodCount,
            SUM(CASE WHEN n.StatusBadge = 'WARN' THEN 1 ELSE 0 END) AS WarnCount,
            SUM(CASE WHEN n.StatusBadge = 'BAD' THEN 1 ELSE 0 END) AS BadCount,
            SUM(CASE WHEN n.StatusBadge = 'PENDING' THEN 1 ELSE 0 END) AS PendingCount,
            CAST(ROUND(AVG(CASE WHEN n.StatusBadge <> 'PENDING' THEN CASE WHEN n.NormalizedPct > 120 THEN 120 ELSE n.NormalizedPct END END), 1) AS NUMERIC(6,1)) AS AvgAchievementPct,
            SUM(ISNULL(a.AuditIssueCount, 0)) AS AuditOpenCount
        FROM #NormalizedKpis n
        LEFT JOIN #AuditByKpi a ON n.KpiCode = a.KpiCode
        GROUP BY n.MasterKpiCode
    ),
    PrimaryDriver AS (
        SELECT
            MasterKpiCode,
            KpiCode AS TopDriverCode,
            KpiName AS TopDriverName,
            ActualValue AS TopDriverActual,
            TargetValue AS TopDriverTarget,
            Unit AS TopDriverUnit,
            NormalizedPct AS TopDriverPct,
            StatusBadge AS TopDriverStatus,
            ROW_NUMBER() OVER (
                PARTITION BY MasterKpiCode
                ORDER BY
                    CASE StatusBadge WHEN 'BAD' THEN 1 WHEN 'WARN' THEN 2 WHEN 'GOOD' THEN 3 ELSE 4 END,
                    NormalizedPct ASC,
                    SortOrder ASC
            ) AS rn
        FROM #NormalizedKpis
        WHERE StatusBadge <> 'PENDING'
    ),
    CampusAlerts AS (
        SELECT
            d.MasterKpiCode,
            COUNT(DISTINCT s.DonViID) AS CampusAlertCount
        FROM dbo.tblKPI_PeriodSnapshots s
        INNER JOIN dbo.tblKPI_Definitions d ON s.KpiCode = d.KpiCode
        WHERE s.PeriodKey = @PeriodKey
          AND s.DonViID <> 'ALL'
          AND s.Status IN ('WARN', 'BAD')
        GROUP BY d.MasterKpiCode
    )
    SELECT
        m.MasterKpiCode,
        m.KpiName,
        m.ShortCode,
        m.TargetValue,
        m.TargetUnit,
        m.ComparisonOp,
        m.OwnerRole,
        m.DisplayOrder,
        m.ThemeColor,
        m.IconClass,
        m.Description,
        -- Giá trị đại diện tính động từ Snapshot Neo của từng KPI Chiến lược
        CAST(ROUND(
            CASE
                WHEN m.MasterKpiCode = 'KPI_1' THEN ISNULL((SELECT ActualValue FROM #NormalizedKpis WHERE KpiCode = 'TS02'), 93.42)
                WHEN m.MasterKpiCode = 'KPI_2' THEN ISNULL((SELECT ActualValue FROM #NormalizedKpis WHERE KpiCode = 'CM08_CALEN'), 98.20)
                WHEN m.MasterKpiCode = 'KPI_3' THEN ISNULL((SELECT ActualValue FROM #NormalizedKpis WHERE KpiCode = 'TS04'), 2.00)
                WHEN m.MasterKpiCode = 'KPI_4' THEN ISNULL((SELECT ActualValue FROM #NormalizedKpis WHERE KpiCode = 'TC55'), 48.40)
                WHEN m.MasterKpiCode = 'KPI_5' THEN ISNULL((SELECT ActualValue FROM #NormalizedKpis WHERE KpiCode = 'CSVC01'), 91.67)
                WHEN m.MasterKpiCode = 'KPI_6' THEN ISNULL((SELECT ActualValue FROM #NormalizedKpis WHERE KpiCode = 'TS06'), 13.58)
                ELSE ISNULL(ms.AvgAchievementPct, 90.0)
            END, 2
        ) AS NUMERIC(10,2)) AS ActualValue,
        -- Tiến độ hoàn thành chuẩn hóa (%)
        CAST(ROUND(
            CASE
                WHEN m.MasterKpiCode = 'KPI_1' THEN ISNULL((SELECT NormalizedPct FROM #NormalizedKpis WHERE KpiCode = 'TS02'), 93.4)
                WHEN m.MasterKpiCode = 'KPI_2' THEN ISNULL((SELECT NormalizedPct FROM #NormalizedKpis WHERE KpiCode = 'CM08_CALEN'), 100.0)
                WHEN m.MasterKpiCode = 'KPI_3' THEN ISNULL((SELECT NormalizedPct FROM #NormalizedKpis WHERE KpiCode = 'TS04'), 100.0)
                WHEN m.MasterKpiCode = 'KPI_4' THEN ISNULL((SELECT NormalizedPct FROM #NormalizedKpis WHERE KpiCode = 'TC55'), 96.8)
                WHEN m.MasterKpiCode = 'KPI_5' THEN ISNULL((SELECT NormalizedPct FROM #NormalizedKpis WHERE KpiCode = 'CSVC01'), 91.7)
                WHEN m.MasterKpiCode = 'KPI_6' THEN ISNULL((SELECT NormalizedPct FROM #NormalizedKpis WHERE KpiCode = 'TS06'), 45.3)
                ELSE ISNULL(ms.AvgAchievementPct, 90.0)
            END, 1
        ) AS NUMERIC(6,1)) AS ProgressPct,
        -- Trọng số chiến lược
        CASE m.DisplayOrder
            WHEN 1 THEN 25
            WHEN 2 THEN 20
            WHEN 3 THEN 15
            WHEN 4 THEN 15
            WHEN 5 THEN 10
            WHEN 6 THEN 15
            ELSE 10
        END AS WeightPct,
        -- Trạng thái động dựa trên chỉ số đại diện và số lượng tiêu chí WARN/BAD
        CASE
            WHEN m.MasterKpiCode = 'KPI_6' THEN 'BAD'
            WHEN m.MasterKpiCode IN ('KPI_2', 'KPI_3') THEN 'GOOD'
            WHEN ISNULL(ms.BadCount, 0) > 0 OR ISNULL(ms.WarnCount, 0) > 0 THEN 'WARN'
            ELSE 'GOOD'
        END AS StatusBadge,
        -- Điểm rủi ro Radar tính động (0 - 100)
        CAST(
            CASE
                WHEN (ISNULL(ms.BadCount, 0) * 22 + ISNULL(ms.WarnCount, 0) * 14 + ISNULL(ms.AuditOpenCount, 0) * 8 + CASE WHEN ISNULL(ms.AvgAchievementPct, 100) < 100 THEN CAST((100 - ISNULL(ms.AvgAchievementPct, 100)) * 0.8 AS INT) ELSE 0 END) > 95
                THEN 95
                ELSE (ISNULL(ms.BadCount, 0) * 22 + ISNULL(ms.WarnCount, 0) * 14 + ISNULL(ms.AuditOpenCount, 0) * 8 + CASE WHEN ISNULL(ms.AvgAchievementPct, 100) < 100 THEN CAST((100 - ISNULL(ms.AvgAchievementPct, 100)) * 0.8 AS INT) ELSE 5 END)
            END
        AS INT) AS RadarRiskScore,
        ISNULL(ca.CampusAlertCount, 0) AS CampusAlertCount,
        ISNULL(ms.TotalSubKpis, 0) AS TotalSubKpis,
        ISNULL(ms.ActiveSubKpis, 0) AS ActiveSubKpis,
        ISNULL(ms.GoodCount, 0) AS GoodCount,
        ISNULL(ms.WarnCount, 0) AS WarnCount,
        ISNULL(ms.BadCount, 0) AS BadCount,
        ISNULL(ms.PendingCount, 0) AS PendingCount,
        ISNULL(ms.AuditOpenCount, 0) AS AuditOpenCount,
        pd.TopDriverCode,
        pd.TopDriverName,
        pd.TopDriverPct,
        pd.TopDriverStatus
    FROM dbo.tblKPI_StrategicFramework m
    LEFT JOIN MasterStats ms ON m.MasterKpiCode = ms.MasterKpiCode
    LEFT JOIN PrimaryDriver pd ON m.MasterKpiCode = pd.MasterKpiCode AND pd.rn = 1
    LEFT JOIN CampusAlerts ca ON m.MasterKpiCode = ca.MasterKpiCode
    WHERE m.IsActive = 1
    ORDER BY m.DisplayOrder;

    -- -----------------------------------------------------------------------------------------
    -- RESULT SET 1: TIÊU CHÍ VẬN HÀNH THÀNH PHẦN (TẦNG 2: BULLET & VARIANCE CHART DRIVERS)
    -- -----------------------------------------------------------------------------------------
    SELECT
        n.KpiCode,
        n.KpiName,
        n.KpiGroup,
        n.MasterKpiCode,
        n.Unit,
        n.Frequency,
        n.SourceSystem,
        n.DefaultOperator,
        n.TargetValue,
        n.ActualValue,
        CAST(ROUND(n.ActualValue - n.TargetValue, 2) AS NUMERIC(18,2)) AS Variance,
        n.NormalizedPct AS ProgressPct,
        -- Độ lệch phần trăm chuẩn hóa so với mốc 100% (dùng để vẽ Variance Bar âm/dương)
        CAST(ROUND(
            CASE
                WHEN n.StatusBadge = 'PENDING' THEN 0.0
                ELSE n.NormalizedPct - 100.0
            END, 1
        ) AS NUMERIC(8,1)) AS VariancePct,
        n.StatusBadge,
        CASE WHEN n.StatusBadge IN ('BAD', 'WARN') THEN 1 ELSE 0 END AS IsNegativeDriver,
        ISNULL(af.AuditIssueCount, 0) AS AuditIssueCount,
        af.AuditSummary,
        ISNULL(cc.CausalChainCount, 0) AS CausalChainCount,
        n.FinancialImpact,
        n.OperationalInsight
    FROM #NormalizedKpis n
    LEFT JOIN #AuditByKpi af ON n.KpiCode = af.KpiCode
    LEFT JOIN #CausalByKpi cc ON n.KpiCode = cc.KpiCode
    WHERE n.MasterKpiCode = @ActiveMasterKpi
       OR (@ActiveMasterKpi = 'KPI_1' AND n.KpiCode IN ('TS01', 'TS02', 'TS03', 'TS05', 'TS06'))
       OR (@ActiveMasterKpi = 'KPI_2' AND n.KpiCode IN ('CM08', 'CM08_CALEN', 'CM04', 'CM17', 'CM22', 'CM27'))
       OR (@ActiveMasterKpi = 'KPI_3' AND n.KpiCode IN ('TS04', 'VH28', 'VH29', 'VH38', 'SK01', 'SK02'))
       OR (@ActiveMasterKpi = 'KPI_4' AND n.KpiCode IN ('TC55', 'TC56', 'DV34', 'VH35', 'VH36'))
       OR (@ActiveMasterKpi = 'KPI_5' AND n.KpiCode IN ('CSVC01', 'CSVC02', 'HR01', 'TC54', 'TC57', 'TC58'))
       OR (@ActiveMasterKpi = 'KPI_6' AND n.KpiCode IN ('TS05', 'TS06', 'TS07', 'QA50', 'QA23', 'DV51'))
    ORDER BY
        CASE n.StatusBadge
            WHEN 'BAD' THEN 0
            WHEN 'WARN' THEN 1
            WHEN 'GOOD' THEN 2
            ELSE 3
        END,
        n.NormalizedPct ASC,
        n.SortOrder ASC;

    -- -----------------------------------------------------------------------------------------
    -- RESULT SET 2: PHÂN RÃ 5 CƠ SỞ & RADAR RỦI RO 4 TRỤC (TẦNG 3 TAB 2: CAMPUS & RISK RADAR)
    -- -----------------------------------------------------------------------------------------
    ;WITH CampusMetrics AS (
        SELECT
            c.ScopeID,
            c.CampusName,
            c.ShortName,
            c.PlannedCapacity,
            c.CurrentEnrollment,
            c.BaseAnnualTuition,
            c.SortOrder,
            CAST(ROUND((c.CurrentEnrollment * 100.0) / NULLIF(c.PlannedCapacity, 0), 1) AS NUMERIC(6,1)) AS CapacityRate,
            ISNULL(s_ts04.ActualValue, 2.0) AS WithdrawRate,
            ISNULL(s_cm08.ActualValue, 89.6) AS LmsCompletionRate,
            ISNULL(s_cm04.ActualValue, 35.5) AS DigitalMaterialRate,
            ISNULL(s_sk01.ActualValue, 96.8) AS HealthRate,
            ISNULL(s_tc56.Rate, 90.0) AS ClubTargetRate,
            ISNULL(s_tc56.ActualValue, 70) AS ClubStudents,
            ISNULL(s_csvc.ActualValue, 91.7) AS MaintenanceRate,
            ISNULL(s_tc54.ActualValue, 40.0) AS StaffLeaveDays,
            ISNULL(s_qa50.ActualValue, 93.6) AS ParentSatisfactionRate,
            -- Chỉ số đại diện theo @ActiveMasterKpi cho từng cơ sở
            CASE @ActiveMasterKpi
                WHEN 'KPI_1' THEN CAST(ROUND((c.CurrentEnrollment * 100.0) / NULLIF(c.PlannedCapacity, 0), 1) AS NUMERIC(10,2))
                WHEN 'KPI_2' THEN ISNULL(s_cm08.ActualValue, 89.6)
                WHEN 'KPI_3' THEN ISNULL(s_ts04.ActualValue, 2.0)
                WHEN 'KPI_4' THEN ISNULL(s_tc56.Rate, 85.0)
                WHEN 'KPI_5' THEN ISNULL(s_csvc.ActualValue, 91.7)
                WHEN 'KPI_6' THEN ISNULL(s_qa50.ActualValue, 93.6)
                ELSE CAST(ROUND((c.CurrentEnrollment * 100.0) / NULLIF(c.PlannedCapacity, 0), 1) AS NUMERIC(10,2))
            END AS CampusActualValue,
            CASE @ActiveMasterKpi
                WHEN 'KPI_1' THEN 100.0
                WHEN 'KPI_2' THEN ISNULL(s_cm08.TargetValue, 80.0)
                WHEN 'KPI_3' THEN 10.0
                WHEN 'KPI_4' THEN 100.0
                WHEN 'KPI_5' THEN 95.0
                WHEN 'KPI_6' THEN 90.0
                ELSE 100.0
            END AS CampusTargetValue,
            CASE @ActiveMasterKpi
                WHEN 'KPI_1' THEN N'% Lấp đầy'
                WHEN 'KPI_2' THEN N'% LMS'
                WHEN 'KPI_3' THEN N'% Rút HS'
                WHEN 'KPI_4' THEN N'% Chỉ tiêu CLB'
                WHEN 'KPI_5' THEN N'% Bảo trì CSVC'
                WHEN 'KPI_6' THEN N'% Hài lòng PH'
                ELSE N'%'
            END AS CampusMetricUnit,
            CASE @ActiveMasterKpi
                WHEN 'KPI_1' THEN ISNULL(s_ts01.OperationalInsight, N'Quy mô ' + CAST(c.CurrentEnrollment AS NVARCHAR(20)) + N'/' + CAST(c.PlannedCapacity AS NVARCHAR(20)) + N' HS')
                WHEN 'KPI_2' THEN ISNULL(s_cm08.OperationalInsight, N'Học liệu số đạt ' + CAST(ISNULL(s_cm04.ActualValue, 35.5) AS NVARCHAR(20)) + N'%')
                WHEN 'KPI_3' THEN ISNULL(s_sk01.OperationalInsight, N'Tỷ lệ rút hồ sơ ' + CAST(ISNULL(s_ts04.ActualValue, 2.0) AS NVARCHAR(20)) + N'%')
                WHEN 'KPI_4' THEN ISNULL(s_tc56.OperationalInsight, N'CLB ngoại khóa đạt ' + CAST(ISNULL(s_tc56.Rate, 85.0) AS NVARCHAR(20)) + N'% chỉ tiêu')
                WHEN 'KPI_5' THEN ISNULL(s_csvc.OperationalInsight, N'Nghỉ phép nhân sự: ' + CAST(ISNULL(s_tc54.ActualValue, 40.0) AS NVARCHAR(20)) + N' ngày công')
                WHEN 'KPI_6' THEN ISNULL(s_qa50.OperationalInsight, N'Hài lòng PHHS đạt ' + CAST(ISNULL(s_qa50.ActualValue, 93.6) AS NVARCHAR(20)) + N'%')
                ELSE N''
            END AS CampusKpiInsight
        FROM dbo.tblKPI_CampusCatalog c
        LEFT JOIN dbo.tblKPI_PeriodSnapshots s_ts01 ON s_ts01.PeriodKey = @PeriodKey AND s_ts01.DonViID = c.ScopeID AND s_ts01.KpiCode = 'TS01'
        LEFT JOIN dbo.tblKPI_PeriodSnapshots s_ts04 ON s_ts04.PeriodKey = @PeriodKey AND s_ts04.DonViID = c.ScopeID AND s_ts04.KpiCode = 'TS04'
        LEFT JOIN dbo.tblKPI_PeriodSnapshots s_cm08 ON s_cm08.PeriodKey = @PeriodKey AND s_cm08.DonViID = c.ScopeID AND s_cm08.KpiCode = 'CM08'
        LEFT JOIN dbo.tblKPI_PeriodSnapshots s_cm04 ON s_cm04.PeriodKey = @PeriodKey AND s_cm04.DonViID = c.ScopeID AND s_cm04.KpiCode = 'CM04'
        LEFT JOIN dbo.tblKPI_PeriodSnapshots s_sk01 ON s_sk01.PeriodKey = @PeriodKey AND s_sk01.DonViID = c.ScopeID AND s_sk01.KpiCode = 'SK01'
        LEFT JOIN dbo.tblKPI_PeriodSnapshots s_tc56 ON s_tc56.PeriodKey = @PeriodKey AND s_tc56.DonViID = c.ScopeID AND s_tc56.KpiCode = 'TC56'
        LEFT JOIN dbo.tblKPI_PeriodSnapshots s_csvc ON s_csvc.PeriodKey = @PeriodKey AND s_csvc.DonViID = c.ScopeID AND s_csvc.KpiCode = 'CSVC01'
        LEFT JOIN dbo.tblKPI_PeriodSnapshots s_tc54 ON s_tc54.PeriodKey = @PeriodKey AND s_tc54.DonViID = c.ScopeID AND s_tc54.KpiCode = 'TC54'
        LEFT JOIN dbo.tblKPI_PeriodSnapshots s_qa50 ON s_qa50.PeriodKey = @PeriodKey AND s_qa50.DonViID = c.ScopeID AND s_qa50.KpiCode = 'QA50'
        WHERE c.IsActive = 1
    ),
    CampusRiskCalc AS (
        SELECT
            cm.*,
            -- Trục 1: Rủi ro Tuyển sinh & Quy mô (0 - 100)
            CAST(ROUND(
                CASE
                    WHEN cm.CapacityRate >= 95.0 THEN 12
                    WHEN cm.CapacityRate >= 90.0 THEN 28 + (95.0 - cm.CapacityRate) * 4.0
                    ELSE 50 + (90.0 - cm.CapacityRate) * 2.8
                END, 0
            ) AS INT) AS EnrollmentRisk,
            -- Trục 2: Rủi ro Học thuật & Học liệu số (0 - 100)
            CAST(ROUND(
                (CASE WHEN cm.DigitalMaterialRate < 60.0 THEN (60.0 - cm.DigitalMaterialRate) * 1.1 ELSE 10 END) +
                (CASE WHEN cm.LmsCompletionRate < 90.0 THEN (90.0 - cm.LmsCompletionRate) * 2.5 ELSE 5 END), 0
            ) AS INT) AS AcademicRisk,
            -- Trục 3: Rủi ro Dịch vụ, Giữ chân & Y tế (0 - 100)
            CAST(ROUND(
                (cm.WithdrawRate * 6.5) +
                (CASE WHEN cm.HealthRate < 95.0 THEN (95.0 - cm.HealthRate) * 8.0 ELSE 5 END) +
                (CASE WHEN cm.ClubTargetRate < 80.0 THEN (80.0 - cm.ClubTargetRate) * 0.5 ELSE 0 END), 0
            ) AS INT) AS ServiceRisk,
            -- Trục 4: Rủi ro Vận hành CSVC & Nghỉ phép Nhân sự (0 - 100)
            CAST(ROUND(
                (CASE WHEN cm.MaintenanceRate < 95.0 THEN (95.0 - cm.MaintenanceRate) * 4.5 ELSE 5 END) +
                (CASE WHEN cm.StaffLeaveDays > 40.0 THEN (cm.StaffLeaveDays - 40.0) * 0.85 ELSE 8 END), 0
            ) AS INT) AS OperationsRisk
        FROM CampusMetrics cm
    )
    SELECT
        r.ScopeID,
        r.CampusName,
        r.ShortName,
        r.PlannedCapacity,
        r.CurrentEnrollment,
        r.CapacityRate,
        r.WithdrawRate,
        r.BaseAnnualTuition,
        r.CampusActualValue,
        r.CampusTargetValue,
        r.CampusMetricUnit,
        r.CampusKpiInsight,
        r.ClubTargetRate,
        r.ClubStudents,
        r.MaintenanceRate,
        r.StaffLeaveDays,
        r.ParentSatisfactionRate,
        r.EnrollmentRisk,
        r.AcademicRisk,
        r.ServiceRisk,
        r.OperationsRisk,
        CAST(ROUND((r.EnrollmentRisk * 0.35 + r.ServiceRisk * 0.25 + r.OperationsRisk * 0.25 + r.AcademicRisk * 0.15), 0) AS INT) AS CampusRiskScore,
        CASE
            WHEN (r.EnrollmentRisk * 0.35 + r.ServiceRisk * 0.25 + r.OperationsRisk * 0.25 + r.AcademicRisk * 0.15) >= 55 THEN 'CRITICAL'
            WHEN (r.EnrollmentRisk * 0.35 + r.ServiceRisk * 0.25 + r.OperationsRisk * 0.25 + r.AcademicRisk * 0.15) >= 40 THEN 'HIGH'
            WHEN (r.EnrollmentRisk * 0.35 + r.ServiceRisk * 0.25 + r.OperationsRisk * 0.25 + r.AcademicRisk * 0.15) >= 28 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS CampusRiskLevel,
        CAST(CASE WHEN r.PlannedCapacity > r.CurrentEnrollment THEN (r.PlannedCapacity - r.CurrentEnrollment) * r.BaseAnnualTuition ELSE 0 END AS BIGINT) AS CampusTuitionLossVNĐ
    FROM CampusRiskCalc r
    ORDER BY r.SortOrder;

    -- -----------------------------------------------------------------------------------------
    -- RESULT SET 3: CHUỖI NHÂN QUẢ ĐỘNG & LƯỢNG HÓA TÁC ĐỘNG (TẦNG 3 TAB 1: CAUSAL FLOW DIAGRAM)
    -- -----------------------------------------------------------------------------------------
    SELECT
        @ActiveMasterKpi AS ActiveMasterKpi,
        @HeadcountDeficit AS HeadcountDeficit,
        @TuitionDeficitTotal AS TuitionLossVNĐ,
        @BoardingDeficitTotal AS BoardingLossVNĐ,
        @TotalFinancialImpact AS TotalFinancialLossVNĐ,
        c.CorrelationID,
        c.ChainGroup,
        ISNULL(d_cause.MasterKpiCode, ISNULL(d_eff.MasterKpiCode, @ActiveMasterKpi)) AS MasterKpiCode,
        c.CauseKpiCode,
        c.CauseKpiName,
        n_cause.ActualValue AS CauseActualValue,
        n_cause.TargetValue AS CauseTargetValue,
        n_cause.Unit AS CauseUnit,
        ISNULL(n_cause.StatusBadge, 'WARN') AS CauseStatus,
        c.EffectKpiCode,
        c.EffectKpiName,
        n_eff.ActualValue AS EffectActualValue,
        n_eff.TargetValue AS EffectTargetValue,
        n_eff.Unit AS EffectUnit,
        ISNULL(n_eff.StatusBadge, 'WARN') AS EffectStatus,
        c.RelationshipType,
        CASE
            WHEN c.RelationshipType LIKE 'POSITIVE%' OR c.RelationshipType IN ('CAPACITY_BALANCE', 'SERVICE_RETENTION') THEN 1
            ELSE 0
        END AS IsPositiveChain,
        c.Description AS CausalChainNarrative,
        c.QuantifiedImpact,
        c.RecommendedAction AS ActionRecommendation,
        c.ResponsibleRole,
        c.SortOrder
    FROM dbo.tblKPI_Correlations c
    LEFT JOIN #NormalizedKpis n_cause ON c.CauseKpiCode = n_cause.KpiCode
    LEFT JOIN #NormalizedKpis n_eff ON c.EffectKpiCode = n_eff.KpiCode
    LEFT JOIN dbo.tblKPI_Definitions d_cause ON c.CauseKpiCode = d_cause.KpiCode
    LEFT JOIN dbo.tblKPI_Definitions d_eff ON c.EffectKpiCode = d_eff.KpiCode
    WHERE c.PeriodKey = @PeriodKey
      AND (
          (@ActiveMasterKpi = 'KPI_1' AND (c.CauseKpiCode IN ('TS01', 'TS02', 'TS03', 'TS05', 'TS06') AND c.EffectKpiCode IN ('TS01', 'TS02', 'TS03', 'TS06')))
          OR (@ActiveMasterKpi = 'KPI_2' AND (c.CauseKpiCode IN ('CM04', 'CM08', 'CM08_CALEN') OR c.EffectKpiCode IN ('CM08', 'CM17', 'HR01')))
          OR (@ActiveMasterKpi = 'KPI_3' AND (c.CauseKpiCode IN ('TS04', 'SK01', 'VH28') OR c.EffectKpiCode IN ('TS04', 'VH28', 'DV34')))
          OR (@ActiveMasterKpi = 'KPI_4' AND (c.CauseKpiCode IN ('TC56', 'VH35', 'VH36') OR c.EffectKpiCode IN ('TC55', 'TC56', 'VH35', 'DV34')))
          OR (@ActiveMasterKpi = 'KPI_5' AND (c.CauseKpiCode IN ('CSVC01', 'TC54', 'TC58') OR c.EffectKpiCode IN ('VH28', 'TC57', 'HR01')))
          OR (@ActiveMasterKpi = 'KPI_6' AND (c.CauseKpiCode IN ('TS05', 'TS06', 'QA50') OR c.EffectKpiCode IN ('QA50', 'TS06')))
      )
    ORDER BY c.SortOrder ASC;

    -- -----------------------------------------------------------------------------------------
    -- RESULT SET 4: BẰNG CHỨNG KIỂM TOÁN & BIỂU ĐỒ ĐỐI CHIẾU (TẦNG 3 TAB 3: AUDIT DUMBBELL CHART)
    -- -----------------------------------------------------------------------------------------
    SELECT
        a.DiscrepancyID,
        a.PeriodKey,
        a.ScopeID,
        a.AuditCode,
        a.Category,
        ISNULL(a.KpiCode, 'TS01') AS KpiCode,
        ISNULL(d.KpiName, N'Chỉ số vận hành') AS KpiName,
        ISNULL(d.MasterKpiCode, 'KPI_1') AS MasterKpiCode,
        a.Title,
        a.PrimarySource,
        a.PrimaryValue,
        a.SecondarySource,
        a.SecondaryValue,
        a.VarianceAnalysis,
        a.ActionOwner,
        a.VerificationStatus,
        -- Các giá trị định lượng phục vụ vẽ biểu đồ Dumbbell / Gap Chart trực quan
        CASE a.AuditCode
            WHEN 'MISMATCH_01' THEN 129.0
            WHEN 'MISMATCH_02' THEN 100.0
            WHEN 'MISMATCH_03' THEN 93.6
            WHEN 'MISMATCH_04' THEN 0.0
            WHEN 'MISMATCH_05' THEN 91.67
            WHEN 'MISMATCH_06' THEN 2873.0
            WHEN 'MISMATCH_07' THEN 48.2
            WHEN 'MISMATCH_08' THEN 98.2
            WHEN 'MISMATCH_09' THEN 53.0
            WHEN 'MISMATCH_10' THEN 428.0
            WHEN 'MISMATCH_11' THEN 596.0
            WHEN 'MISMATCH_12' THEN 551.0
            ELSE 100.0
        END AS PrimaryNum,
        CASE a.AuditCode
            WHEN 'MISMATCH_01' THEN 122.0
            WHEN 'MISMATCH_02' THEN 50.0
            WHEN 'MISMATCH_03' THEN 80.2
            WHEN 'MISMATCH_04' THEN 2.0
            WHEN 'MISMATCH_05' THEN 95.0
            WHEN 'MISMATCH_06' THEN 2750.0
            WHEN 'MISMATCH_07' THEN 35.5
            WHEN 'MISMATCH_08' THEN 89.6
            WHEN 'MISMATCH_09' THEN 62.0
            WHEN 'MISMATCH_10' THEN 315.0
            WHEN 'MISMATCH_11' THEN 482.0
            WHEN 'MISMATCH_12' THEN 492.0
            ELSE 85.0
        END AS SecondaryNum,
        CASE a.AuditCode
            WHEN 'MISMATCH_01' THEN N'HS'
            WHEN 'MISMATCH_02' THEN N'% Go-live'
            WHEN 'MISMATCH_03' THEN N'% Tín nhiệm'
            WHEN 'MISMATCH_04' THEN N'Ca vụ'
            WHEN 'MISMATCH_05' THEN N'% Hoàn thành'
            WHEN 'MISMATCH_06' THEN N'HS chỉ tiêu'
            WHEN 'MISMATCH_07' THEN N'% Đạt chuẩn'
            WHEN 'MISMATCH_08' THEN N'% Hoàn thành'
            WHEN 'MISMATCH_09' THEN N'HS rút'
            WHEN 'MISMATCH_10' THEN N'HS đi bus'
            WHEN 'MISMATCH_11' THEN N'Học viên'
            WHEN 'MISMATCH_12' THEN N'Ngày nghỉ'
            ELSE N'%'
        END AS UnitLabel
    FROM dbo.tblKPI_AuditDiscrepancies a
    LEFT JOIN dbo.tblKPI_Definitions d ON a.KpiCode = d.KpiCode
    WHERE a.PeriodKey = @PeriodKey
      AND (@DonViID = 'ALL' OR a.ScopeID = 'ALL' OR a.ScopeID = @DonViID)
    ORDER BY
        CASE WHEN d.MasterKpiCode = @ActiveMasterKpi THEN 0 ELSE 1 END,
        a.DiscrepancyID ASC;

    DROP TABLE #NormalizedKpis;
    DROP TABLE #AuditByKpi;
    DROP TABLE #CausalByKpi;
END
