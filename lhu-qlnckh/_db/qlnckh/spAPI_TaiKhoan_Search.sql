CREATE   PROC spAPI_TaiKhoan_Search
@Keyword NVARCHAR(100)
AS
BEGIN
	SELECT 
		TK.[MaNV], 
		TK.[HoNV], 
		TK.[TenNV], 
		RTRIM(LTRIM(TK.HoNV + N' ' + TK.TenNV)) AS HoTen,
		TK.[TenThe], 
		TK.[BankIDVietQR], 
		TK.[BankCodeVietQR], 
		TK.[BankNameVietQR], 
		TK.[TaiKhoan],
		TK.[TaiKhoan] AS SoTaiKhoan,
		TK.[BankNameVietQR] AS NganHang,
		TK.[TenThe] AS TenChuTaiKhoan,
		NV.[Email],
		DV.[TenDonVi] AS TenPhongBan
	FROM [dbo].[TaiKhoan] TK 
	LEFT JOIN [dbo].[NhanVien] NV ON TK.MaNV = NV.MaNV
	LEFT JOIN [dbo].[DonVi] DV ON NV.MaDonVi = DV.MaDonVi
	WHERE (@Keyword IS NULL OR @Keyword = ''
			OR TK.MaNV LIKE '%' + @Keyword + '%'
			OR (TK.HoNV + N' ' + TK.TenNV LIKE '%' + @Keyword + '%')
			OR (TK.TenThe LIKE '%' + @Keyword + '%'))
		AND TK.Is_Xoa = 0
END