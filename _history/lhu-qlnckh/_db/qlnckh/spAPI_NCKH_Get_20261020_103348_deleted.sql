
CREATE PROC [dbo].[spAPI_NCKH_Get]
AS
BEGIN
	SELECT DT.[DeTaiNCKHID]
	, DT.[DotID]
	, DOT.TenDot
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
		FROM NCKH_DeTai DT 
			INNER JOIN NCKH_Dot DOT ON DT.DotID = DOT.DotID
			INNER JOIN NCKH_LoaiHoiDong L ON L.LoaiHoiDongID = DOT.LoaiHoiDong
			WHERE DT.Is_Xoa = 0
	ORDER BY [DeTaiNCKHID] DESC 

END