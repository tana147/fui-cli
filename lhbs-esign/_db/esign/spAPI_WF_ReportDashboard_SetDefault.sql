CREATE PROCEDURE [dbo].[spAPI_WF_ReportDashboard_SetDefault]
    @ReportDashboardID BIGINT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblWF_ReportDashboard
    SET IsDefault = CASE WHEN ReportDashboardID = @ReportDashboardID THEN 1 ELSE 0 END,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE OwnerUserID = @sys_UserID
      AND [Enable] = 0;

    SELECT Message = N'Đã đặt dashboard mặc định.', ReportDashboardID = @ReportDashboardID;
END
