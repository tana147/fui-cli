CREATE PROCEDURE [dbo].[spAPI_WF_ReportDefinition_GetList]
    @sys_UserID VARCHAR(50),
    @Keyword NVARCHAR(200) = NULL,
    @OnlyMine BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @q NVARCHAR(200) = LTRIM(RTRIM(ISNULL(@Keyword, N'')));

    SELECT
        R.ReportDefinitionID,
        R.ReportCode,
        R.ReportName,
        R.Description,
        R.DatasetCode,
        DatasetName = D.DatasetName,
        R.ChartType,
        R.DimensionKey,
        R.MetricKey,
        R.TimeRangeKey,
        R.StatusFilter,
        R.SelectedFieldsJson,
        R.IsShared,
        R.IsPinnedDashboard,
        R.IsActive,
        R.OwnerUserID,
        R.OwnerUserName,
        R.CreateTime,
        R.UpdateTime
    FROM dbo.tblWF_ReportDefinition AS R
    LEFT JOIN dbo.tblWF_ReportDataset AS D
        ON D.DatasetCode = R.DatasetCode
       AND D.[Enable] = 0
    WHERE R.[Enable] = 0
      AND (@OnlyMine = 0 OR R.OwnerUserID = @sys_UserID)
      AND (
            @q = N''
            OR R.ReportName LIKE N'%' + @q + N'%'
            OR ISNULL(R.DatasetCode, '') LIKE '%' + CAST(@q AS VARCHAR(200)) + '%'
          )
    ORDER BY ISNULL(R.IsPinnedDashboard, 0) DESC, ISNULL(R.UpdateTime, R.CreateTime) DESC, R.ReportDefinitionID DESC;
END
