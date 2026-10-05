
CREATE PROC spAPI_AnPham_Dot_Ins
@TenDot NVARCHAR(50),
@TinhTrang INT,
@NienKhoa VARCHAR(9),
@ThoiGianBatDau date,
@ThoiGianKetThuc date,
@ThongBao nvarchar(max),
@FileHuongDan nvarchar(200),
@SYS_UserID varchar(9),
@sys_SystemRight INT

AS
BEGIN
	INSERT INTO AnPham_Dot([AnPham_DotTen], [AnPham_DotTinhTrang], [NienKhoa], [ThoiGianBatDau], [ThoiGianKetThuc], [ThongBao], [FileHuongDan], [CreateUser], [CreateTime])
	VALUES(@TenDot, @TinhTrang, @NienKhoa, @ThoiGianBatDau, @ThoiGianKetThuc, @ThongBao, @FileHuongDan, @SYS_UserID, GETDATE())
END