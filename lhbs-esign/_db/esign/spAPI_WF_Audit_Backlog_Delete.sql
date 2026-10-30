CREATE PROCEDURE [dbo].[spAPI_WF_Audit_Backlog_Delete]
    @BacklogID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.tblWF_AuditBacklog
    SET [Enable] = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE BacklogID = @BacklogID AND [Enable] = 0;
    SELECT Message = N'Đã xóa backlog.', BacklogID = @BacklogID;
END
