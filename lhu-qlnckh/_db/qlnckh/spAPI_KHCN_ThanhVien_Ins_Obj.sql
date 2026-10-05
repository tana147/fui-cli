CREATE PROC [dbo].[spAPI_KHCN_ThanhVien_Ins_Obj]
@DeTaiKHCNID INT,
@ThanhVienKHCNObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN
	--insert vào table Thành Viên 
	INSERT INTO [dbo].[KHCN_ThanhVien]
	(
		[DeTaiKHCNID],
		[STT],
		[Is_ChuNhiem],
		[Is_NhanVien],
		[Is_SinhVien],
		[MaNhanVien],
		[Ho],
		[Ten],
		[Email],
		[TenPhongBan],
		[SoTaiKhoan],
		[NganHang],
		[TenChuTaiKhoan],
		[NhanVienCapNhat],
		[ThoiGianCapNhat]
	)
	SELECT
		@DeTaiKHCNID,
		json.STT,
		json.Is_ChuNhiem,
		json.Is_NhanVien,
		json.Is_SinhVien,
		json.MaNhanVien,
		json.Ho,
		json.Ten,
		json.Email,
		json.TenPhongBan,
		json.SoTaiKhoan,
		json.NganHang,
		json.TenChuTaiKhoan,
		@SYS_UserID,
		GETDATE()
	FROM OPENJSON(@ThanhVienKHCNObj)
	WITH (
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
	) AS json;
END