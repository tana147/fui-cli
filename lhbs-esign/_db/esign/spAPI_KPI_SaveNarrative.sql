-- ========================================================
-- STORED PROCEDURE: spAPI_KPI_SaveNarrative
-- Lưu / cập nhật mẫu câu chuỗi nhân quả kèm biểu thức, phân loại kịch bản & prompt kiểm toán
-- DB: eSignature (esign)
-- ========================================================
CREATE OR ALTER PROCEDURE spAPI_KPI_SaveNarrative
    @NarrativeID INT,
    @NarrativeCode VARCHAR(50),
    @NarrativeGroup NVARCHAR(100),
    @AnchorKpiCode VARCHAR(50),
    @Title NVARCHAR(200),
    @ConditionExpr NVARCHAR(500),
    @TemplatePattern NVARCHAR(MAX),
    @ActionPattern NVARCHAR(200),
    @ScenarioType VARCHAR(30),
    @VerificationPrompt NVARCHAR(500),
    @SortOrder INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @AnchorKpiCode IS NULL OR @AnchorKpiCode = '' SET @AnchorKpiCode = 'TS01';
    IF @ScenarioType IS NULL OR @ScenarioType = '' SET @ScenarioType = 'CAUSAL_IMPACT';
    IF @SortOrder IS NULL OR @SortOrder <= 0 SET @SortOrder = 1;

    IF @NarrativeID IS NOT NULL AND @NarrativeID > 0 AND EXISTS (SELECT 1 FROM tblKPI_CausalNarratives WHERE NarrativeID = @NarrativeID)
    BEGIN
        UPDATE tblKPI_CausalNarratives
        SET 
            NarrativeCode = @NarrativeCode,
            NarrativeGroup = @NarrativeGroup,
            AnchorKpiCode = @AnchorKpiCode,
            Title = @Title,
            ConditionExpr = @ConditionExpr,
            TemplatePattern = @TemplatePattern,
            ActionPattern = @ActionPattern,
            ScenarioType = @ScenarioType,
            VerificationPrompt = @VerificationPrompt,
            SortOrder = @SortOrder
        WHERE NarrativeID = @NarrativeID;
    END
    ELSE IF EXISTS (SELECT 1 FROM tblKPI_CausalNarratives WHERE NarrativeCode = @NarrativeCode)
    BEGIN
        UPDATE tblKPI_CausalNarratives
        SET 
            NarrativeGroup = @NarrativeGroup,
            AnchorKpiCode = @AnchorKpiCode,
            Title = @Title,
            ConditionExpr = @ConditionExpr,
            TemplatePattern = @TemplatePattern,
            ActionPattern = @ActionPattern,
            ScenarioType = @ScenarioType,
            VerificationPrompt = @VerificationPrompt,
            SortOrder = @SortOrder
        WHERE NarrativeCode = @NarrativeCode;
    END
    ELSE
    BEGIN
        INSERT INTO tblKPI_CausalNarratives (
            NarrativeCode, NarrativeGroup, AnchorKpiCode, Title,
            ConditionExpr, TemplatePattern, ActionPattern, ScenarioType,
            VerificationPrompt, SortOrder, IsActive, CreatedAt
        )
        VALUES (
            @NarrativeCode, @NarrativeGroup, @AnchorKpiCode, @Title,
            @ConditionExpr, @TemplatePattern, @ActionPattern, @ScenarioType,
            @VerificationPrompt, @SortOrder, 1, GETDATE()
        );
    END

    SELECT 1 AS Success, N'Đã cập nhật chuỗi nhân quả động kèm kiểm toán M&E' AS Message;
END;
