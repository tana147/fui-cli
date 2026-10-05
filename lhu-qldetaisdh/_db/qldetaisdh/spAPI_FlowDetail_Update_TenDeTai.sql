CREATE PROC [dbo].[spAPI_FlowDetail_Update_TenDeTai] 
@StudentID VARCHAR(9),
@Text_Content NVARCHAR(MAX),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
	DECLARE @Task_Detail_ID_ThesisDefend INT
	DECLARE @Task_ID_DangKyBaoVe_NC INT = 4
	DECLARE @Flow_ID_DangKyBaoVe_NC INT
	
	SELECT @Task_Detail_ID_ThesisDefend = Task_Detail_ID
	FROM Task_Detail
	WHERE FieldName = 'ThesisNameDefend'
	
	SELECT @Flow_ID_DangKyBaoVe_NC = f.Flow_ID 
	FROM Flow f 
	WHERE f.Student_ID = @StudentID
	AND f.Task_ID = @Task_ID_DangKyBaoVe_NC
	
	UPDATE Flow_Detail
	SET 
		Text_Content = @Text_Content,
		Updated_At = GETDATE(),
		Updated_By = @SYS_UserID
	WHERE Task_Detail_ID = @Task_Detail_ID_ThesisDefend
		AND Flow_ID = @Flow_ID_DangKyBaoVe_NC 
		AND use_yn = 1
END