CREATE PROCEDURE [dbo].[spAPI_WF_Role_Delete]
    @sys_UserID VARCHAR(50),
    @RolesID    INT
AS
BEGIN
    UPDATE dbo.tblWF_Roles SET Enable = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE RolesID = @RolesID;
END
