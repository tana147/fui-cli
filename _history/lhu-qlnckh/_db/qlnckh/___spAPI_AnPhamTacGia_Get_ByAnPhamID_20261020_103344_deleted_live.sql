CREATE PROC [dbo].[spAPI_AnPhamTacGia_Get_ByAnPhamID]
@AnPhamID INT
AS
BEGIN
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
		, B.[TrangThai]
		, B.[NhanVienCapNhat]
		, B.[ThoiGianCapNhat]
		, B.[Is_NhanVien]
		, B.TacGiaGroupID -- CASE WHEN B.TacGiaGroupID = 1 THEN N'Nhân viên' WHEN B.TacGiaGroupID = 2 THEN N'Sinh viên' ELSE N'Khác' END AS TacGiaGroupID
		, B.[Is_Xoa]
		, B.[Is_LienHeTacGia]
		, B.[Is_TacGiaPhu]
		, B.[NguoiDaiDienQuyetToan]
		, B.[NguonCapKinhPhi]
		, B.[HeSoHoTroCaoHoc]
	FROM AnPham_TacGia B WHERE B.AnPhamID = @AnPhamID and b.Is_Xoa =0

END
