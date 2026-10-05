CREATE PROC [dbo].[spAPI_AnPham_LichSu_Get]
@AnPhamID INT
AS
BEGIN
	SELECT A.AnPhamID, A.ThoiGianSubmit AS ThoiGian, A.NhanVienSubmit AS NhanVien, N.HoTen
	FROM AnPham A
		LEFT JOIN NhanVien N ON N.MaNV = A.NhanVienSubmit
	WHERE A.AnPhamID = @AnPhamID

	SELECT L.LichSuID, L.AnPhamID, L.HanhDong, L.MoTa, L.NhanVien, N.HoTen, L.ThoiGian
	FROM AnPham_LichSu L
		LEFT JOIN NhanVien N ON N.MaNV = L.NhanVien
	WHERE L.AnPhamID = @AnPhamID
	ORDER BY L.ThoiGian ASC, L.LichSuID ASC

	-- Trạng thái duyệt hiện tại của AnPham, dùng để dựng lại mốc "Duyệt" cho các bài
	-- đã duyệt TRƯỚC khi bảng AnPham_LichSu tồn tại (không có dòng log tương ứng)
	SELECT A.TrangThai, A.DotDuyet, A.ThoiGianDuyet, A.NhanVienCapNhat, N.HoTen
	FROM AnPham A
		LEFT JOIN NhanVien N ON N.MaNV = A.NhanVienCapNhat
	WHERE A.AnPhamID = @AnPhamID
END
