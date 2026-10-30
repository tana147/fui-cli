CREATE PROCEDURE [dbo].[spAPI_WF_ReportDashboard_PinReport]
    @ReportDefinitionID BIGINT,
    @sys_UserID VARCHAR(50),
    @sys_UserFullName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DashboardID BIGINT;
    DECLARE @NextSort INT = 10;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.tblWF_ReportDefinition
        WHERE ReportDefinitionID = @ReportDefinitionID
          AND [Enable] = 0
          AND OwnerUserID = @sys_UserID
    )
    BEGIN
        RAISERROR(N'Không tìm thấy báo cáo để ghim dashboard.', 16, 1);
        RETURN;
    END

    EXEC dbo.spAPI_WF_ReportDashboard_GetMy @sys_UserID = @sys_UserID, @sys_UserFullName = @sys_UserFullName;

    SELECT TOP (1)
        @DashboardID = ReportDashboardID
    FROM dbo.tblWF_ReportDashboard
    WHERE OwnerUserID = @sys_UserID
      AND [Enable] = 0
      AND IsActive = 1
    ORDER BY IsDefault DESC, ReportDashboardID DESC;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.tblWF_ReportDashboardWidget
        WHERE ReportDashboardID = @DashboardID
          AND ReportDefinitionID = @ReportDefinitionID
          AND [Enable] = 0
          AND IsActive = 1
    )
    BEGIN
        SELECT Message = N'Báo cáo đã có trên dashboard.', ReportDashboardID = @DashboardID, ReportDefinitionID = @ReportDefinitionID;
        RETURN;
    END

    SELECT @NextSort = ISNULL(MAX(SortOrder), 0) + 10
    FROM dbo.tblWF_ReportDashboardWidget
    WHERE ReportDashboardID = @DashboardID
      AND [Enable] = 0;

    INSERT INTO dbo.tblWF_ReportDashboardWidget
    (
        ReportDashboardID, ReportDefinitionID, WidgetTitle, ChartType, GridX, GridY, GridW, GridH,
        SortOrder, IsPinned, IsActive, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
    )
    SELECT
        @DashboardID, R.ReportDefinitionID, R.ReportName, R.ChartType, 0, 0, 6, 4,
        @NextSort, 1, 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 0
    FROM dbo.tblWF_ReportDefinition AS R
    WHERE R.ReportDefinitionID = @ReportDefinitionID
      AND R.[Enable] = 0;

    UPDATE dbo.tblWF_ReportDefinition
    SET IsPinnedDashboard = 1,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE ReportDefinitionID = @ReportDefinitionID
      AND [Enable] = 0;

    SELECT Message = N'Đã ghim báo cáo lên dashboard.', ReportDashboardID = @DashboardID, ReportDefinitionID = @ReportDefinitionID;
END
