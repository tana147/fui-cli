CREATE OR ALTER PROCEDURE spAPI_KPI_GetAuditDiscrepancies
    @PeriodKey VARCHAR(20),
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

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
      AND (@Category IS NULL OR @Category = '' OR Category = @Category)
    ORDER BY DiscrepancyID;
END;
