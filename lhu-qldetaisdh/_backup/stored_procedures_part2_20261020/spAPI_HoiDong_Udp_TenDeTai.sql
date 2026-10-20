CREATE PROC [dbo].[spAPI_HoiDong_Udp_TenDeTai]
@Student_ID VARCHAR(9)
,@TenDeTaiMoi NVARCHAR(MAX)
,@SYS_UserID VARCHAR(9)
,@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	UPDATE HoiDong
	SET 
		DeTai = @TenDeTaiMoi
		,Updated_By = @SYS_UserID
		,Updated_At = GETDATE()
	WHERE StudentID = @Student_ID AND KetQuaHoiDong <> 2 AND Is_Xoa = 0
END