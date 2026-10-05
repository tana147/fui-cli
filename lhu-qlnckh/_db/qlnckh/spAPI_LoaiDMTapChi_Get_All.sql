CREATE PROC [dbo].[spAPI_LoaiDMTapChi_Get_All]
AS
BEGIN
	SELECT  0 AS [DanhMucLoaiTapChiID]
		--, [TenVietTatLoaiDanhMucTapChi]
		, N'Khác' AS [TenLoaiDanhMucTapChi] 
		, '' AS [MoTa]
		, 99 AS Sort
	
	UNION ALL

	SELECT  [DanhMucLoaiTapChiID]
		--, [TenVietTatLoaiDanhMucTapChi]
		, [TenVietTatLoaiDanhMucTapChi] + ' - '+ [TenLoaiDanhMucTapChi] AS [TenLoaiDanhMucTapChi] 
		, [MoTa]
		, Sort
	FROM 
		[dbo].[LoaiDanhMucTapChi]
		WHERE Is_Xoa = 'FALSE'
		ORDER BY Sort ASC

END