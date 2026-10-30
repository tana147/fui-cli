--[dbo].[spAPI_KhenThuong_Get_By_KhoiID] 1
CREATE PROC [dbo].[spAPI_KhenThuong_Get_By_KhoiID] @KhoiID INT, @NienKhoa INT
AS
BEGIN
    SELECT ISNULL(kt.KhenThuongID, 0) AS KhenThuongID
         , hsl.HocSinhID
         , hsl.HSLopID
         , hs.Ho + ' ' + hs.Ten       AS HoTen
         , hsl.SoDanhBo
         , hs.NgaySinh
         , hs.Nu
         , kt.HocSinhTieuBieu
         , kt.ThanhTichKhac
         , kt.NoiDungThuKhen
         , kt.DanhHieu
         , kt.VaoSoKT
         , kt.SoQuyetDinhKT
         , kt.NgayKhenThuong_VI
         , kt.NgayKhenThuong_EN
		 , kt.NgayKhenThuong_ThuKhen_VI
		 , kt.NgayKhenThuong_ThuKhen_EN
    FROM
           dbo.tblHocSinhLop           AS hsl
           LEFT JOIN dbo.tblKhenThuong AS kt ON kt.HSLopID   = hsl.HSLopID
											AND kt.NienKhoa = @NienKhoa
                                            AND kt.Enable    = 1
           INNER JOIN dbo.tblHocSinh   AS hs ON hs.HocSinhID = hsl.HocSinhID
                                            AND hs.TinhTrang = 0
           INNER JOIN dbo.tblLop       AS l ON l.LopID       = hsl.LopID
                                           AND l.KhoiID      = @KhoiID
										   AND L.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        ORDER BY
           hsl.SoDanhBo
         , hs.Ten;
END;