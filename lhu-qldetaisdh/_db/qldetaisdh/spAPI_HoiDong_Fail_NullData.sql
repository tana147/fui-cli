
CREATE PROC [dbo].[spAPI_HoiDong_Fail_NullData]
@StudentID VARCHAR(9),

@SYS_UserID VARCHAR(9),
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

	DECLARE @Process_Student_ID INT
	DECLARE @Flow_ID_DK_BaoVe INT
	DECLARE @Flow_ID_Bao_Ve INT
	DECLARE @Flow_ID_Duyet_DeTai INT

	SELECT @Process_Student_ID = Process_Stu_ID
	FROM Process_Student
	WHERE Student_ID = @StudentID AND Process_ID IN (1,4) AND Process_Student_Status <> 'X'

	-- Đăng ký bảo vệ luận văn/đồ án
	SELECT @Flow_ID_DK_BaoVe = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'signForDefendThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	UPDATE Flow_Detail
	SET
		File_URL = NULL
		,Text_Content = Null
		,File_Name = Null
		,File_ID = Null
		,File_Type = Null
	WHERE Flow_ID = @Flow_ID_DK_BaoVe AND Task_Detail_ID <> 119 -- Không được null tên đề tài

	-- Bảo vệ luận văn/đồ án
	SELECT @Flow_ID_Bao_Ve = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'defendThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	UPDATE Flow_Detail
	SET
		File_URL = NULL
		,Text_Content = Null
		,File_Name = Null
		,File_ID = Null
		,File_Type = Null
	WHERE Flow_ID = @Flow_ID_Bao_Ve

	-- Duyệt đề tài (Hội đồng)
	SELECT @Flow_ID_Duyet_DeTai = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'reviewThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	UPDATE Flow_Detail
	SET
		File_URL = NULL
		,Text_Content = Null
		,File_Name = Null
		,File_ID = Null
		,File_Type = Null
	WHERE Flow_ID = @Flow_ID_Duyet_DeTai
END
