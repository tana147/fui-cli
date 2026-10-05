
CREATE PROC [dbo].[spAPI_NCKH_Get_ByDotID] --9
@DotID INT
AS
BEGIN
	SELECT DISTINCT DT.[DeTaiNCKHID]
	, DT.[DotID]
	, DOT.TenDot
	, DOT.NamHoc
	, L.TenLoaiHoiDong
	, DT.[TenDeTaiNCKH]
	, DT.[KhoaID]
	, DT.[TieuBan]
	, DT.[DiemDG1]
	, DT.[DiemDG2]
	, DT.[DiemDG3]
	, DT.[DiemDG4]
	, DT.[DiemDG5]
	, DT.[DiemDG6]
	, DT.[DiemPB1]
	, DT.[DiemPB2]
	, DT.[DiemDGTB]
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
			AND DT.DotID = @DotID 
	ORDER BY [DeTaiNCKHID] ASC 
END


