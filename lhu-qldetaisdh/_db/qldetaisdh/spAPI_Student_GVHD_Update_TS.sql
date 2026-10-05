CREATE PROC [dbo].[spAPI_Student_GVHD_Update_TS]
@StudentObjArr NVARCHAR(MAX),
@sys_UserID varchar(9),
@sys_GroupID int,
@sys_SystemRight INT,
@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	-- Kiểm tra quyền Tiến sĩ: FunctionRight = 2 hoặc SystemRight IN (1,2,3,9)
	IF (@sys_SystemRight NOT IN (1,2,3,9) AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
	DECLARE @TaskID_GiaoDeTai_TS INT = 41
	DECLARE @TaskDetailID_ThesisName_TS INT = 279
	DECLARE @TaskDetailID_GVHD1_TS INT = 280
	DECLARE @TaskDetailID_GVHD2_TS INT = 281

	DECLARE @TempStudentInfo AS TABLE
	(
		StudentID VARCHAR(20),
		DeTai NVARCHAR(MAX),
		GVHD1 NVARCHAR(200),
		GVHD2 NVARCHAR(200)
	)

	INSERT INTO @TempStudentInfo
	(
	    StudentID,
	    DeTai,
	    GVHD1,
	    GVHD2
	)
	SELECT
	    StudentID,
	    COALESCE(DeTai, ThesisName),
	    GVHD1,
	    GVHD2
	FROM OPENJSON(@StudentObjArr)
	WITH
	(
	    StudentID VARCHAR(20) '$.StudentID',
	    DeTai NVARCHAR(MAX) '$.DeTai',
	    ThesisName NVARCHAR(MAX) '$.ThesisName',
	    GVHD1 NVARCHAR(200) '$.GVHD1',
	    GVHD2 NVARCHAR(200) '$.GVHD2'
	)

	IF EXISTS (
		SELECT 1 FROM @TempStudentInfo 
		WHERE StudentID IS NULL 
		   OR LEN(LTRIM(RTRIM(StudentID))) <> 9 
		   OR StudentID LIKE '%[^0-9]%'
	)
	BEGIN
		SET @MsgError = N'Mã số học viên không hợp lệ. Đối với Tiến sĩ, mã học viên bắt buộc phải đúng chuẩn 9 chữ số.'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
	-- Cursor loop từng học viên
	DECLARE 
	    @Student_ID VARCHAR(20),
	    @Process_ID INT,
	    @Flow_ID INT,
	    @Task_ID INT,
	    @DeTai NVARCHAR(MAX),
	    @GVHD1 NVARCHAR(200),
	    @GVHD2 NVARCHAR(200)
	
	DECLARE cur_UpdateGVHD_TS CURSOR LOCAL FAST_FORWARD FOR
	
	SELECT 
	    t.StudentID,
	    p.Process_ID,
	    f.Flow_ID,
	    f.Task_ID,
	    t.DeTai,
	    t.GVHD1,
	    t.GVHD2
	FROM @TempStudentInfo t
	INNER JOIN StudentInfo s 
	    ON s.StudentID = t.StudentID
	INNER JOIN Process_Student p 
	    ON p.Student_ID = t.StudentID
	    AND p.Process_Student_Status <> 'X'
	    AND p.Process_ID = 6
	INNER JOIN Flow f 
	    ON f.Process_Student_ID = p.Process_Stu_ID
	    AND f.Task_ID = @TaskID_GiaoDeTai_TS
	    AND f.use_yn = 1
	
	OPEN cur_UpdateGVHD_TS
	
	FETCH NEXT FROM cur_UpdateGVHD_TS INTO
	    @Student_ID,
	    @Process_ID,
	    @Flow_ID,
	    @Task_ID,
	    @DeTai,
	    @GVHD1,
	    @GVHD2
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
	    -- Đảm bảo Flow_Detail tồn tại
	    IF NOT EXISTS (SELECT 1 FROM Flow_Detail WHERE Flow_ID = @Flow_ID AND Task_Detail_ID = @TaskDetailID_ThesisName_TS)
	    BEGIN
	        INSERT INTO Flow_Detail (Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, use_yn, Created_By, Created_At, Updated_By, Updated_At)
	        VALUES (@Flow_ID, @Task_ID, @TaskDetailID_ThesisName_TS, 'W', 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE())
	    END
	    IF NOT EXISTS (SELECT 1 FROM Flow_Detail WHERE Flow_ID = @Flow_ID AND Task_Detail_ID = @TaskDetailID_GVHD1_TS)
	    BEGIN
	        INSERT INTO Flow_Detail (Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, use_yn, Created_By, Created_At, Updated_By, Updated_At)
	        VALUES (@Flow_ID, @Task_ID, @TaskDetailID_GVHD1_TS, 'W', 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE())
	    END
	    IF NOT EXISTS (SELECT 1 FROM Flow_Detail WHERE Flow_ID = @Flow_ID AND Task_Detail_ID = @TaskDetailID_GVHD2_TS)
	    BEGIN
	        INSERT INTO Flow_Detail (Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, use_yn, Created_By, Created_At, Updated_By, Updated_At)
	        VALUES (@Flow_ID, @Task_ID, @TaskDetailID_GVHD2_TS, 'W', 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE())
	    END

	    -- 1. Cập nhật Tên đề tài
	    IF ISNULL(@DeTai, '') <> ''
	    BEGIN
	        EXEC [dbo].[spAPI_FlowDetail_UpdateData]
	            @Student_ID       = @Student_ID,
	            @Process_ID       = @Process_ID,
	            @Flow_ID          = @Flow_ID,
	            @Task_ID          = @Task_ID,
	            @Task_Detail_ID   = @TaskDetailID_ThesisName_TS,
	            @File_URL         = NULL,
	            @Text_Content     = @DeTai,
	            @File_Name        = NULL,
	            @File_ID          = NULL,
	            @File_Type        = NULL,
	            @Flow_Detail_ID   = NULL,
	            @sys_UserID       = @sys_UserID,
	            @sys_GroupID      = @sys_GroupID,
	            @sys_SystemRight  = @sys_SystemRight,
	            @sys_RawData      = NULL
	    END

	    -- 2. Cập nhật GVHD 1
	    IF ISNULL(@GVHD1, '') <> ''
	    BEGIN
	        EXEC [dbo].[spAPI_FlowDetail_UpdateData]
	            @Student_ID       = @Student_ID,
	            @Process_ID       = @Process_ID,
	            @Flow_ID          = @Flow_ID,
	            @Task_ID          = @Task_ID,
	            @Task_Detail_ID   = @TaskDetailID_GVHD1_TS,
	            @File_URL         = NULL,
	            @Text_Content     = @GVHD1,
	            @File_Name        = NULL,
	            @File_ID          = NULL,
	            @File_Type        = NULL,
	            @Flow_Detail_ID   = NULL,
	            @sys_UserID       = @sys_UserID,
	            @sys_GroupID      = @sys_GroupID,
	            @sys_SystemRight  = @sys_SystemRight,
	            @sys_RawData      = NULL
	    END

	    -- 3. Cập nhật GVHD 2
	    IF @GVHD2 IS NOT NULL
	    BEGIN
	        EXEC [dbo].[spAPI_FlowDetail_UpdateData]
	            @Student_ID       = @Student_ID,
	            @Process_ID       = @Process_ID,
	            @Flow_ID          = @Flow_ID,
	            @Task_ID          = @Task_ID,
	            @Task_Detail_ID   = @TaskDetailID_GVHD2_TS,
	            @File_URL         = NULL,
	            @Text_Content     = @GVHD2,
	            @File_Name        = NULL,
	            @File_ID          = NULL,
	            @File_Type        = NULL,
	            @Flow_Detail_ID   = NULL,
	            @sys_UserID       = @sys_UserID,
	            @sys_GroupID      = @sys_GroupID,
	            @sys_SystemRight  = @sys_SystemRight,
	            @sys_RawData      = NULL
	    END
	
	    FETCH NEXT FROM cur_UpdateGVHD_TS INTO
	        @Student_ID,
	        @Process_ID,
	        @Flow_ID,
	        @Task_ID,
	        @DeTai,
	        @GVHD1,
	        @GVHD2
	END

	CLOSE cur_UpdateGVHD_TS
	DEALLOCATE cur_UpdateGVHD_TS
END