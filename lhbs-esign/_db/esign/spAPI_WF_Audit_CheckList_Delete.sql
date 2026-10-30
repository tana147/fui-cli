CREATE PROCEDURE [dbo].[spAPI_WF_Audit_CheckList_Delete]
    @ChecklistID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.tblWF_AuditChecklist
    SET [Enable] = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE ChecklistID = @ChecklistID AND [Enable] = 0;
    SELECT Message = N'Đã xóa checklist.', ChecklistID = @ChecklistID;
END
