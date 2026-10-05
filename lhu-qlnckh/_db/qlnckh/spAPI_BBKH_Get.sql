CREATE PROC [dbo].[spAPI_BBKH_Get]
AS
BEGIN
	SELECT  [BaiBaoID]
	, BB.[SoThuTu]
	, BB.[TenTacGia]
	, BB.[TenDonVi]
	, BB.[TenBaiBao]
	, BB.[TenTapChiHoiThao]
	, BB.[NamDang]
	, BB.[NoiDang]
	, BB.[IFDiemHDGSNN]
	, BB.[TheLoai]
	, BB.[GhiChu]
	, BB.[FileID_List]
	, BB.[AnPhamID]
	, BB.[DanhMucLoaiTapChiID]
	, BB.[TenLoaiDanhMucTapChi]
	, E.TenNhomHienThiExcel 
	--, [LoaiAnPhamID]
	FROM BaiBaoKhoaHoc BB 
		LEFT JOIN AnPham A ON BB.AnPhamID = A.AnPhamID
		LEFT JOIN [dbo].[AnPham_Loai_Sub] E ON E.LoaiSubAnPhamID       = A.LoaiSubAnPhamID
	WHERE BB.Is_Xoa = 0
	order by NamDang desc
END