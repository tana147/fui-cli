CREATE PROC spAPI_NhomDM_KHCN_Get
AS
BEGIN
	SELECT [NhomKHCNID], TenNhomKHCN, MaNhomKHCN
		FROM [dbo].[KHCN_NhomDM]
			WHERE is_Xoa = 0 AND TrangThai = 0
END