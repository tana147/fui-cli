
CREATE PROC [dbo].[spAPI_RPT_Temp]
AS
BEGIN
	SELECT NamDangBai, COUNT(*) SL FROM AnPham 
	WHERE TrangThai IN (2,3,4) -- 1: Lưu tạm; 2: Chờ Duyệt ; 3: Đã Duyệt; 4: Đã Ra quyết định khen thưởng
	AND Is_Xoa = 0 
	GROUP BY NamDangBai

	SELECT A.LoaiAnPhamID, L.TenLoaiAnPham, NamDangBai,  COUNT(*) SL 
	FROM AnPham  A INNER JOIN AnPham_Loai L ON A.LoaiAnPhamID = L.LoaiAnPhamID
	WHERE  A.TrangThai IN (2,3,4) -- 1: Lưu tạm; 2: Chờ Duyệt ; 3: Đã Duyệt; 4: Đã Ra quyết định khen thưởng
	AND A.Is_Xoa = 0 
	GROUP BY  A.LoaiAnPhamID, L.TenLoaiAnPham, NamDangBai
	ORDER BY LoaiAnPhamID, NamDangBai

	SELECT A.LoaiAnPhamID, L.TenLoaiAnPham,   NoiDangBai,  NamDangBai, 
--	CASE WHEN S.TenLoaiSubAnPham IS NULL THEN N'Khác' ELSE S.TenLoaiSubAnPham END TenLoaiSubAnPham,
	CASE WHEN DM.TenVietTatLoaiDanhMucTapChi IS NULL THEN N'Khác' ELSE DM.TenVietTatLoaiDanhMucTapChi END TenVietTatLoaiDanhMucTapChi,  COUNT(*) SL 
	FROM AnPham  A 
		INNER JOIN AnPham_Loai L ON A.LoaiAnPhamID = L.LoaiAnPhamID
		--LEFT JOIN AnPham_Loai_Sub S ON A.LoaiSubAnPhamID = S.LoaiSubAnPhamID
		LEFT JOIN LoaiDanhMucTapChi DM ON DM.DanhMucLoaiTapChiID = A.DanhMucLoaiTapChiID
	WHERE  A.TrangThai IN (2,3,4) -- 1: Lưu tạm; 2: Chờ Duyệt ; 3: Đã Duyệt; 4: Đã Ra quyết định khen thưởng
	AND A.Is_Xoa = 0 
	GROUP BY A.LoaiAnPhamID, L.TenLoaiAnPham, DM.TenVietTatLoaiDanhMucTapChi, NoiDangBai,  NamDangBai--, S.TenLoaiSubAnPham
	ORDER BY LoaiAnPhamID, NamDangBai

	--
	SELECT A.LoaiAnPhamID, L.TenLoaiAnPham,   NoiDangBai,  NamDangBai, 
	CASE WHEN S.TenLoaiSubAnPham IS NULL THEN N'Khác' ELSE S.TenLoaiSubAnPham END TenLoaiSubAnPham,
	CASE WHEN DM.TenVietTatLoaiDanhMucTapChi IS NULL THEN N'Khác' ELSE DM.TenVietTatLoaiDanhMucTapChi END TenVietTatLoaiDanhMucTapChi,  COUNT(*) SL 
	FROM AnPham  A 
		INNER JOIN AnPham_Loai L ON A.LoaiAnPhamID = L.LoaiAnPhamID
		LEFT JOIN AnPham_Loai_Sub S ON A.LoaiSubAnPhamID = S.LoaiSubAnPhamID
		LEFT JOIN LoaiDanhMucTapChi DM ON DM.DanhMucLoaiTapChiID = A.DanhMucLoaiTapChiID
	WHERE  A.TrangThai IN (2,3,4) -- 1: Lưu tạm; 2: Chờ Duyệt ; 3: Đã Duyệt; 4: Đã Ra quyết định khen thưởng
	AND A.Is_Xoa = 0 
	GROUP BY A.LoaiAnPhamID, L.TenLoaiAnPham, DM.TenVietTatLoaiDanhMucTapChi, NoiDangBai,  NamDangBai, S.TenLoaiSubAnPham
	ORDER BY LoaiAnPhamID, NamDangBai
END