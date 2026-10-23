CREATE PROCEDURE [dbo].[spAPI_HDKH_LLKH_NCKH_Select]
	@sys_UserID varchar(9)
AS
-- Lý lịch khoa học: tổng hợp dữ liệu NCKH đang có của chính người đăng nhập. Chỉ đọc.
BEGIN
	SET NOCOUNT ON;

	-- [0] Hướng nghiên cứu chính
	SELECT HuongNghienCuuChinh = (SELECT TOP 1 HuongNghienCuuChinh FROM tblHDKH_Profile_CaNhan
		WHERE NhanVienID = @sys_UserID AND IsDeleted = 0)

	-- [1] Đề tài, dự án: KHCN cấp cơ sở và hội đồng NCKH giảng viên
	SELECT Nguon = N'Đề tài KHCN cấp cơ sở', D.MaSoDeTai, TenDeTai = D.TenDeTaiKHCN_Vi,
		Cap = N'Cơ sở (Trường)', LinhVuc = LTRIM(N.TenNhomKHCN),
		ThoiGian = CONCAT(D.ThangBatDau, IIF(D.ThangKetThuc IS NULL, '', N' – ' + D.ThangKetThuc)),
		Nam = D.NamThucHien, VaiTro = IIF(TV.Is_ChuNhiem = 1, N'Chủ nhiệm', N'Thành viên')
	FROM KHCN_ThanhVien TV
		INNER JOIN KHCN_DeTai D ON D.DeTaiKHCNID = TV.DeTaiKHCNID AND D.Is_Xoa = 0
		LEFT JOIN KHCN_NhomDM N ON N.NhomKHCNID = D.NhomKHCNID
	WHERE TV.MaNhanVien = @sys_UserID AND TV.Is_Xoa = 0
	UNION ALL
	SELECT N'Hội đồng NCKH ' + ISNULL(LHD.TenLoaiHoiDong, ''), NULL, D.TenDeTaiNCKH,
		N'Cơ sở (Trường)', NULL, DT.NamHoc, NULL,
		IIF(TV.Is_ChuNhiem = 1, N'Chủ nhiệm', N'Thành viên')
	FROM NCKH_ThanhVien TV
		INNER JOIN NCKH_DeTai D ON D.DeTaiNCKHID = TV.DeTaiNCKHID AND D.Is_Xoa = 0
		LEFT JOIN NCKH_Dot DT ON DT.DotID = D.DotID
		LEFT JOIN NCKH_LoaiHoiDong LHD ON LHD.LoaiHoiDongID = DT.LoaiHoiDong
	WHERE TV.MaThanhVien = @sys_UserID AND TV.Is_NhanVien = 1 AND TV.Is_Xoa = 0
	ORDER BY Nam DESC

	-- [2] Công trình đã công bố (ấn phẩm), bỏ bản lưu tạm (1) và bị từ chối (5)
	SELECT A.AnPhamID, A.TenAnPham, A.TenTapChi, A.NamDangBai, A.ISSN,
		DuongDanBaiBao = COALESCE(A.DoiLink, A.DuongDanBaiBao),
		A.NoiDangBai,
		A.LoaiAnPhamID, L.TenLoaiAnPham, S.TenLoaiSubAnPham, A.TenLoaiDanhMucTapChi, A.DiemHoiDong,
		A.TongSoTacGia, T.Is_TacGiaChinh,
		TapSoTrang = A.TapSoTrang,
		ThangDang = A.ThangDang,
		TheLoaiBienSoanID = A.TheLoaiBienSoanID,
		TheLoaiSach = BS.TenTheLoai,
		VaiTroID = T.VaiTroID,
		TenVaiTro = VT.TenVaiTro,
		Is_TacGiaLienHe = T.Is_TacGiaLienHe,
		A.Is_DeNghiXetThuong,
		NhomHienThi = CASE
			WHEN A.LoaiAnPhamID IN (15, 16) THEN N'Tạp chí quốc tế (WoS/Scopus)'
			WHEN A.LoaiAnPhamID = 3 THEN N'Tạp chí trong nước'
			WHEN A.LoaiAnPhamID = 2 THEN N'Hội thảo quốc tế'
			WHEN A.LoaiAnPhamID = 1 THEN N'Hội thảo trong nước'
			WHEN A.LoaiAnPhamID = 6 THEN N'Sách, giáo trình, chương sách'
			ELSE N'Khác' END,
		TrangThai = CASE A.TrangThai WHEN 2 THEN N'Chờ duyệt' WHEN 3 THEN N'Đã duyệt'
			WHEN 4 THEN N'Đã ra QĐ khen thưởng' ELSE N'Khác' END,
		TacGia = (SELECT STRING_AGG(LTRIM(RTRIM(CONCAT(X.HoTacGia, ' ', X.TenTacGia))), ', ')
				WITHIN GROUP (ORDER BY X.AnPhamTacGiaID)
			FROM AnPham_TacGia X WHERE X.AnPhamID = A.AnPhamID AND X.Is_Xoa = 0)
	FROM AnPham_TacGia T
		INNER JOIN AnPham A ON A.AnPhamID = T.AnPhamID AND A.Is_Xoa = 0 AND A.TrangThai NOT IN (1, 5)
		LEFT JOIN AnPham_Loai L ON L.LoaiAnPhamID = A.LoaiAnPhamID
		LEFT JOIN AnPham_Loai_Sub S ON S.LoaiSubAnPhamID = A.LoaiSubAnPhamID
		LEFT JOIN tblHDKH_DM_VaiTro VT ON VT.ID = T.VaiTroID
		LEFT JOIN tblHDKH_DM_TheLoaiBienSoan BS ON BS.ID = A.TheLoaiBienSoanID
	WHERE T.MaNhanVien = @sys_UserID AND T.Is_Xoa = 0
	ORDER BY A.NamDangBai DESC, A.AnPhamID DESC

	-- [3] Kê khai giờ NCKH: đề tài (form 1), sách/giáo trình (form 2), sở hữu trí tuệ (form 14)
	;WITH S AS (
		SELECT DISTINCT SB.SubmissionID, SB.FormID, SB.NamHoc, SB.TrangThaiDuyet
		FROM tblHDKH_KeKhai_Submission SB
		WHERE SB.IsDeleted = 0 AND SB.FormID IN (1, 2, 14)
			AND (SB.NhanVienID_KeKhai = @sys_UserID OR EXISTS (SELECT 1 FROM tblHDKH_KeKhai_ThanhVien TV
				WHERE TV.SubmissionID = SB.SubmissionID AND TV.NhanVienID = @sys_UserID AND TV.IsDeleted = 0))
	), V AS (
		SELECT S.SubmissionID, S.FormID, S.NamHoc, S.TrangThaiDuyet, FD.FieldName, FV.FieldValue
		FROM S
			INNER JOIN tblHDKH_KeKhai_FieldValue FV ON FV.SubmissionID = S.SubmissionID AND FV.IsDeleted = 0
			INNER JOIN tblHDKH_Field_Definition FD ON FD.FieldID = FV.FieldID
	), P AS (
		SELECT SubmissionID, FormID, NamHoc, TrangThaiDuyet,
			Ten = MAX(CASE WHEN FieldName IN ('ten_de_tai', 'ten_sach', 'ten_sang_che') THEN FieldValue END),
			CapDeTai = MAX(CASE WHEN FieldName = 'cap_de_tai' THEN FieldValue END),
			VaiTro = MAX(CASE WHEN FieldName = 'vai_tro' THEN FieldValue END),
			TheLoaiBienSoan = MAX(CASE WHEN FieldName = 'the_loai_bien_soan' THEN FieldValue END),
			LoaiSHTT = MAX(CASE WHEN FieldName = 'loai_hinh_shtt' THEN FieldValue END),
			NoiPhatHanh = MAX(CASE WHEN FieldName = 'noi_phat_hanh' THEN FieldValue END),
			ThoiGianPhatHanh = MAX(CASE WHEN FieldName = 'thoi_gian_phat_hanh' THEN FieldValue END)
		FROM V GROUP BY SubmissionID, FormID, NamHoc, TrangThaiDuyet
	)
	SELECT P.SubmissionID,
		Loai = CASE P.FormID WHEN 1 THEN 'DE_TAI' WHEN 2 THEN 'SACH' ELSE 'SHTT' END,
		P.Ten, P.NamHoc, P.TrangThaiDuyet, P.NoiPhatHanh, P.ThoiGianPhatHanh,
		CapDeTai = CD.TenCapDeTai, VaiTro = VT.TenVaiTro, TheLoaiBienSoan = BS.TenTheLoai, LoaiSHTT = SH.TenLoaiHinh
	FROM P
		LEFT JOIN tblHDKH_DM_CapDeTai CD ON CAST(CD.ID AS varchar(10)) = P.CapDeTai
		LEFT JOIN tblHDKH_DM_VaiTro VT ON CAST(VT.ID AS varchar(10)) = P.VaiTro
		LEFT JOIN tblHDKH_DM_TheLoaiBienSoan BS ON CAST(BS.ID AS varchar(10)) = P.TheLoaiBienSoan
		LEFT JOIN tblHDKH_DM_LoaiHinhSHTT SH ON CAST(SH.ID AS varchar(10)) = P.LoaiSHTT
	ORDER BY P.NamHoc DESC

	-- [4] Cuộc thi KH&CN và sở hữu trí tuệ đã đề nghị khen thưởng
	SELECT K.KhenThuongID, K.LoaiKhenThuong, K.TenCuocThi_CongTrinh, K.SoQuyetDinh_VanBang,
		NoiCapVanBang = K.NoiCapVanBang,
		MaSoDeTai = K.MaSoDeTai,
		K.Is_DauRaDeTaiCoSo,
		SoMinhChung = (SELECT COUNT(*) FROM ThiKHCN_File F WHERE F.KhenThuongID = K.KhenThuongID AND F.Is_Xoa = 0),
		NgayBanHanh = CONVERT(varchar(10), K.NgayBanHanh, 23),
		CapDo = CASE K.CapDoCuocThi WHEN 1 THEN N'Cấp quốc tế' WHEN 2 THEN N'Cấp khu vực quốc tế'
			WHEN 3 THEN N'Cấp quốc gia' WHEN 4 THEN N'Cấp khu vực (trong nước)' WHEN 5 THEN N'Cấp tỉnh'
			WHEN 6 THEN N'Cấp trường / Ngày hội Lạc Hồng' END,
		Giai = CASE K.GiaiThuong WHEN 1 THEN N'Giải Nhất' WHEN 2 THEN N'Giải Nhì' WHEN 3 THEN N'Giải Ba'
			WHEN 4 THEN N'Khuyến khích' WHEN 5 THEN N'Báo cáo ngày hội' END,
		LoaiSHTT = CASE K.LoaiSHTT WHEN 1 THEN N'Sáng chế / Giống cây trồng' WHEN 2 THEN N'Giải pháp hữu ích'
			WHEN 3 THEN N'Kiểu dáng công nghiệp' WHEN 4 THEN N'Quyền tác giả' END,
		VaiTro = CASE TV.VaiTro WHEN 1 THEN N'Trưởng nhóm' WHEN 2 THEN N'Đồng tác giả' WHEN 3 THEN N'GVHD'
			WHEN 4 THEN N'Hỗ trợ SHTT' END,
		NhomTacGia = (SELECT STRING_AGG(X.HoTen, ', ') FROM ThiKHCN_ThanhVien X
			WHERE X.KhenThuongID = K.KhenThuongID AND X.Is_Xoa = 0)
	FROM ThiKHCN_ThanhVien TV
		INNER JOIN ThiKHCN_KhenThuong K ON K.KhenThuongID = TV.KhenThuongID AND K.Is_Xoa = 0
	WHERE TV.MaDinhDanh = @sys_UserID AND TV.Is_Xoa = 0
	ORDER BY K.NgayBanHanh DESC

	-- [5] Dữ liệu tự khai trước đây trong module Lý lịch khoa học cũ
	SELECT Loai = N'Đào tạo', NoiDung = CONCAT(HocVi, N' – ', ChuyenNganh, N' – ', NoiDaoTao), ThoiGian = CAST(NamTotNghiep AS nvarchar(20))
	FROM tblHDKH_Profile_DaoTao WHERE NhanVienID = @sys_UserID AND IsDeleted = 0
	UNION ALL
	SELECT N'Công tác', CONCAT(NoiCongTac, N' – ', CongViecDamNhiem), ThoiGian
	FROM tblHDKH_Profile_CongTac WHERE NhanVienID = @sys_UserID AND IsDeleted = 0
	UNION ALL
	SELECT N'Đề tài', CONCAT(TenDeTai, N' – ', CoQuanTaiTro, N' – ', VaiTro), ThoiGianThucHien
	FROM tblHDKH_Profile_DeTaiDaThamGia WHERE NhanVienID = @sys_UserID AND IsDeleted = 0
	UNION ALL
	SELECT N'Công trình', CONCAT(TenTacGia, N' – ', TenCongTrinh, N' – ', TapChi_HoiThao), NULL
	FROM tblHDKH_Profile_CongTrinhDaCongBo WHERE NhanVienID = @sys_UserID AND IsDeleted = 0
END