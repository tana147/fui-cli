CREATE PROC [dbo].[spAPI_ToTrinhAnPham_Get] 
AS
BEGIN
	DECLARE @TrangThai INT = 3 -- Đã duyệt
	SELECT DISTINCT	
			ROW_NUMBER() OVER (ORDER BY A.AnPhamID) AS 'STT'
			, A.AnPhamID
			, A.DanhMucLoaiTapChiID
			, D.TenLoaiDanhMucTapChi
			, C.LoaiAnPhamID
			, C.TenLoaiAnPham
			, A.[TenTapChi]
			, A.[TenAnPham]
			, A.[MaNhanVienDaiDien]
			, A.[TenNhanVienDaiDien]
			, A.[DonViDaiDien]
			, A.[SoTacGia_LHU]
			, A.[DuongDanBaiBao]
			, A.[NamDangBai]
			, A.[NoiDangBai]
			, A.[DiemHoiDong]
			, A.[HeSo_IF]
			, A.[TenHeSoChatLuong]
			, A.[DiemHeSoChatLuong]
			, A.[PhiThongBao]
			, A.[PhiDangBai]
			, A.[HoanPhiDangBai]
			, A.[ISSN]
			, A.[Dieu]
			, A.[Khoan]
			, A.[Muc]
			, A.[TongSoTienThuong]
			, A.[GhiChu]
			, STUFF((SELECT ', ' + B.HoTacGia + ' ' + B.TenTacGia
					 FROM [dbo].[AnPham_TacGia] B
					 WHERE B.AnPhamID = A.AnPhamID AND B.Is_Xoa = 0
					 FOR XML PATH('')), 1, 2, '') AS TacGia
			, CASE WHEN A.TrangThai = 1 THEN N'Lưu tạm'
				   WHEN A.TrangThai = 2 THEN N'Chờ duyệt'
					WHEN A.TrangThai = 3 THEN N'Đã duyệt'
					WHEN A.TrangThai = 4 THEN N'Đã ra quyết định khen thưởng'
		END TrangThai
		FROM AnPham A 
			INNER JOIN [dbo].[AnPham_TacGia] B ON B.AnPhamID = A.AnPhamID
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			INNER JOIN [dbo].[LoaiDanhMucTapChi] D ON D.DanhMucLoaiTapChiID = A.DanhMucLoaiTapChiID
			WHERE  B.Is_Xoa = 0 AND A.Is_Xoa = 0 AND A.TrangThai = 3  AND A.ToTrinhID IS  NULL
		GROUP BY 
			 A.AnPhamID
			, A.DanhMucLoaiTapChiID
			, D.TenLoaiDanhMucTapChi
			, C.LoaiAnPhamID
			, C.TenLoaiAnPham
			, A.[TenTapChi]
			, A.[TenAnPham]
			, A.[MaNhanVienDaiDien]
			, A.[TenNhanVienDaiDien]
			, A.[DonViDaiDien]
			, A.[SoTacGia_LHU]
			, A.[DuongDanBaiBao]
			, A.[NamDangBai]
			, A.[NoiDangBai]
			, A.[DiemHoiDong]
			, A.[HeSo_IF]
			, A.[TenHeSoChatLuong]
			, A.[DiemHeSoChatLuong]
			, A.[PhiThongBao]
			, A.[PhiDangBai]
			, A.[HoanPhiDangBai]
			, A.[ISSN]
			, A.[Dieu]
			, A.[Khoan]
			, A.[Muc]
			, A.[TongSoTienThuong]
			, A.[GhiChu]
			, A.[TrangThai]

END