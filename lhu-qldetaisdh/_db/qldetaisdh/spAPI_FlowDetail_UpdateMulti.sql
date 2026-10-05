CREATE PROCEDURE [dbo].[spAPI_FlowDetail_UpdateMulti]
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

	--IF (@sys_SystemRight NOT IN (1, 2, 3, 9))
	--BEGIN
	--	RAISERROR(N'Bạn không có quyền thực hiện tác vụ này', 16, 1);
	--	RETURN 0;
	--END

	IF @IsApproveAll IS NULL
		SET @IsApproveAll = 0;

	DECLARE @ERRCODE INT = 0;
	DECLARE @err_location VARCHAR(1000) = '';

	DECLARE @task_parent INT;
	DECLARE @last_task_id INT = 0;
	DECLARE @last_flow_id INT = 0;
	DECLARE @last_task_detail_id INT = 0;
	DECLARE @NOW_STATUS VARCHAR(20) = '';

	SELECT @task_parent = task_begin
	FROM process
	WHERE process_id = @Process_ID;

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
	END

	-- RÀNG BUỘC CHỐNG FILE MA CHO HÀNG LOẠT (Chỉ kiểm tra khi File_ID mới thay đổi so với DB)
	DECLARE @ErrTaskSeq INT;
	DECLARE @ErrTaskDesc NVARCHAR(255);
	DECLARE @ErrFileName NVARCHAR(255);
	DECLARE @ErrFileID VARCHAR(50);

	SELECT TOP 1 
		@ErrTaskSeq = td.Task_Detail_Seq,
		@ErrTaskDesc = td.Task_Detail_Description,
		@ErrFileName = dt.File_Name,
		@ErrFileID = dt.File_ID
	FROM @DetailsTable dt
	LEFT JOIN Flow_Detail fd ON dt.Task_Detail_ID = fd.Task_Detail_ID AND fd.Flow_ID = @Flow_ID AND fd.use_yn = 1
	LEFT JOIN Task_Detail td ON dt.Task_Detail_ID = td.Task_Detail_ID
	WHERE NULLIF(LTRIM(RTRIM(dt.File_ID)), '') IS NOT NULL
	  AND (@IsApproveAll = 0 OR dt.File_ID IS NOT NULL)
	  AND (fd.File_ID IS NULL OR LTRIM(RTRIM(dt.File_ID)) <> LTRIM(RTRIM(fd.File_ID)))
	  AND NOT EXISTS (
		  SELECT 1 FROM dbo.FileData f WHERE f.FileID = LTRIM(RTRIM(dt.File_ID))
	  );

	IF (@ErrFileID IS NOT NULL)
	BEGIN
		SET @err_location = N'Lỗi tại mục ' + CAST(ISNULL(@ErrTaskSeq, 0) AS NVARCHAR(10)) 
			+ N' ("' + ISNULL(@ErrTaskDesc, N'') + N'"): File "' + ISNULL(@ErrFileName, N'') 
			+ N'" (Mã: ' + @ErrFileID + N') chưa được lưu thành công trên máy chủ. Vui lòng chọn và tải lại file này!';
		RAISERROR(@err_location, 16, 1);
		RETURN 0;
	END;

	BEGIN TRY
		BEGIN TRANSACTION;

		/* 1. CẬP NHẬT DỮ LIỆU & TRẠNG THÁI HÀNG LOẠT VÀO FLOW_DETAIL */
		IF EXISTS (SELECT 1 FROM @DetailsTable)
		BEGIN
			UPDATE fd
			SET
				fd.Text_Content = CASE 
					WHEN @IsApproveAll = 1 AND dt.Text_Content IS NULL THEN fd.Text_Content 
					ELSE dt.Text_Content 
				END,
				fd.File_ID = CASE 
					WHEN @IsApproveAll = 1 AND (dt.File_ID IS NULL OR dt.File_ID = '') THEN fd.File_ID 
					ELSE dt.File_ID 
				END,
				fd.File_Name = CASE 
					WHEN @IsApproveAll = 1 AND (dt.File_Name IS NULL OR dt.File_Name = '') THEN fd.File_Name 
					ELSE dt.File_Name 
				END,
				fd.File_Type = CASE 
					WHEN @IsApproveAll = 1 AND (dt.File_Type IS NULL OR dt.File_Type = '') THEN fd.File_Type 
					ELSE dt.File_Type 
				END,
				fd.File_URL = CASE 
					WHEN @IsApproveAll = 1 AND (dt.File_URL IS NULL OR dt.File_URL = '') THEN fd.File_URL 
					ELSE dt.File_URL 
				END,
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
			-- Nếu không truyền chi tiết nhưng IsApproveAll = 1, duyệt tất cả các task detail của flow này
			UPDATE FLOW_DETAIL
			SET
				Flow_Detail_Status = 'C',
				Updated_By = @sys_UserID,
				Updated_At = GETDATE()
			WHERE FLOW_ID = @Flow_ID AND TASK_ID = @Task_ID;
		END

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

		/* 4. TÌM TASK CHƯA HOÀN THÀNH ĐẦU TIÊN ĐỂ AUTO-NEXT */
		SET @last_task_id = 0;
		SET @last_flow_id = 0;
		SET @last_task_detail_id = 0;

		;WITH TREE_TASK AS (
			SELECT
				F.TASK_PARENT,
				F.TASK_ID,
				0 AS lv,
				F.FLOW_ID,
				F.FLOW_STATUS,
				F.SEQ,
				CAST(F.SEQ * 100000 AS bigint) AS X_SEQ
			FROM FLOW F
			WHERE F.STUDENT_ID = @Student_ID
			  AND F.PROCESS_ID = @Process_ID
			  AND F.TASK_PARENT = @task_parent
			  AND F.USE_YN = 1

			UNION ALL

			SELECT
				F.TASK_PARENT,
				F.TASK_ID,
				T.lv + 1 AS lv,
				F.FLOW_ID,
				F.FLOW_STATUS,
				F.SEQ,
				CAST(
					T.X_SEQ + F.SEQ * 100000 / ((T.lv + 1) * 10)
					AS bigint
				) AS X_SEQ
			FROM FLOW F
			INNER JOIN TREE_TASK T ON F.TASK_PARENT = T.TASK_ID
			WHERE F.STUDENT_ID = @Student_ID
			  AND F.PROCESS_ID = @Process_ID
			  AND F.USE_YN = 1
		)
		SELECT TOP 1
			@last_task_id = TASK_ID,
			@last_flow_id = FLOW_ID
		FROM TREE_TASK
		WHERE FLOW_STATUS <> 'C'
		ORDER BY X_SEQ ASC
		OPTION (MAXRECURSION 100);

		/* 5. AUTO-NEXT DETAIL ĐẦU TIÊN CỦA STEP TIẾP THEO */
		IF (@last_task_id > 0 AND @last_flow_id > 0)
		BEGIN
			SELECT TOP 1
				@last_task_detail_id = fd.TASK_DETAIL_ID
			FROM FLOW_DETAIL fd
			INNER JOIN TASK_DETAIL td ON td.TASK_ID = fd.TASK_ID AND td.TASK_DETAIL_ID = fd.TASK_DETAIL_ID
			WHERE fd.FLOW_ID = @last_flow_id
			  AND fd.TASK_ID = @last_task_id
			  AND fd.FLOW_DETAIL_STATUS <> 'C'
			  AND td.USE_YN = 1
			ORDER BY td.TASK_DETAIL_SEQ ASC;

			IF (@last_task_detail_id > 0)
			BEGIN
				UPDATE FLOW_DETAIL
				SET
					FLOW_DETAIL_STATUS = 'P',
					Updated_By = 'auto_next_nckh',
					Updated_At = GETDATE()
				WHERE FLOW_ID = @last_flow_id
				  AND TASK_ID = @last_task_id
				  AND TASK_DETAIL_ID = @last_task_detail_id
				  AND FLOW_DETAIL_STATUS = 'W';
			END;

			SET @NOW_STATUS = dbo.CheckStatusFlow(
				@Student_ID,
				@Process_ID,
				@last_flow_id,
				@last_task_id,
				0
			);

			IF (@NOW_STATUS <> ' ')
			BEGIN
				UPDATE FLOW
				SET
					FLOW_STATUS = @NOW_STATUS,
					Updated_By = 'auto_next_nckh',
					Updated_At = GETDATE()
				WHERE PROCESS_ID = @Process_ID
				  AND STUDENT_ID = @Student_ID
				  AND FLOW_ID = @last_flow_id
				  AND TASK_ID = @last_task_id
				  AND USE_YN = 1
				  AND FLOW_STATUS <> @NOW_STATUS;
			END;
		END;

		/* 6. ĐỒNG BỘ LẠI TOÀN BỘ CÂY SAU AUTO-NEXT */
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
			THROW 50002, @err_location, 1;
		END;

		/* 7. CHỐT TRẠNG THÁI FLOW HIỆN TẠI */
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
			ISNULL(ERROR_PROCEDURE(), 'spAPI_FlowDetail_UpdateMulti'),
			'; Line: ',
			ERROR_LINE(),
			'; Error: ',
			ERROR_MESSAGE()
		);
		THROW;
	END CATCH;
END;
