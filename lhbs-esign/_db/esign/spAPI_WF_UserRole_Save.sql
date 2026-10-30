CREATE PROCEDURE [dbo].[spAPI_WF_UserRole_Save]
    @sys_UserID VARCHAR(50),
    @UserID     VARCHAR(50),
    @RoleIDs    NVARCHAR(MAX) -- Nhận chuỗi JSON dạng "[1, 2, 3]"
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Xóa toàn bộ vai trò cũ của User này
        DELETE FROM dbo.tblWF_UserRoles WHERE EmployeeCode = @UserID;

        -- 2. Chèn danh sách vai trò mới nếu chuỗi RoleIDs không rỗng
        IF @RoleIDs IS NOT NULL AND @RoleIDs <> '' AND @RoleIDs <> '[]'
        BEGIN
            INSERT INTO dbo.tblWF_UserRoles (EmployeeCode, RolesID, CreateTime, UpdateUser, UpdateTime)
            SELECT @UserID, CAST([value] AS INT), GETDATE(), @sys_UserID, GETDATE()
            FROM OPENJSON(@RoleIDs);
        END

        COMMIT TRANSACTION;
        SELECT @UserID AS UserID;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END

