CREATE PROC [dbo].[spAPI_AnPham_RPT_ByDotDuyet]
@DotDuyetID INT,
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,9))
	BEGIN
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	DECLARE @tbl AS TABLE(AnPhamID INT, SoTienKhenThuong NUMERIC(18,0), SoTienHoanPhiDangBai NUMERIC(18,0))
	INSERT INTO @tbl(AnPhamID, SoTienKhenThuong, SoTienHoanPhiDangBai)
	SELECT A.AnPhamID
		,SUM(ISNULL(A.SoTienKhenThuong,0)) AS SoTienKhenThuong
		, SUM(ISNULL(A.SoTienHoanPhiDangBai,0)) AS SoTienHoanPhiDangBai
	FROM AnPham_TacGia A INNER JOIN AnPham B ON A.AnPhamID = B.AnPhamID
	WHERE  B.Is_Xoa = 0 AND A.Is_Xoa = 0
		AND B.DotDuyet = @DotDuyetID
	GROUP BY A.AnPhamID

	SELECT
			ROW_NUMBER() OVER (ORDER BY A.ThoiGianCapNhat, A.AnPhamID DESC) AS 'STT'
			, A.TenLoaiDanhMucTapChi
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
			, E.SoTienKhenThuong
			, E.SoTienHoanPhiDangBai
			, E.SoTienKhenThuong + E.SoTienHoanPhiDangBai AS TongTienKhenThuong
			, A.[ISSN]
			, A.NhanVienCapNhat
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
			, CONVERT(VARCHAR(10), A.ThoiGianSubmit, 103) AS ThoiGianGui
			, A.ThoiGianCapNhat
			, A.AnPham_DotID
			, A.DotDuyet
		FROM AnPham A
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			INNER JOIN @tbl E ON A.AnPhamID = E.AnPhamID
			WHERE  A.Is_Xoa = 0
				AND A.DotDuyet = @DotDuyetID
		ORDER BY A.ThoiGianCapNhat, A.AnPhamID DESC
END
