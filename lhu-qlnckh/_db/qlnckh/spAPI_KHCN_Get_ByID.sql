CREATE PROC [dbo].[spAPI_KHCN_Get_ByID]
@DeTaiKHCNID INT
AS
BEGIN
		SELECT [DeTaiKHCNID]
	, DT.[NhomKHCNID]
	, N.MaNhomKHCN
	, N.TenNhomKHCN
	, [MaSoDeTai]
	, [TenDeTaiKHCN_Vi]
	, [TenDeTaiKHCN_En]
	, [DonVi]
	, [NamDangKy]
	, [SoThangThucHien]
	, [ThangBatDau]
	, [ThangKetThuc]
	, [NamThucHien]
	, [SoTien]
	, [GhiChu]

	FROM KHCN_DeTai DT INNER JOIN KHCN_NhomDM N ON DT.NhomKHCNID = N.NhomKHCNID
	WHERE DT.Is_Xoa = 0 AND N.Is_Xoa = 0 AND DeTaiKHCNID = @DeTaiKHCNID 

	SELECT  [ThanhVienKHCNID]
	, [DeTaiKHCNID]
	, [STT]
	, [Is_ChuNhiem]
	, [Is_NhanVien]
	, [Is_SinhVien]
	, [MaNhanVien]
	, [Ho]
	, [Ten]
	, [Email]
	, [TenPhongBan]
	, [SoTaiKhoan]
	, [NganHang]
	, [TenChuTaiKhoan]
	FROM [dbo].[KHCN_ThanhVien] 
	WHERE DeTaiKHCNID = @DeTaiKHCNID AND Is_Xoa = 0


	SELECT [TienDoID], [DeTaiKHCNID], [SoTT], [SoTien], [GhiChu]
	FROM [dbo].[KHCN_TienDoCapKinhPhi] WHERE DeTaiKHCNID = @DeTaiKHCNID AND Is_Xoa = 0

	SELECT [SanPhamKHCNID]
	, [DeTaiKHCNID]
	, [TenSanPhamDuKien]
	, [SoLuong]
	FROM [dbo].[KHCN_SanPham]  WHERE DeTaiKHCNID = @DeTaiKHCNID AND Is_Xoa = 0

END