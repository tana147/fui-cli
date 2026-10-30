CREATE PROC [dbo].[spAPI_HocSinh_Get] @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
        SET @NienKhoa = dbo.fn_GetNienKhoa_HienTai();

    SELECT hs.HocSinhID
         , hs.Ho
         , hs.Ten
         , hs.Ho + ' ' + hs.Ten AS HoTen
         , hs.EnglishName
         , hs.NgaySinh
         , hs.Nu
         , hs.TinhTrang
         , hs.TenTinhTrang
		 , hsl.LopID
		 , l.TenLop
    FROM
           dbo.tblHocSinh AS hs
		   INNER JOIN dbo.tblHocSinhLop AS hsl ON hsl.HocSinhID = hs.HocSinhID 
                                              AND hsl.Enable = 1
		   INNER JOIN dbo.tblLop AS l ON l.LopID = hsl.LopID 
                                     AND l.NienKhoa = @NienKhoa 
                                     AND l.Enable = 1
    AND hsl.NienKhoa = l.NienKhoa
        WHERE
           hs.TinhTrang = 0
	ORDER BY l.TenLop, hsl.SoDanhBo;
END;