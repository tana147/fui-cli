
CREATE PROC [dbo].[spAPI_HoiDong_GiangVien_Get_Diem]
@HoiDongID INT
AS
BEGIN
		SELECT  [HoiDongID]
			, [StudentID]
			, [DeTai]
			, [Decision_ID]
			, [LoaiHoiDong]
			, [DiemHoiDong]
			, [KetQuaHoiDong]
			, [NhanXet]
			, [FileNhanXetID]
			, [FileNhanXetName]
			, [ThoiGianBaoVe]
			, [FileKiemPhieuID]
			, [FileKiemPhieuName]
		FROM HoiDong WHERE HoiDongID = @HoiDongID --AND [HoiDong_Status] = 0
	SELECT
		[TVHDID]
		, [HoiDongID]
		, [StudentID]
		, [GiangVienID]
		, [HocViHocHam]
		, [HoTenGiangVien]
		, [CoQuanCongTac]
		, [NganhGiangDay]
		, [ChucTrach]
		, [Diem]
		, [KetQua]
		, [NhanXet]
		, [FileNhanXetID]
		, [FileNhanXetName]
		, [FileDiemID]
		, [FileDiemName]
	FROM HoiDongThanhVien 
	WHERE HoiDongID = @HoiDongID AND [Is_Xoa] = 0
END