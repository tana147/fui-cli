-- [dbo].[spAPI_RPT_BBKH_Summary] 'GV0000611',9 
CREATE PROC [dbo].[spAPI_RPT_BBKH_Summary]
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	--DECLARE @MsgError NVARCHAR(500)
	--IF (@sys_SystemRight NOT IN (1,2,9))
	--BEGIN 
	--	SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
	--	RAISERROR(@MsgError, 16, 1)
	--	RETURN 0;
	--END

	--BieuDo Circlre 1
	SELECT
    SUM(CASE WHEN BB.NoiDang = N'Trong nước' THEN 1 ELSE 0 END) AS SL_TrongNuoc,
    SUM(CASE WHEN BB.NoiDang = N'Quốc tế' THEN 1 ELSE 0 END) AS SL_QuocTe,
	COUNT(*) AS SL_Tong
	FROM BaiBaoKhoaHoc BB

	--BieuDo Circle 2
	SELECT
	L.LoaiAnPhamID, L.TenLoaiAnPham, COUNT(*) AS SL_BB
	FROM BaiBaoKhoaHoc BB INNER JOIN AnPham_Loai L ON BB.LoaiAnPhamID = L.LoaiAnPhamID
	WHERE BB.NoiDang = N'Quốc tế'
	GROUP BY L.LoaiAnPhamID, L.TenLoaiAnPham
	ORDER BY L.LoaiAnPhamID, L.TenLoaiAnPham 
	
	--BieuDo Circle 3
	SELECT
	L.LoaiAnPhamID, L.TenLoaiAnPham, COUNT(*) AS SL_BB
	FROM BaiBaoKhoaHoc BB INNER JOIN AnPham_Loai L ON BB.LoaiAnPhamID = L.LoaiAnPhamID AND ISNULL(BB.DanhMucLoaiTapChiID,0) <> 34
	WHERE BB.NoiDang = N'Trong nước'
	GROUP BY L.LoaiAnPhamID, L.TenLoaiAnPham
	UNION
	SELECT
	0 LoaiAnPhamID, N'Tạp chí Khoa học LHU' TenLoaiAnPham, COUNT(*) AS SL_BB
	FROM BaiBaoKhoaHoc BB INNER JOIN AnPham_Loai L ON BB.LoaiAnPhamID = L.LoaiAnPhamID AND ISNULL(BB.DanhMucLoaiTapChiID,0) = 34
	WHERE BB.NoiDang = N'Trong nước'
	GROUP BY L.LoaiAnPhamID, L.TenLoaiAnPham
	ORDER BY L.LoaiAnPhamID, L.TenLoaiAnPham 
	

	--BieuDo Stack 2.1
	SELECT
    NamHoc AS Nam, SUM(CASE WHEN BB.NoiDang = N'Trong nước' THEN 1 ELSE 0 END) AS SL_TrongNuoc,
    SUM(CASE WHEN BB.NoiDang = N'Quốc tế' THEN 1 ELSE 0 END) AS SL_QuocTe,
	COUNT(*) AS SL_Tong
	FROM BaiBaoKhoaHoc BB
	GROUP BY NamHoc
	ORDER BY NamHoc

	DECLARE @YEAR AS TABLE(NamHoc VARCHAR(9))
	INSERT INTO @YEAR(NamHoc)
	SELECT DISTINCT NamHoc FROM  BaiBaoKhoaHoc BB

	DECLARE @tbl AS TABLE (NamHoc VARCHAR(9), LoaiAnPhamID INT, TenLoaiAnPham NVARCHAR(500))
	INSERT INTO @tbl(NamHoc, LoaiAnPhamID, TenLoaiAnPham)
	SELECT Y.NamHoc, 0 LoaiAnPhamID, N'Tạp chí Khoa học LHU' TenLoaiAnPham
	FROM @YEAR Y 
	UNION
	SELECT Y.NamHoc, L.LoaiAnPhamID, L.TenLoaiAnPham
	FROM @YEAR Y , AnPham_Loai L 
	WHERE L.LoaiAnPhamID NOT IN ( 10,11) AND L.Is_Xoa = 0
	

	--BieuDo Line 2.2
	SELECT DISTINCT A.NamHoc AS Nam, A.LoaiAnPhamID, A.TenLoaiAnPham, ISNULL(B.SL_BB,0) AS SL_BB
	FROM @tbl A
		LEFT JOIN 
			(
				SELECT BB.NamHoc, BB.DanhMucLoaiTapChiID, L.LoaiAnPhamID, L.TenLoaiAnPham, ISNULL(COUNT(BB.LoaiAnPhamID), 0) AS SL_BB
				FROM  BaiBaoKhoaHoc BB INNER JOIN AnPham_Loai L ON BB.LoaiAnPhamID = L.LoaiAnPhamID 
				WHERE ISNULL(BB.DanhMucLoaiTapChiID,0) <> 34
				GROUP BY L.LoaiAnPhamID, L.TenLoaiAnPham, BB.NamHoc ,BB.DanhMucLoaiTapChiID
			) AS B ON B.NamHoc = A.NamHoc AND B.LoaiAnPhamID = A.LoaiAnPhamID 
			WHERE A.LoaiAnPhamID <> 0
	UNION
	SELECT DISTINCT A.NamHoc AS Nam, A.LoaiAnPhamID, N'Tạp chí Khoa học LHU' TenLoaiAnPham, ISNULL(B.SL_BB,0) AS SL_BB
	FROM @tbl A
		LEFT JOIN 
			(
				SELECT BB.NamHoc, 0 LoaiAnPhamID, N'Tạp chí Khoa học LHU' TenLoaiAnPham, ISNULL(COUNT(BB.LoaiAnPhamID), 0) AS SL_BB
				FROM  BaiBaoKhoaHoc BB WHERE  BB.DanhMucLoaiTapChiID = 34
				GROUP BY BB.LoaiAnPhamID, BB.NamHoc 
			) AS B ON B.NamHoc = A.NamHoc AND B.LoaiAnPhamID = A.LoaiAnPhamID
				WHERE  A.LoaiAnPhamID = 0
	ORDER BY LoaiAnPhamID, A.NamHoc


END

--select * from BaiBaoKhoaHoc where LoaiAnPhamID = 3 --Tạp chí Khoa học LHU
-- select * from BaiBaoKhoaHoc where DanhMucLoaiTapChiID = 34
--select * from ANPHAM_LOAI

--update BaiBaoKhoaHoc set loaianphamid = 3 where DanhMucLoaiTapChiID = 34
