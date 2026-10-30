CREATE PROC spAPI_ThongTinCuoiNam_Get_By_NienKhoa
    @NienKhoa INT
  , @CapID    INT
AS
BEGIN
    SELECT nxt_l.LopID
         , l.TenLop
         , nxt.HSLopID
         , hs.HocSinhID
         , hs.Ho + ' ' + hs.Ten AS HoTen
         , nxt.PhoiHopCMHS
         , nxt.NhanXetGVCN_VePhuHuynh_HTML
         , nxt.NhanXetGVCN_VeHocSinh_HTML
         , nxt.PhanLoai_TuyenThang
         , nxt.Flyers
         , nxt.DiemTA
         , nxt.DKHocTiep
         , nxt.DeXuat_NDCamKet
    FROM
           dbo.tblNhanXetThang                nxt
           INNER JOIN dbo.tblNhanXetThang_Lop nxt_l ON nxt_l.Lop_NhanXetThangID = nxt.Lop_NhanXetThangID
                                                   AND nxt_l.Is_HienThiPhuHuynh = 0
           INNER JOIN dbo.tblLop              AS l ON l.LopID                   = nxt_l.LopID
                                                  AND l.CapID                   = @CapID
                                                  AND l.NienKhoa                = @NienKhoa
           INNER JOIN dbo.tblHocSinh          AS hs ON hs.HocSinhID             = nxt.HocSinhID
    ORDER BY
           l.TenLop
         , hs.Ten;
END;

