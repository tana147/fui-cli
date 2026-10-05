CREATE PROC [dbo].[spAPI_GiangVien_Get]
AS
BEGIN
	SELECT  
		GiangVienID, 
		HocViHocHam, 
		HoTenGiangVien, 
		CoQuanCongTac, 
		CoQuanCongTacTiengViet,
		NganhGiangDay, 
		NganhID, 
		DiaChi,
		SoDienThoai, 
		SoTKNganHang, 
		TenNganHang, 
		MaSoThue,
		Email_GV, 
		FileVanBang_ID, 
		FileVanBang_Name, 
		FileVanBang_Url, 
		FileLyLichKH_ID, 
		FileLyLichKH_Name, 
		FileLyLichKH_Url
	FROM GiangVien 
	WHERE Is_Xoa = 0
END