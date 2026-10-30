
CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyen_GetTree]
    @HocLieuID INT,
    @sys_UserID VARCHAR(50),
    @sys_SystemRight INT,
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
    DECLARE @TargetExists BIT = 0;
    DECLARE @TargetKhoiID INT = NULL;
    DECLARE @TargetMonHocID INT = NULL;
    DECLARE @IsSharedSubject BIT = 0;

    SELECT
        @TargetExists = 1,
        @TargetKhoiID = hl.KhoiID,
        @TargetMonHocID = hl.MonHocID,
        @IsSharedSubject = CASE
            WHEN ISNULL(hl.KhoiID, 0) <> 0
             AND ISNULL(hl.MonHocID, 0) <> 0
             AND l.Code = 'TAI_LIEU_THAM_KHAO' THEN 1
            ELSE 0
        END
    FROM dbo.tblHocLieu_FP hl
    LEFT JOIN dbo.tblFP_TaiNguyenLoai l ON l.TaiNguyenLoaiID = hl.TaiNguyenLoaiID
    WHERE hl.HocLieuID = @HocLieuID
      AND hl.Loai = 'TAI_NGUYEN'
      AND (
            @sys_SystemRight IN (3, 9)
            OR hl.CreateUser = @sys_UserID
            OR (
                ISNULL(hl.KhoiID, 0) <> 0
                AND ISNULL(hl.MonHocID, 0) <> 0
                AND l.Code = 'TAI_LIEU_THAM_KHAO'
            )
          )
      AND hl.Is_Xoa = 0;

    IF @TargetExists = 0
        THROW 50108, N'Không tìm thấy bộ tài nguyên hoặc bạn không có quyền truy cập.', 1;

    -- Trả tên giáo viên tạo tài liệu để Content Hub hiển thị rõ nguồn sở hữu thay vì chỉ có mã tài khoản.
    SELECT nd.NoiDungID, nd.HocLieuID, nd.ParentID, nd.TenNoiDung, nd.LoaiNoiDung, nd.ThuTu, nd.DataJson,
           NguonTaiNguyenCode, NguonResourceType, NguonResourceID,
           nd.CreateUser, nd.CreateTime, nd.UpdateTime,
           gv.HoGV + N' ' + gv.TenGV AS NguoiUploadName
    FROM dbo.tblNoiDungHocLieu_FP nd
    LEFT JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = nd.CreateUser
    WHERE nd.Is_Xoa = 0
      AND (
            nd.HocLieuID = @HocLieuID
            OR (
                @IsSharedSubject = 1
                AND EXISTS (
                    SELECT 1
                    FROM dbo.tblHocLieu_FP shared_hl
                    INNER JOIN dbo.tblFP_TaiNguyenLoai shared_l
                        ON shared_l.TaiNguyenLoaiID = shared_hl.TaiNguyenLoaiID
                    WHERE shared_hl.HocLieuID = nd.HocLieuID
                      AND shared_hl.Is_Xoa = 0
                      AND shared_hl.Loai = 'TAI_NGUYEN'
                      AND shared_hl.KhoiID = @TargetKhoiID
                      AND shared_hl.MonHocID = @TargetMonHocID
                      AND shared_l.Code = 'TAI_LIEU_THAM_KHAO'
                )
            )
          )
    ORDER BY ISNULL(ParentID, 0), ThuTu, TenNoiDung;
END;

GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_GetTree] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_GetTree] FROM [public];
