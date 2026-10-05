CREATE PROC [dbo].[spAPI_Student_GVHD_Update]
@StudentObjArr NVARCHAR(MAX),
@sys_UserID varchar(9),
@sys_GroupID int,
@sys_SystemRight INT,
@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	-- Thạc sĩ giữ như cũ (SystemRight IN 1,2,3,9), Tiến sĩ là FunctionRight = 2
	IF (@sys_SystemRight NOT IN (1,2,3,9) AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
	DECLARE @TaskID_PhanCongGVHD_NC INT = 34
	DECLARE @TaskID_PhanCongGVHD_UD INT = 35

	DECLARE @TaskDetailID_GVHD1_NC INT = 47
	DECLARE @TaskDetailID_GVHD2_NC INT = 55

	DECLARE @TaskDetailID_GVHD1_UD INT = 60
	DECLARE @TaskDetailID_GVHD2_UD INT = 62

	DECLARE @TempStudentInfo AS TABLE
	(
		StudentID VARCHAR(9),
		GVHD1 NVARCHAR(200),
		GVHD2 NVARCHAR(200)
	)

	INSERT INTO @TempStudentInfo
	(
	    StudentID,
	    GVHD1,
	    GVHD2
	)
	SELECT
	    StudentID,
	    GVHD1,
	    GVHD2
	FROM OPENJSON(@StudentObjArr)
	WITH
	(
	    StudentID VARCHAR(9) '$.StudentID',
	    GVHD1 NVARCHAR(200) '$.GVHD1',
	    GVHD2 NVARCHAR(200) '$.GVHD2'
	)
	
	-- =========================================================
	-- 1. KHAI BÁO BIẾN DÙNG ĐỂ LOOP TỪNG DÒNG
	-- =========================================================
	DECLARE 
	    @Student_ID VARCHAR(20),
	    @Process_ID INT,
	    @Flow_ID INT,
	    @Task_ID INT,
	    @GVHD1 NVARCHAR(200),
	    @GVHD2 NVARCHAR(200),
	    @TaskDetailID_GVHD1 INT,
	    @TaskDetailID_GVHD2 INT
	
	
	-- =========================================================
	-- 2. CURSOR LẤY DANH SÁCH CẦN UPDATE
	-- =========================================================
	DECLARE cur_UpdateGVHD CURSOR LOCAL FAST_FORWARD FOR
	
	SELECT 
	    t.StudentID,
	    p.Process_ID,
	    f.Flow_ID,
	    f.Task_ID,
	    t.GVHD1,
	    t.GVHD2,
	    CASE 
	        WHEN p.Process_ID = 1 THEN @TaskDetailID_GVHD1_NC
	        WHEN p.Process_ID = 4 THEN @TaskDetailID_GVHD1_UD
	    END AS TaskDetailID_GVHD1,
	    CASE 
	        WHEN p.Process_ID = 1 THEN @TaskDetailID_GVHD2_NC
	        WHEN p.Process_ID = 4 THEN @TaskDetailID_GVHD2_UD
	    END AS TaskDetailID_GVHD2
	
	FROM @TempStudentInfo t
	
	INNER JOIN StudentInfo s 
	    ON s.StudentID = t.StudentID
	INNER JOIN Process_Student p 
	    ON p.Student_ID = t.StudentID
	    AND p.Process_Student_Status <> 'X'
	    AND p.Process_ID IN (1, 4)
	INNER JOIN Flow f 
	    ON f.Process_Student_ID = p.Process_Stu_ID
	    AND f.Task_ID IN (
	        @TaskID_PhanCongGVHD_NC,
	        @TaskID_PhanCongGVHD_UD
	    )
	
	-- =========================================================
	-- 3. MỞ CURSOR VÀ ĐỌC DÒNG ĐẦU TIÊN
	-- =========================================================
	OPEN cur_UpdateGVHD
	
	FETCH NEXT FROM cur_UpdateGVHD INTO
	    @Student_ID,
	    @Process_ID,
	    @Flow_ID,
	    @Task_ID,
	    @GVHD1,
	    @GVHD2,
	    @TaskDetailID_GVHD1,
	    @TaskDetailID_GVHD2
	
	-- =========================================================
	-- 4. LOOP TỪNG DÒNG VÀ GỌI PROC UPDATE
	-- =========================================================
	WHILE @@FETCH_STATUS = 0
	BEGIN
	    -- =====================================================
	    -- 4.1 Update GVHD1 vào FlowDetail tương ứng
	    -- =====================================================
	    BEGIN
	        EXEC [dbo].[spAPI_FlowDetail_UpdateData]
	            @Student_ID       = @Student_ID,
	            @Process_ID       = @Process_ID,
	            @Flow_ID          = @Flow_ID,
	            @Task_ID          = @Task_ID,
	            @Task_Detail_ID   = @TaskDetailID_GVHD1,
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

	    -- =====================================================
	    -- 4.2 Update GVHD2 vào FlowDetail tương ứng
	    -- =====================================================
	    --IF ISNULL(@GVHD2, '') <> ''
	    BEGIN
	        EXEC [dbo].[spAPI_FlowDetail_UpdateData]
	            @Student_ID       = @Student_ID,
	            @Process_ID       = @Process_ID,
	            @Flow_ID          = @Flow_ID,
	            @Task_ID          = @Task_ID,
	            @Task_Detail_ID   = @TaskDetailID_GVHD2,
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
	
	    -- Đọc dòng tiếp theo
	    FETCH NEXT FROM cur_UpdateGVHD INTO
	        @Student_ID,
	        @Process_ID,
	        @Flow_ID,
	        @Task_ID,
	        @GVHD1,
	        @GVHD2,
	        @TaskDetailID_GVHD1,
	        @TaskDetailID_GVHD2
	END

	-- =========================================================
	-- 5. ĐÓNG VÀ GIẢI PHÓNG CURSOR
	-- =========================================================
	CLOSE cur_UpdateGVHD
	DEALLOCATE cur_UpdateGVHD
END