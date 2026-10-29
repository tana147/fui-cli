CREATE   PROCEDURE spAPI_KPI_GetCorrelations
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
    ORDER BY SortOrder, CorrelationID;

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

    -- 4.2. Nạp dữ liệu biến động từ tblKPI_PeriodBreakdowns
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 
        'TS04.Reason.' + DimensionCode,
        CAST(CAST(ActualCount AS INT) AS NVARCHAR(20))
    FROM tblKPI_PeriodBreakdowns
    WHERE PeriodKey = @PeriodKey 
      AND KpiCode = 'TS04' 
      AND (DonViID = @DonViID OR (DonViID = 'ALL' AND @DonViID = 'ALL'));

    -- Nạp lý do rút học động từ tblKPI_PeriodBreakdowns
    IF NOT EXISTS (SELECT 1 FROM #ContextVars WHERE VarKey = 'TS04.Reason.FAR')
    BEGIN
        DECLARE @DynFar INT = ISNULL((SELECT SUM(ActualCount) FROM tblKPI_PeriodBreakdowns WHERE PeriodKey = @PeriodKey AND DimensionCode IN ('FAR', 'BUS') AND (@DonViID = 'ALL' OR DonViID = @DonViID)), 0);
        INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('TS04.Reason.FAR', CAST(@DynFar AS NVARCHAR(20)));
    END;
    IF NOT EXISTS (SELECT 1 FROM #ContextVars WHERE VarKey = 'TS04.Reason.BUS')
    BEGIN
        DECLARE @DynBus INT = ISNULL((SELECT SUM(ActualCount) FROM tblKPI_PeriodBreakdowns WHERE PeriodKey = @PeriodKey AND DimensionCode = 'BUS' AND (@DonViID = 'ALL' OR DonViID = @DonViID)), 0);
        INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('TS04.Reason.BUS', CAST(@DynBus AS NVARCHAR(20)));
    END;

    -- Bảo trì cơ sở vật chất (Truy vấn động từ tblKPI_Snap_Maintenance)
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'MAINT.AcRepairs', CAST(ISNULL(COUNT(*), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_Maintenance 
    WHERE PeriodKey = @PeriodKey AND (Location LIKE N'%lạnh%' OR Category LIKE N'%lạnh%' OR IssueDescription LIKE N'%lạnh%')
      AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'MAINT.PendingTickets', CAST(ISNULL(COUNT(*), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_Maintenance 
    WHERE PeriodKey = @PeriodKey AND Status IN ('PENDING', 'RECORDED') AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'MAINT.TotalTickets', CAST(ISNULL(COUNT(*), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_Maintenance 
    WHERE PeriodKey = @PeriodKey AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    -- Y tế học đường (Truy vấn động từ tblKPI_Snap_Healthcare)
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'HEALTH.Cases', CAST(ISNULL(COUNT(*), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_Healthcare 
    WHERE PeriodKey = @PeriodKey AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'HEALTH.FluA', CAST(ISNULL(COUNT(*), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_Healthcare 
    WHERE PeriodKey = @PeriodKey AND (DiseaseType LIKE N'%Cúm%' OR DiseaseType LIKE N'%Sốt%' OR DiseaseType LIKE N'%hô hấp%')
      AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'DV38.OutbreakCases', CAST(ISNULL(SUM(CASE WHEN DiseaseType LIKE N'%dịch%' OR DiseaseType LIKE N'%Cúm%' THEN 1 ELSE 0 END), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_Healthcare 
    WHERE PeriodKey = @PeriodKey AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    -- Nghỉ phép nhân sự (Truy vấn động từ tblKPI_Snap_HRM_Leave)
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'LEAVE.Days', CAST(ISNULL(CAST(ROUND(SUM(LeaveDays), 0) AS INT), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_HRM_Leave 
    WHERE PeriodKey = @PeriodKey AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'LEAVE.Count', CAST(ISNULL(COUNT(*), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_HRM_Leave 
    WHERE PeriodKey = @PeriodKey AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'LEAVE.KitchenDays', CAST(ISNULL(CAST(ROUND(SUM(CASE WHEN Department LIKE N'%Bếp%' THEN LeaveDays ELSE 0 END), 0) AS INT), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_HRM_Leave 
    WHERE PeriodKey = @PeriodKey AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'LEAVE.KinderDays', CAST(ISNULL(CAST(ROUND(SUM(CASE WHEN ScopeID IN ('MNLK', 'MNTB', 'MNBH') OR Department LIKE N'%Mầm Non%' THEN LeaveDays ELSE 0 END), 0) AS INT), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_HRM_Leave 
    WHERE PeriodKey = @PeriodKey AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    -- Dịch vụ CLB & Ngoài giờ (Truy vấn động từ tblKPI_Snap_Finance_Services)
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'CLUB.Revenue', CAST(ISNULL(CAST(ROUND(SUM(NetRevenue) / 1000000.0, 0) AS INT), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_Finance_Services 
    WHERE PeriodKey = @PeriodKey AND ItemCode LIKE 'CLB_%' AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'CLUB.Students', CAST(ISNULL(SUM(StudentCount), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_Finance_Services 
    WHERE PeriodKey = @PeriodKey AND ItemCode LIKE 'CLB_%' AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    -- Tuyển sinh & CRM Pipeline (Truy vấn động từ tblKPI_Snap_CRM_Pipeline)
    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'CRM.Leads', CAST(ISNULL(SUM(TotalLeads), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_CRM_Pipeline 
    WHERE PeriodKey = @PeriodKey AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'CRM.Conversion', CAST(ISNULL(SUM(EnrolledStudents), 0) AS NVARCHAR(50))
    FROM tblKPI_Snap_CRM_Pipeline 
    WHERE PeriodKey = @PeriodKey AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

    INSERT INTO #ContextVars (VarKey, VarValue)
    SELECT 'CRM.ConvRate', CAST(ROUND(ISNULL(SUM(EnrolledStudents) * 100.0 / NULLIF(SUM(TotalLeads), 0), 0), 2) AS NVARCHAR(50))
    FROM tblKPI_Snap_CRM_Pipeline 
    WHERE PeriodKey = @PeriodKey AND (@DonViID = 'ALL' OR ScopeID = @DonViID);

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
    DECLARE @QASample INT = ISNULL((
        SELECT TOP 1 CAST(ParamValue AS INT) FROM tblKPI_Parameters 
        WHERE ParamCode = 'QA_SampleSize' AND (ScopeID = @DonViID OR ScopeID = 'ALL')
        ORDER BY CASE WHEN ScopeID = @DonViID THEN 1 ELSE 2 END
    ), 65);
    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('QA.SampleSize', CAST(@QASample AS NVARCHAR(20)));

    DECLARE @RollDiff INT = CASE @DonViID
        WHEN 'TH' THEN 2
        WHEN 'MNLK' THEN 1
        ELSE 0
    END;
    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('AUDIT.RollDiff', CAST(@RollDiff AS NVARCHAR(20)));

    IF NOT EXISTS (SELECT 1 FROM #ContextVars WHERE VarKey = 'DV50.Actual')
        INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('DV50.Actual', '93.6');

    INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('CM09.UncompensatedPeriods', '2');

    IF NOT EXISTS (SELECT 1 FROM #ContextVars WHERE VarKey = 'CM10.Actual')
        INSERT INTO #ContextVars (VarKey, VarValue) VALUES ('CM10.Actual', '76.5');

    -- Thêm metadata
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

    -- 6. Điểm Vênh Kiểm Toán & Mâu Thuẫn Số Liệu (Result Set 5: Audit Discrepancies)
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
        VerificationStatus,
        CreatedAt
    FROM tblKPI_AuditDiscrepancies
    WHERE PeriodKey = @PeriodKey
      AND (ScopeID = @DonViID OR @DonViID = 'ALL' OR ScopeID = 'ALL')
    ORDER BY DiscrepancyID;

    -- 7. Dimensional Breakdowns (Result Set 6: Breakdowns Mart)
    SELECT 
        BreakdownID,
        PeriodKey,
        DonViID,
        KpiCode,
        DimensionType,
        DimensionCode,
        DimensionName,
        ActualCount,
        ActualValue,
        Rate,
        ResponsibleOwner,
        Note
    FROM tblKPI_PeriodBreakdowns
    WHERE PeriodKey = @PeriodKey
      AND (DonViID = @DonViID OR @DonViID = 'ALL' OR DonViID = 'ALL')
    ORDER BY KpiCode, BreakdownID;

    DROP TABLE #ContextVars;
END;
