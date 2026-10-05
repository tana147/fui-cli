
CREATE PROC [dbo].[spAPI_NCKH_Get_ByID]
@DeTaiNCKHID INT
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
			WHERE DT.DeTaiNCKHID = @DeTaiNCKHID AND DT.Is_Xoa = 0
	SELECT 
		  [ThanhVienNCKHID]
		, [DeTaiNCKHID]
		, [STT]
		, [Is_ChuNhiem]
		, [Is_NhanVien]
		, [Is_SinhVien]
		, [MaThanhVien]
		, [Ho]
		, [Ten]
		, [Email]
		, [PhongBanID]
		, [LopID]
		, [SoTaiKhoan]
		, [NganHang]
		, [TenChuTaiKhoan]
	FROM NCKH_ThanhVien TV WHERE TV.[DeTaiNCKHID] = @DeTaiNCKHID AND TV.Is_Xoa = 0 
END