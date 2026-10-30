CREATE PROCEDURE [dbo].[spAPI_WF_Permission_Delete]
    @sys_UserID     VARCHAR(50),
    @PermissionsID  INT,
    @IsHardDelete   BIT = 0 -- Mặc định là 0 (Xóa mềm), truyền 1 để Xóa cứng
AS
BEGIN
    IF @IsHardDelete = 1
    BEGIN
        -- 1. XÓA CỨNG (Hard Delete): Xóa vĩnh viễn khỏi Database
        -- Xóa các liên kết trước để tránh lỗi khóa ngoại
        DELETE FROM dbo.tblWF_RolePermissions WHERE PermissionsID = @PermissionsID;
        DELETE FROM dbo.tblWF_Permissions WHERE PermissionsID = @PermissionsID;
    END
    ELSE
    BEGIN
        -- 2. XÓA MỀM (Soft Delete): Chỉ ẩn đi bằng cách đổi trạng thái
        UPDATE dbo.tblWF_Permissions 
        SET Enable = 0, 
            UpdateUser = @sys_UserID, 
            UpdateTime = GETDATE()
        WHERE PermissionsID = @PermissionsID;
    END
    
    -- Trả về kết quả
    SELECT @PermissionsID AS PermissionsID;
END

