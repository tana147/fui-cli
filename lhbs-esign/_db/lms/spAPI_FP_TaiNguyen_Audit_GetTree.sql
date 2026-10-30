
CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyen_Audit_GetTree]
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
           '[3][9]',
           NULL
       ) = 0
    BEGIN
        RAISERROR(N'[Unauthorized]Bạn không có quyền thực hiện chức năng quản lý tài nguyên này.', 16, 1);
        RETURN;
    END;
IF ISNULL(@sys_UserID, '') = '' OR ISNULL(@sys_SystemRight, 0) NOT IN (3, 9)
        THROW 50011, N'Bạn không có quyền xem chi tiết kho tài nguyên giáo viên.', 1;

    SELECT
        nd.NoiDungID,
        nd.HocLieuID,
        nd.ParentID,
        nd.TenNoiDung,
        nd.LoaiNoiDung,
        nd.ThuTu,
        nd.DataJson,
        nd.CreateUser,
        nd.CreateTime,
        nd.UpdateTime,
        hl.CreateUser AS OwnerUserID,
        hl.KhoiID,
        hl.MonHocID
    FROM dbo.tblNoiDungHocLieu_FP nd
    INNER JOIN dbo.tblHocLieu_FP hl ON hl.HocLieuID = nd.HocLieuID
    WHERE nd.HocLieuID = @HocLieuID
        AND nd.Is_Xoa = 0
        AND hl.Is_Xoa = 0
        AND hl.Loai = 'TAI_NGUYEN'
    ORDER BY ISNULL(nd.ParentID, 0), nd.ThuTu, nd.TenNoiDung;
END;

GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Audit_GetTree] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Audit_GetTree] FROM [public];
