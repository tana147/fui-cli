CREATE PROCEDURE [dbo].[spAPI_WF_ReportDashboard_Delete]
    @ReportDashboardID BIGINT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblWF_ReportDashboardWidget
    SET [Enable] = 1,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE ReportDashboardID = @ReportDashboardID
      AND [Enable] = 0;

    UPDATE dbo.tblWF_ReportDashboard
    SET [Enable] = 1,
        IsActive = 0,
        IsDefault = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE ReportDashboardID = @ReportDashboardID
      AND OwnerUserID = @sys_UserID
      AND [Enable] = 0;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.tblWF_ReportDashboard
        WHERE OwnerUserID = @sys_UserID
          AND [Enable] = 0
          AND IsDefault = 1
    )
    BEGIN
        ;WITH NextDefault AS
        (
            SELECT TOP (1) *
            FROM dbo.tblWF_ReportDashboard
            WHERE OwnerUserID = @sys_UserID
              AND [Enable] = 0
            ORDER BY UpdateTime DESC, ReportDashboardID DESC
        )
        UPDATE NextDefault
        SET IsDefault = 1,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE();
    END

    SELECT Message = N'Đã xóa dashboard.', ReportDashboardID = @ReportDashboardID;
END
