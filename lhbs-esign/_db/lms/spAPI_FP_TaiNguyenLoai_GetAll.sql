
CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyenLoai_GetAll]
    @sys_UserID VARCHAR(50),
    @sys_SystemRight INT = 0,
    @sys_FunctionRight VARCHAR(2000)
AS
BEGIN
    SET NOCOUNT ON;

    

    IF dbo.fn_CheckUserPermission(
           @sys_SystemRight,
           @sys_FunctionRight,
           '[1][2][3][5][9]',
           NULL
       ) = 0
    BEGIN
        RAISERROR(N'[Unauthorized]Bạn không có quyền thực hiện chức năng quản lý tài nguyên này.', 16, 1);
        RETURN;
    END;
SELECT TaiNguyenLoaiID, Code, TenLoai, KieuLoc, IsActive, ThuTu
    FROM dbo.tblFP_TaiNguyenLoai
    WHERE IsActive = 1
    ORDER BY ThuTu, TenLoai;
END;

GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyenLoai_GetAll] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyenLoai_GetAll] FROM [public];
