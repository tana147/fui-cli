
CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyen_Delete]
    @HocLieuID INT,
    @sys_UserID VARCHAR(50),
    @sys_SystemRight INT = 0,
    @sys_FunctionRight VARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    
    IF dbo.fn_CheckUserPermission(
           @sys_SystemRight,
           @sys_FunctionRight,
           '[3][5][9]',
           NULL
       ) = 0
    BEGIN
        RAISERROR(N'[Unauthorized]Bạn không có quyền thực hiện chức năng quản lý tài nguyên này.', 16, 1);
        RETURN;
    END;
SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    UPDATE dbo.tblHocLieu_FP
    SET Is_Xoa = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE HocLieuID = @HocLieuID
      AND Loai = 'TAI_NGUYEN'
      AND (@sys_SystemRight IN (3, 9) OR CreateUser = @sys_UserID)
      AND Is_Xoa = 0;

    IF @@ROWCOUNT = 0
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50109, N'Không tìm thấy bộ tài nguyên hoặc bạn không có quyền xóa.', 1;
    END;

    UPDATE dbo.tblNoiDungHocLieu_FP
    SET Is_Xoa = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE HocLieuID = @HocLieuID AND Is_Xoa = 0;

    COMMIT TRANSACTION;
    SELECT Success = 1;
END;

GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Delete] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Delete] FROM [public];
