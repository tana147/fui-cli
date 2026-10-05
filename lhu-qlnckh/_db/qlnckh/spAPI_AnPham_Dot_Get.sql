CREATE PROC [dbo].[spAPI_AnPham_Dot_Get]
AS
BEGIN
	SELECT [AnPham_DotID]
	, [AnPham_DotTen] AS TenDot
	, AnPham_DotTinhTrang AS TinhTrang
	, [NienKhoa]
	, [ThoiGianBatDau]
	, [ThoiGianKetThuc]
	, [ThongBao]
	, [FileHuongDan]
	FROM [dbo].[AnPham_Dot]
	WHERE IS_XOA = 0
END
