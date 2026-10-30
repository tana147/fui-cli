CREATE PROCEDURE [dbo].[spAPI_WF_Audit_TestCase_Delete]
    @AuditTestCaseID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.tblWF_AuditTestCase
    SET [Enable] = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE AuditTestCaseID = @AuditTestCaseID AND [Enable] = 0;
    SELECT Message = N'Đã xóa testcase.', AuditTestCaseID = @AuditTestCaseID;
END
