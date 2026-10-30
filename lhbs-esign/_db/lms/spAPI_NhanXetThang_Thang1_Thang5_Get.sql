-- [dbo].[spAPI_NhanXetThang_Thang1_Thang5_Get] 2270, 2, 2025
CREATE PROC [dbo].[spAPI_NhanXetThang_Thang1_Thang5_Get]
    @LopID    INT
  , @HocKi    INT
  , @NienKhoa INT
AS
BEGIN
    DECLARE @Lop_NhanXetThangID INT = 0;
    IF (@HocKi = 1)
    BEGIN
        SELECT TOP 1
               @Lop_NhanXetThangID = Lop_NhanXetThangID
        FROM
               dbo.tblNhanXetThang_Lop
        WHERE
               LopID   = @LopID
          AND  Enable   = 1
          AND  NienKhoa = @NienKhoa
          AND  Thang    = 1;
    END;
    ELSE
    BEGIN
        SELECT TOP 1
               @Lop_NhanXetThangID = Lop_NhanXetThangID
        FROM
               dbo.tblNhanXetThang_Lop
        WHERE
               LopID             = @LopID
          AND  Enable             = 1
          AND  NienKhoa           = @NienKhoa
          AND  Thang              = 5
          AND  Is_HienThiPhuHuynh = 1;
    END;

    SELECT ISNULL(nxt.NhanXetThangID, 0) AS NhanXetThangID
         , hsl.HocSinhID
         , hsl.HSLopID
         , hs.Ho + ' ' + hs.Ten          AS HoTen
         , hsl.SoDanhBo
         , hs.NgaySinh
         , hs.Nu
         , nxt.NhanXetCuoiNam_HTML
         , nxt.DiemToan
         , nxt.SoSao_Toan
         , nxt.NhanXetToan_HTML
         , nxt.DiemTiengViet
         , nxt.SoSao_TiengViet
         , nxt.NhanXetTiengViet_HTML
         , nxt.NhanXetMonHocKhac_HTML
         , nxt.HoatDongGiaoDucKhac_HTML
         , nxt.PhamChatNangLuc_HTML
         , nxt.NoiDungKienThuc_HTML
         , nxt.NoiDungNangLuc_HTML
         , nxt.NoiDungHoatDongKhac_HTML
         , nxt.PhoiHopCMHS
         , nxt.NhanXetGVCN_VePhuHuynh_HTML
         , nxt.NhanXetGVCN_VeHocSinh_HTML
         , nxt.PhanLoai_TuyenThang
         , nxt.Flyers
         , nxt.DiemTA
         , nxt.DKHocTiep
         , nxt.DeXuat_NDCamKet
         , nxt.UuDiem
         , nxt.NhuocDiem
         , nxt.DeXuat
    FROM
           dbo.tblHocSinhLop                 AS hsl
           LEFT JOIN dbo.tblNhanXetThang     AS nxt ON nxt.HSLopID                = hsl.HSLopID
                                                   AND nxt.Lop_NhanXetThangID     = @Lop_NhanXetThangID
                                                   AND nxt.Enable                 = 1
           LEFT JOIN dbo.tblNhanXetThang_Lop AS nxt_l ON nxt_l.Lop_NhanXetThangID = nxt.Lop_NhanXetThangID
                                                     AND nxt_l.Enable             = 1
           INNER JOIN dbo.tblHocSinh         AS hs ON hs.HocSinhID                = hsl.HocSinhID
                                                  AND hs.TinhTrang                = 0
    WHERE
           hsl.LopID = @LopID
           -- Báo cáo học kỳ phải lấy đúng danh sách học sinh của lớp và niên khóa.
       AND hsl.NienKhoa = @NienKhoa
    ORDER BY
           hsl.SoDanhBo
         , hs.Ten;
END;
