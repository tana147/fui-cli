
CREATE PROC [dbo].[spAPI_NCKH_Dot_Ins]
@LoaiHoiDong INT , --1: Sinh viên; 2: Giảng viên
@TenDot NVARCHAR(100),
@NamHoc VARCHAR(10),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	--DECLARE @MsgError NVARCHAR(500)
	--IF (@sys_SystemRight NOT IN (1,2,9))
	--BEGIN 
	--	SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
	--	RAISERROR(@MsgError, 16, 1)
	--	RETURN 0;
	--END
	INSERT INTO [dbo].[NCKH_Dot]([LoaiHoiDong], [TenDot], [NamHoc], NhanVienCapNhat, ThoiGianCapNhat)
	VALUES(@LoaiHoiDong, @TenDot, @NamHoc, @SYS_UserID, GETDATE())
END