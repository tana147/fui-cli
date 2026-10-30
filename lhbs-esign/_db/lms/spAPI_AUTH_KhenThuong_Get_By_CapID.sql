--[dbo].[spAPI_AUTH_KhenThuong_Get_By_CapID] 3,2025

CREATE PROC [dbo].[spAPI_AUTH_KhenThuong_Get_By_CapID]
@CapID INT,
@NienKhoa INT
AS
BEGIN
	SELECT kt.KhenThuongID
		 , hsl.HocSinhID
		 , hs.Ho + ' ' + hs.Ten AS HoTen
         , kt.KhoiID
         , kt.HSLopID
         , kt.HocSinhTieuBieu
         , kt.NoiDungThuKhen
         , kt.ThanhTichKhac
         , kt.DanhHieu 	
	FROM dbo.tblKhenThuong kt
		INNER JOIN dbo.tblHocSinhLop hsl ON hsl.HSLopID = kt.HSLopID  AND hsl.Enable = 1
		INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID 
		INNER JOIN dbo.tblLop l ON l.LopID = hsl.LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
		AND l.CapID = @CapID
	AND hsl.NienKhoa = l.NienKhoa
        WHERE kt.Enable = 1 AND kt.NienKhoa = @NienKhoa    
END

