CREATE PROC [dbo].[spAPI_AnPham_DotDuyet_Ins]
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
	INSERT INTO AnPham_DotDuyet([TenDotDuyet], [TinhTrang], [NienKhoa], [ThoiGianBatDau], [ThoiGianKetThuc], [GhiChu], [CreateUser], [CreateTime])
	VALUES(@TenDotDuyet, @TinhTrang, @NienKhoa, @ThoiGianBatDau, @ThoiGianKetThuc, @GhiChu, @SYS_UserID, GETDATE())
END
