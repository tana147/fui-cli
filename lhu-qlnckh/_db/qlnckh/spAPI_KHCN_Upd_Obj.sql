
CREATE PROC [dbo].[spAPI_KHCN_Upd_Obj]
@DeTaiKHCNID INT,
@DeTaiKHCNObj NVARCHAR(MAX),
@ThanhVienKHCNObj NVARCHAR(MAX),  
@SanPhamKHCNObj NVARCHAR(MAX), 
@TienDoKHCNObj NVARCHAR(MAX),
@SYS_UserID VARCHAR(9)
AS
BEGIN

	-- insert vào table KHCN_DeTai
	UPDATE [dbo].[KHCN_DeTai]
	SET
		[NhomKHCNID] = json.NhomKHCNID,
		[MaSoDeTai] = json.MaSoDeTai,
		[TenDeTaiKHCN_Vi] = json.TenDeTaiKHCN_Vi,
		[TenDeTaiKHCN_En] = json.TenDeTaiKHCN_En,
		[DonVi] = json.DonVi,
		[NamDangKy] = json.NamDangKy,
		[SoThangThucHien] = json.SoThangThucHien,
		[ThangBatDau] = json.ThangBatDau,
		[ThangKetThuc] = json.ThangKetThuc,
		[NamThucHien] = json.NamThucHien,
		[SoTien] = json.SoTien,
		[GhiChu] = json.GhiChu,
		[NhanVienCapNhat] = @SYS_UserID
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
	) AS json
	WHERE [dbo].[KHCN_DeTai].DeTaiKHCNID = @DeTaiKHCNID
		
	
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

	----update vào table Sản Phẩm
	UPDATE [dbo].[KHCN_SanPham]
	SET
		[TenSanPhamDuKien] = json.TenSanPhamDuKien,
		[SoLuong] = json.SoLuong,
		[NhanVienCapNhat] = @SYS_UserID
	FROM OPENJSON(@SanPhamKHCNObj)
	WITH (
		SanPhamKHCNID INT,
		TenSanPhamDuKien nvarchar(200),
		SoLuong INT
	) AS json
	WHERE [KHCN_SanPham].[SanPhamKHCNID] = json.SanPhamKHCNID

	----update vào table TienDoCapKinhPhi
	UPDATE [dbo].[KHCN_TienDoCapKinhPhi]
	SET
		[SoTT] = json.SoTT,
		[SoTien] = json.SoTien,
		[GhiChu] = json.GhiChu,
		[NgayTienDo] = json.NgayTienDo,
		[NhanVienCapNhat] = @SYS_UserID,
		[ThoiGianCapNhat] = GETDATE()

	FROM OPENJSON(@TienDoKHCNObj)
	WITH (
		TienDoID INT,
		SoTT TINYINT,
		SoTien NUMERIC(18,2),
		GhiChu NVARCHAR(200),
		NgayTienDo VARCHAR(10)
	) AS json
	WHERE [dbo].[KHCN_TienDoCapKinhPhi].TienDoID = json.TienDoID
END
