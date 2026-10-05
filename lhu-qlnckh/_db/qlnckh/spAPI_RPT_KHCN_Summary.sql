CREATE PROC [dbo].[spAPI_RPT_KHCN_Summary]
AS
BEGIN
	--SELECT A.NamHoc AS NamThucHien, COUNT(*) AS SL_DT
	--FROM KHCN_DeTai A
	--WHERE A.Is_Xoa = 0
	--GROUP BY A.NamHoc
	--ORDER BY A.NamHoc

	SELECT '2018-2019' AS NamThucHien, 18 AS SL_DT
	UNION ALL
	SELECT '2019-2020' AS NamThucHien, 37 AS SL_DT
	UNION ALL
	SELECT '2020-2021' AS NamThucHien, 19 AS SL_DT
	UNION ALL
	SELECT '2021-2022' AS NamThucHien, 23 AS SL_DT
	UNION ALL
	SELECT '2022-2023' AS NamThucHien, 15 AS SL_DT
	UNION ALL
	SELECT '2023-2024' AS NamThucHien, 10 AS SL_DT

	SELECT 
	 ROW_NUMBER() OVER (ORDER BY [DeTaiKHCNID]) AS SoThuTu
	,[DeTaiKHCNID]
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
	, [NamHoc]
	--, [SoTien]
	, [GhiChu]

	FROM KHCN_DeTai DT INNER JOIN KHCN_NhomDM N ON DT.NhomKHCNID = N.NhomKHCNID
	WHERE DT.Is_Xoa = 0 AND N.Is_Xoa = 0
END