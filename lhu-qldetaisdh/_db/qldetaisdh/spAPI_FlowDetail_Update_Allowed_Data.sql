 --[dbo].[spAPI_FlowDetail_UpdateData] '923000167', 1, 21601, 18, 56, NULL, N'Nâng cao công tác quản lý tài chính tại Bộ Tư lệnh TP. Hồ Chí Minh.', NULL, NULL, NULL, '923000167', 1
 -- [dbo].[spAPI_FlowDetail_UpdateData] '917000226', 1, 25, 2, 47, N'TS HUỲNH CAO TUẤN', NULL, NULL
CREATE PROCEDURE [dbo].[spAPI_FlowDetail_Update_Allowed_Data]
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
	DECLARE @Ten_DeTai_BaoVe_ID INT = 119

	IF  (@Task_Detail_ID <> @Ten_DeTai_BaoVe_ID)
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ khác ngoài link dữ liệu tên đề tài bảo vệ'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	SELECT @AllowNULL = td.AllowNull, @TaskDetailType = td.Task_Detail_Type, @FieldName = td.FieldName
	FROM Task_Detail td
	WHERE td.Task_Detail_ID = @Task_Detail_ID

	IF @AllowNULL = '0' AND @FieldName <> 'QDThanhLapHoiDongConfirm'
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

	PRINT @Flow_Detail_Status

	BEGIN TRY  
		BEGIN TRANSACTION;  

		SELECT 1
		FROM Flow WITH (UPDLOCK, HOLDLOCK)
		WHERE Flow_ID = @Flow_ID
			AND Task_ID = @Task_ID
			AND Student_ID = @Student_ID
			AND Process_ID = @Process_ID
			AND use_yn = 1;
		
		IF(not exists(select 1 from PROCESS_STUDENT WHERE Process_ID = @Process_ID AND STUDENT_ID= @Student_ID AND USE_YN=1))
		BEGIN
			set @err_location = @err_location + '[PROCESS_STUDENT] Data does not exists' ;
			RAISERROR(@err_location, 16, 1);
			return 0;
		END;
		 
	
		if(not exists(SELECT 1 FROM FLOW_DETAIL WHERE FLOW_ID = @FLOW_ID AND TASK_ID = @TASK_ID AND TASK_DETAIL_ID = @TASK_DETAIL_ID AND USE_YN =1))
		BEGIN
			set @err_location = @err_location + '[FLOW_DETAIL] Data does not exists' ;
			RAISERROR(@err_location , 16, 1);
			return 0;
		END	  

		UPDATE Flow_Detail
		   SET 
			  File_URL = @File_URL
			  ,File_Id = @File_ID
			  ,Text_Content = @Text_Content
			  ,File_Name	= @File_Name
			  ,File_Type	= @File_Type
			  --,Flow_Detail_Status = @Flow_Detail_Status
			  --,Flow_Detail_Status = CASE WHEN @sys_GroupID = 2 THEN 'P' else  Flow_Detail_Status end
			  ,Flow_Detail_Status = CASE WHEN Flow_Detail_Status = 'C' THEN Flow_Detail_Status else 'P' end
			  ,Updated_By = @sys_UserID
			  ,Updated_At = getdate()
		 WHERE Flow_ID = @Flow_ID
			  and Task_ID = @Task_ID
			  and Task_Detail_ID = @Task_Detail_ID
			  and use_yn = 1
			  ;

		IF NOT EXISTS (
			SELECT 1
			FROM Flow_Detail WITH (UPDLOCK, HOLDLOCK)
			WHERE Flow_ID = @Flow_ID
			AND Task_ID = @Task_ID
			AND use_yn = 1
			AND Flow_Detail_Status <> 'P'
		)
		BEGIN
		UPDATE Flow
		   SET  
			   --Flow_Status =CASE WHEN @sys_GroupID = 2 THEN 'P' else  Flow_Status end
			   Flow_Status = 'P'
			  ,Updated_By = @sys_UserID
			  ,Updated_At = getdate()
		 WHERE Flow_ID = @Flow_ID
			  and Task_ID = @Task_ID
			  and Student_ID= @Student_ID
			  and Process_ID = @Process_ID
			  and use_yn = 1
			  ;
		END
		 
		COMMIT TRANSACTION ;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION ;
		SET @ERRCODE = @@ERROR;
		set @err_location= @err_location + ERROR_MESSAGE();
		RAISERROR(@err_location, 16, 1);
			return 0;
END CATCH
END
