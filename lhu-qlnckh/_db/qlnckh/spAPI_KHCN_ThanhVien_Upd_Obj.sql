CREATE PROC [dbo].[spAPI_KHCN_ThanhVien_Upd_Obj]
@ThanhVienKHCNObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN
	--update vào table Thành Viên 
	UPDATE [dbo].[KHCN_ThanhVien]
	SET
		[STT] = json.STT,
		[Is_ChuNhiem] = json.Is_ChuNhiem,
		[Is_NhanVien] = json.Is_NhanVien,
		[Is_SinhVien] = json.Is_SinhVien,
		[MaNhanVien] = json.MaNhanVien,
		[Ho] = json.Ho,
		[Ten] = json.Ten,
		[Email] = json.Email,
		[TenPhongBan] = json.TenPhongBan,
		[SoTaiKhoan] = json.SoTaiKhoan,
		[NganHang] = json.NganHang,
		[TenChuTaiKhoan] = json.TenChuTaiKhoan,
		[NhanVienCapNhat] = @SYS_UserID
	FROM OPENJSON(@ThanhVienKHCNObj)
	WITH (
		ThanhVienKHCNID INT,
		STT TINYINT,
		Is_ChuNhiem BIT,
		Is_NhanVien BIT,
		Is_SinhVien BIT,
		MaNhanVien VARCHAR(9),
		Ho NVARCHAR(150),
		Ten NVARCHAR(150),
		Email VARCHAR(50),
		TenPhongBan NVARCHAR(250),
		SoTaiKhoan NVARCHAR(50),
		NganHang NVARCHAR(250),
		TenChuTaiKhoan NVARCHAR(150)
	) AS json
	WHERE [dbo].[KHCN_ThanhVien].[ThanhVienKHCNID] = json.ThanhVienKHCNID
END