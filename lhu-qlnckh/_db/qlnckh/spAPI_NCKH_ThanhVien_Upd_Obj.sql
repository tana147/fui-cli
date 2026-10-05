CREATE PROC [dbo].[spAPI_NCKH_ThanhVien_Upd_Obj]
@ThanhVienNCKHObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN
	--update vào table Thành Viên 
	UPDATE [dbo].[NCKH_ThanhVien]
	SET
		[STT] = json.STT,
		[Is_ChuNhiem] = json.Is_ChuNhiem,
		[Is_NhanVien] = json.Is_NhanVien,
		[Is_SinhVien] = json.Is_SinhVien,
		[MaThanhVien] = json.MaThanhVien,
		[Ho] = json.Ho,
		[Ten] = json.Ten,
		[Email] = json.Email,
		[PhongBanID] =json.PhongBanID,
		[LopID] = json.LopID,
		[SoTaiKhoan] = json.SoTaiKhoan,
		[NganHang] = json.NganHang,
		[TenChuTaiKhoan] = json.TenChuTaiKhoan,
		[NhanVienCapNhat] = @SYS_UserID
	FROM OPENJSON(@ThanhVienNCKHObj)
	WITH (
		ThanhVienNCKHID INT,
		STT TINYINT,
		Is_ChuNhiem BIT,
		Is_NhanVien BIT,
		Is_SinhVien BIT,
		MaThanhVien VARCHAR(9),
		Ho NVARCHAR(150),
		Ten NVARCHAR(150),
		Email VARCHAR(50),
		PhongBanID NVARCHAR(250),
		LopID VARCHAR(50),
		SoTaiKhoan NVARCHAR(50),
		NganHang NVARCHAR(250),
		TenChuTaiKhoan NVARCHAR(151)
	) AS json
	WHERE [dbo].[NCKH_ThanhVien].[ThanhVienNCKHID] = json.ThanhVienNCKHID
END