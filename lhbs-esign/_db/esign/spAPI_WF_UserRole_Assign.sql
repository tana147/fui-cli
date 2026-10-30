CREATE PROCEDURE [dbo].[spAPI_WF_UserRole_Assign]
    @sys_UserID    VARCHAR(50), -- Người thực hiện gán
    @TargetUserID  VARCHAR(50), -- User được gán quyền
    @RoleIDs       VARCHAR(MAX) -- Danh sách RolesID cách nhau bằng dấu phẩy, VD: '1,3'
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Xóa các gán quyền cũ của User này
        DELETE FROM dbo.tblWF_UserRoles WHERE EmployeeCode = @TargetUserID;

        -- 2. Gán các Nhóm quyền mới
        INSERT INTO dbo.tblWF_UserRoles (EmployeeCode, RolesID, Enable, CreateTime, UpdateUser, UpdateTime)
        SELECT
            @TargetUserID,
            CAST(value AS INT),
            1,
            GETDATE(),
            @sys_UserID,
            GETDATE()
        FROM STRING_SPLIT(@RoleIDs, ',');

        COMMIT TRANSACTION;
        SELECT 1 AS Success;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END
