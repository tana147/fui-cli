CREATE PROCEDURE [dbo].[spAPI_WF_ReportDashboard_GetDetail]
    @ReportDashboardID BIGINT = 0,
    @sys_UserID VARCHAR(50),
    @sys_UserFullName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TargetDashboardID BIGINT = ISNULL(@ReportDashboardID, 0);

    IF @TargetDashboardID <= 0
    BEGIN
        SELECT TOP (1)
            @TargetDashboardID = D.ReportDashboardID
        FROM dbo.tblWF_ReportDashboard AS D
        WHERE D.OwnerUserID = @sys_UserID
          AND D.[Enable] = 0
          AND D.IsActive = 1
        ORDER BY D.IsDefault DESC, D.ReportDashboardID DESC;
    END

    IF ISNULL(@TargetDashboardID, 0) <= 0
    BEGIN
        EXEC dbo.spAPI_WF_ReportDashboard_GetMy
            @sys_UserID = @sys_UserID,
            @sys_UserFullName = @sys_UserFullName;
        RETURN;
    END

    SELECT
        ReportDashboardID,
        DashboardCode,
        DashboardName,
        OwnerUserID,
        OwnerUserName,
        LayoutJson,
        IsDefault,
        IsActive,
        CreateTime,
        UpdateTime
    FROM dbo.tblWF_ReportDashboard
    WHERE ReportDashboardID = @TargetDashboardID
      AND OwnerUserID = @sys_UserID
      AND [Enable] = 0;

    SELECT
        W.ReportDashboardWidgetID,
        W.ReportDashboardID,
        W.ReportDefinitionID,
        WidgetTitle = ISNULL(NULLIF(W.WidgetTitle, N''), R.ReportName),
        ChartType = ISNULL(NULLIF(W.ChartType, ''), R.ChartType),
        R.ConfigJson,
        W.GridX,
        W.GridY,
        W.GridW,
        W.GridH,
        W.SortOrder,
        W.IsPinned,
        ReportName = R.ReportName,
        DatasetCode = R.DatasetCode,
        DatasetName = D.DatasetName,
        R.TimeRangeKey,
        R.DimensionKey,
        R.MetricKey,
        R.UpdateTime
    FROM dbo.tblWF_ReportDashboardWidget AS W
    INNER JOIN dbo.tblWF_ReportDefinition AS R
        ON R.ReportDefinitionID = W.ReportDefinitionID
       AND R.[Enable] = 0
    LEFT JOIN dbo.tblWF_ReportDataset AS D
        ON D.DatasetCode = R.DatasetCode
       AND D.[Enable] = 0
    WHERE W.ReportDashboardID = @TargetDashboardID
      AND W.[Enable] = 0
      AND W.IsActive = 1
    ORDER BY W.SortOrder, W.ReportDashboardWidgetID;
END
