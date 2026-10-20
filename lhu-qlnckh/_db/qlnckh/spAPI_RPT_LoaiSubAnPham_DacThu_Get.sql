CREATE PROCEDURE spAPI_RPT_LoaiSubAnPham_DaThu_Get
AS
BEGIN
	SELECT LoaiSubAnPhamID, LoaiAnPhamID, TenLoaiSubAnPham, TenNhomHienThiExcel FROM dbo.AnPham_Loai_Sub WHERE LoaiAnPhamID IN (15,16) ORDER BY LoaiAnPhamID,Sort	
END