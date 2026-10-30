CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_Get]
    @NienKhoa         INT
  , @TuanHocID        INT
  , @LopID            INT
  , @KhoiID           INT
  , @ViewMode         VARCHAR(10)  -- 'GVBM' | 'GVCN' | 'BGH'
  , @sys_UserID       VARCHAR(20)
  , @sys_SystemRight  INT
  , @sys_FunctionRight VARCHAR(2000)
AS
BEGIN
    SET NOCOUNT ON;

    -- SystemRight: 3=BGH, 4=Quản sinh, 9=Admin. TODO: khi sec.lhbs.vn cấp mã FunctionRight riêng cho
    -- Bí thư Đoàn-TPT Đội thì thắt chặt/mở rộng thêm.
    IF @ViewMode = 'BGH' AND NOT (@sys_SystemRight IN (3, 4, 9) OR CHARINDEX('[QS]', ISNULL(@sys_FunctionRight, N'')) > 0)
    BEGIN
        RAISERROR(N'Bạn không có quyền xem chức năng này.', 16, 1)
        RETURN
    END

    SELECT dk.DangKyID
         , dk.LopID
         , dk.TenLop
         , dk.KhoiID
         , dk.MonHocID
         , dk.TenMonHoc
         , dk.LoaiThietBi
         , dk.GiaoVienDangKyID
         , COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(gv.HoGV, N'') + N' ' + ISNULL(gv.TenGV, N''))), N''), dk.TenGiaoVienDangKy) AS TenGiaoVienDangKy
         , dk.Thu
         , dk.Buoi
         , dk.TietBatDau
         , dk.TietKetThuc
         , dk.NgayApDung
         , dk.TuanHocID
         , dk.GhiChu
         , dk.IsTreHan
         , dk.IsDaThongBaoPH
         , dk.CreateTime
         , (SELECT COUNT(*) FROM dbo.tblDangKyMangLaptop_HocSinh h WHERE h.DangKyID = dk.DangKyID AND h.Enable = 1) AS SoHocSinh
         , (SELECT h.HocSinhID, h.HoTen, h.LoaiThietBi
            FROM dbo.tblDangKyMangLaptop_HocSinh h
            WHERE h.DangKyID = dk.DangKyID AND h.Enable = 1
            FOR JSON PATH) AS JsonHocSinh
         , CASE WHEN EXISTS (SELECT 1 FROM dbo.tblNhom n WHERE n.TenNhom = dk.TenLop AND n.NienKhoa = dk.NienKhoa AND n.Enable = 1)
                THEN (SELECT COUNT(*) FROM dbo.tblHocSinhNhom hsn INNER JOIN dbo.tblNhom n ON n.NhomID = hsn.NhomID
                      WHERE n.TenNhom = dk.TenLop AND n.NienKhoa = dk.NienKhoa AND n.Enable = 1 AND hsn.Enable = 1)
                ELSE (SELECT COUNT(*) FROM dbo.tblHocSinhLop hsl WHERE hsl.LopID = dk.LopID AND hsl.Enable = 1)
           END AS TongSoHocSinh
         , (SELECT COUNT(*) FROM dbo.tblDangKyMangLaptop_HocSinh h WHERE h.DangKyID = dk.DangKyID AND h.Enable = 1 AND h.IsViPham = 1) AS SoViPham
    FROM dbo.tblDangKyMangLaptop dk
    LEFT JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = dk.GiaoVienDangKyID
    WHERE dk.Enable = 1
      AND dk.NienKhoa = @NienKhoa
      AND (@TuanHocID = 0 OR dk.TuanHocID = @TuanHocID)
      AND (@LopID = 0 OR dk.LopID = @LopID)
      AND (@KhoiID = 0 OR dk.KhoiID = @KhoiID)
      AND (
             (@ViewMode = 'GVBM' AND dk.GiaoVienDangKyID = @sys_UserID)
          OR (@ViewMode = 'GVCN' AND EXISTS (
                 SELECT 1 FROM dbo.tblLop l
                 WHERE l.LopID = dk.LopID AND l.GVCN = @sys_UserID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
             ))
          OR (@ViewMode = 'BGH')
      )
    ORDER BY dk.NgayApDung DESC, dk.TietBatDau
END
