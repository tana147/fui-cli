CREATE PROCEDURE [dbo].[spAPI_FlowDetail_UpdateData]
	@Student_ID varchar(20),
	@Process_ID int,
	@Flow_ID	int,
	@Task_ID	int,
	@Task_Detail_ID int,
	@File_URL NVARCHAR(500),
	@Text_Content	nvarchar(max),
	@File_Name		nvarchar(255),
	@File_ID VARCHAR(50),
	@File_Type		nvarchar(50),
	@Flow_Detail_ID int,
	@sys_UserID varchar(9),
	@sys_GroupID int,
	@sys_SystemRight INT,
	@sys_RawData nvarchar(max) -- chứa toàn bộ chuỗi json nguyên thuỷ từ client gửi lên
AS
BEGIN
	
	-- Kiểm tra bỏ trống file và Text content
	DECLARE @AllowNULL CHAR(1)
	DECLARE @TaskDetailType NVARCHAR(500)
	DECLARE @FieldName VARCHAR(50)
	DECLARE @MsgError NVARCHAR(500)
	--@sys_GroupID = 1 AND @sys_SystemRight = 1
	IF  (@sys_GroupID = 1 AND @sys_SystemRight = 1)
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	SELECT @AllowNULL = td.AllowNull, @TaskDetailType = td.Task_Detail_Type, @FieldName = td.FieldName
	FROM Task_Detail td
	WHERE td.Task_Detail_ID = @Task_Detail_ID

	IF @AllowNULL = '0'
	   AND @FieldName <> 'QDThanhLapHoiDongConfirm'
	   AND @FieldName <> 'fileDKDeTai'
	BEGIN
		IF (@TaskDetailType IN ('FILE', 'FILEVIEW'))
		BEGIN
			IF @File_ID IS NULL OR @File_ID = ''
			BEGIN
				INSERT INTO Payload_Error_Log
				(
					Payload,
					ErrorType,
					CreateDate,
					CreateUser
				)
				VALUES
				(	
					@sys_RawData,
					'File',
					GETDATE(),
					@sys_UserID
				)

				SET @MsgError = N'Bạn không được bỏ trống file'
				RAISERROR(@MsgError, 16, 1)

				RETURN 0;
			END
		END
		ELSE
		BEGIN
			IF @Text_Content IS NULL OR @Text_Content = ''
			BEGIN
				INSERT INTO Payload_Error_Log
				(
					Payload,
					ErrorType,
					CreateDate,
					CreateUser
				)
				VALUES
				(	
					@sys_RawData,
					'Text content',
					GETDATE(),
					@sys_UserID
				)

				SET @MsgError = N'Bạn không được bỏ trống nội dung nhập liệu'
				RAISERROR(@MsgError, 16, 1)

				RETURN 0;
			END
		END
	END

	DECLARE @ERRCODE INT;
	DECLARE @err_location varchar(1000);
	set @err_location= '[FlowDetail_UpdateData]-Student[' + cast(@Student_ID as varchar)+']-Process['+cast(@Process_ID as varchar)+']-Task['+ +cast(@Task_ID as varchar) +']-Task_Detail['+cast(@Task_Detail_ID as varchar)+']'; 
	
	DECLARE @Flow_Detail_Status VARCHAR(10)
	IF @sys_GroupID = 1  --/* 1: nhân viên ; 2: sinh viên học viên*/
		SET @Flow_Detail_Status = 'C'
	ELSE
		SET @Flow_Detail_Status = 'P'

	-- Tự động tìm Flow_Detail_ID nếu client không truyền
	IF (@Flow_Detail_ID IS NULL OR @Flow_Detail_ID <= 0)
	BEGIN
		SELECT TOP 1 @Flow_Detail_ID = Flow_Detail_ID
		FROM Flow_Detail WITH (NOLOCK)
		WHERE Flow_ID = @Flow_ID
		  AND Task_ID = @Task_ID
		  AND Task_Detail_ID = @Task_Detail_ID
		  AND use_yn = 1
		ORDER BY Flow_Detail_ID DESC;
	END;

	-- RÀNG BUỘC CHỐNG FILE MA (Phantom File ID Validation):
	-- Chỉ kiểm tra khi có truyền File_ID mới và giá trị này thay đổi so với file đã lưu trước đó trong DB
	IF (NULLIF(LTRIM(RTRIM(@File_ID)), '') IS NOT NULL)
	BEGIN
		DECLARE @ExistingFileID VARCHAR(50) = NULL;

		IF (@Flow_Detail_ID IS NOT NULL AND @Flow_Detail_ID > 0)
		BEGIN
			SELECT @ExistingFileID = File_ID FROM Flow_Detail WHERE Flow_Detail_ID = @Flow_Detail_ID;
		END
		ELSE
		BEGIN
			SELECT TOP 1 @ExistingFileID = File_ID 
			FROM Flow_Detail 
			WHERE Flow_ID = @Flow_ID AND Task_ID = @Task_ID AND Task_Detail_ID = @Task_Detail_ID AND use_yn = 1
			ORDER BY Flow_Detail_ID DESC;
		END;

		-- Nếu File_ID mới khác File_ID cũ thì bắt buộc phải tồn tại trong FileData
		IF (@ExistingFileID IS NULL OR LTRIM(RTRIM(@File_ID)) <> LTRIM(RTRIM(@ExistingFileID)))
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM dbo.FileData WHERE FileID = LTRIM(RTRIM(@File_ID)))
			BEGIN
				DECLARE @TaskDesc NVARCHAR(255);
				SELECT @TaskDesc = Task_Detail_Description FROM Task_Detail WHERE Task_Detail_ID = @Task_Detail_ID;

				INSERT INTO Payload_Error_Log (Payload, ErrorType, CreateDate, CreateUser)
				VALUES (@sys_RawData, 'Phantom File: ' + ISNULL(@File_ID, ''), GETDATE(), @sys_UserID);

				SET @MsgError = N'Mục "' + ISNULL(@TaskDesc, N'Đính kèm') + N'" - File "' + ISNULL(@File_Name, N'') 
					+ N'" (Mã: ' + LTRIM(RTRIM(@File_ID)) + N') chưa được lưu thành công trên máy chủ. Vui lòng chọn và tải lại file!';
				RAISERROR(@MsgError, 16, 1);
				RETURN 0;
			END;
		END;
	END;

	BEGIN TRY  
		BEGIN TRANSACTION;  

		IF (@Flow_Detail_ID IS NOT NULL AND @Flow_Detail_ID > 0)
		BEGIN
			UPDATE Flow_Detail
			   SET 
				  File_URL = @File_URL
				  ,File_Id = @File_ID
				  ,Text_Content = @Text_Content
				  ,File_Name	= @File_Name
				  ,File_Type	= @File_Type
				  ,Flow_Detail_Status = CASE WHEN Flow_Detail_Status = 'C' THEN Flow_Detail_Status ELSE @Flow_Detail_Status END
				  ,Updated_By = @sys_UserID
				  ,Updated_At = getdate()
			 WHERE Flow_Detail_ID = @Flow_Detail_ID;
		END
		ELSE
		BEGIN
			UPDATE Flow_Detail
			   SET 
				  File_URL = @File_URL
				  ,File_Id = @File_ID
				  ,Text_Content = @Text_Content
				  ,File_Name	= @File_Name
				  ,File_Type	= @File_Type
				  ,Flow_Detail_Status = CASE WHEN Flow_Detail_Status = 'C' THEN Flow_Detail_Status ELSE @Flow_Detail_Status END
				  ,Updated_By = @sys_UserID
				  ,Updated_At = getdate()
			 WHERE Flow_ID = @Flow_ID
				  AND Task_ID = @Task_ID
				  AND Task_Detail_ID = @Task_Detail_ID
				  AND use_yn = 1;
		END

		-- Đồng bộ trạng thái Flow để không bị kẹt ở W
		DECLARE @NOW_STATUS varchar(20) = dbo.CheckStatusFlow(
			@Student_ID,
			@Process_ID,
			@Flow_ID,
			@Task_ID,
			0
		);

		IF (@NOW_STATUS <> ' ')
		BEGIN
			UPDATE FLOW
			SET
				FLOW_STATUS = @NOW_STATUS,
				Updated_By = @sys_UserID,
				Updated_At = GETDATE()
			WHERE PROCESS_ID = @Process_ID
			  AND STUDENT_ID = @Student_ID
			  AND FLOW_ID = @Flow_ID
			  AND TASK_ID = @Task_ID
			  AND USE_YN = 1
			  AND FLOW_STATUS <> @NOW_STATUS;
		END

		COMMIT TRANSACTION;
		RETURN 1;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION ;
		SET @ERRCODE = @@ERROR;
		set @err_location= @err_location + ERROR_MESSAGE();
		RAISERROR(@err_location, 16, 1);
		return 0;
	END CATCH
END
