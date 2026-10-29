-- ==============================================================================
-- STORED PROCEDURE: spAPI_KPI_GetPeriodSnapshots
-- Mô tả: Cung cấp danh mục 60 chỉ tiêu vận hành (Snapshots) theo kỳ và đơn vị
-- Thuần túy READ-ONLY truy vấn từ kho dữ liệu chốt kỳ tblKPI_PeriodSnapshots
-- DB: eSignature (esign)
-- ==============================================================================

CREATE   PROCEDURE spAPI_KPI_GetPeriodSnapshots
    @PeriodKey VARCHAR(20),
    @DonViID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    IF @DonViID IS NULL OR @DonViID = ''
        SET @DonViID = 'ALL';

    -- 1. RESULT SET 0: CHI TIẾT 60 CHỈ TIÊU VẬN HÀNH CHỐT KỲ
    SELECT 
        s.SnapshotID,
        s.PeriodKey,
        s.DonViID,
        s.KpiCode,
        s.KpiName,
        s.KpiGroup,
        s.FrameworkLevel,
        s.FrameworkRef,
        s.ActualValue,
        s.TargetValue,
        s.Unit,
        s.Rate,
        s.Status,
        s.DataSourceType,
        s.SpecCode,
        s.FinancialImpact,
        s.OperationalInsight,
        s.IsFrozen,
        s.CreatedAt,
        spec.SourceSystem,
        spec.ApiEndpoint,
        spec.HttpMethod,
        spec.SyncSchedule,
        spec.RequestSchema,
        spec.ResponseSchema,
        spec.GolivePrerequisites
    FROM tblKPI_PeriodSnapshots s
    LEFT JOIN tblKPI_DataSourceSpecs spec ON s.SpecCode = spec.SpecCode
    WHERE s.PeriodKey = @PeriodKey
      AND (
          (@DonViID = 'ALL' AND s.DonViID = 'ALL')
          OR (@DonViID <> 'ALL' AND s.DonViID = @DonViID)
          OR (@DonViID <> 'ALL' AND s.DonViID = 'ALL' AND NOT EXISTS (
              SELECT 1 FROM tblKPI_PeriodSnapshots sub 
              WHERE sub.PeriodKey = s.PeriodKey AND sub.DonViID = @DonViID AND sub.KpiCode = s.KpiCode
          ))
      )
    ORDER BY CASE s.KpiGroup 
        WHEN N'Quy mô & Tuyển sinh' THEN 1
        WHEN N'Chất lượng Giáo dục' THEN 2
        WHEN N'Học thuật & Đào tạo' THEN 2
        WHEN N'Vận hành & Dịch vụ' THEN 3
        WHEN N'Tài chính & CSVC' THEN 4
        WHEN N'Tài chính & Dịch vụ' THEN 4
        ELSE 5 END, s.KpiCode;

    -- 2. RESULT SET 1: TỔNG HỢP THEO NHÓM CHỈ TIÊU (GROUP SUMMARY)
    SELECT 
        s.KpiGroup,
        COUNT(*) AS TotalCount,
        SUM(CASE WHEN s.Status = 'GOOD' THEN 1 ELSE 0 END) AS GoodCount,
        SUM(CASE WHEN s.Status = 'WARN' THEN 1 ELSE 0 END) AS WarnCount,
        SUM(CASE WHEN s.Status = 'DANGER' OR s.Status = 'BAD' THEN 1 ELSE 0 END) AS DangerCount
    FROM tblKPI_PeriodSnapshots s
    WHERE s.PeriodKey = @PeriodKey
      AND (
          (@DonViID = 'ALL' AND s.DonViID = 'ALL')
          OR (@DonViID <> 'ALL' AND s.DonViID = @DonViID)
      )
    GROUP BY s.KpiGroup;

    -- 3. RESULT SET 2: DANH MỤC ĐẶC TẢ KỸ THUẬT GOLIVE (6 HỆ THỐNG NGUỒN)
    SELECT 
        SpecCode,
        KpiGroup,
        SourceSystem,
        ApiEndpoint,
        HttpMethod,
        SyncSchedule,
        RequestSchema,
        ResponseSchema,
        GolivePrerequisites
    FROM tblKPI_DataSourceSpecs
    ORDER BY SpecCode;
END;
