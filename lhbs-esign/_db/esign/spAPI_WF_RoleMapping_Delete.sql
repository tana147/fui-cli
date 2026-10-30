CREATE PROCEDURE [dbo].[spAPI_WF_RoleMapping_Delete]
    @RoleMappingID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblWF_RoleMapping
    SET [Enable] = 1,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE RoleMappingID = @RoleMappingID
      AND [Enable] = 0;

    SELECT
        Message = N'Đã xóa mềm role mapping thành công.',
        RoleMappingID = @RoleMappingID;
END
