
CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyenMuc_GetAll]
    @TaiNguyenLoaiID INT,
    @sys_SystemRight INT = 0,
    @sys_FunctionRight VARCHAR(2000) = NULL
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
SELECT TaiNguyenMucID, TaiNguyenLoaiID, Code, TenMuc, IsActive, ThuTu
    FROM dbo.tblFP_TaiNguyenMuc
    WHERE TaiNguyenLoaiID = @TaiNguyenLoaiID AND IsActive = 1
    ORDER BY ThuTu, TenMuc;
END;

GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyenMuc_GetAll] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyenMuc_GetAll] FROM [public];
