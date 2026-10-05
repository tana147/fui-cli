
CREATE PROCEDURE [dbo].[spAPI_FlowDetail_UpdateStatus]
	@Student_ID varchar(20),
	@Process_ID int,
	@Flow_ID int,
	@Task_ID int,
	@Task_Detail_ID int,
	@Flow_Detail_Status varchar(20),
	@sys_UserID varchar(9),
	@sys_SystemRight int
AS
BEGIN
	SET NOCOUNT ON;

	IF (@sys_SystemRight NOT IN (1, 2, 3, 9))
		RETURN 0;

	DECLARE @ERRCODE int = 0;
	DECLARE @err_location varchar(1000) = '';

	DECLARE @task_parent int;
	DECLARE @last_task_id int = 0;
	DECLARE @last_flow_id int = 0;
	DECLARE @last_task_detail_id int = 0;

	DECLARE @NOW_STATUS varchar(20) = '';

	SELECT @task_parent = task_begin
	FROM process
	WHERE process_id = @Process_ID;

	BEGIN TRY
		BEGIN TRANSACTION;

		/* 1. CẬP NHẬT DETAIL HIỆN TẠI */
		UPDATE FLOW_DETAIL
		SET
			FLOW_DETAIL_STATUS = @Flow_Detail_Status,
			Updated_By = @sys_UserID,
			Updated_At = GETDATE()
		WHERE FLOW_ID = @Flow_ID
		  AND TASK_ID = @Task_ID
		  AND (
				@Task_Detail_ID IS NULL
				OR @Task_Detail_ID = 0
				OR TASK_DETAIL_ID = @Task_Detail_ID
		  );

		/* 2. DỌN CACHE P CỦA SDH */
		UPDATE fd
		SET
			fd.FLOW_DETAIL_STATUS = 'W',
			fd.Updated_By = @sys_UserID,
			fd.Updated_At = GETDATE()
		FROM FLOW_DETAIL fd
		INNER JOIN FLOW f
			ON f.FLOW_ID = fd.FLOW_ID
		INNER JOIN TASK_DETAIL td
			ON td.TASK_ID = fd.TASK_ID
			AND td.TASK_DETAIL_ID = fd.TASK_DETAIL_ID
		WHERE fd.FLOW_DETAIL_STATUS = 'P'
		  AND f.STUDENT_ID = @Student_ID
		  AND f.PROCESS_ID = @Process_ID
		  AND f.USE_YN = 1
		  AND f.FLOW_STATUS <> 'C'
		  AND td.USER_INPUT = 'SDH'
		  AND td.USE_YN = 1;

		/*
			3. ĐỒNG BỘ TRẠNG THÁI TRƯỚC KHI TÌM STEP TIẾP THEO

			Root cause:
			Step 1 vẫn đang có FLOW_STATUS khác C tại thời điểm tìm task tiếp theo.
			Do đó query tiếp tục lấy Step 1 thay vì Step 2.
		*/
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

		/* 4. TÌM TASK CHƯA HOÀN THÀNH ĐẦU TIÊN */
		SET @last_task_id = 0;
		SET @last_flow_id = 0;
		SET @last_task_detail_id = 0;

		;WITH TREE_TASK AS
		(
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
					T.X_SEQ
					+ F.SEQ * 100000 / ((T.lv + 1) * 10)
					AS bigint
				) AS X_SEQ
			FROM FLOW F
			INNER JOIN TREE_TASK T
				ON F.TASK_PARENT = T.TASK_ID
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
			INNER JOIN TASK_DETAIL td
				ON td.TASK_ID = fd.TASK_ID
				AND td.TASK_DETAIL_ID = fd.TASK_DETAIL_ID
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

		/*
			Nếu tất cả detail active đã hoàn tất thì ép FLOW thành C.
			Các TASK_DETAIL có USE_YN = 0 không được tính.
		*/
		IF NOT EXISTS
		(
			SELECT 1
			FROM FLOW_DETAIL fd
			INNER JOIN TASK_DETAIL td
				ON td.TASK_ID = fd.TASK_ID
				AND td.TASK_DETAIL_ID = fd.TASK_DETAIL_ID
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

		RETURN 1;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		SET @ERRCODE = ERROR_NUMBER();

		SET @err_location = CONCAT(
			'Procedure: ',
			ISNULL(ERROR_PROCEDURE(), 'spAPI_FlowDetail_UpdateStatus'),
			'; Line: ',
			ERROR_LINE(),
			'; Error: ',
			ERROR_MESSAGE()
		);

		THROW;
	END CATCH;
END;
