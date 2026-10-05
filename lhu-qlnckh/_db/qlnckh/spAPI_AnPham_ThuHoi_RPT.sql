CREATE PROC spAPI_AnPham_ThuHoi_RPT
@AnPhamID INT,
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
		DECLARE @MsgError NVARCHAR(500)
		IF (@sys_SystemRight NOT IN (1,2,9))
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END

		DELETE BaiBaoKhoaHoc WHERE AnPhamID = @AnPhamID
END
