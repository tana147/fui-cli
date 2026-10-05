
CREATE PROC spAPI_AnPham_Dot_Upd
@AnPham_DotID INT,
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
	UPDATE AnPham_Dot
	SET AnPham_DotTen = @TenDot
	, [AnPham_DotTinhTrang] = @TinhTrang
	, [NienKhoa] = @NienKhoa
	, [ThoiGianBatDau] = @ThoiGianBatDau
	, [ThoiGianKetThuc] = @ThoiGianKetThuc
	, [ThongBao] = @ThongBao
	, [FileHuongDan] = @FileHuongDan
	, UpdateUser = @SYS_UserID
	, UpdateTime = GETDATE()
	WHERE AnPham_DotID = @AnPham_DotID
END