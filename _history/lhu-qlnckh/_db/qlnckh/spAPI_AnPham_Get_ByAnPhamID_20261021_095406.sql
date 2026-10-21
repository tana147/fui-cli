CREATE PROC [dbo].[spAPI_AnPham_Get_ByAnPhamID]
@AnPhamID INT
AS
BEGIN
	SELECT 	A.AnPhamID
			, A.DanhMucLoaiTapChiID
			, A.TenLoaiDanhMucTapChi
			, C.LoaiAnPhamID
			, C.TenLoaiAnPham 
			, A.LoaiSubAnPhamID
			, A.TenLoaiSubAnPham
			, A.[TenTapChi]
			, A.[TenAnPham]
			, A.[MaNhanVienDaiDien]
			, A.[TenNhanVienDaiDien]
			, A.[DonViDaiDien]
			, A.[SoTacGia_LHU]
			, A.[TongSoTacGia]
			, A.[DuongDanBaiBao]
			, A.[NamDangBai]
			, A.[NoiDangBai]
			, A.[DiemHoiDong]
			, A.[HeSo_IF]
			, A.[TenHeSoChatLuong]
			, A.[DiemHeSoChatLuong]
			, A.[HeSoChatLuongID]
			, A.[PhiThongBao]
			, A.[PhiDangBai]
			, A.[HoanPhiDangBai]
			, A.[ISSN]
			, A.TapSoTrang, A.ThangDang, A.TheLoaiBienSoanID
			, A.[Dieu]
			, A.[Khoan]
			, A.[Muc]
			, A.[TongSoTienThuong]
			, A.[GhiChu]
			, A.[SoQuyetDinhKhenThuong]
			, A.[FileIDAnPham]
			, D.FileName AS FileNameAnPham
			, '/FileData/' + A.[FileIDAnPham] AS FileUrlAnPham
			, A.[FileIDKhenThuong]
			, A.[CongThucKhenThuongID]
			, B.FileName AS FileNameKhenThuong
			, '/FileData/' + A.[FileIDKhenThuong] AS FileUrlKhenThuong
			, A.FileIDMinhChungHoTroCaoHoc
			, E.FileName AS FileNameMinhChungHoTroCaoHoc
			, '/FileData/' + A.FileIDMinhChungHoTroCaoHoc AS FileUrlMinhChungHoTroCaoHoc
			, A.FileIDMinhChungWos
			, G.FileName AS FileNameMinhChungWos
			, '/FileData/' + A.FileIDMinhChungWos AS FileUrlMinhChungWos
			, A.FileIDMinhChungScopus
			, H.FileName AS FileNameMinhChungScopus
			, '/FileData/' + A.FileIDMinhChungScopus AS FileUrlMinhChungScopus
			, A.FileIDMinhChungHDCDGSNN
			, I.FileName AS FileNameMinhChungHDCDGSNN
			, '/FileData/' + A.FileIDMinhChungHDCDGSNN AS FileUrlMinhChungHDCDGSNN
            , A.FileIDMinhChungLacHong
            , J.FileName AS FileNameMinhChungLacHong
			, '/FileData/' + A.FileIDMinhChungLacHong AS FileUrlMinhChungLacHong
            , A.FileIDMinhChungKhac
            ,  K.FileName AS FileNameMinhChungKhac
			, '/FileData/' + A.FileIDMinhChungKhac AS FileUrlMinhChungKhac
			 --1: Lưu tạm; 2: Chờ Duyệt ; 3: Đã Duyệt; 4: Đã Ra quyết định khen thưởng
			, CASE WHEN A.TrangThai = 1 THEN N'Lưu tạm'
				   WHEN A.TrangThai = 2 THEN N'Chờ duyệt'
				   WHEN A.TrangThai = 3 THEN N'Đã duyệt'
				   WHEN A.TrangThai = 4 THEN N'Đã ra quyết định khen thưởng'
				   WHEN A.TrangThai = 5 THEN N'Bị từ chối'
				END TrangThai
			, A.TrangThai AS TrangThaiID
			, A.LyDoReject
			, A.HinhThucThanhToan
			, A.NguonCapKinhPhi
			, A.NhomAnPham
			, A.DotDuyet
			, A.ThoiGianDuyet
			, CASE WHEN F.AnPhamID IS NULL THEN 0 ELSE 1 END DaGuiDashboard
		FROM AnPham A 
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			LEFT JOIN FileData B ON A.FileIDKhenThuong = B.FileID
			LEFT JOIN FileData D ON A.FileIDAnPham = D.FileID
			LEFT JOIN FileData E ON A.FileIDMinhChungHoTroCaoHoc = E.FileID
			LEFT JOIN FileData G ON A.FileIDMinhChungWos = G.FileID
			LEFT JOIN FileData H ON A.FileIDMinhChungScopus = H.FileID
			LEFT JOIN FileData I ON A.FileIDMinhChungHDCDGSNN = I.FileID
			LEFT JOIN FileData J ON A.FileIDMinhChungLacHong = J.FileID
			LEFT JOIN FileData K ON A.FileIDMinhChungKhac = K.FileID
			LEFT JOIN [dbo].[BaiBaoKhoaHoc] F ON F.AnPhamID = A.AnPhamID
		WHERE A.AnPhamID = @AnPhamID AND A.Is_Xoa = 0

	SELECT 
		ROW_NUMBER() OVER (ORDER BY B.[AnPhamTacGiaID]) AS 'STT'
		, B.[AnPhamTacGiaID]
		, B.[AnPhamID]
		, B.[MaNhanVien]
		, B.[HoTacGia]
		, B.[TenTacGia]
		, B.[EmailTacGia]
		, B.[AP_Index]
		, B.[TenPhongBan]
		, B.[SoTaiKhoan]
		, B.[NganHang]
		, B.[TenChuTaiKhoan]
		, B.[SoTienKhenThuong]
		, B.[SoTienHoanPhiDangBai]
		, B.[CongThucKhenThuongID]
		, B.[NoiDungCongThucKhenThuong]
		, B.[TrangThai]
		, B.[NhanVienCapNhat]
		, B.[ThoiGianCapNhat]
		, B.[Is_NhanVien]
		--, CASE WHEN B.TacGiaGroupID = 1 THEN N'Nhân viên' WHEN B.TacGiaGroupID = 2 THEN N'Sinh viên' ELSE N'Khác' END AS TacGiaGroupID
		, B.TacGiaGroupID
		, B.[Is_Xoa]
		, B.Is_TacGiaChinh
		, B.[Is_TacGiaPhu]
		, B.VaiTroID, B.Is_TacGiaLienHe
		, B.NguoiDaiDienQuyetToan
		, B.NguonCapKinhPhi
		, B.HeSoHoTroCaoHoc
	FROM AnPham_TacGia B WHERE B.AnPhamID = @AnPhamID and b.Is_Xoa =0
		

	SELECT 
		  C.[AnPhamFileID]
		, C.[AnPhamID]
		, C.[LoaiFile]
		, C.[FileIDList]
		,  JSON_QUERY('[' + 
        STUFF(
            (
                SELECT
                    ', {"FileIDMinhChung":"' + FileID + '","FileNameMinhChung":"' + FileName + '","FileUrlMinhChung":"/FileData/'+ FileID +'"}'
                FROM FileData AS F
                WHERE CHARINDEX(FileID, C.FileIDList) > 0
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 2, ''
        ) + ']') AS FileList
		, C.[MoTa]
		, C.[TrangThai]
		, C.[NhanVienCapNhat]
		, C.[ThoiGianCapNhat]
		, C.[Is_Xoa]
	FROM AnPham_File C WHERE C.AnPhamID = @AnPhamID and C.Is_Xoa =0
END