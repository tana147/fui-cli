
CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyen_GetAll]
    @KhoiID INT,
    @MonHocID INT,
    @TaiNguyenLoaiID INT,
    @TaiNguyenMucID INT,
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
SELECT
        hl.HocLieuID, hl.TenHocLieu, hl.BoSachID, hl.MonHocID, hl.KhoiID,
        hl.HocKy, hl.ThumbnailURL, hl.TinhTrang, hl.Loai,
        hl.TaiNguyenLoaiID, hl.TaiNguyenMucID,
        l.Code AS TaiNguyenLoaiCode, l.TenLoai, l.KieuLoc,
        m.Code AS TaiNguyenMucCode, m.TenMuc,
        hl.CreateUser, hl.CreateUser AS NguoiUploadID, hl.CreateTime, hl.UpdateTime,
        gv.HoGV + N' ' + gv.TenGV AS NguoiUploadName,
        mh.MonHocName AS TenMonHoc,
        (SELECT COUNT(*) FROM dbo.tblNoiDungHocLieu_FP nd
         WHERE nd.HocLieuID = hl.HocLieuID AND nd.Is_Xoa = 0
           AND nd.LoaiNoiDung <> 'THU_MUC') AS SoLuongFile
    FROM dbo.tblHocLieu_FP hl
    LEFT JOIN dbo.tblMonHoc mh ON mh.MonHocID = hl.MonHocID
    LEFT JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = hl.CreateUser
    LEFT JOIN dbo.tblFP_TaiNguyenLoai l ON l.TaiNguyenLoaiID = hl.TaiNguyenLoaiID
    LEFT JOIN dbo.tblFP_TaiNguyenMuc m ON m.TaiNguyenMucID = hl.TaiNguyenMucID
    WHERE hl.Is_Xoa = 0 AND hl.Loai = 'TAI_NGUYEN'
      -- Kho tài liệu Khối/Môn là tài nguyên dùng chung; Hồ sơ/Sáng kiến (Khối/Môn = 0)
      -- vẫn giữ quyền riêng theo người tạo, trừ BGH/Admin.
      AND (
            @sys_SystemRight IN (3, 9)
            OR hl.CreateUser = @sys_UserID
            OR (
                ISNULL(hl.KhoiID, 0) <> 0
                AND ISNULL(hl.MonHocID, 0) <> 0
                AND l.Code = 'TAI_LIEU_THAM_KHAO'
            )
          )
      AND (ISNULL(@KhoiID, 0) = 0 OR hl.KhoiID = @KhoiID)
      AND (ISNULL(@MonHocID, 0) = 0 OR hl.MonHocID = @MonHocID)
      AND (ISNULL(@TaiNguyenLoaiID, 0) = 0 OR hl.TaiNguyenLoaiID = @TaiNguyenLoaiID)
      AND (ISNULL(@TaiNguyenMucID, 0) = 0 OR hl.TaiNguyenMucID = @TaiNguyenMucID)
    -- Ưu tiên kho do giáo viên hiện tại tạo để luồng upload vẫn ghi được vào kho có quyền sở hữu.
    ORDER BY CASE WHEN hl.CreateUser = @sys_UserID THEN 0 ELSE 1 END,
             ISNULL(hl.UpdateTime, hl.CreateTime) DESC, hl.TenHocLieu;
END;

GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_GetAll] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_GetAll] FROM [public];
