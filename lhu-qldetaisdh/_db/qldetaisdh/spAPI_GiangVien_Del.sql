
CREATE PROC [dbo].[spAPI_GiangVien_Del]
@GiangVienID INT,
@SYS_UserID VARCHAR(9),
@Sys_GroupID INT,
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	ELSE
	BEGIN
		UPDATE GiangVien
		SET Is_Xoa = 1
			, Updated_At = GETDATE()
			, Updated_By = @SYS_UserID
		WHERE GiangVienID = @GiangVienID
	END
	
END
