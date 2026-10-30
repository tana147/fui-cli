CREATE PROCEDURE [dbo].[spAPI_WF_RolePermission_Save]
    @sys_UserID          VARCHAR(50),
    @RolesID             INT,
    @PermissionsIDList   VARCHAR(MAX) -- ví dụ: '3,4,5'
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Xóa tất cả các quyền cũ của Role này
        DELETE FROM dbo.tblWF_RolePermissions
        WHERE RolesID = @RolesID;

        -- 2. Thêm lại các quyền mới từ danh sách gửi xuống
        IF @PermissionsIDList IS NOT NULL AND @PermissionsIDList <> ''
        BEGIN
            INSERT INTO dbo.tblWF_RolePermissions (RolesID, PermissionsID, CreateTime, UpdateUser, UpdateTime, Enable)
            SELECT 
                @RolesID, 
                CAST(value AS INT), 
                GETDATE(), 
                @sys_UserID, 
                GETDATE(), 
                1
            FROM STRING_SPLIT(@PermissionsIDList, ',');
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH

    -- Trả về RolesID
    SELECT @RolesID AS RolesID;
END
