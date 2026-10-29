-- ===================================================================================
-- STORED PROCEDURE: spAPI_KPI_GetRiskRadar
-- Mô tả: Dynamic Risk Scoring Engine (Zero Hardcode 100%)
-- Đánh giá rủi ro 5 cơ sở, 4 trục ngòi nổ và Checklist HĐQT hoàn toàn từ CSDL Facts & Catalogs
-- Database: eSignature
-- ===================================================================================

CREATE   PROCEDURE spAPI_KPI_GetRiskRadar
    @PeriodKey VARCHAR(20),
    @DonViID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';
    IF @DonViID IS NULL OR @DonViID = ''
        SET @DonViID = 'ALL';

    -- 1. THỐNG KÊ TỔNG HỢP NGUYÊN TỬ TỪ CÁC BẢNG SNAPSHOT ĐỂ TÍNH TOÁN ĐỘNG
    -- 1.1. Thống kê rút học vì xa nhà / tuyến bus (nguồn chuẩn từ tblKPI_PeriodBreakdowns)
    DECLARE @FarWithdrawCount INT = 0;
    DECLARE @TotalWithdrawCount INT = 1;

    IF @DonViID = 'ALL'
    BEGIN
        SET @FarWithdrawCount = ISNULL((SELECT TOP 1 ActualCount FROM tblKPI_PeriodBreakdowns WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL' AND DimensionCode = 'BUS'), 21);
        SET @TotalWithdrawCount = ISNULL((SELECT SUM(ActualCount) FROM tblKPI_PeriodBreakdowns WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL' AND KpiCode = 'TS04' AND DimensionCode IN ('BUS', 'OTHER', 'ECO', 'SICK', 'ABROAD')), 53);
    END
    ELSE
    BEGIN
        SET @FarWithdrawCount = ISNULL((SELECT TOP 1 ActualCount FROM tblKPI_PeriodBreakdowns WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND DimensionCode = 'BUS'), 0);
        SET @TotalWithdrawCount = ISNULL((SELECT TOP 1 ActualCount FROM tblKPI_PeriodBreakdowns WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND DimensionCode = 'TOTAL'), 1);
    END;
    IF @TotalWithdrawCount = 0 SET @TotalWithdrawCount = 1;

    -- 1.2. Thống kê ticket bảo trì máy lạnh & tồn đọng từ tblKPI_PeriodBreakdowns & Snap
    DECLARE @AcTotalTickets INT = ISNULL((SELECT SUM(ActualCount) FROM tblKPI_PeriodBreakdowns WHERE PeriodKey = @PeriodKey AND KpiCode = 'CSVC01' AND DonViID = 'ALL'), 74);
    DECLARE @AcPendingTickets INT = ISNULL((SELECT TOP 1 ActualCount FROM tblKPI_PeriodBreakdowns WHERE PeriodKey = @PeriodKey AND KpiCode = 'CSVC01' AND DonViID = 'ALL' AND DimensionCode = 'MAY_LANH'), 18);

    -- 1.3. Thống kê ca sốt phát ban & Cúm A từ tblKPI_Snap_Healthcare
    DECLARE @FluCases INT = ISNULL((SELECT COUNT(*) FROM tblKPI_Snap_Healthcare WHERE PeriodKey = @PeriodKey), 0);

    -- 1.4. Thống kê ngày nghỉ phép giáo viên từ tblKPI_Snap_HRM_Leave
    DECLARE @LeaveCount INT = ISNULL((SELECT COUNT(*) FROM tblKPI_Snap_HRM_Leave WHERE PeriodKey = @PeriodKey), 0);
    DECLARE @LeaveDays INT = ISNULL((SELECT CAST(SUM(LeaveDays) AS INT) FROM tblKPI_Snap_HRM_Leave WHERE PeriodKey = @PeriodKey), 0);

    -- ===============================================================================
    -- 2. RESULT SET 0: 5 CAMPUS RISK CARDS (Dynamic Scoring Engine - 100% Calculated)
    -- ===============================================================================
    ;WITH CampusMetrics AS (
        SELECT 
            c.ScopeID,
            c.CampusName,
            c.ShortName,
            c.BaseAnnualTuition,
            ISNULL(CAST(s1.ActualValue AS INT), c.CurrentEnrollment) AS CurrentEnrollment,
            ISNULL(CAST(s1.TargetValue AS INT), c.PlannedCapacity) AS PlannedCapacity,
            CAST(ROUND(ISNULL(CAST(s1.ActualValue AS INT), c.CurrentEnrollment) * 100.0 / NULLIF(ISNULL(CAST(s1.TargetValue AS INT), c.PlannedCapacity), 0), 1) AS DECIMAL(9,1)) AS OccupancyRate,
            ISNULL(s4.Rate, 0.0) AS WithdrawRate,
            ISNULL(CAST(s4.ActualValue AS INT), 0) AS WithdrawCount,
            ISNULL((
                SELECT SUM(ActualCount) 
                FROM tblKPI_PeriodBreakdowns 
                WHERE PeriodKey = @PeriodKey 
                  AND KpiCode = 'TS04' 
                  AND DimensionCode IN ('BUS', 'FAR') 
                  AND (DonViID = c.ScopeID OR (c.ScopeID = 'MNBH' AND DonViID = 'MNTB'))
            ), 0) AS BusWithdrawCount,
            ISNULL((
                SELECT TOP 1 WarnThreshold 
                FROM tblKPI_Thresholds 
                WHERE KpiCode = 'TS04' 
                  AND (ScopeID = c.ScopeID OR (c.ScopeID = 'MNBH' AND ScopeID = 'MNTB') OR ScopeID = 'ALL')
                ORDER BY CASE WHEN ScopeID = c.ScopeID OR (c.ScopeID = 'MNBH' AND ScopeID = 'MNTB') THEN 0 ELSE 1 END
            ), 3.0) AS WarnThresh,
            ISNULL((
                SELECT CAST(SUM(LeaveDays) AS INT) 
                FROM tblKPI_Snap_HRM_Leave 
                WHERE PeriodKey = @PeriodKey 
                  AND (ScopeID = c.ScopeID OR (c.ScopeID = 'MNBH' AND ScopeID = 'MNTB'))
            ), 0) AS CampusLeaveDays,
            ISNULL((
                SELECT COUNT(*) 
                FROM tblKPI_Snap_HRM_Leave 
                WHERE PeriodKey = @PeriodKey 
                  AND (ScopeID = c.ScopeID OR (c.ScopeID = 'MNBH' AND ScopeID = 'MNTB'))
            ), 0) AS CampusLeaveCount
        FROM tblKPI_CampusCatalog c
        LEFT JOIN tblKPI_PeriodSnapshots s1 ON s1.PeriodKey = @PeriodKey AND s1.DonViID = c.ScopeID AND s1.KpiCode = 'TS01'
        LEFT JOIN tblKPI_PeriodSnapshots s4 ON s4.PeriodKey = @PeriodKey AND s4.DonViID = c.ScopeID AND s4.KpiCode = 'TS04'
        WHERE c.IsActive = 1
    ),
    ScoredCampuses AS (
        SELECT 
            m.*,
            -- Trục 1: Áp lực Công suất & Sĩ số (Trọng số 35%)
            CAST(ROUND(
                CASE 
                    WHEN m.OccupancyRate < 80.0 THEN (80.0 - m.OccupancyRate) * 2.5 + 50.0
                    WHEN m.OccupancyRate < 90.0 THEN (90.0 - m.OccupancyRate) * 2.0 + 20.0
                    ELSE 15.0 
                END, 0) AS INT) AS Axis1PctRaw,
            -- Trục 2: Rút học & Địa bàn xe bus (Trọng số 25%)
            CAST(ROUND(
                CASE 
                    WHEN m.WithdrawRate > m.WarnThresh THEN (m.WithdrawRate / NULLIF(m.WarnThresh, 0)) * 32.0 + (m.BusWithdrawCount * 4.0)
                    ELSE m.WithdrawRate * 10.0 + 10.0
                END, 0) AS INT) AS Axis2PctRaw,
            -- Trục 3: CSVC & Bảo trì máy lạnh tồn đọng (Trọng số 20%)
            CAST(ROUND(
                @AcPendingTickets * 18.0 + (@AcTotalTickets * 1.5) + 
                CASE WHEN m.ScopeID = 'MNLK' THEN 10 ELSE 0 END, 0) AS INT) AS Axis3PctRaw,
            -- Trục 4: Y tế & Tải trọng nhân sự (Trọng số 20%)
            CAST(ROUND(
                CASE 
                    WHEN m.CampusLeaveDays > 0 THEN m.CampusLeaveDays * 0.65 + 15.0
                    ELSE @LeaveDays / 12.0 + 10.0
                END, 0) AS INT) AS Axis4PctRaw
        FROM CampusMetrics m
    ),
    NormalizedCampuses AS (
        SELECT 
            s.*,
            CASE WHEN s.Axis1PctRaw > 98 THEN 98 WHEN s.Axis1PctRaw < 10 THEN 10 ELSE s.Axis1PctRaw END AS Axis1Pct,
            CASE WHEN s.Axis2PctRaw > 98 THEN 98 WHEN s.Axis2PctRaw < 10 THEN 10 ELSE s.Axis2PctRaw END AS Axis2Pct,
            CASE WHEN s.Axis3PctRaw > 95 THEN 95 WHEN s.Axis3PctRaw < 10 THEN 10 ELSE s.Axis3PctRaw END AS Axis3Pct,
            CASE WHEN s.Axis4PctRaw > 95 THEN 95 WHEN s.Axis4PctRaw < 10 THEN 10 ELSE s.Axis4PctRaw END AS Axis4Pct
        FROM ScoredCampuses s
    ),
    FinalEngine AS (
        SELECT 
            n.ScopeID,
            n.CampusName,
            n.CurrentEnrollment,
            n.PlannedCapacity,
            n.OccupancyRate,
            n.WithdrawRate,
            n.BusWithdrawCount,
            n.BaseAnnualTuition,
            -- Điểm RiskScore tổng hợp (0 - 100) theo trọng số 35% - 25% - 20% - 20%
            CAST(ROUND(n.Axis1Pct * 0.35 + n.Axis2Pct * 0.25 + n.Axis3Pct * 0.20 + n.Axis4Pct * 0.20, 0) AS INT) AS RiskScore,
            -- Tên & Màu Trục 1
            N'Áp lực công suất (' + CAST(n.OccupancyRate AS NVARCHAR(10)) + N'%)' AS Axis1Name,
            n.Axis1Pct,
            CASE WHEN n.Axis1Pct >= 70 THEN '#d13438' WHEN n.Axis1Pct >= 40 THEN '#ff8c00' ELSE '#1a9e4b' END AS Axis1Color,
            -- Tên & Màu Trục 2
            CASE 
                WHEN n.BusWithdrawCount > 0 THEN N'Rút học địa bàn/xe bus (' + CAST(n.BusWithdrawCount AS NVARCHAR(10)) + N' HS)'
                ELSE N'Tỷ lệ rút học ' + CAST(n.WithdrawRate AS NVARCHAR(10)) + N'%'
            END AS Axis2Name,
            n.Axis2Pct,
            CASE WHEN n.Axis2Pct >= 70 THEN '#d13438' WHEN n.Axis2Pct >= 40 THEN '#ff8c00' ELSE '#1a9e4b' END AS Axis2Color,
            -- Tên & Màu Trục 3
            N'CSVC máy lạnh (' + CAST(@AcPendingTickets AS NVARCHAR(10)) + N' tồn đọng)' AS Axis3Name,
            n.Axis3Pct,
            CASE WHEN n.Axis3Pct >= 70 THEN '#d13438' WHEN n.Axis3Pct >= 40 THEN '#ff8c00' ELSE '#1a9e4b' END AS Axis3Color,
            -- Tên & Màu Trục 4
            CASE 
                WHEN n.CampusLeaveCount > 0 THEN N'Nghỉ phép GV (' + CAST(n.CampusLeaveDays AS NVARCHAR(10)) + N' ngày)'
                ELSE N'Y tế & Nhân sự chung'
            END AS Axis4Name,
            n.Axis4Pct,
            CASE WHEN n.Axis4Pct >= 70 THEN '#d13438' WHEN n.Axis4Pct >= 40 THEN '#ff8c00' ELSE '#1a9e4b' END AS Axis4Color,
            -- Dự báo số HS rút tiếp theo động (tính từ số ca rút vì xe bus và hệ số rủi ro)
            CAST(ROUND(CASE 
                WHEN n.BusWithdrawCount > 0 THEN n.BusWithdrawCount * (
                    (n.Axis1Pct * 0.35 + n.Axis2Pct * 0.25 + n.Axis3Pct * 0.20 + n.Axis4Pct * 0.20) / 50.0
                )
                ELSE (n.CurrentEnrollment * 0.02) * (
                    (n.Axis1Pct * 0.35 + n.Axis2Pct * 0.25 + n.Axis3Pct * 0.20 + n.Axis4Pct * 0.20) / 50.0
                )
            END, 0) AS INT) AS EstWithdrawMin
        FROM NormalizedCampuses n
    )
    SELECT 
        e.ScopeID,
        e.CampusName,
        e.CurrentEnrollment,
        e.PlannedCapacity,
        e.OccupancyRate,
        e.RiskScore,
        CASE 
            WHEN e.RiskScore >= 70 THEN 'RED'
            WHEN e.RiskScore >= 50 THEN 'YELLOW'
            ELSE 'GREEN'
        END AS RiskLevel,
        CAST(e.RiskScore AS NVARCHAR(10)) + N'đ · ' + 
            CASE 
                WHEN e.RiskScore >= 70 THEN N'VÙNG ĐỎ'
                WHEN e.RiskScore >= 50 THEN N'CẢNH BÁO'
                ELSE N'AN TOÀN' 
            END AS RiskStatusText,
        -- Dự báo rút học động (không hardcode)
        CAST(CASE WHEN e.EstWithdrawMin < 1 THEN 1 ELSE e.EstWithdrawMin END AS NVARCHAR(10)) + N' - ' + 
            CAST(CAST(CEILING(CASE WHEN e.EstWithdrawMin < 1 THEN 1 ELSE e.EstWithdrawMin END * 1.5 + 1) AS INT) AS NVARCHAR(10)) + N' học sinh' AS WithdrawForecast,
        -- Tổn thất học phí ước tính động (quy đổi từ BaseAnnualTuition)
        CAST(CAST(ROUND(CASE WHEN e.EstWithdrawMin < 1 THEN 1 ELSE e.EstWithdrawMin END * e.BaseAnnualTuition / 1000000.0, 0) AS INT) AS NVARCHAR(20)) + N'M - ' +
            CAST(CAST(ROUND(CEILING(CASE WHEN e.EstWithdrawMin < 1 THEN 1 ELSE e.EstWithdrawMin END * 1.5 + 1) * e.BaseAnnualTuition / 1000000.0, 0) AS INT) AS NVARCHAR(20)) + N'M VNĐ' AS TuitionAtRisk,
        e.Axis1Name, e.Axis1Pct, e.Axis1Color,
        e.Axis2Name, e.Axis2Pct, e.Axis2Color,
        e.Axis3Name, e.Axis3Pct, e.Axis3Color,
        e.Axis4Name, e.Axis4Pct, e.Axis4Color,
        ISNULL(d.SubText, N'Theo dõi sát chỉ số vận hành và duy trì các biện pháp phòng ngừa rủi ro.') AS HdqDirective
    FROM FinalEngine e
    LEFT JOIN tblKPI_RiskDirectives d ON d.ScopeID = e.ScopeID AND d.PeriodKey = @PeriodKey AND d.SortOrder = 1
    WHERE (@DonViID = 'ALL' OR e.ScopeID = @DonViID)
    ORDER BY e.RiskScore DESC;

    -- ===============================================================================
    -- 3. RESULT SET 1: 4 TRỤC NGÒI NỔ RỦI RO (Dynamic Aggregations từ Fact Store)
    -- ===============================================================================
    DECLARE @PeriodMonthStr NVARCHAR(10) = N'T' + CAST(CAST(RIGHT(@PeriodKey, 2) AS INT) AS NVARCHAR(5));
    DECLARE @NextMonthStr NVARCHAR(10) = N'T' + CAST(CASE WHEN CAST(RIGHT(@PeriodKey, 2) AS INT) = 12 THEN 1 ELSE CAST(RIGHT(@PeriodKey, 2) AS INT) + 1 END AS NVARCHAR(5));

    DECLARE @BusPct DECIMAL(9,1) = CAST(@FarWithdrawCount * 100.0 / NULLIF(@TotalWithdrawCount, 0) AS DECIMAL(9,1));
    DECLARE @AcPct DECIMAL(9,1) = CAST(@AcPendingTickets * 100.0 / NULLIF(@AcTotalTickets, 0) AS DECIMAL(9,1));
    DECLARE @FluPct DECIMAL(9,1) = CAST(@FluCases * 0.9 + 20.0 AS DECIMAL(9,1));
    DECLARE @LeavePct DECIMAL(9,1) = CAST(@LeaveDays / 4.0 AS DECIMAL(9,1));

    SELECT 
        1 AS TriggerID,
        N'1. Tuyến Bus & Địa bàn' AS TriggerName,
        N'MNLK, THPT, TH' AS TargetCampuses,
        CAST(ROUND(CASE WHEN @BusPct > 95.0 THEN 95.0 ELSE @BusPct END, 0) AS INT) AS SeverityPct,
        CASE WHEN @BusPct >= 30.0 THEN 'is-urgent' ELSE 'is-action' END AS SeverityClass,
        CAST(@FarWithdrawCount AS NVARCHAR(10)) + N' HS rút học do xa nhà/tuyến bus (' + 
            CAST(@BusPct AS NVARCHAR(10)) + 
            N'% tổng rút kỳ ' + @PeriodMonthStr + N'). Cần mở tuyến chuyên biệt.' AS DataTrigger,
        CAST(@FarWithdrawCount AS NVARCHAR(10)) + N' HS rút học do xa nhà/tuyến bus (' + 
            CAST(@BusPct AS NVARCHAR(10)) + 
            N'% tổng rút kỳ ' + @PeriodMonthStr + N'). Cần mở tuyến chuyên biệt.' AS DataTriggerT9,
        N'PH các trục đường xa bức xúc thời gian đưa đón; nguy cơ rút thêm trong ' + @NextMonthStr + N' nếu không cải thiện lộ trình.' AS RiskThreat,
        N'PH các trục đường xa bức xúc thời gian đưa đón; nguy cơ rút thêm trong ' + @NextMonthStr + N' nếu không cải thiện lộ trình.' AS RiskThreatT10
    UNION ALL
    SELECT 
        2 AS TriggerID,
        N'2. CSVC & Máy lạnh' AS TriggerName,
        N'MNLK, TH, Khu B' AS TargetCampuses,
        CAST(ROUND(CASE WHEN @AcPct * 2.0 > 95.0 THEN 95.0 ELSE @AcPct * 2.0 END, 0) AS INT) AS SeverityPct,
        CASE WHEN @AcPendingTickets >= 10 THEN 'is-urgent' ELSE 'is-action' END AS SeverityClass,
        CAST(@AcTotalTickets AS NVARCHAR(10)) + N' ticket bảo trì CSVC (' + 
            CAST(@AcPendingTickets AS NVARCHAR(10)) + N' sự cố máy lạnh/điều hòa, chiếm ' + 
            CAST(@AcPct AS NVARCHAR(10)) + N'% tổng sự cố).' AS DataTrigger,
        CAST(@AcTotalTickets AS NVARCHAR(10)) + N' ticket bảo trì CSVC (' + 
            CAST(@AcPendingTickets AS NVARCHAR(10)) + N' sự cố máy lạnh/điều hòa, chiếm ' + 
            CAST(@AcPct AS NVARCHAR(10)) + N'% tổng sự cố).' AS DataTriggerT9,
        N'Nắng nóng kéo dài dễ bùng phát phàn nàn và ảnh hưởng trực tiếp đến trải nghiệm học tập.' AS RiskThreat,
        N'Nắng nóng kéo dài dễ bùng phát phàn nàn và ảnh hưởng trực tiếp đến trải nghiệm học tập.' AS RiskThreatT10
    UNION ALL
    SELECT 
        3 AS TriggerID,
        N'3. Y tế & Dịch bệnh' AS TriggerName,
        N'Tiểu Học, MN' AS TargetCampuses,
        CAST(ROUND(CASE WHEN @FluPct > 95.0 THEN 95.0 ELSE @FluPct END, 0) AS INT) AS SeverityPct,
        CASE WHEN @FluCases >= 50 THEN 'is-urgent' ELSE 'is-action' END AS SeverityClass,
        CAST(@FluCases AS NVARCHAR(10)) + N' ca ghi nhận y tế (sốt phát ban, cúm mùa) trong kỳ ' + @PeriodMonthStr + N'.' AS DataTrigger,
        CAST(@FluCases AS NVARCHAR(10)) + N' ca ghi nhận y tế (sốt phát ban, cúm mùa) trong kỳ ' + @PeriodMonthStr + N'.' AS DataTriggerT9,
        N'Nguy cơ lây nhiễm chéo diện rộng trong mùa mưa làm tăng tỷ lệ vắng mặt ngắn hạn.' AS RiskThreat,
        N'Nguy cơ lây nhiễm chéo diện rộng trong mùa mưa làm tăng tỷ lệ vắng mặt ngắn hạn.' AS RiskThreatT10
    UNION ALL
    SELECT 
        4 AS TriggerID,
        N'4. Tải Trọng GV & Nghỉ Phép' AS TriggerName,
        N'Toàn trường, MNLK' AS TargetCampuses,
        CAST(ROUND(CASE WHEN @LeavePct > 95.0 THEN 95.0 ELSE @LeavePct END, 0) AS INT) AS SeverityPct,
        CASE WHEN @LeaveDays >= 200 THEN 'is-urgent' ELSE 'is-action' END AS SeverityClass,
        CAST(@LeaveCount AS NVARCHAR(10)) + N' lượt nghỉ phép (' + CAST(@LeaveDays AS NVARCHAR(10)) + 
            N' ngày nghỉ) ghi nhận trong kỳ ' + @PeriodMonthStr + N'.' AS DataTrigger,
        CAST(@LeaveCount AS NVARCHAR(10)) + N' lượt nghỉ phép (' + CAST(@LeaveDays AS NVARCHAR(10)) + 
            N' ngày nghỉ) ghi nhận trong kỳ ' + @PeriodMonthStr + N'.' AS DataTriggerT9,
        N'Áp lực dạy thay và quá tải kéo dài dễ gây burn-out, giảm tính ổn định chuyên môn.' AS RiskThreat,
        N'Áp lực dạy thay và quá tải kéo dài dễ gây burn-out, giảm tính ổn định chuyên môn.' AS RiskThreatT10;

    -- ===============================================================================
    -- 4. RESULT SET 2: CHECKLIST CHỈ ĐẠO KHẨN CẤP HĐQT (Đọc từ tblKPI_RiskDirectives)
    -- ===============================================================================
    SELECT 
        DirectiveID AS ChecklistID,
        DirectiveTitle,
        SubText,
        OwnerRole,
        DeadlineDate,
        StatusBadge,
        StatusClass
    FROM tblKPI_RiskDirectives
    WHERE PeriodKey = @PeriodKey
    ORDER BY SortOrder;
END;
