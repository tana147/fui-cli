CREATE PROCEDURE [dbo].[spAPI_WF_Audit_SpecChange_Delete]
    @SpecChangeID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.tblWF_AuditSpecChange
    SET [Enable] = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE SpecChangeID = @SpecChangeID AND [Enable] = 0;
    SELECT Message = N'Đã xóa changed spec.', SpecChangeID = @SpecChangeID;
END
