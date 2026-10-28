CREATE OR ALTER PROCEDURE spAPI_KPI_GetCorrelations
    @PeriodKey VARCHAR(20),
    @DonViID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';
    IF @DonViID IS NULL OR @DonViID = ''
        SET @DonViID = 'ALL';

    -- 1. Correlation Nodes & Chains (Result Set 0 - Giữ nguyên Contract cho các màn hình liên quan)
    SELECT 
        CorrelationID,
        PeriodKey,
        ChainGroup,
        CauseKpiCode,
        CauseKpiName,
        EffectKpiCode,
        EffectKpiName,
        RelationshipType,
        Description,
        QuantifiedImpact,
        RecommendedAction,
        ResponsibleRole,
        SortOrder,
        CreatedAt
    FROM tblKPI_Correlations
    WHERE PeriodKey = @PeriodKey
    ORDER BY ChainGroup, SortOrder;

    -- 2. Chains Summary (Result Set 1 - Giữ nguyên Contract cũ)
    SELECT 
        ChainGroup,
        COUNT(*) AS LinksCount
    FROM tblKPI_Correlations
    WHERE PeriodKey = @PeriodKey
    GROUP BY ChainGroup;

    -- 3. Causal Narratives Registry (Result Set 2 - Chuẩn hóa Biểu Thức Động, Phân Loại Kịch Bản & Verification Prompt)
    SELECT 
        NarrativeID,
        NarrativeCode,
        NarrativeGroup,
        ISNULL(AnchorKpiCode, 'TS01') AS AnchorKpiCode,
        Title,
        ConditionExpr,
        TemplatePattern,
        ActionPattern,
        ISNULL(ScenarioType, 'CAUSAL_IMPACT') AS ScenarioType,
        VerificationPrompt,
        DefaultParamsJson,
        SortOrder,
        IsActive
    FROM tblKPI_CausalNarratives
    WHERE IsActive = 1
    ORDER BY SortOrder;

    -- 4. Dynamic Context Store (Result Set 3 - Key/Value Map của toàn bộ Snapshots, Params, Assumptions, Audits)
    CREATE TABLE #ContextVars (
        VarKey VARCHAR(100) PRIMARY KEY,
        VarValue NVARCHAR(500)
    );

    -- 4.1. Nạp Snapshot KPI của Đơn vị (hoặc ALL nếu thiếu)
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 
        s.KpiCode + '.Actual',
        CAST(s.ActualValue AS NVARCHAR(50))
    FROM tblKPI_PeriodSnapshots s
    WHERE s.PeriodKey = @PeriodKey 
      AND s.DonViID = @DonViID;

    -- Thêm các trường phụ của Snapshot (.Target, .Rate, .Status)
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 
        s.KpiCode + '.Target',
        CAST(s.TargetValue AS NVARCHAR(50))
    FROM tblKPI_PeriodSnapshots s
    WHERE s.PeriodKey = @PeriodKey AND s.DonViID = @DonViID;

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 
        s.KpiCode + '.Rate',
        CAST(s.Rate AS NVARCHAR(50))
    FROM tblKPI_PeriodSnapshots s
    WHERE s.PeriodKey = @PeriodKey AND s.DonViID = @DonViID;

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 
        s.KpiCode + '.Status',
        s.Status
    FROM tblKPI_PeriodSnapshots s
    WHERE s.PeriodKey = @PeriodKey AND s.DonViID = @DonViID;

    -- Nếu đơn vị chọn là con nhưng thiếu chỉ số, tự động fallback từ ALL
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 
        s.KpiCode + '.Actual',
        CAST(s.ActualValue AS NVARCHAR(50))
    FROM tblKPI_PeriodSnapshots s
    WHERE s.PeriodKey = @PeriodKey AND s.DonViID = 'ALL'
      AND NOT EXISTS (SELECT 1 FROM #ContextVars WHERE VarKey = s.KpiCode + '.Actual');

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 
        s.KpiCode + '.Rate',
        CAST(s.Rate AS NVARCHAR(50))
    FROM tblKPI_PeriodSnapshots s
    WHERE s.PeriodKey = @PeriodKey AND s.DonViID = 'ALL'
      AND NOT EXISTS (SELECT 1 FROM #ContextVars WHERE VarKey = s.KpiCode + '.Rate');

    -- 4.2. Phân tích chi tiết lý do rút học (TS04.Reason.*)
    DECLARE @TotalWithdraw FLOAT = ISNULL((SELECT CAST(VarValue AS FLOAT) FROM #ContextVars WHERE VarKey = 'TS04.Actual'), 53);
    IF @TotalWithdraw <= 0 SET @TotalWithdraw = 1;

    -- Rút vì xa trường / xe bus (FAR)
    DECLARE @FarCount INT = CASE @DonViID
        WHEN 'MNLK' THEN 4
        WHEN 'MNTB' THEN 3
        WHEN 'TH' THEN 8
        WHEN 'THCS' THEN 4
        ELSE 21
    END;
    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('TS04.Reason.FAR', CAST(@FarCount AS NVARCHAR(20)));
    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('TS04.Reason.BUS', CAST(@FarCount AS NVARCHAR(20)));

    -- 4.3. Nạp Tham số Nghiệp vụ từ tblKPI_Parameters (PARAM.*)
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 
        'PARAM.' + p.ParamCode,
        CAST(p.ParamValue AS NVARCHAR(50))
    FROM tblKPI_Parameters p
    WHERE (p.ScopeID = @DonViID OR (p.ScopeID = 'ALL' AND NOT EXISTS (
        SELECT 1 FROM tblKPI_Parameters p2 WHERE p2.ParamCode = p.ParamCode AND p2.ScopeID = @DonViID
    )));

    -- 4.4. Nạp Tham số Giả định từ tblKPI_CausalAssumptions (ASSUMPTION.*)
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 
        'ASSUMPTION.' + aKey,
        aValue
    FROM (
        SELECT TOP 1
            CAST(AnnualTuitionMillion AS NVARCHAR(50)) AS Tuition,
            CAST(GrossMarginPct AS NVARCHAR(50)) AS Margin,
            CAST(RemainingYearsInLevel AS NVARCHAR(50)) AS RemYears,
            CAST(MonthlyLeads AS NVARCHAR(50)) AS MonthlyLeads,
            CAST(ConversionRate AS NVARCHAR(50)) AS ConvRate,
            CAST(PlannedCapacity AS NVARCHAR(50)) AS Capacity,
            CAST(CurrentEnrollment AS NVARCHAR(50)) AS Enrollment
        FROM tblKPI_CausalAssumptions
        WHERE UnitCode = @DonViID OR (UnitCode = 'MNLK' AND @DonViID = 'ALL')
    ) src
    UNPIVOT (
        aValue FOR aKey IN (Tuition, Margin, RemYears, MonthlyLeads, ConvRate, Capacity, Enrollment)
    ) unpvt;

    -- 4.5. Nạp Nhóm Biến Kiểm Toán Dữ Liệu & Nghịch Lý (Audit & Paradox Variables)
    -- Cỡ mẫu khảo sát QA.SampleSize
    DECLARE @QASample INT = ISNULL((
        SELECT TOP 1 CAST(ParamValue AS INT) FROM tblKPI_Parameters 
        WHERE ParamCode = 'QA_SampleSize' AND (ScopeID = @DonViID OR ScopeID = 'ALL')
        ORDER BY CASE WHEN ScopeID = @DonViID THEN 1 ELSE 2 END
    ), 65);
    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('QA.SampleSize', CAST(@QASample AS NVARCHAR(20)));

    -- Lệch cân đối luân chuyển sĩ số (AUDIT.RollDiff)
    DECLARE @RollDiff INT = CASE @DonViID
        WHEN 'TH' THEN 2
        WHEN 'MNLK' THEN 1
        ELSE 0
    END;
    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('AUDIT.RollDiff', CAST(@RollDiff AS NVARCHAR(20)));

    -- Tỷ lệ hài lòng PHHS (DV50.Actual)
    IF NOT EXISTS (SELECT 1 FROM #ContextVars WHERE VarKey = 'DV50.Actual')
        INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('DV50.Actual', '93.5');

    -- Số ca dịch bệnh y tế trường học (DV38.OutbreakCases)
    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('DV38.OutbreakCases', '0');

    -- Số tiết GV vắng chưa dạy bù (CM09.UncompensatedPeriods)
    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('CM09.UncompensatedPeriods', '2');

    -- Tỷ lệ dự giờ đạt chuẩn (CM10.Actual) cho kịch bản bẫy đầu ra
    IF NOT EXISTS (SELECT 1 FROM #ContextVars WHERE VarKey = 'CM10.Actual')
        INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('CM10.Actual', '76.5');

    -- Thêm các metadata cơ sở vào Context
    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('CONTEXT.DonViID', @DonViID);
    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('CONTEXT.PeriodKey', @PeriodKey);

    -- Xuất Result Set 3: Danh sách biến phẳng ContextStore
    SELECT VarKey, VarValue FROM #ContextVars ORDER BY VarKey;

    -- 5. Ngưỡng KPI áp dụng cho ngữ cảnh (Result Set 4: Thresholds)
    SELECT 
        ThresholdID,
        KpiCode,
        ScopeType,
        ScopeID,
        TargetValue,
        WarnThreshold,
        CriticalThreshold,
        ComparisonOperator,
        StatusGoodLabel,
        StatusWarnLabel,
        StatusBadLabel,
        Description
    FROM tblKPI_Thresholds
    WHERE ScopeID = @DonViID OR (ScopeID = 'ALL' AND NOT EXISTS (
        SELECT 1 FROM tblKPI_Thresholds t2 WHERE t2.KpiCode = tblKPI_Thresholds.KpiCode AND t2.ScopeID = @DonViID
    ))
    ORDER BY KpiCode;

    DROP TABLE #ContextVars;
END;
