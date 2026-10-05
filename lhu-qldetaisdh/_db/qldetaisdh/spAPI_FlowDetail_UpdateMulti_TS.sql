CREATE PROCEDURE [dbo].[spAPI_FlowDetail_UpdateMulti_TS]
	@Student_ID VARCHAR(20),
	@Process_ID INT,
	@Flow_ID INT,
	@Task_ID INT,
	@JsonDetails NVARCHAR(MAX),
	@IsApproveAll BIT,
	@sys_UserID VARCHAR(9),
	@sys_GroupID INT,
	@sys_SystemRight INT
AS
BEGIN
	SET NOCOUNT ON;

	IF @IsApproveAll IS NULL
		SET @IsApproveAll = 0;

	DECLARE @ERRCODE INT = 0;
	DECLARE @err_location VARCHAR(1000) = '';
	DECLARE @NOW_STATUS VARCHAR(20) = '';

	-- Parse JSON
	DECLARE @DetailsTable TABLE (
		Task_Detail_ID INT,
		Text_Content NVARCHAR(MAX),
		File_ID VARCHAR(50),
		File_Name NVARCHAR(255),
		File_Type NVARCHAR(50),
		File_URL NVARCHAR(500),
		Flow_Detail_Status VARCHAR(20)
	);

	IF (@JsonDetails IS NOT NULL AND ISJSON(@JsonDetails) = 1)
	BEGIN
		INSERT INTO @DetailsTable (
			Task_Detail_ID, Text_Content, File_ID, File_Name, File_Type, File_URL, Flow_Detail_Status
		)
		SELECT
			Task_Detail_ID, Text_Content, File_ID, File_Name, File_Type, File_URL, Flow_Detail_Status
		FROM OPENJSON(@JsonDetails)
		WITH (
			Task_Detail_ID INT '$.Task_Detail_ID',
			Text_Content NVARCHAR(MAX) '$.Text_Content',
			File_ID VARCHAR(50) '$.File_ID',
			File_Name NVARCHAR(255) '$.File_Name',
			File_Type NVARCHAR(50) '$.File_Type',
			File_URL NVARCHAR(500) '$.File_URL',
			Flow_Detail_Status VARCHAR(20) '$.Flow_Detail_Status'
		);
	END;

	BEGIN TRY
		BEGIN TRANSACTION;

		/* 1. CẬP NHẬT DỮ LIỆU & TRẠNG THÁI HÀNG LOẠT VÀO FLOW_DETAIL */
		IF EXISTS (SELECT 1 FROM @DetailsTable)
		BEGIN
			UPDATE fd
			SET
				fd.Text_Content = dt.Text_Content,
				fd.File_ID = dt.File_ID,
				fd.File_Name = dt.File_Name,
				fd.File_Type = dt.File_Type,
				fd.File_URL = dt.File_URL,
				fd.Flow_Detail_Status = CASE 
					WHEN @IsApproveAll = 1 THEN 'C'
					WHEN dt.Flow_Detail_Status IS NOT NULL AND dt.Flow_Detail_Status <> '' THEN dt.Flow_Detail_Status
					WHEN (dt.File_ID IS NOT NULL AND dt.File_ID <> '') OR (dt.Text_Content IS NOT NULL AND dt.Text_Content <> '') THEN 'C'
					ELSE 'W'
				END,
				fd.Updated_By = @sys_UserID,
				fd.Updated_At = GETDATE()
			FROM FLOW_DETAIL fd
			INNER JOIN @DetailsTable dt ON fd.TASK_DETAIL_ID = dt.Task_Detail_ID
			WHERE fd.FLOW_ID = @Flow_ID AND fd.TASK_ID = @Task_ID;
		END
		ELSE IF (@IsApproveAll = 1)
		BEGIN
			UPDATE FLOW_DETAIL
			SET
				Flow_Detail_Status = 'C',
				Updated_By = @sys_UserID,
				Updated_At = GETDATE()
			WHERE FLOW_ID = @Flow_ID AND TASK_ID = @Task_ID;
		END;

		/* 2. DỌN CACHE P CỦA SDH */
		UPDATE fd
		SET
			fd.FLOW_DETAIL_STATUS = 'W',
			fd.Updated_By = @sys_UserID,
			fd.Updated_At = GETDATE()
		FROM FLOW_DETAIL fd
		INNER JOIN FLOW f ON f.FLOW_ID = fd.FLOW_ID
		INNER JOIN TASK_DETAIL td ON td.TASK_ID = fd.TASK_ID AND td.TASK_DETAIL_ID = fd.TASK_DETAIL_ID
		WHERE fd.FLOW_DETAIL_STATUS = 'P'
		  AND f.STUDENT_ID = @Student_ID
		  AND f.PROCESS_ID = @Process_ID
		  AND f.USE_YN = 1
		  AND f.FLOW_STATUS <> 'C'
		  AND td.USER_INPUT = 'SDH'
		  AND td.USE_YN = 1;

		/* 3. ĐỒNG BỘ TOÀN BỘ CÂY TIẾN TRÌNH */
		SET @ERRCODE = 0;
		SET @err_location = '';

		EXEC dbo.FLow_UpdateStatusFull
			@Student_ID,
			@Process_ID,
			0,
			@sys_UserID,
			@ERRCODE OUT,
			@err_location OUT;

		IF ISNULL(@ERRCODE, 0) <> 0
		BEGIN
			IF NULLIF(@err_location, '') IS NULL
				SET @err_location = 'FLow_UpdateStatusFull failed';
			THROW 50001, @err_location, 1;
		END;

		/* 4. CHỐT TRẠNG THÁI FLOW HIỆN TẠI (KHÔNG AUTO-NEXT BƯỚC TIẾP THEO) */
		SET @NOW_STATUS = dbo.CheckStatusFlow(
			@Student_ID,
			@Process_ID,
			@Flow_ID,
			@Task_ID,
			0
		);

		IF NOT EXISTS
		(
			SELECT 1
			FROM FLOW_DETAIL fd
			INNER JOIN TASK_DETAIL td ON td.TASK_ID = fd.TASK_ID AND td.TASK_DETAIL_ID = fd.TASK_DETAIL_ID
			WHERE fd.FLOW_ID = @Flow_ID
			  AND fd.TASK_ID = @Task_ID
			  AND fd.FLOW_DETAIL_STATUS <> 'C'
			  AND td.USE_YN = 1
		)
		BEGIN
			SET @NOW_STATUS = 'C';
		END;

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
		END;

		COMMIT TRANSACTION;

		SELECT 1 AS Success;
		RETURN 1;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		SET @ERRCODE = ERROR_NUMBER();
		SET @err_location = CONCAT(
			'Procedure: ',
			ISNULL(ERROR_PROCEDURE(), 'spAPI_FlowDetail_UpdateMulti_TS'),
			'; Line: ',
			ERROR_LINE(),
			'; Error: ',
			ERROR_MESSAGE()
		);
		THROW;
	END CATCH;
END;
