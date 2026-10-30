CREATE PROCEDURE [dbo].[spAPI_WF_ReportDashboard_GetMy]
    @sys_UserID VARCHAR(50),
    @sys_UserFullName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DashboardID BIGINT;

    SELECT TOP (1)
        @DashboardID = ReportDashboardID
    FROM dbo.tblWF_ReportDashboard
    WHERE OwnerUserID = @sys_UserID
      AND [Enable] = 0
      AND IsActive = 1
    ORDER BY IsDefault DESC, ReportDashboardID DESC;

    IF ISNULL(@DashboardID, 0) = 0
    BEGIN
        INSERT INTO dbo.tblWF_ReportDashboard
        (
            DashboardCode, DashboardName, OwnerUserID, OwnerUserName, LayoutJson,
            IsDefault, IsActive, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            NULL, N'Dashboard báo cáo của tôi', @sys_UserID, ISNULL(@sys_UserFullName, @sys_UserID), N'{}',
            1, 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 0
        );

        SET @DashboardID = SCOPE_IDENTITY();

        UPDATE dbo.tblWF_ReportDashboard
        SET DashboardCode = 'DSB-' + RIGHT('000000' + CAST(@DashboardID AS VARCHAR(20)), 6)
        WHERE ReportDashboardID = @DashboardID
          AND [Enable] = 0;
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
    WHERE ReportDashboardID = @DashboardID
      AND [Enable] = 0;

    SELECT
        W.ReportDashboardWidgetID,
        W.ReportDashboardID,
        W.ReportDefinitionID,
        WidgetTitle = ISNULL(NULLIF(W.WidgetTitle, N''), R.ReportName),
        ChartType = ISNULL(NULLIF(W.ChartType, ''), R.ChartType),
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
    WHERE W.ReportDashboardID = @DashboardID
      AND W.[Enable] = 0
      AND W.IsActive = 1
    ORDER BY W.SortOrder, W.ReportDashboardWidgetID;
END
