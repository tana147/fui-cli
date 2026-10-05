CREATE PROC [dbo].[spAPI_KHCN_Ins_Obj]
@DeTaiKHCNObj NVARCHAR(MAX),
@ThanhVienKHCNObj NVARCHAR(MAX),  
@SanPhamKHCNObj NVARCHAR(MAX), 
@TienDoKHCNObj NVARCHAR(MAX),
@SYS_UserID VARCHAR(9)
AS
BEGIN
	DECLARE @DeTaiKHCNID INT

	-- insert vào table KHCN_DeTai
	INSERT INTO [dbo].[KHCN_DeTai]
	(
		[NhomKHCNID],
		[MaSoDeTai],
		[TenDeTaiKHCN_Vi],
		[TenDeTaiKHCN_En],
		[DonVi],
		[NamDangKy],
		[SoThangThucHien],
		[ThangBatDau],
		[ThangKetThuc],
		[NamThucHien],
		[SoTien],
		[GhiChu],
		[NhanVienCapNhat]
	)
	SELECT
		json.NhomKHCNID,
		json.MaSoDeTai,
		json.TenDeTaiKHCN_Vi,
		json.TenDeTaiKHCN_En,
		json.DonVi,
		json.NamDangKy,
		json.SoThangThucHien,
		json.ThangBatDau,
		json.ThangKetThuc,
		json.NamThucHien,
		json.SoTien,
		json.GhiChu,
		@SYS_UserID
	FROM OPENJSON(@DeTaiKHCNObj)
	WITH (
		NhomKHCNID INT,
		MaSoDeTai NVARCHAR(20),
		TenDeTaiKHCN_Vi NVARCHAR(500),
		TenDeTaiKHCN_En NVARCHAR(500),
		DonVi NVARCHAR(500),
		NamDangKy INT,
		SoThangThucHien INT,
		ThangBatDau VARCHAR(10),
		ThangKetThuc VARCHAR(10),
		NamThucHien INT,
		SoTien NUMERIC(18, 2),
		GhiChu NVARCHAR(500)
	) AS json;
		
	IF @@ROWCOUNT > 0
		SELECT @DeTaiKHCNID = @@IDENTITY;
	
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
		[NhanVienCapNhat]
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
		@SYS_UserID
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
	--insert vào table Sản Phẩm
	INSERT INTO [dbo].[KHCN_SanPham]
	(
		[DeTaiKHCNID],
		[TenSanPhamDuKien],
		[SoLuong],
		[NhanVienCapNhat]
	)
	SELECT
		@DeTaiKHCNID,
		json.TenSanPhamDuKien,
		json.SoLuong,
		@SYS_UserID
	FROM OPENJSON(@SanPhamKHCNObj)
	WITH (
		TenSanPhamDuKien nvarchar(200),
		SoLuong INT
	) AS json;

	--insert vào table TienDoCapKinhPhi
	INSERT INTO [dbo].[KHCN_TienDoCapKinhPhi]
	(
		[DeTaiKHCNID],
		[SoTT],
		[SoTien],
		[GhiChu],
		[NgayTienDo],
		[NhanVienCapNhat]
	)
	SELECT
		@DeTaiKHCNID,
		json.SoTT,
		json.SoTien,
		json.GhiChu,
		json.NgayTienDo,
		@SYS_UserID
	FROM OPENJSON(@TienDoKHCNObj)
	WITH (
		SoTT TINYINT,
		SoTien NUMERIC(18,2),
		GhiChu NVARCHAR(200),
		NgayTienDo VARCHAR(10)
	) AS json;
END