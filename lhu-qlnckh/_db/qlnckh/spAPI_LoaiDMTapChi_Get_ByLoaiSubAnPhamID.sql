CREATE PROC [dbo].[spAPI_LoaiDMTapChi_Get_ByLoaiSubAnPhamID]
@LoaiSubAnPhamID INT
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
		, [TenVietTatLoaiDanhMucTapChi]  AS [TenLoaiDanhMucTapChi] 
		, [MoTa]
		, Sort
	FROM 
		[dbo].[LoaiDanhMucTapChi]
		WHERE Is_Xoa = 'FALSE' AND LoaiSubAnPhamID = @LoaiSubAnPhamID
		ORDER BY Sort ASC

END