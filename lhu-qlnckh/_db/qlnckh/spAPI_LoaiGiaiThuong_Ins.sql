CREATE PROC spAPI_LoaiGiaiThuong_Ins
@MaLoaiGiaiThuong nvarchar(20),
@TenLoaiGiaiThuong NVARCHAR(500),
@SYS_USERID VARCHAR(9)
AS
BEGIN
	INSERT INTO [dbo].[LoaiGiaiThuong]( [MaLoaiGiaiThuong], [TenLoaiGiaiThuong], [NhanVienCapNhat], [ThoiGianCapNhat], [Is_Xoa])
	VALUES(@MaLoaiGiaiThuong, @TenLoaiGiaiThuong, @SYS_USERID, GETDATE(), 0)
END