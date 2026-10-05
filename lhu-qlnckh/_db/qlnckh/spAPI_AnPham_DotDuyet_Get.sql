CREATE PROC [dbo].[spAPI_AnPham_DotDuyet_Get]
AS
BEGIN
	SELECT [AnPham_DotDuyetID]
	, [TenDotDuyet]
	, [TinhTrang]
	, [NienKhoa]
	, [ThoiGianBatDau]
	, [ThoiGianKetThuc]
	, [GhiChu]
	FROM [dbo].[AnPham_DotDuyet]
	WHERE IS_XOA = 0
	ORDER BY AnPham_DotDuyetID DESC
END
