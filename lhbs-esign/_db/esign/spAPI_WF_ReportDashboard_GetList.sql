CREATE PROCEDURE [dbo].[spAPI_WF_ReportDashboard_GetList]
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        D.ReportDashboardID,
        D.DashboardCode,
        D.DashboardName,
        D.OwnerUserID,
        D.OwnerUserName,
        D.LayoutJson,
        D.IsDefault,
        D.IsActive,
        D.CreateTime,
        D.UpdateTime,
        WidgetCount = ISNULL(W.WidgetCount, 0)
    FROM dbo.tblWF_ReportDashboard AS D
    OUTER APPLY
    (
        SELECT WidgetCount = COUNT(1)
        FROM dbo.tblWF_ReportDashboardWidget AS X
        WHERE X.ReportDashboardID = D.ReportDashboardID
          AND X.[Enable] = 0
          AND X.IsActive = 1
    ) AS W
    WHERE D.OwnerUserID = @sys_UserID
      AND D.[Enable] = 0
    ORDER BY D.IsDefault DESC, D.UpdateTime DESC, D.ReportDashboardID DESC;
END
