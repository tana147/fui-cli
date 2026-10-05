 -- [spUpdateTaskDetail] 1, 119, 'I', NULL, 'GV0000611'
CREATE PROCEDURE [dbo].[spUpdateTaskDetail]
	@Process_ID int,
	@Task_Detail_ID int,	
	@Action varchar(10),
	@Student_ID varchar(20), -- nếu lấy hết tất cả sinh viên thì truyền NULL, xử lý từng đứa thì truyền mã sv
	@sys_UserID varchar(9)
AS
BEGIN
	DECLARE @TASKBEGIN INT
	DECLARE @TASKID INT
	DECLARE @COUNT INT
	DECLARE @ERRCODE INT;
	DECLARE @err_location varchar(1000);
	SET @err_location= 'Process['+ +cast(@Process_ID as varchar) +']-Task_detail_id[' + cast(@Task_Detail_ID as varchar)+']';
	SELECT @TASKBEGIN = ISNULL(MAX(TASK_BEGIN),-1) 
		FROM PROCESS_STUDENT 
		WHERE Process_ID = @Process_ID  AND USE_YN=1 AND Process_Student_Status <> 'X';

	IF(@Action<>'I' and @Action<>'U' and @Action<>'D') 
	BEGIN
		SET @err_location = @err_location + 'Action['+@Action+'] Data does not exists';
		RAISERROR(@err_location, 16, 1);
		return 0;
	END;

	IF(@TASKBEGIN<0)
	BEGIN
		SET @err_location = @err_location + '[PROCESS_STUDENT] Data does not exists:';
		RAISERROR(@err_location, 16, 1);
		RETURN 0;
	END;

	SELECT @TASKID = ISNULL(MAX(TASK_ID),-1) FROM task_detail WHERE TASK_DETAIL_ID=@Task_Detail_ID;

	IF(@TASKID < 0)
	BEGIN
		SET @err_location = @err_location + '[TASK DETAIL] Data does not exists:';
		RAISERROR(@err_location, 16, 1);
		RETURN 0;
	END;

	WITH TREE_TASK AS(
		select TASK_PARENT, TASK_ID, SEQ, TASK_Require, 0 lv from TASK_TASK where TASK_PARENT = @TASKBEGIN
		union all
		select a.TASK_PARENT, a.TASK_ID, a.SEQ, a.TASK_Require, b.lv + 1 lv
		from TASK_TASK a inner join TREE_TASK b on a.TASK_PARENT = b.TASK_ID
		)
	select @COUNT = COUNT(1) from tree_task WHERE TASK_ID = @TASKID

	IF(@COUNT<=0)
	BEGIN
		set @err_location = @err_location + 'TASK DETAIL No belongs to PROCESS_STUDENT' ;
		RAISERROR(@err_location, 16, 1);
		return 0;
	END;

	DECLARE @CR_STUDENT_ID VARCHAR(20); 
	DECLARE @cr_Process_Stu_ID int;
	DECLARE ALL_STUDENT CURSOR LOCAL FOR
	SELECT STUDENT_ID, Process_Stu_ID 
		 FROM Process_Student 
		 WHERE PROCESS_ID = @Process_ID 
				AND STUDENT_ID = CASE WHEN @Student_ID IS NULL OR @Student_ID ='' OR @Student_ID =' ' THEN STUDENT_ID ELSE @Student_ID END
				AND Process_Student_Status <> 'X';
	BEGIN TRY  
		BEGIN TRANSACTION;  
		OPEN ALL_STUDENT;
		FETCH NEXT FROM ALL_STUDENT INTO @CR_STUDENT_ID, @cr_Process_Stu_ID;
		WHILE @@FETCH_STATUS = 0
		BEGIN 
			IF(@Action='I')
			BEGIN
				--1.insert flow 
				SELECT @COUNT = count(1) 
					FROM Flow 
					WHERE Student_ID = @CR_STUDENT_ID  --em tâm fix
							AND Process_ID = @Process_ID 
							AND Process_Student_ID = @cr_Process_Stu_ID 
							AND Task_ID= @TASKID;

				IF(@count=0)
				BEGIN
					INSERT INTO [dbo].[Flow]([Process_Student_ID],			[Process_ID],				[Student_ID],				[Task_Parent],          [Task_ID],				[Seq],
													[Task_Require],			[use_yn],					[Flow_Status],				[Created_By],		    [Created_At],			[Updated_By]	   ,[Updated_At]
											) 
					SELECT	@cr_Process_Stu_ID process_student_id,			@Process_ID process_id,		@CR_STUDENT_ID student_id,	task_parent,			a.task_id,				b.seq, 
											b.task_require,					1 use_yn,					'W' flow_status,			@sys_UserID created_by, getdate() created_at,	@sys_UserID update_by, getdate() updated_at 
					FROM tasks a 
						INNER JOIN task_task b ON a.task_id = b.task_id
						WHERE a.task_id = @TASKID 
						;
				END;

				--2.insert flow_detail 
				INSERT INTO [dbo].[Flow_Detail]
						   ([Flow_ID],							[Task_ID],							[Task_Detail_ID],			   
							[Flow_Detail_Status],				[use_yn],
							[Created_By],						[Created_At],						[Updated_By],								[Updated_At]
							)  
				SELECT		Flow_id,							b.Task_id,							b.task_detail_ID
							,'W'								, 1
							,@sys_UserID created_by				,getdate() created_at,				@sys_UserID update_by,						getdate() updated_at 
				FROM flow a INNER JOIN Task_detail b ON a.task_id = b.task_id
				WHERE A.Process_ID = @Process_ID 
						AND A.Student_ID = @CR_STUDENT_ID --em Tâm fix 
						AND a.task_id = @TASKID 
						AND b.task_detail_id = @Task_Detail_ID
				;
			END
			ELSE IF(@Action='U')
			BEGIN
				MERGE Flow AS a
				USING (SELECT a.task_id, b.seq, b.task_require
							FROM tasks a INNER JOIN task_task b ON a.task_id = b.task_id
							WHERE a.task_id=@TASKID 
						) b
					ON (a.task_id = b.task_id 
							and a.student_id = @CR_STUDENT_ID 
							and a.process_id = @Process_ID 
							and a.process_student_id = @cr_Process_Stu_ID 
							and a.task_id= @TASKID)
				WHEN MATCHED THEN
						UPDATE
						SET a.seq			= b.seq,
							a.task_require	= b.task_require,
							a.flow_status	= 'W',
							a.Updated_By	= @sys_UserID,
							a.updated_at	= getdate() 
						; 
			END
			ELSE IF(@Action='D')
			BEGIN				
				DELETE FROM flow_detail WHERE task_detail_id = @Task_Detail_ID;
				SELECT @COUNT = count(b.task_detail_id) 
					FROM flow a 
						INNER JOIN flow_detail b ON a.flow_id = b.flow_id AND a.task_id = b.task_id
						WHERE a.student_id = @CR_STUDENT_ID 
							AND a.process_id = @Process_ID 
							AND a.process_student_id = @cr_Process_Stu_ID 
							AND a.task_id= @TASKID
				IF(@COUNT=0)
				BEGIN
					DELETE FROM flow 
					WHERE student_id = @CR_STUDENT_ID 
						AND process_id=@Process_ID 
						AND process_student_id = @cr_Process_Stu_ID 
						AND task_id= @TASKID
					;
				END;
			END;
			FETCH NEXT FROM ALL_STUDENT INTO @CR_STUDENT_ID, @cr_Process_Stu_ID; 
		END

		CLOSE ALL_STUDENT;
		DEALLOCATE ALL_STUDENT; 
		 
		COMMIT TRANSACTION ;
	END TRY
	BEGIN CATCH 
		CLOSE ALL_STUDENT;
		DEALLOCATE ALL_STUDENT; 
		ROLLBACK TRANSACTION ;
		SET @ERRCODE = @@ERROR;
		set @err_location= @err_location + ERROR_MESSAGE();
		RAISERROR(@err_location, 16, 1);
			return 0;
END CATCH
END
