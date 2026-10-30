CREATE PROCEDURE [dbo].[spAPI_WF_RolePermission_Assign]
    @sys_UserID    VARCHAR(50),
    @RolesID       INT,
    @PermissionIDs VARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.tblWF_RolePermissions WHERE RolesID = @RolesID;

        INSERT INTO dbo.tblWF_RolePermissions (RolesID, PermissionsID, Enable, CreateTime, UpdateUser, UpdateTime)
        SELECT
            @RolesID,
            CAST(value AS INT),
            1,
            GETDATE(),
            @sys_UserID,
            GETDATE()
        FROM STRING_SPLIT(@PermissionIDs, ',');

        COMMIT TRANSACTION;
        SELECT 1 AS Success;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END
