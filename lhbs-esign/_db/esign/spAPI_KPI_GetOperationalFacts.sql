CREATE OR ALTER PROCEDURE spAPI_KPI_GetOperationalFacts
    @PeriodKey VARCHAR(20),
    @DomainCode VARCHAR(50),
    @ScopeID VARCHAR(50),
    @Limit INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    IF @Limit IS NULL OR @Limit <= 0
        SET @Limit = 200;

    SELECT TOP (@Limit)
        FactID,
        PeriodKey,
        SchoolYear,
        DomainCode,
        ScopeID,
        EntityCode,
        EntityName,
        Dim1,
        Dim2,
        Dim3,
        Dim4,
        MetricCount,
        MetricAmount,
        MetricRate,
        Status,
        OccurredDate,
        PayloadJson,
        SourceSystem,
        CreatedAt
    FROM tblKPI_OperationalFacts
    WHERE PeriodKey = @PeriodKey
      AND (@DomainCode IS NULL OR @DomainCode = '' OR DomainCode = @DomainCode)
      AND (@ScopeID IS NULL OR @ScopeID = '' OR @ScopeID = 'ALL' OR ScopeID = @ScopeID)
    ORDER BY FactID DESC;
END;
