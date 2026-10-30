CREATE PROC [dbo].[spAPI_KhenThuong_Get] 
    @LopID INT,
    @NienKhoa INT
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
           INNER JOIN dbo.tblLop       AS l  ON l.LopID = hsl.LopID
                                            AND l.Enable = 1
                                            AND (@NienKhoa IS NULL OR l.NienKhoa = @NienKhoa)
           AND hsl.NienKhoa = l.NienKhoa
        LEFT JOIN dbo.tblKhenThuong AS kt ON kt.HSLopID   = hsl.HSLopID
                                            AND kt.Enable    = 1
           INNER JOIN dbo.tblHocSinh   AS hs ON hs.HocSinhID = hsl.HocSinhID
                                            AND hs.TinhTrang = 0
    WHERE
           hsl.LopID = @LopID
      AND  hsl.Enable = 1
    ORDER BY
           hsl.SoDanhBo
         , hs.Ten;
END;
