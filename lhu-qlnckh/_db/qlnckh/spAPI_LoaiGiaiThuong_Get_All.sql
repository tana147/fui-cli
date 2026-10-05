CREATE PROC [dbo].[spAPI_LoaiGiaiThuong_Get_All]   
AS
BEGIN
	SELECT 
		0 LoaiGiaiThuongID,
		'ALL' MaLoaiGiaiThuong,
		N'Tất cả' AS TenLoaiGiaiThuong

	UNION ALL
	SELECT 
		lgt.LoaiGiaiThuongID,
		lgt.MaLoaiGiaiThuong,
		(lgt.MaLoaiGiaiThuong + ' - ' + lgt.TenLoaiGiaiThuong) AS TenLoaiGiaiThuong
	FROM dbo.LoaiGiaiThuong lgt
	WHERE lgt.Is_Xoa = 0
END