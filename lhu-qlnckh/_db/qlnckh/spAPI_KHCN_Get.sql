
CREATE PROC [dbo].[spAPI_KHCN_Get]
AS
BEGIN
	SELECT DT.[DeTaiKHCNID]
	, STUFF(
			(SELECT ', ' + TV2.Ho + ' ' + TV2.Ten 
			 FROM [dbo].[KHCN_ThanhVien] TV2 
			 WHERE TV2.DeTaiKHCNID = DT.DeTaiKHCNID
			 ORDER BY TV2.Is_ChuNhiem, TV2.Is_NhanVien
			 FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 
			1, 2, ''
		) AS TacGia
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

	FROM KHCN_DeTai DT 
		INNER JOIN KHCN_NhomDM N ON DT.NhomKHCNID = N.NhomKHCNID
		INNER JOIN [dbo].[KHCN_ThanhVien] TV ON TV.DeTaiKHCNID = DT.DeTaiKHCNID
	WHERE DT.Is_Xoa = 0 AND N.Is_Xoa = 0 AND TV.Is_Xoa = 0
END
