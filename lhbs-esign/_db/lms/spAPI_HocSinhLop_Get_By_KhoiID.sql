CREATE PROC [dbo].[spAPI_HocSinhLop_Get_By_KhoiID] @KhoiID INT
AS
BEGIN
    SELECT hsl.HSLopID
         , hsl.HocSinhID
		 , hsl.SoDanhBo
         , hs.Ho + ' ' + hs.Ten AS HoTen
    FROM
           dbo.tblHocSinhLop         hsl
           INNER JOIN dbo.tblLop     AS l ON l.LopID       = hsl.LopID AND l.NienKhoa = hsl.NienKhoa
                                         AND l.KhoiID      = @KhoiID
                                         AND l.Enable      = 1
                                         AND hsl.NienKhoa  = dbo.fn_GetNienKhoa_HienTai()
           INNER JOIN dbo.tblHocSinh AS hs ON hs.HocSinhID = hsl.HocSinhID
                                          AND hs.TinhTrang = 0
    WHERE
           hsl.Enable = 1
	order by SoDanhBo
END;