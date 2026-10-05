CREATE PROC [dbo].[spAPI_AnPham_DotDuyet_Upd]
@AnPham_DotDuyetID INT,
@TenDotDuyet NVARCHAR(100),
@TinhTrang TINYINT,
@NienKhoa VARCHAR(10),
@ThoiGianBatDau SMALLDATETIME,
@ThoiGianKetThuc SMALLDATETIME,
@GhiChu NVARCHAR(500),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	UPDATE AnPham_DotDuyet
	SET TenDotDuyet = @TenDotDuyet
	, TinhTrang = @TinhTrang
	, NienKhoa = @NienKhoa
	, ThoiGianBatDau = @ThoiGianBatDau
	, ThoiGianKetThuc = @ThoiGianKetThuc
	, GhiChu = @GhiChu
	, UpdateUser = @SYS_UserID
	, UpdateTime = GETDATE()
	WHERE AnPham_DotDuyetID = @AnPham_DotDuyetID
END
