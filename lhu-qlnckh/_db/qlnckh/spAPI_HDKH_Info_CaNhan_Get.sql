CREATE PROC spAPI_HDKH_Info_CaNhan_Get
@NhanVienID VARCHAR(9)
AS
BEGIN
	SELECT [MaNV] UserID 
	, [HoTen], [Ten], [Email], [MaDonVi], [HocViID], [ChucVu], [IsActive], [NgaySinh], [GioiTinh], [SoDienThoai]
	FROM NhanVien WHERE MaNV = @NhanVienID
END

