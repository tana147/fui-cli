CREATE PROCEDURE [dbo].[spAPI_WF_Role_Save]
    @sys_UserID  VARCHAR(50),
    @RolesID     INT = 0,
    @Name        VARCHAR(50),
    @Description NVARCHAR(MAX),
    @Enable      TINYINT = 1
AS
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.tblWF_Roles WHERE RolesID = @RolesID)
    BEGIN
        UPDATE dbo.tblWF_Roles
        SET Name = @Name,
            Description = @Description,
            Enable = @Enable,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE RolesID = @RolesID;
        SELECT @RolesID AS RolesID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tblWF_Roles (Name, Description, Enable, CreateTime, UpdateUser, UpdateTime)
        VALUES (@Name, @Description, @Enable, GETDATE(), @sys_UserID, GETDATE());
        SELECT SCOPE_IDENTITY() AS RolesID;
    END
END
