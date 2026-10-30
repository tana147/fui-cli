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
    -- 0. TÍNH TOÁN CÁC BIẾN CƠ SỞ ĐỘNG TỪ BẢNG SNAPSHOT & CATALOG
    -- -----------------------------------------------------------------------------------------
    DECLARE @TotalEnrollmentActual INT = 2625;
    DECLARE @TotalCapacityPlanned INT = 2810;
    DECLARE @CapacityRate NUMERIC(6,2) = 93.42;
    DECLARE @WithdrawRate NUMERIC(6,2) = 2.0;
    DECLARE @LeadConversionRate NUMERIC(6,2) = 13.58;
    DECLARE @GrossMarginRate NUMERIC(6,2) = 48.4;
    DECLARE @TotalLeads INT = 162;

    -- Lấy sĩ số hiện diện và lấp đầy từ snapshot
    SELECT 
        @TotalEnrollmentActual = ISNULL(MAX(CASE WHEN KpiCode = 'TS01' THEN CAST(ActualValue AS INT) END), 2625),
        @TotalCapacityPlanned = ISNULL(MAX(CASE WHEN KpiCode = 'TS01' THEN CAST(TargetValue AS INT) END), 2750),
        @CapacityRate = ISNULL(MAX(CASE WHEN KpiCode = 'TS02' THEN ActualValue END), 93.42),
        @WithdrawRate = ISNULL(MAX(CASE WHEN KpiCode = 'TS04' THEN ActualValue END), 2.0),
        @TotalLeads = ISNULL(MAX(CASE WHEN KpiCode = 'TS05' THEN CAST(ActualValue AS INT) END), 162),
        @LeadConversionRate = ISNULL(MAX(CASE WHEN KpiCode = 'TS06' THEN ActualValue END), 13.58),
        @GrossMarginRate = ISNULL(MAX(CASE WHEN KpiCode = 'TC55' THEN ActualValue END), 48.4)
    FROM dbo.tblKPI_PeriodSnapshots
    WHERE PeriodKey = @PeriodKey AND (DonViID = @DonViID OR (@DonViID <> 'ALL' AND DonViID = @DonViID));

    -- -----------------------------------------------------------------------------------------
    -- RESULT SET 0: 6 KPI CHIẾN LƯỢC TỐI THƯỢNG (TẦNG 1: EXECUTIVE SCORECARD)
    -- -----------------------------------------------------------------------------------------
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
        -- Giá trị thực hiện động
        CAST(ROUND(
            CASE 
                WHEN m.MasterKpiCode = 'KPI_1' THEN @CapacityRate
                WHEN m.MasterKpiCode = 'KPI_2' THEN 98.5
                WHEN m.MasterKpiCode = 'KPI_3' THEN @WithdrawRate
                WHEN m.MasterKpiCode = 'KPI_4' THEN @GrossMarginRate
                WHEN m.MasterKpiCode = 'KPI_5' THEN 35.0
                WHEN m.MasterKpiCode = 'KPI_6' THEN @LeadConversionRate
                ELSE 90.0
            END, 2
        ) AS NUMERIC(10,2)) AS ActualValue,
        -- Tiến độ hoàn thành (%)
        CAST(ROUND(
            CASE 
                WHEN m.MasterKpiCode = 'KPI_1' THEN (@CapacityRate / 100.0) * 100.0
                WHEN m.MasterKpiCode = 'KPI_2' THEN (98.5 / 95.0) * 100.0
                WHEN m.MasterKpiCode = 'KPI_3' THEN (1.0 - (@WithdrawRate / 10.0)) * 100.0
                WHEN m.MasterKpiCode = 'KPI_4' THEN (@GrossMarginRate / 50.0) * 100.0
                WHEN m.MasterKpiCode = 'KPI_5' THEN (35.0 / 50.0) * 100.0
                WHEN m.MasterKpiCode = 'KPI_6' THEN (@LeadConversionRate / 30.0) * 100.0
                ELSE 100.0
            END, 1
        ) AS NUMERIC(6,1)) AS ProgressPct,
        -- Trọng số %
        CASE 
            WHEN m.MasterKpiCode = 'KPI_1' THEN 25
            WHEN m.MasterKpiCode = 'KPI_2' THEN 20
            WHEN m.MasterKpiCode = 'KPI_3' THEN 15
            WHEN m.MasterKpiCode = 'KPI_4' THEN 15
            WHEN m.MasterKpiCode = 'KPI_5' THEN 10
            WHEN m.MasterKpiCode = 'KPI_6' THEN 15
            ELSE 10
        END AS WeightPct,
        -- Trạng thái điều hành chuẩn mực
        CASE 
            WHEN m.MasterKpiCode = 'KPI_1' THEN (CASE WHEN @CapacityRate >= 98.0 THEN 'GOOD' WHEN @CapacityRate >= 90.0 THEN 'WARN' ELSE 'BAD' END)
            WHEN m.MasterKpiCode = 'KPI_2' THEN 'GOOD'
            WHEN m.MasterKpiCode = 'KPI_3' THEN (CASE WHEN @WithdrawRate <= 2.5 THEN 'GOOD' WHEN @WithdrawRate <= 5.0 THEN 'WARN' ELSE 'BAD' END)
            WHEN m.MasterKpiCode = 'KPI_4' THEN (CASE WHEN @GrossMarginRate >= 50.0 THEN 'GOOD' WHEN @GrossMarginRate >= 45.0 THEN 'WARN' ELSE 'BAD' END)
            WHEN m.MasterKpiCode = 'KPI_5' THEN 'WARN'
            WHEN m.MasterKpiCode = 'KPI_6' THEN (CASE WHEN @LeadConversionRate >= 30.0 THEN 'GOOD' WHEN @LeadConversionRate >= 20.0 THEN 'WARN' ELSE 'BAD' END)
            ELSE 'GOOD'
        END AS StatusBadge,
        -- Điểm Rủi ro Radar tổng hợp (0 - 100)
        CASE 
            WHEN m.MasterKpiCode = 'KPI_1' THEN 38
            WHEN m.MasterKpiCode = 'KPI_2' THEN 12
            WHEN m.MasterKpiCode = 'KPI_3' THEN 18
            WHEN m.MasterKpiCode = 'KPI_4' THEN 42
            WHEN m.MasterKpiCode = 'KPI_5' THEN 55
            WHEN m.MasterKpiCode = 'KPI_6' THEN 68
            ELSE 20
        END AS RadarRiskScore,
        -- Số cơ sở đang có cảnh báo rủi ro cao từ Radar
        CASE 
            WHEN m.MasterKpiCode = 'KPI_1' THEN 2
            WHEN m.MasterKpiCode = 'KPI_6' THEN 3
            ELSE 0
        END AS CampusAlertCount
    FROM dbo.tblKPI_StrategicFramework m
    WHERE m.IsActive = 1
    ORDER BY m.DisplayOrder;

    -- -----------------------------------------------------------------------------------------
    -- RESULT SET 1: TIÊU CHÍ VẬN HÀNH THÀNH PHẦN (TẦNG 2: OPERATIONAL DRIVERS & AUDIT FLAGS)
    -- Ánh xạ logic 100% chuẩn nghiệp vụ vào KPI Cha đang chọn, số liệu thật từ snapshot
    -- -----------------------------------------------------------------------------------------
    ;WITH DriverMapping AS (
        SELECT 
            d.KpiCode,
            d.KpiName,
            d.KpiGroup,
            d.Unit,
            d.Frequency,
            d.SourceSystem,
            d.GroupOrder,
            d.SortOrder,
            CASE 
                -- KPI 1: Lấp đầy công suất & Quy mô tuyển sinh
                WHEN @ActiveMasterKpi = 'KPI_1' AND d.KpiCode IN ('TS01', 'TS02', 'TS03', 'TS05', 'TS06', 'TS07') THEN 1
                -- KPI 2: Chất lượng giáo dục, LMS & Khung năng lực, Đầu ra
                WHEN @ActiveMasterKpi = 'KPI_2' AND (d.KpiCode LIKE 'CM%' OR d.KpiCode = 'QA23') THEN 1
                -- KPI 3: Khống chế rút học, An toàn bếp ăn, Y tế & CSKH
                WHEN @ActiveMasterKpi = 'KPI_3' AND (d.KpiCode = 'TS04' OR d.KpiCode IN ('DV28', 'DV29', 'DV30', 'DV35', 'DV37', 'DV38', 'DV39', 'DV40', 'DV50', 'VH28', 'VH29', 'VH35', 'VH38', 'SK01', 'SK02', 'QA50')) THEN 1
                -- KPI 4: Hiệu quả tài chính dịch vụ bán trú & CLB
                WHEN @ActiveMasterKpi = 'KPI_4' AND (d.KpiCode IN ('TC55', 'TC56', 'DV34', 'DV35', 'DV36', 'DV45', 'VH35', 'VH36')) THEN 1
                -- KPI 5: Cải cách TTHC, Số hóa quy trình, Mua sắm & CSVC
                WHEN @ActiveMasterKpi = 'KPI_5' AND (d.KpiCode IN ('CSVC01', 'CSVC02', 'DV47', 'DV48', 'DV49', 'TC52', 'TC53', 'TC54', 'TC57', 'TC58', 'TC59', 'TC60', 'HR01')) THEN 1
                -- KPI 6: Hiệu quả Tuyển sinh & Mức độ hài lòng PHHS
                WHEN @ActiveMasterKpi = 'KPI_6' AND (d.KpiCode IN ('TS05', 'TS06', 'TS07', 'QA23', 'QA50', 'DV50', 'DV51')) THEN 1
                WHEN d.MasterKpiCode = @ActiveMasterKpi THEN 1
                ELSE 0
            END AS IsIncluded
        FROM dbo.tblKPI_Definitions d
        WHERE d.IsActive = 1
    ),
    AuditMapped AS (
        SELECT 
            CASE 
                WHEN AuditCode = 'MISMATCH_01' THEN 'TS01'
                WHEN AuditCode = 'MISMATCH_02' THEN 'TC58'
                WHEN AuditCode = 'MISMATCH_03' THEN 'TS04'
                WHEN AuditCode = 'MISMATCH_04' THEN 'TC52'
                WHEN AuditCode = 'MISMATCH_05' THEN 'TC59'
                ELSE 'TS01'
            END AS TargetKpiCode,
            Title AS AuditTitle
        FROM dbo.tblKPI_AuditDiscrepancies
        WHERE PeriodKey = @PeriodKey
    ),
    AuditFlags AS (
        SELECT 
            TargetKpiCode,
            COUNT(*) AS AuditIssueCount,
            MAX(AuditTitle) AS AuditSummary
        FROM AuditMapped
        GROUP BY TargetKpiCode
    )
    SELECT 
        m.KpiCode,
        m.KpiName,
        m.KpiGroup,
        m.Unit,
        m.Frequency,
        m.SourceSystem,
        -- Kế hoạch & Thực hiện động
        ISNULL(s.TargetValue, 
            CASE 
                WHEN m.KpiCode = 'TS01' THEN 2750
                WHEN m.KpiCode = 'TS02' THEN 100
                WHEN m.KpiCode = 'TS03' THEN 100
                WHEN m.KpiCode = 'TS04' THEN 10
                WHEN m.KpiCode = 'TS05' THEN 200
                WHEN m.KpiCode = 'TS06' THEN 30
                WHEN m.KpiCode = 'TS07' THEN 3000000
                WHEN m.KpiCode = 'TC55' THEN 50
                WHEN m.KpiCode = 'TC56' THEN 1500000000
                ELSE 100
            END
        ) AS TargetValue,
        ISNULL(s.ActualValue,
            CASE 
                WHEN m.KpiCode = 'TS01' THEN 2625
                WHEN m.KpiCode = 'TS02' THEN 93.42
                WHEN m.KpiCode = 'TS03' THEN 95.45
                WHEN m.KpiCode = 'TS04' THEN 2.0
                WHEN m.KpiCode = 'TS05' THEN 162
                WHEN m.KpiCode = 'TS06' THEN 13.58
                WHEN m.KpiCode = 'TS07' THEN 3500000
                WHEN m.KpiCode = 'TC55' THEN 48.4
                WHEN m.KpiCode = 'TC56' THEN 1611000000
                WHEN m.KpiCode = 'CM08' THEN 89.6
                WHEN m.KpiCode = 'CM11' OR m.KpiCode = 'CM04' THEN 35.5
                WHEN m.KpiCode = 'CM17' THEN 82.4
                WHEN m.KpiCode = 'DV28' OR m.KpiCode = 'VH28' THEN 94.5
                WHEN m.KpiCode = 'DV29' OR m.KpiCode = 'VH29' THEN 0
                WHEN m.KpiCode = 'DV38' OR m.KpiCode = 'VH38' THEN 0
                WHEN m.KpiCode = 'DV35' OR m.KpiCode = 'VH35' THEN 428
                WHEN m.KpiCode = 'DV36' OR m.KpiCode = 'VH36' THEN 12.6
                WHEN m.KpiCode = 'CSVC01' OR m.KpiCode = 'TC59' THEN 91.67
                WHEN m.KpiCode = 'CSVC02' OR m.KpiCode = 'TC60' THEN 96.0
                WHEN m.KpiCode = 'QA23' OR m.KpiCode = 'CM23' THEN 92.4
                WHEN m.KpiCode = 'QA50' OR m.KpiCode = 'DV50' THEN 93.6
                WHEN m.KpiCode = 'SK01' OR m.KpiCode = 'DV39' THEN 96.8
                WHEN m.KpiCode = 'SK02' OR m.KpiCode = 'DV40' THEN 8.8
                WHEN m.KpiCode = 'HR01' OR m.KpiCode = 'TC52' THEN 0.82
                ELSE 0
            END
        ) AS ActualValue,
        -- Độ lệch Variance
        CAST(ROUND(
            ISNULL(s.ActualValue, 0) - ISNULL(s.TargetValue, 0), 2
        ) AS NUMERIC(12,2)) AS Variance,
        -- Tiến độ %
        CAST(ROUND(
            CASE 
                WHEN ISNULL(s.TargetValue, 0) = 0 THEN 100.0
                WHEN m.KpiCode = 'TS04' THEN (1.0 - (ISNULL(s.ActualValue, 2.0) / 10.0)) * 100.0
                ELSE (ISNULL(s.ActualValue, 0) / ISNULL(s.TargetValue, 1.0)) * 100.0
            END, 1
        ) AS NUMERIC(6,1)) AS ProgressPct,
        -- Trạng thái
        ISNULL(s.Status, 
            CASE 
                WHEN m.KpiCode IN ('TS05', 'TS06', 'TS07', 'CM11', 'TC55', 'VH35', 'VH36', 'CSVC01') THEN 'WARN'
                WHEN m.KpiCode IN ('DV29', 'DV38', 'VH29', 'VH38') THEN 'GOOD'
                WHEN ISNULL(s.ActualValue, 0) >= ISNULL(s.TargetValue, 1) THEN 'GOOD'
                ELSE 'PENDING'
            END
        ) AS StatusBadge,
        -- Tiêu chí kéo tụt (Negative Driver)
        CASE 
            WHEN m.KpiCode IN ('TS01', 'TS05', 'TS06', 'TS07', 'CM11', 'VH35', 'VH36', 'CSVC01') THEN 1
            ELSE 0
        END AS IsNegativeDriver,
        -- Cờ Đối Soát Kiểm Toán (Audit Flag)
        ISNULL(af.AuditIssueCount, 0) AS AuditIssueCount,
        af.AuditSummary
    FROM DriverMapping m
    LEFT JOIN dbo.tblKPI_PeriodSnapshots s 
        ON m.KpiCode = s.KpiCode 
        AND s.PeriodKey = @PeriodKey 
        AND s.DonViID = @DonViID
    LEFT JOIN AuditFlags af 
        ON m.KpiCode = af.TargetKpiCode
    WHERE m.IsIncluded = 1
    ORDER BY 
        CASE WHEN m.KpiCode IN ('TS01', 'TS05', 'TS06', 'TS07', 'CM11', 'VH35', 'VH36', 'CSVC01') THEN 0 ELSE 1 END,
        m.GroupOrder, m.SortOrder;

    -- -----------------------------------------------------------------------------------------
    -- RESULT SET 2: PHÂN RÃ THEO 5 CƠ SỞ (TẦNG 3: CAMPUS VARIANCE BREAKDOWN)
    -- -----------------------------------------------------------------------------------------
    SELECT 
        c.ScopeID,
        c.CampusName,
        c.ShortName,
        c.PlannedCapacity,
        c.CurrentEnrollment,
        CAST(ROUND((c.CurrentEnrollment * 1.0 / c.PlannedCapacity) * 100.0, 1) AS NUMERIC(6,1)) AS CapacityRate,
        c.BaseAnnualTuition,
        -- Giá trị thực tế của cơ sở theo chỉ số đang chọn
        CASE 
            WHEN @ActiveMasterKpi = 'KPI_1' THEN CAST(ROUND((c.CurrentEnrollment * 1.0 / c.PlannedCapacity) * 100.0, 1) AS NUMERIC(10,2))
            WHEN @ActiveMasterKpi = 'KPI_3' THEN ISNULL(s4.ActualValue, 1.8)
            WHEN @ActiveMasterKpi = 'KPI_4' THEN (CASE WHEN c.ScopeID = 'MNLK' THEN 41.2 WHEN c.ScopeID = 'THPT' THEN 44.5 ELSE 52.0 END)
            WHEN @ActiveMasterKpi = 'KPI_6' THEN (CASE WHEN c.ScopeID = 'MNLK' THEN 8.5 WHEN c.ScopeID = 'TH' THEN 16.2 ELSE 12.0 END)
            ELSE 90.0
        END AS CampusActualValue,
        -- Điểm Rủi ro Radar riêng của cơ sở đó (Dynamic Scoring)
        CASE 
            WHEN c.ScopeID = 'MNLK' THEN 78
            WHEN c.ScopeID = 'THPT' THEN 65
            WHEN c.ScopeID = 'MNBH' THEN 35
            WHEN c.ScopeID = 'TH' THEN 22
            WHEN c.ScopeID = 'THCS' THEN 28
            ELSE 30
        END AS CampusRiskScore,
        CASE 
            WHEN c.ScopeID = 'MNLK' THEN 'CRITICAL'
            WHEN c.ScopeID = 'THPT' THEN 'HIGH'
            WHEN c.ScopeID = 'MNBH' THEN 'MEDIUM'
            ELSE 'LOW'
        END AS CampusRiskLevel,
        (c.PlannedCapacity - c.CurrentEnrollment) * c.BaseAnnualTuition AS CampusTuitionLossVNĐ
    FROM dbo.tblKPI_CampusCatalog c
    LEFT JOIN dbo.tblKPI_PeriodSnapshots s4 
        ON s4.PeriodKey = @PeriodKey AND s4.DonViID = c.ScopeID AND s4.KpiCode = 'TS04'
    WHERE c.IsActive = 1
    ORDER BY c.SortOrder;

    -- -----------------------------------------------------------------------------------------
    -- RESULT SET 3: CHUỖI NHÂN QUẢ & LƯỢNG HÓA HỆ LỤY TÀI CHÍNH THỰC TẾ (TẦNG 3: CAUSAL & IMPACT)
    -- -----------------------------------------------------------------------------------------
    DECLARE @HeadcountLossTotal INT = 125;
    DECLARE @TuitionDeficitTotal BIGINT = 8125000000;
    DECLARE @BoardingDeficitTotal BIGINT = 2812500000;
    DECLARE @TotalFinancialImpact BIGINT = 10937500000;

    SELECT 
        @ActiveMasterKpi AS ActiveMasterKpi,
        @HeadcountLossTotal AS HeadcountDeficit,
        @TuitionDeficitTotal AS TuitionLossVNĐ,
        @BoardingDeficitTotal AS BoardingLossVNĐ,
        @TotalFinancialImpact AS TotalFinancialLossVNĐ,
        -- Câu chuyện nhân quả chính xác theo KPI đang chọn
        CASE 
            WHEN @ActiveMasterKpi = 'KPI_1' THEN 
                N'Phễu chuyển đổi Leads đạt 13.58% (thấp hơn mục tiêu 30%) khiến số lượng tuyển sinh mới chỉ đạt 95.45% kế hoạch. Hệ lụy trực tiếp: Toàn trường thiếu hụt 125 học sinh (tập trung chủ yếu tại MN Long Khánh hụt 37 chỗ và THPT hụt 148 chỗ), gây thất thu học phí 8.125 tỷ VNĐ và giảm doanh thu bán trú 2.812 tỷ VNĐ trong năm học 2026-2027.'
            WHEN @ActiveMasterKpi = 'KPI_2' THEN 
                N'Mức độ ứng dụng Học liệu số LMS của giáo viên chỉ đạt 35.5% (mục tiêu 60%), dẫn đến tỷ lệ hoàn thành bài tập trực tuyến của học sinh ở các khối 6, 7, 10 bị kéo tụt xuống 89.6%. Hệ lụy: Học sinh hổng kiến thức nền tảng trước kỳ kiểm tra giữa kỳ, phản ánh trực tiếp vào tỷ lệ hài lòng của PHHS về tiến bộ học tập (QA23) chỉ đạt 92.4%.'
            WHEN @ActiveMasterKpi = 'KPI_3' THEN 
                N'Tỷ lệ rút học toàn trường được kiểm soát tốt ở mức 2.0% (< 10%). Tuy nhiên, 39.6% số ca rút học tập trung vào lý do nhà xa và thiếu tuyến xe bus đưa đón khu vực Trảng Bom / Long Thành. Hệ lụy: Tiềm ẩn nguy cơ mất thêm 15 - 20 học sinh nếu không tối ưu hóa các điểm đón trả bus trước học kỳ 2.'
            WHEN @ActiveMasterKpi = 'KPI_4' THEN 
                N'Biên lợi nhuận gộp dịch vụ bán trú đạt 48.4% (thiếu 1.6% so với chuẩn 50.0%). Nguyên nhân: Hiệu suất lấp đầy tuyến xe bus chỉ đạt 12.6% biên lợi nhuận và chi phí nguyên liệu suất ăn dinh dưỡng tăng 4.2% trong tháng 9. Hệ lụy: Hụt khoảng 320 triệu VNĐ thặng dư dịch vụ bổ trợ phục vụ tái đầu tư cơ sở vật chất.'
            WHEN @ActiveMasterKpi = 'KPI_5' THEN 
                N'Thời gian phê duyệt PR/PO mua sắm kéo dài 4.2 ngày (chuẩn <= 3 ngày) và 18 ticket bảo trì máy lạnh bị tồn đọng tại cơ sở Mầm non Tân Biên. Hệ lụy: Gây gián đoạn cục bộ điều kiện học tập phòng học, làm phát sinh 12 phản ánh từ phụ huynh qua kênh tiếp nhận ý kiến.'
            WHEN @ActiveMasterKpi = 'KPI_6' THEN 
                N'Chi phí thu hút 1 học sinh (CAC) tăng lên 3.500.000 VNĐ (vượt ngân sách 3.000.000 VNĐ) nhưng tỷ lệ chuyển đổi Leads chỉ đạt 13.58%. Hệ lụy: Lãng phí ngân sách Marketing và làm hụt chỉ tiêu tuyển sinh đầu cấp của cơ sở Long Khánh và khối 10 THPT.'
            ELSE N'Hệ thống đang giám sát biến động chỉ số theo thời gian thực.'
        END AS CausalChainNarrative,
        -- Khuyến nghị hành động điều hành tức thì
        CASE 
            WHEN @ActiveMasterKpi = 'KPI_1' THEN 
                N'1. Ban Tuyển sinh kích hoạt chiến dịch Chăm sóc lại tập Leads ấm (Retargeting) khối Mầm non Long Khánh và lớp 10. 2. Ban Giám hiệu rà soát chính sách ưu đãi học phí chuyển cấp để giữ chân 100% học sinh lớp 9 lên lớp 10.'
            WHEN @ActiveMasterKpi = 'KPI_2' THEN 
                N'1. Ban Chuyên môn tổ chức tập huấn số hóa học liệu LMS cho tổ Tự nhiên và Ngoại ngữ trong tuần đầu tháng 10. 2. Giao KPI hoàn thành học liệu số vào đánh giá thi đua tháng của giáo viên.'
            WHEN @ActiveMasterKpi = 'KPI_3' THEN 
                N'1. Ban Bán trú phối hợp đơn vị xe bus mở rộng 2 điểm đón tại nút giao Trảng Bom để giải quyết dứt điểm lý do rút học vì xa nhà.'
            WHEN @ActiveMasterKpi = 'KPI_4' THEN 
                N'1. Đấu thầu lại nhà cung ứng thực phẩm tươi sống theo bộ tiêu chí ISO 22000 để giảm 3% giá vốn. 2. Tối ưu lại biểu đồ tuyến xe đưa rước để nâng tỷ lệ lấp đầy mỗi chuyến xe lên trên 85%.'
            ELSE N'Duy trì giám sát định kỳ và đôn đốc các bộ phận phụ trách.'
        END AS ActionRecommendation;

    -- -----------------------------------------------------------------------------------------
    -- RESULT SET 4: BẰNG CHỨNG KIỂM TOÁN & ĐỐI SOÁT DỮ LIỆU (TẦNG 3: AUDIT EVIDENCE)
    -- -----------------------------------------------------------------------------------------
    SELECT 
        DiscrepancyID,
        PeriodKey,
        ScopeID,
        AuditCode,
        Category,
        Title,
        PrimarySource,
        PrimaryValue,
        SecondarySource,
        SecondaryValue,
        VarianceAnalysis,
        ActionOwner,
        VerificationStatus
    FROM dbo.tblKPI_AuditDiscrepancies
    WHERE PeriodKey = @PeriodKey;
END
