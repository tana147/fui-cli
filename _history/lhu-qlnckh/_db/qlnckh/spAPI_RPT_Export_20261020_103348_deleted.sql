--  [dbo].[spAPI_RPT_Export] '3', '2024-06-03', '2024-06-03', 'GV0000611', 9
CREATE PROC [dbo].[spAPI_RPT_Export] 
@TrangThai VARCHAR(10) -- MẢNG TRẠNG THÁI VÍ DỤ 1,2
,@TuNgay datetime
,@DenNgay datetime
,@SYS_UserID VARCHAR(9)
,@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
		IF (@sys_SystemRight NOT IN (1,2,9))
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
	END

	DECLARE @tt as TABLE (TrangThai VARCHAR(2))
	INSERT @tt(TrangThai)
	SELECT data FROM [DBO].[FN_STRING_SPLIT](@TrangThai,',')

	DECLARE @X AS TABLE(AnPhamID INT, TongSoTienThuong NUMERIC(18,2), TongSoTienHoanPhiDangBai NUMERIC(18,2))
	INSERT INTO @X(AnPhamID , TongSoTienThuong , TongSoTienHoanPhiDangBai)
	SELECT A.AnPhamID , SUM(ISNULL(A.SoTienKhenThuong,0)) AS TongSoTienThuong
			, SUM(ISNULL(A.SoTienHoanPhiDangBai,0)) AS SoTienHoanPhiDangBai
	FROM AnPham_TacGia A INNER JOIN AnPham B ON A.AnPhamID = B.AnPhamID 
	WHERE A.Is_Xoa = 0 AND B.Is_Xoa = 0 AND B.TrangThai = 3
	GROUP BY A.AnPhamID


	SELECT DISTINCT	
			ROW_NUMBER() OVER (ORDER BY A.TrangThai ASC,  A.AnPhamID DESC) AS 'STT'
			, A.AnPhamID
			, A.[TenAnPham]
			, STUFF((SELECT ', ' + B.HoTacGia + ' ' + B.TenTacGia
					 FROM [dbo].[AnPham_TacGia] B
					 WHERE B.AnPhamID = A.AnPhamID AND B.Is_Xoa = 0
					 FOR XML PATH('')), 1, 2, '') AS TacGia
			, A.[DonViDaiDien]
			, A.[MaNhanVienDaiDien]
			, A.[TenNhanVienDaiDien]
			, C.TenLoaiAnPham AS N'Danh mục Bài báo/ Ấn phẩm'
			, E.TenLoaiSubAnPham AS N'Thuộc Danh mục tạp chí'
			, A.TenLoaiDanhMucTapChi  AS N'Tên Danh mục tạp chí'
			, A.[TenTapChi] AS N'Tên tạp chí'
			, A.[DuongDanBaiBao]
			, A.[NamDangBai]
			, A.[NoiDangBai]
			, A.[DiemHoiDong]
			, A.[HeSo_IF]
			, ISNULL(A.[DiemHeSoChatLuong],0) AS DiemHeSoChatLuong
			, A.[PhiThongBao]
			, A.[PhiDangBai]
			, A.[HoanPhiDangBai]
			, A.[ISSN]
			, A.[GhiChu]
			 --1: Lưu tạm; 2: Chờ Duyệt ; 3: Đã Duyệt; 4: Đã Ra quyết định khen thưởng
			--, CASE WHEN A.TrangThai = 1 THEN N'Lưu tạm'
			--	   WHEN A.TrangThai = 2 THEN N'Chờ duyệt'
			--	   WHEN A.TrangThai = 3 THEN N'Đã duyệt'
			--	   WHEN A.TrangThai = 4 THEN N'Đã ra quyết định khen thưởng'
			--	   WHEN A.TrangThai = 5 THEN N'Bị từ chối'
			--	   WHEN A.TrangThai = 6 THEN N'Phục hồi'
			--END TrangThai
			--, A.TrangThai AS TrangThaiID
			--, CASE WHEN D.AnPhamID IS NULL THEN 0 ELSE 1 END DaGuiDashboard
			, CASE WHEN A.NhomAnPham = 1 THEN N'Ấn phẩm khoa học' WHEN A.NhomAnPham = 2 THEN N'Hỗ trợ đầu vào cao học' WHEN A.NhomAnPham =3 THEN N'Có hướng dẫn cao học' END AS N'Nhóm ấn phẩm' 
			, CONVERT(VARCHAR(10), A.ThoiGianSubmit, 103) AS ThoiGianGui
			, B1.TongSoTienThuong  AS TongSoTienThuong-- SUM(ISNULL(B.SoTienKhenThuong,0)) AS TongSoTienThuong
			, B1.TongSoTienHoanPhiDangBai AS SoTienHoanPhiDangBai --SUM(ISNULL(B.SoTienHoanPhiDangBai,0)) AS SoTienHoanPhiDangBai
		FROM AnPham A 
			INNER JOIN [dbo].[AnPham_TacGia] B ON B.AnPhamID = A.AnPhamID 
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			INNER JOIN @X B1 ON B1.AnPhamID = A.AnPhamID
			LEFT JOIN [dbo].[BaiBaoKhoaHoc] D ON D.AnPhamID = A.AnPhamID
			LEFT JOIN AnPham_Loai_Sub E ON E.LoaiSubAnPhamID = A.LoaiSubAnPhamID
			WHERE  B.Is_Xoa = 0 AND A.Is_Xoa = 0 AND (A.TrangThai IN (SELECT CONVERT(TINYINT, TrangThai) FROM @tt)  OR @TrangThai = '0')
		GROUP BY 
			 A.AnPhamID
			, A.TenLoaiDanhMucTapChi
			, C.LoaiAnPhamID
			, C.TenLoaiAnPham
			, A.LoaiSubAnPhamID
			, E.TenLoaiSubAnPham
			, A.[TenTapChi]
			, A.[TenAnPham]
			, A.[MaNhanVienDaiDien]
			, A.[TenNhanVienDaiDien]
			, A.[DonViDaiDien]
			, A.[DuongDanBaiBao]
			, A.[NamDangBai]
			, A.[NoiDangBai]
			, A.[DiemHoiDong]
			, A.[HeSo_IF]
			, A.[DiemHeSoChatLuong]
			, A.[PhiThongBao]
			, A.[PhiDangBai]
			, A.[HoanPhiDangBai]
			, A.[ISSN]
			, A.[GhiChu]
			, A.[TrangThai]
			, D.[AnPhamID]
			, A.NhomAnPham
			, A.ThoiGianSubmit
			, B1.TongSoTienThuong
			, B1.TongSoTienHoanPhiDangBai
		ORDER BY  DonViDaiDien


		---lấy chi tiết thông tin cá nhân có tiền
		SELECT DISTINCT	
			ROW_NUMBER() OVER (ORDER BY  B.MaNhanVien , A.AnPhamID) AS 'STT'
			, A.AnPhamID
			
			, B.MaNhanVien
			, B.HoTacGia + ' ' + B.TenTacGia AS HoTen
			, B.SoTaiKhoan
			, B.NganHang
			, B.NguonCapKinhPhi
			, B.AP_Index
			, A.[TenAnPham]
			, B.SoTienKhenThuong
			, B.SoTienHoanPhiDangBai
			, C.TenLoaiAnPham AS N'Danh mục Bài báo/ Ấn phẩm'
			, E.TenLoaiSubAnPham AS N'Thuộc Danh mục tạp chí'
			, A.TenLoaiDanhMucTapChi  AS N'Tên Danh mục tạp chí'
			, A.[TenTapChi] AS N'Tên tạp chí'
			, A.[DuongDanBaiBao]
			, A.[NamDangBai]
			, A.[NoiDangBai]
			, A.[DiemHoiDong]
			, A.[HeSo_IF]
			, ISNULL(A.[DiemHeSoChatLuong],0) AS DiemHeSoChatLuong
			, A.[ISSN]
			, A.[GhiChu]
			, CASE WHEN A.NhomAnPham = 1 THEN N'Ấn phẩm khoa học' WHEN A.NhomAnPham = 2 THEN N'Hỗ trợ đầu vào cao học' WHEN A.NhomAnPham =3 THEN N'Có hướng dẫn cao học' END AS N'Nhóm ấn phẩm' 
			, CONVERT(VARCHAR(10), A.ThoiGianSubmit, 103) AS ThoiGianGui
		FROM AnPham A 
			INNER JOIN [dbo].[AnPham_TacGia] B ON B.AnPhamID = A.AnPhamID AND ISNULL(B.SoTienKhenThuong, 0) > 0
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			LEFT JOIN [dbo].[BaiBaoKhoaHoc] D ON D.AnPhamID = A.AnPhamID
			LEFT JOIN AnPham_Loai_Sub E ON E.LoaiSubAnPhamID = A.LoaiSubAnPhamID
			WHERE  B.Is_Xoa = 0 AND A.Is_Xoa = 0 AND (A.TrangThai IN (SELECT CONVERT(TINYINT, TrangThai) FROM @tt)  OR @TrangThai = '0')
		GROUP BY 
			 A.AnPhamID
			, B.[AnPhamTacGiaID]
			, B.MaNhanVien
			, B.HoTacGia + ' ' + B.TenTacGia
			, B.AP_Index
			, B.SoTaiKhoan
			, B.NganHang
			, B.NguonCapKinhPhi
			, B.SoTienKhenThuong
			, B.SoTienHoanPhiDangBai
			, A.TenLoaiDanhMucTapChi
			, C.LoaiAnPhamID
			, C.TenLoaiAnPham
			, A.LoaiSubAnPhamID
			, E.TenLoaiSubAnPham
			, A.[TenTapChi]
			, A.[TenAnPham]
			, A.[DuongDanBaiBao]
			, A.[NamDangBai]
			, A.[NoiDangBai]
			, A.[DiemHoiDong]
			, A.[HeSo_IF]
			, A.[DiemHeSoChatLuong]
			, A.[ISSN]
			, A.[GhiChu]
			, A.[TrangThai]
			, D.[AnPhamID]
			, A.NhomAnPham
			, A.ThoiGianSubmit
		ORDER BY  B.NguonCapKinhPhi, B.MaNhanVien , A.AnPhamID



		---TIỀN SUM THEO ĐƠN VỊ ĐẠI DIỆN
		SELECT DISTINCT	
			 A.[DonViDaiDien]
			,SUM( B1.TongSoTienThuong)  AS TongSoTienThuong-- SUM(ISNULL(B.SoTienKhenThuong,0)) AS TongSoTienThuong
			, SUM(B1.TongSoTienHoanPhiDangBai) AS SoTienHoanPhiDangBai --SUM(ISNULL(B.SoTienHoanPhiDangBai,0)) AS SoTienHoanPhiDangBai
		FROM AnPham A 
			--INNER JOIN [dbo].[AnPham_TacGia] B ON B.AnPhamID = A.AnPhamID 
			INNER JOIN @X B1 ON B1.AnPhamID = A.AnPhamID
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			LEFT JOIN [dbo].[BaiBaoKhoaHoc] D ON D.AnPhamID = A.AnPhamID
			LEFT JOIN AnPham_Loai_Sub E ON E.LoaiSubAnPhamID = A.LoaiSubAnPhamID
			WHERE A.Is_Xoa = 0 AND (A.TrangThai IN (SELECT CONVERT(TINYINT, TrangThai) FROM @tt)  OR @TrangThai = '0')
		GROUP BY 
			 A.[DonViDaiDien]--, B1.TongSoTienThuong , B1.TongSoTienHoanPhiDangBai
		ORDER BY  DonViDaiDien

		------TIỀN SUM THEO NGUỒN CẤP KINH PHÍ
		SELECT DISTINCT	
			
			 B.NguonCapKinhPhi
			, SUM(ISNULL(B.SoTienKhenThuong,0)) AS TongSoTienThuong
			, SUM(ISNULL(B.SoTienHoanPhiDangBai,0)) AS SoTienHoanPhiDangBai
		FROM AnPham A 
			INNER JOIN [dbo].[AnPham_TacGia] B ON B.AnPhamID = A.AnPhamID  AND ISNULL(B.SoTienKhenThuong, 0) > 0
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			LEFT JOIN [dbo].[BaiBaoKhoaHoc] D ON D.AnPhamID = A.AnPhamID
			LEFT JOIN AnPham_Loai_Sub E ON E.LoaiSubAnPhamID = A.LoaiSubAnPhamID
			WHERE  B.Is_Xoa = 0 AND A.Is_Xoa = 0 AND (A.TrangThai IN (SELECT CONVERT(TINYINT, TrangThai) FROM @tt)  OR @TrangThai = '0')
		GROUP BY 
			 B.NguonCapKinhPhi
		ORDER BY  B.NguonCapKinhPhi


		-- ĐỐI CHIẾU
		DECLARE @Y AS TABLE(AnPhamID INT, NguonCapKinhPhi VARCHAR(500))
		INSERT INTO @Y(AnPhamID ,  NguonCapKinhPhi)
		SELECT A.AnPhamID ,
			 STUFF((SELECT DISTINCT ', ' + ISNULL(B.NguonCapKinhPhi,'...')
					 FROM [dbo].[AnPham_TacGia] B
					 WHERE B.AnPhamID = A.AnPhamID AND B.Is_Xoa = 0 AND ISNULL(B.SoTienKhenThuong,0)>0
					 FOR XML PATH('')), 1, 2, '') AS NguonCapKinhPhi
		FROM  AnPham A INNER JOIN AnPham_TacGia B  ON A.AnPhamID = B.AnPhamID 
		WHERE A.Is_Xoa = 0 AND B.Is_Xoa = 0 AND A.TrangThai = 3
		GROUP BY A.AnPhamID

		SELECT A.AnPhamID, A.TenAnPham, A.MaNhanVienDaiDien, A.TenNhanVienDaiDien, A.DonViDaiDien, B.NguonCapKinhPhi
		FROM AnPham A INNER JOIN @Y B ON A.AnPhamID = B.AnPhamID
		WHERE A.Is_Xoa = 0 AND A.TrangThai = 3 AND A.DonViDaiDien <> B.NguonCapKinhPhi

END

