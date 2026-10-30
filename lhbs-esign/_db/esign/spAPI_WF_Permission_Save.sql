CREATE PROCEDURE [dbo].[spAPI_WF_Permission_Save]
    @sys_UserID     VARCHAR(50),
    @PermissionsID  INT = 0,
    @Name           VARCHAR(100),
    @Resource       VARCHAR(50),
    @Action         VARCHAR(50),
    @Enable         TINYINT = 1
AS
BEGIN
    -- Nếu đang Sửa một bản ghi cụ thể
    IF EXISTS (SELECT 1 FROM dbo.tblWF_Permissions WHERE PermissionsID = @PermissionsID)
    BEGIN
        UPDATE dbo.tblWF_Permissions
        SET Name = @Name, Resource = @Resource, Action = @Action, Enable = @Enable,
            UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE PermissionsID = @PermissionsID;
        SELECT @PermissionsID AS PermissionsID;
    END
    -- Nếu Thêm mới nhưng đã có Resource + Action (Xử lý khôi phục từ Xóa mềm)
    ELSE IF EXISTS (SELECT 1 FROM dbo.tblWF_Permissions WHERE Resource = @Resource AND Action = @Action)
    BEGIN
        UPDATE dbo.tblWF_Permissions
        SET Name = @Name, 
            Enable = 1, -- Tự động kích hoạt lại
            UpdateUser = @sys_UserID, 
            UpdateTime = GETDATE()
        WHERE Resource = @Resource AND Action = @Action;
        
        SELECT TOP 1 PermissionsID FROM dbo.tblWF_Permissions WHERE Resource = @Resource AND Action = @Action;
    END
    -- Thêm mới hoàn toàn
    ELSE
    BEGIN
        INSERT INTO dbo.tblWF_Permissions (Name, Resource, Action, Enable, CreateTime, UpdateUser, UpdateTime)
        VALUES (@Name, @Resource, @Action, @Enable, GETDATE(), @sys_UserID, GETDATE());
        SELECT SCOPE_IDENTITY() AS PermissionsID;
    END
END

