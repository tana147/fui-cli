CREATE   PROCEDURE spAPI_KPI_GetPeriods
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        PeriodKey,
        PeriodName,
        PeriodType,
        SchoolYear,
        StartDate,
        EndDate,
        IsFrozen,
        DataSourceType,
        FreezeDate,
        FrozenBy,
        Note
    FROM tblKPI_Periods
    ORDER BY StartDate DESC;
END;
