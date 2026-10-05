CREATE PROC [dbo].[spAPI_RPT_AnPham_NamDang] --  2025 ,'gv0000611',9
@NamDang VARCHAR(50)
,@SYS_UserID VARCHAR(9)
,@sys_SystemRight INT
AS
BEGIN
	DECLARE @NamDangTable AS TABLE(NamDang INT) 
	INSERT INTO @NamDangTable(NamDang)
	SELECT CAST(value AS INT) FROM string_split(@NamDang,',')

	DECLARE @tbl AS TABLE(AnPhamID INT, SoTienKhenThuong NUMERIC(18,0), SoTienHoanPhiDangBai NUMERIC(18,0))
	INSERT INTO @tbl(AnPhamID, SoTienKhenThuong, SoTienHoanPhiDangBai)
	SELECT A.AnPhamID 
		,SUM(ISNULL(A.SoTienKhenThuong,0)) AS SoTienKhenThuong
		, SUM(ISNULL(A.SoTienHoanPhiDangBai,0)) AS SoTienHoanPhiDangBai 
	FROM AnPham_TacGia A INNER JOIN AnPham B ON A.AnPhamID = B.AnPhamID
	WHERE  B.Is_Xoa = 0 AND A.Is_Xoa = 0 
		AND (B.TrangThai IN (2,3))
		AND B.NamDangBai in (SELECT NamDang FROM @NamDangTable)
	GROUP BY A.AnPhamID

	SELECT DISTINCT	
			ROW_NUMBER() OVER (ORDER BY A.TrangThai ASC,  A.AnPhamID DESC) AS 'STT'
			, A.AnPhamID
			--, A.DanhMucLoaiTapChiID
			, A.TenLoaiDanhMucTapChi
			, C.LoaiAnPhamID
			, COALESCE(A.TenLoaiAnPham_Edit, C.TenLoaiAnPham) AS TenLoaiAnPham
			, A.LoaiSubAnPhamID
			, G.TenLoaiSubAnPham
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
			, COALESCE(A.DiemHeSoChatLuong_Edit, A.[DiemHeSoChatLuong])  AS DiemHeSoChatLuong
			, A.[PhiThongBao]
			--, A.[PhiDangBai]
			--, A.[HoanPhiDangBai]
			, E.SoTienKhenThuong
			, E.SoTienHoanPhiDangBai
			, E.SoTienKhenThuong + E.SoTienHoanPhiDangBai AS TongTienKhenThuong
			, A.[ISSN]
			--, A.[Dieu]
			--, A.[Khoan]
			--, A.[Muc]
			--, A.[TongSoTienThuong]
			--, A.[GhiChu]
			
			, STUFF((SELECT ', ' + B.HoTacGia + ' ' + B.TenTacGia
					 FROM [dbo].[AnPham_TacGia] B
					 WHERE B.AnPhamID = A.AnPhamID AND B.Is_Xoa = 0
					 FOR XML PATH('')), 1, 2, '') AS TacGia
			 --1: Lưu tạm; 2: Chờ Duyệt ; 3: Đã Duyệt; 4: Đã Ra quyết định khen thưởng
			, CASE WHEN A.TrangThai = 1 THEN N'Lưu tạm'
				   WHEN A.TrangThai = 2 THEN N'Chờ duyệt'
				   WHEN A.TrangThai = 3 THEN N'Đã duyệt'
				   WHEN A.TrangThai = 4 THEN N'Đã ra quyết định khen thưởng'
				   WHEN A.TrangThai = 5 THEN N'Bị từ chối'
				   WHEN A.TrangThai = 6 THEN N'Phục hồi'
			END TrangThai
			, A.TrangThai AS TrangThaiID
			, CASE WHEN D.AnPhamID IS NULL THEN 0 ELSE 1 END DaGuiDashboard
			, A.NhomAnPham
			, CONVERT(VARCHAR(10), A.ThoiGianSubmit, 103) AS ThoiGianGui
			,A.GroupAnPham_Edit
			,COALESCE(A.HeSoChatLuongID_Edit, A.HeSoChatLuongID)  AS HeSoChatLuongID 
		FROM AnPham A 
			INNER JOIN [dbo].[AnPham_TacGia] B ON B.AnPhamID = A.AnPhamID
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			INNER JOIN @tbl E ON A.AnPhamID = E.AnPhamID
			INNER JOIN dbo.AnPham_Loai_Sub G ON G.LoaiSubAnPhamID = A.LoaiSubAnPhamID
			INNER JOIN [dbo].[AnPham_Dot] F ON F.[AnPham_DotID] = A.[AnPham_DotID]  --AND F.[AnPham_DotTinhTrang] = 1
			LEFT JOIN [dbo].[BaiBaoKhoaHoc] D ON D.AnPhamID = A.AnPhamID
			WHERE  B.Is_Xoa = 0 
				AND A.Is_Xoa = 0 
				AND (A.TrangThai IN (2,3))
			--	AND A.Is_LocalStore = 0
				AND A.NamDangBai in (SELECT NamDang FROM @NamDangTable)
		GROUP BY 
			 A.AnPhamID
			, A.DanhMucLoaiTapChiID
			, A.TenLoaiDanhMucTapChi
			, C.LoaiAnPhamID
			, COALESCE(A.TenLoaiAnPham_Edit, C.TenLoaiAnPham)
			, A.LoaiSubAnPhamID
			, G.TenLoaiSubAnPham
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
			, COALESCE(A.DiemHeSoChatLuong_Edit, A.[DiemHeSoChatLuong])
			, A.[PhiThongBao]
			, A.[PhiDangBai]
			--, A.[HoanPhiDangBai]
			, A.[ISSN]
			, A.DiemHoiDong
			, A.[Dieu]
			, A.[Khoan]
			, A.[Muc]
		--	, A.[TongSoTienThuong]
			, A.[GhiChu]
			, A.[TrangThai]
			, D.[AnPhamID]
			, A.NhomAnPham
			, A.ThoiGianSubmit
			, E.SoTienKhenThuong
			, E.SoTienHoanPhiDangBai
			, A.DuongDanBaiBao
			,A.GroupAnPham_Edit
			,COALESCE(A.HeSoChatLuongID_Edit, A.HeSoChatLuongID) 
			 
		ORDER BY A.[TrangThai] ASC, A.AnPhamID DESC

END