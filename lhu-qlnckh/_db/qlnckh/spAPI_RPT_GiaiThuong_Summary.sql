
CREATE PROC [dbo].[spAPI_RPT_GiaiThuong_Summary]
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

	SELECT GT.LoaiGiaiThuongID, L.TenLoaiGiaiThuong,  COUNT(*) AS SL_GT
	FROM [dbo].[GiaiThuong] GT INNER JOIN LoaiGiaiThuong L ON GT.LoaiGiaiThuongID = L.LoaiGiaiThuongID
	WHERE GT.Is_Xoa = 0
	GROUP BY GT.LoaiGiaiThuongID, L.TenLoaiGiaiThuong


	DECLARE @YEAR AS TABLE(NamHoc VARCHAR(9))
	INSERT INTO @YEAR(NamHoc)
	SELECT DISTINCT NamHoc FROM  [GiaiThuong] GT

	DECLARE @tbl AS TABLE (NamHoc VARCHAR(9), LoaiGiaiThuongID INT, TenLoaiGiaiThuong nvarchar(500))
	INSERT INTO @tbl(NamHoc , LoaiGiaiThuongID , TenLoaiGiaiThuong )
	SELECT  Y.NamHoc, L.LoaiGiaiThuongID, L.TenLoaiGiaiThuong
	FROM @YEAR Y, [dbo].LoaiGiaiThuong L
	WHERE L.Is_Xoa = 0

		--BieuDo Line 2.2
	SELECT DISTINCT A.NamHoc AS NamDatGiai, A.LoaiGiaiThuongID, A.TenLoaiGiaiThuong, ISNULL(B.SL_GT,0) AS SL_GT
	FROM @tbl A
		LEFT JOIN 
			(
				SELECT GT.NamHoc, L.LoaiGiaiThuongID, L.TenLoaiGiaiThuong, ISNULL(COUNT(GT.LoaiGiaiThuongID), 0) AS SL_GT
				FROM  GiaiThuong GT INNER JOIN LoaiGiaiThuong L ON GT.LoaiGiaiThuongID = L.LoaiGiaiThuongID
				WHERE GT.Is_Xoa = 0 AND L.Is_Xoa =0
				GROUP BY GT.NamHoc, L.LoaiGiaiThuongID, L.TenLoaiGiaiThuong
			) AS B ON B.NamHoc = A.NamHoc AND B.LoaiGiaiThuongID = A.LoaiGiaiThuongID
	ORDER BY LoaiGiaiThuongID, A.NamHoc


END

