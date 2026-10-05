
CREATE PROC spAPI_NCKH_Dot_Del
@DotID INT,
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
	UPDATE [NCKH_Dot]
	SET Is_Xoa = 1,
		NhanVienCapNhat = @SYS_UserID,
		ThoiGianCapNhat = GETDATE()

	WHERE DotID = @DotID
END