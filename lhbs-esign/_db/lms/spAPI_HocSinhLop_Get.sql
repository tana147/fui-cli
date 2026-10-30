CREATE PROC [dbo].[spAPI_HocSinhLop_Get] 
    @LopID INT,
    @NienKhoa INT
AS
BEGIN
    SELECT hsl.HSLopID,
           hsl.HocSinhID,
           hsl.LopID,
           hsl.SoDanhBo,
           hsl.Enable,
           hs.Ho,
           hs.Ten,
           hs.TinhTrang,
           hs.TenTinhTrang,
		   hs.EnglishName
    FROM dbo.tblHocSinhLop hsl
        INNER JOIN dbo.tblHocSinh hs
            ON hs.HocSinhID = hsl.HocSinhID
    WHERE hsl.LopID = @LopID
      AND (@NienKhoa IS NULL OR @NienKhoa = 0 OR hsl.NienKhoa = @NienKhoa)
	ORDER BY hsl.SoDanhBo, hs.Ten
END;