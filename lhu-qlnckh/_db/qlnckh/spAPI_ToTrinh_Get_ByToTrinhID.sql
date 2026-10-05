-- [dbo].[spAPI_ToTrinh_Get_ByToTrinhID] 21
CREATE  PROC [dbo].[spAPI_ToTrinh_Get_ByToTrinhID] 
@ToTrinhID INT
AS
BEGIN
	
	--DECLARE @TrangThai INT = 2 -- A.TrangThai = 2 THEN N'Đã duyệt'
	-- Tạo bảng tạm
	DECLARE @TempTable AS TABLE
		(
			STT INT,
			AnPhamID INT,
			DanhMucLoaiTapChiID INT,
			TenLoaiDanhMucTapChi NVARCHAR(MAX),
			LoaiAnPhamID INT,
			TenLoaiAnPham NVARCHAR(MAX),
			TenTapChi NVARCHAR(MAX),
			TenAnPham NVARCHAR(MAX),
			MaNhanVienDaiDien NVARCHAR(MAX),
			TenNhanVienDaiDien NVARCHAR(MAX),
			DonViDaiDien NVARCHAR(MAX),
			SoTacGia_LHU INT,
			DuongDanBaiBao NVARCHAR(MAX),
			NamDangBai NVARCHAR(MAX),
			NoiDangBai NVARCHAR(MAX),
			DiemHoiDong FLOAT,
			HeSo_IF FLOAT,
			TenHeSoChatLuong NVARCHAR(MAX),
			DiemHeSoChatLuong FLOAT,
			PhiThongBao NUMERIC(18,2),
			PhiDangBai NUMERIC(18,2),
			HoanPhiDangBai NUMERIC(18,2),
			ISSN NVARCHAR(MAX),
			Dieu NVARCHAR(MAX),
			Khoan NVARCHAR(MAX),
			Muc NVARCHAR(MAX),
			TongSoTienThuong NUMERIC(18,2),
			SoTienKhenThuong NUMERIC(18,2),
			GhiChu NVARCHAR(MAX),
			TacGia NVARCHAR(MAX),
			TrangThai NVARCHAR(30),
			TrangThaiID INT
		)
	INSERT INTO @TempTable(STT,
				AnPhamID,
				DanhMucLoaiTapChiID,
				TenLoaiDanhMucTapChi,
				LoaiAnPhamID,
				TenLoaiAnPham,
				TenTapChi,
				TenAnPham,
				MaNhanVienDaiDien,
				TenNhanVienDaiDien,
				DonViDaiDien,
				SoTacGia_LHU,
				DuongDanBaiBao,
				NamDangBai,
				NoiDangBai,
				DiemHoiDong,
				HeSo_IF,
				TenHeSoChatLuong,
				DiemHeSoChatLuong,
				PhiThongBao,
				PhiDangBai,
				HoanPhiDangBai,
				ISSN,
				Dieu,
				Khoan,
				Muc,
				TongSoTienThuong,
				SoTienKhenThuong,
				GhiChu,
				TacGia,
				TrangThai,
				TrangThaiID)
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
			, B.[SoTienKhenThuong]
			, A.[GhiChu]
			, STUFF((SELECT ', ' + B.HoTacGia + ' ' + B.TenTacGia
					 FROM [dbo].[AnPham_TacGia] B
					 WHERE B.AnPhamID = A.AnPhamID AND B.Is_Xoa = 0
					 FOR XML PATH('')), 1, 2, '') AS TacGia
			, CASE WHEN A.TrangThai = 0 THEN N'Lưu tạm'
				   WHEN A.TrangThai = 1 THEN N'Chờ duyệt'
					WHEN A.TrangThai = 2 THEN N'Đã duyệt'
					WHEN A.TrangThai = 3 THEN N'Đã ra quyết định khen thưởng'
		END TrangThai,
		A.TrangThai AS TrangThaiID
		FROM AnPham A 
			INNER JOIN [dbo].[AnPham_TacGia] B ON B.AnPhamID = A.AnPhamID
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			INNER JOIN [dbo].[LoaiDanhMucTapChi] D ON D.DanhMucLoaiTapChiID = A.DanhMucLoaiTapChiID
			WHERE  B.Is_Xoa = 0 AND A.Is_Xoa = 0  AND A.ToTrinhID = @ToTrinhID
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
			, B.[SoTienKhenThuong]

		DECLARE @SLAnPham_BangSo INT = 0
		
		DECLARE @TongTienKhenThuong NUMERIC(18,2)
		SET @SLAnPham_BangSo = (SELECT COUNT(*) FROM @TempTable)
		SET @TongTienKhenThuong = (SELECT SUM(ISNULL([SoTienKhenThuong],0)) FROM @TempTable)

		-- Object 1: Lấy ra thông thông tin tờ trình
		SELECT [ToTrinhID]
		, [Ngay]
		, [Thang]
		, [Nam]
		, [SoQD]
		, [TieuDeQuyetDinh]
		, [NamHocKhenThuong]
		, [DotKhenThuong]
		, [ToTrinhFileID]
		, [ToTrinhFileUrl]
		, [ToTrinhFileName]
		, [ToTrinhLoai]
		, @SLAnPham_BangSo AS SLAnPham_BangSo
		, [dbo].[Num2Text](@SLAnPham_BangSo) AS SLAnPham_BangChu
		, @TongTienKhenThuong AS TongTienKhenThuong
		, [dbo].[FN_TIENTHANHCHU](@TongTienKhenThuong) AS TongTienKhenThuong_BangChu
		FROM ToTrinh WHERE ToTrinhID = @ToTrinhID

		
		-- Object 2: Lấy ra chi thông tin chi tiết tác giả ấn phẩm
		SELECT * FROM @TempTable

		-- Object 3: Chỉ lấy ra danh sách ẩn phẩm
		SELECT DISTINCT 
		--ROW_NUMBER() OVER (ORDER BY A.AnPhamID) AS 'STT'
		DENSE_RANK() OVER (ORDER BY A.AnPhamID) AS 'STT'
			, A.AnPhamID
			, A.DanhMucLoaiTapChiID
			, A.TenLoaiDanhMucTapChi
			, A.LoaiAnPhamID
			, A.TenLoaiAnPham
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
			, A.[TacGia]
			, A.[TrangThaiID]
			FROM @TempTable A

END

