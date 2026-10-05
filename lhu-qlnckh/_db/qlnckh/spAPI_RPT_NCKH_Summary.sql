
CREATE PROC [dbo].[spAPI_RPT_NCKH_Summary]
AS
BEGIN
	--DECLARE @MsgError NVARCHAR(500)
	--IF (@sys_SystemRight NOT IN (1,2,9))
	--BEGIN 
	--	SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
	--	RAISERROR(@MsgError, 16, 1)
	--	RETURN 0;
	--END

	SELECT b.TenDot , COUNT(*) AS SL_DT
	FROM NCKH_DeTai A INNER JOIN NCKH_Dot B ON A.DotID = B.DotID
	WHERE A.Is_Xoa = 0 AND B.Is_Xoa =0 
	GROUP BY TenDot, A.DotID
	ORDER BY A.DotID


	DECLARE @tbl AS TABLE(DeTaiNCKHID INT, DotID INT, TenDot NVARCHAR(200), TenLoaiHoiDong nvarchar(500), TenDeTaiNCKH NVARCHAR(500), KhoaID VARCHAR(9), MoTaSanPham NVARCHAR(500), SinhVien NVARCHAR(500),GiaoVien NVARCHAR(500) )
	INSERT INTO @tbl(DeTaiNCKHID , DotID , TenDot , TenLoaiHoiDong , TenDeTaiNCKH , KhoaID , MoTaSanPham, SinhVien, GiaoVien )
	SELECT DISTINCT 
	 DT.[DeTaiNCKHID]
	, DT.[DotID]
	, DOT.TenDot
	, L.TenLoaiHoiDong
	, DT.[TenDeTaiNCKH]
	, DT.[KhoaID]

	, DT.[MoTa_SanPham]
	,  STUFF((SELECT ', ' + TV.Ho + ' ' + TV.Ten
               FROM NCKH_ThanhVien TV
               WHERE TV.DeTaiNCKHID = DT.DeTaiNCKHID AND TV.Is_SinhVien = 1 AND TV.Is_Xoa = 0
               FOR XML PATH('')), 1, 2, '') AS SinhVien
	, STUFF((SELECT ', ' + TV.Ho + ' ' + TV.Ten
               FROM NCKH_ThanhVien TV
               WHERE TV.DeTaiNCKHID = DT.DeTaiNCKHID AND ( TV.Is_NhanVien = 1  OR TV.Is_ChuNhiem = 1) AND TV.Is_Xoa = 0
               FOR XML PATH('')), 1, 2, '') AS GiaoVien
	FROM NCKH_DeTai DT 
			INNER JOIN NCKH_Dot DOT ON DT.DotID = DOT.DotID
			INNER JOIN NCKH_LoaiHoiDong L ON L.LoaiHoiDongID = DOT.LoaiHoiDong
			INNER JOIN NCKH_ThanhVien TV ON DT.DeTaiNCKHID = TV.DeTaiNCKHID
			WHERE DT.Is_Xoa = 0 AND TV.Is_Xoa = 0
	ORDER BY [DeTaiNCKHID] ASC 

	SELECT
	   ROW_NUMBER() OVER (ORDER BY DeTaiNCKHID) AS SoThuTu,
	DeTaiNCKHID , DotID , TenDot , TenLoaiHoiDong , TenDeTaiNCKH , A.KhoaID , B.MaDonVi as TenKhoa, MoTaSanPham, SinhVien, GiaoVien
	FROM @tbl A INNER JOIN DonVi B ON A.KhoaID = B.MaDonVi
	
	--table theo khoa
	SELECT A.KhoaID, B.MaDonVi as TenKhoa, COUNT(*) SL_DT FROM @tbl A INNER JOIN DonVi B ON A.KhoaID = B.MaDonVi
	GROUP BY A.KhoaID, B.MaDonVi

END

