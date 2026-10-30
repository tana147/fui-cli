
/*
    VÙNG KIỂM TRA BGH / ADMIN
    Hai API này cố ý tách khỏi API giáo viên. Khi khai báo route API phải gắn
    quyền BGH/Admin; không công bố route này cho role giáo viên.
*/
CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyen_Audit_GetAll]
    @KhoiID INT = 0,
    @MonHocID INT = 0,
    @OwnerUserID VARCHAR(50) = NULL,
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
        THROW 50010, N'Bạn không có quyền kiểm tra kho tài nguyên giáo viên.', 1;

    SELECT
        hl.HocLieuID,
        hl.TenHocLieu,
        hl.MonHocID,
        hl.KhoiID,
        hl.TinhTrang,
        hl.CreateUser AS OwnerUserID,
        hl.CreateTime,
        hl.UpdateTime,
        mh.MonHocName AS TenMonHoc,
        COUNT(CASE WHEN nd.LoaiNoiDung <> 'THU_MUC' AND nd.Is_Xoa = 0 THEN 1 END) AS SoLuongFile
    FROM dbo.tblHocLieu_FP hl
    LEFT JOIN dbo.tblMonHoc mh ON mh.MonHocID = hl.MonHocID
    LEFT JOIN dbo.tblNoiDungHocLieu_FP nd ON nd.HocLieuID = hl.HocLieuID
    WHERE hl.Is_Xoa = 0
        AND hl.Loai = 'TAI_NGUYEN'
        AND (ISNULL(@KhoiID, 0) = 0 OR hl.KhoiID = @KhoiID)
        AND (ISNULL(@MonHocID, 0) = 0 OR hl.MonHocID = @MonHocID)
        AND (@OwnerUserID IS NULL OR hl.CreateUser = @OwnerUserID)
    GROUP BY
        hl.HocLieuID, hl.TenHocLieu, hl.MonHocID, hl.KhoiID, hl.TinhTrang,
        hl.CreateUser, hl.CreateTime, hl.UpdateTime, mh.MonHocName
    ORDER BY ISNULL(hl.UpdateTime, hl.CreateTime) DESC;
END;

GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Audit_GetAll] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Audit_GetAll] FROM [public];
