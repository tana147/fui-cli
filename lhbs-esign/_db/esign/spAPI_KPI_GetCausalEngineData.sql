-- ==============================================================================
-- STORED PROCEDURE: spAPI_KPI_GetCausalEngineData
-- Mô tả: Cung cấp toàn bộ dữ liệu cấu hình động cho 3 Không Gian Quản Trị KPI LHBS:
--        1. Ma Trận 60 Chỉ Tiêu & Ngưỡng Đa Tầng (Baseline & Overrides, Scopes, Formats)
--        2. Hồ Sơ Đơn Vị & Biểu Phí Tham Số
--        3. Studio Chuỗi Nhân Quả Biểu Thức, Nghịch Lý Dữ Liệu & Human-in-the-loop Confirm
-- DB: eSignature (esign)
-- ==============================================================================

CREATE   PROCEDURE spAPI_KPI_GetCausalEngineData
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Result Set 0: Danh Mục 60 Chỉ Tiêu Chuẩn Hóa (tblKPI_Definitions)
    SELECT 
        KpiCode,
        KpiName,
        KpiGroup,
        GroupOrder,
        SortOrder,
        Unit,
        Frequency,
        SourceSystem,
        DefaultTarget,
        DefaultWarn,
        DefaultCritical,
        DefaultOperator,
        FrameworkRef,
        Description,
        IsActive,
        ISNULL(ApplicableScopes, 'ALL') AS ApplicableScopes,
        ISNULL(ValueFormat, 'NUMBER') AS ValueFormat
    FROM tblKPI_Definitions
    WHERE IsActive = 1
    ORDER BY GroupOrder, SortOrder;

    -- 2. Result Set 1: Danh Sách Ngưỡng Đa Tầng (tblKPI_Thresholds)
    SELECT 
        ThresholdID,
        KpiCode,
        ScopeType,
        ScopeID,
        PeriodKey,
        TargetValue,
        WarnThreshold,
        CriticalThreshold,
        ComparisonOperator,
        StatusGoodLabel,
        StatusWarnLabel,
        StatusBadLabel,
        Description
    FROM tblKPI_Thresholds
    ORDER BY KpiCode, ScopeID;

    -- 3. Result Set 2: Danh Sách Tham Số Vận Hành 5 Cơ Sở (tblKPI_Parameters)
    SELECT 
        ParamID,
        ParamCode,
        ScopeType,
        ScopeID,
        PeriodKey,
        ParamValue,
        ParamStringValue,
        Description
    FROM tblKPI_Parameters
    ORDER BY ParamCode, ScopeID;

    -- 4. Result Set 3: Danh Mục Chuỗi Nhân Quả Biểu Thức (tblKPI_CausalNarratives)
    SELECT 
        NarrativeID,
        NarrativeCode,
        NarrativeGroup,
        ISNULL(AnchorKpiCode, 'TS01') AS AnchorKpiCode,
        Title,
        ConditionExpr,
        TemplatePattern,
        ActionPattern,
        DefaultParamsJson,
        ISNULL(ScenarioType, 'CAUSAL_IMPACT') AS ScenarioType,
        VerificationPrompt,
        SortOrder,
        IsActive
    FROM tblKPI_CausalNarratives
    WHERE IsActive = 1
    ORDER BY SortOrder ASC;

    -- 5. Result Set 4: Danh Mục Lý Do & Tuyến Xử Lý Quy Trách Nhiệm (tblKPI_CausalReasons)
    SELECT 
        ReasonCode,
        ScenarioCode,
        ReasonName,
        SortOrder,
        ResponsibleOwner,
        ActionOwner,
        WatchIndicator,
        RecommendedAction,
        ControlLevel,
        HistoricalCount,
        IsActive
    FROM tblKPI_CausalReasons
    WHERE IsActive = 1
    ORDER BY SortOrder ASC;

    -- 6. Result Set 5: Danh Mục Kịch Bản What-If (tblKPI_CausalScenarios)
    SELECT 
        ScenarioCode,
        ScenarioName,
        ScenarioDescription,
        DefaultUnit,
        ISNULL(ScenarioType, 'CAUSAL_IMPACT') AS ScenarioType,
        VerificationPrompt,
        IsActive
    FROM tblKPI_CausalScenarios
    WHERE IsActive = 1
    ORDER BY CASE 
        WHEN ScenarioCode = 'RUT_HOC' THEN 1
        WHEN ScenarioCode = 'TUYEN_THEM' THEN 2
        WHEN ScenarioCode = 'MO_TUYEN_BUS' THEN 3
        WHEN ScenarioCode = 'GIU_CHAN_CHUYEN_CAP' THEN 4
        WHEN ScenarioCode = 'MO_RONG_CLB' THEN 5
        WHEN ScenarioCode = 'CHUYEN_DOI' THEN 6
        ELSE 7 END;

    -- 7. Result Set 6: Bảng Ma Trận Phân Công Trách Nhiệm (tblKPI_CausalActionAssignments)
    SELECT 
        AssignmentID,
        ScenarioCode,
        RoleCode,
        RoleTitle,
        ActionDescription,
        SortOrder
    FROM tblKPI_CausalActionAssignments
    ORDER BY ScenarioCode, SortOrder ASC;

    -- 8. Result Set 7: Hồ Sơ Giả Định Đơn Vị (tblKPI_CausalAssumptions)
    SELECT 
        UnitCode,
        UnitName,
        OwnerTitle,
        PlannedCapacity,
        CurrentEnrollment,
        AnnualTuitionMillion,
        GrossMarginPct,
        RemainingYearsInLevel,
        NextLevelTuitionMillion,
        NextLevelYears,
        TransitionProbability,
        MonthlyLeads,
        ConversionRate,
        ClbParticipationRate,
        ClbAvgFeeMillion,
        ClassCount
    FROM tblKPI_CausalAssumptions
    ORDER BY CASE UnitCode 
        WHEN 'MNBH' THEN 1 
        WHEN 'MNLK' THEN 2 
        WHEN 'TH' THEN 3 
        WHEN 'THCS' THEN 4 
        WHEN 'THPT' THEN 5 
        ELSE 6 END;

    -- 9. Result Set 8: Danh Mục Quy Tắc Logic Nhân Quả (tblKPI_CausalRules)
    SELECT 
        RuleID,
        RuleCode,
        RuleName,
        ConditionExpr,
        Severity,
        OutcomeSummary,
        IsActive
    FROM tblKPI_CausalRules
    WHERE IsActive = 1
    ORDER BY RuleID ASC;

    -- 10. Result Set 9: Ma Trận Co Giãn Tương Quan Hệ Thống (tblKPI_CorrelationOntology)
    SELECT 
        RelationID,
        RelationCode,
        RelationType,
        SourceKpiCode AS CauseKpiCode,
        TargetKpiCode AS EffectKpiCode,
        ElasticityRatio AS ElasticityCoeff,
        FinancialKpiCode,
        UnitFinancialImpact,
        ActionRoleOwner AS InterventionOwner,
        SeverityLevel
    FROM tblKPI_CorrelationOntology
    WHERE IsActive = 1
    ORDER BY SortOrder ASC;
END;
