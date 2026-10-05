CREATE PROC [dbo].[spAPI_NCKH_ThanhVien_Ins_Obj]
@DeTaiNCKHID INT,
@ThanhVienNCKHObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN
	--insert vào table Thành Viên 
	INSERT INTO [dbo].[NCKH_ThanhVien]
	(
		[DeTaiNCKHID],
		[STT],
		[Is_ChuNhiem],
		[Is_NhanVien],
		[Is_SinhVien],
		[MaThanhVien],
		[Ho],
		[Ten],
		[Email],
		[PhongBanID],
		[LopID],
		[SoTaiKhoan],
		[NganHang],
		[TenChuTaiKhoan],
		[NhanVienCapNhat]
	)
	SELECT
		@DeTaiNCKHID,
		json.STT,
		json.Is_ChuNhiem,
		json.Is_NhanVien,
		json.Is_SinhVien,
		json.MaThanhVien,
		json.Ho,
		json.Ten,
		json.Email,
		json.PhongBanID,
		json.LopID,
		json.SoTaiKhoan,
		json.NganHang,
		json.TenChuTaiKhoan,
		@SYS_UserID
	FROM OPENJSON(@ThanhVienNCKHObj)
	WITH (
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
		TenChuTaiKhoan NVARCHAR(150)
	) AS json;
END