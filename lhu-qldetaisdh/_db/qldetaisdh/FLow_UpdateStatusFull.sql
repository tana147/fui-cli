 
CREATE PROCEDURE [dbo].[FLow_UpdateStatusFull]
	@Student_ID varchar(20),
	@Process_ID int, 
	@IN_Task_ID	int,
	@user_id    varchar(20),
	@Out_Err_code int out,
	@Out_Err_Loc varchar(1000) out
AS
BEGIN 
	set @Out_Err_Loc= 'UPDATE_STATUS-Flow['+ +cast(@Process_ID as varchar) +']-Student[' + cast(@Student_ID as varchar)+']';

	DECLARE @TASK_BEGIN int; 
	DECLARE @TASK_PARENT int;  
	DECLARE @TASK_ID int;
	DECLARE @FLOW_ID int;
	DECLARE @FLOW_PARENT int;
	DECLARE @LV int;
	DECLARE @NOW_STATUS VARCHAR(20); 

	SELECT @TASK_BEGIN= isnull(TASK_BEGIN,-1) FROM PROCESS_STUDENT WHERE Process_ID = @Process_ID AND STUDENT_ID= @Student_ID AND USE_YN=1;

		IF(@TASK_BEGIN <0)
		BEGIN
			set @Out_Err_code =1;
			set @Out_Err_Loc = @Out_Err_Loc + '{PROCESS_STUDENT} Data does not exists!';
			--RAISERROR(@Out_Err_Loc, 16, 1);
			return 0;
		END;

	DECLARE ALL_TASK CURSOR LOCAL FOR
			WITH TREE_TASK AS(
				SELECT TASK_PARENT, F.TASK_ID, 0 lv, FLOW_ID
					FROM FLOW F 
					WHERE  Process_ID = @Process_ID AND STUDENT_ID = @Student_ID AND Task_Parent = @TASK_BEGIN AND USE_YN=1 
				UNION ALL
				SELECT F.TASK_PARENT, F.TASK_ID,  T.lv + 1 lv, F.FLOW_ID
				FROM FLOW F 
				INNER JOIN TREE_TASK T on F.TASK_PARENT = T.TASK_ID
				WHERE  F.use_yn =1
			) 
			SELECT	A.TASK_PARENT,A.TASK_ID, A.LV, A.FLOW_ID
			FROM TREE_TASK A
			ORDER BY LV Desc
			;

	BEGIN TRY  
		set @Out_Err_code=0;
		Open ALL_TASK;
		FETCH NEXT FROM ALL_TASK INTO @TASK_PARENT,@TASK_ID,@LV,@FLOW_ID;
		WHILE @@FETCH_STATUS = 0
		BEGIN 
			--now task
			SET @NOW_STATUS = dbo.CheckStatusFlow(@Student_ID,@Process_ID,@FLOW_ID,@TASK_ID,@TASK_BEGIN);
			set @Out_Err_Loc=@Out_Err_Loc+char(13)+'CheckStatusFlow('+@Student_ID+','+cast(@Process_ID as varchar)+','+cast(@FLOW_ID as varchar)+','+cast(@TASK_ID as varchar)+','+cast(@TASK_BEGIN as varchar)+')='+@NOW_STATUS;
			IF(@NOW_STATUS=' ')
			BEGIN
				set @Out_Err_code =12;
				set @Out_Err_Loc = @Out_Err_Loc + 'Task['+@TASK_ID+']{FLOW} Update Flow Status error !'+'CheckStatusFlow('+@Student_ID+','+cast(@Process_ID as varchar)+','+cast(@FLOW_ID as varchar)+','+cast(@TASK_ID as varchar)+','+cast(@TASK_BEGIN as varchar)+')';				
				break;
			END; 
			UPDATE FLOW SET FLOW_STATUS = @NOW_STATUS, [Updated_By]=@user_id,[Updated_At]=getdate()
			WHERE Process_ID = @Process_ID AND STUDENT_ID = @Student_ID AND FLOW_ID=@FLOW_ID AND Task_ID=@TASK_ID AND USE_YN=1
			; 
			FETCH NEXT FROM ALL_TASK INTO @TASK_PARENT,@TASK_ID,@LV,@FLOW_ID; 
		END

		CLOSE ALL_TASK;
		DEALLOCATE ALL_TASK; 
		if(@Out_Err_code>0)
			return 0;
		--UPDATE STATUS PROCESS STUDENT
		SET @NOW_STATUS = dbo.CheckStatusFlow(@Student_ID,@Process_ID,0,@TASK_BEGIN,@TASK_BEGIN);
		IF(@NOW_STATUS=' ')
		BEGIN
			set @Out_Err_code =30;
			set @Out_Err_Loc = @Out_Err_Loc + '{PROCESS_STATUS} Update Flow Status error !'+'CheckStatusFlow('+@Student_ID+','+cast(@Process_ID as varchar)+',0,'+cast(@TASK_BEGIN as varchar)+','+cast(@TASK_BEGIN as varchar)+')';
			--RAISERROR(@Out_Err_Loc, 16, 1);
			return 0;
		END;   
		UPDATE PROCESS_Student SET Process_Student_Status =@NOW_STATUS, [Updated_By]=@user_id,[Updated_At]=getdate()
		WHERE Process_ID = @Process_ID AND STUDENT_ID= @Student_ID AND USE_YN=1
		;  
		SET @Out_Err_code = 0;
		set @Out_Err_Loc= @Out_Err_Loc+'OK';
		return 1
	END TRY
	BEGIN CATCH
		CLOSE ALL_TASK;
		DEALLOCATE ALL_TASK; 
		SET @Out_Err_code = @@ERROR;
		set @Out_Err_Loc= 'X:' + @Out_Err_Loc;
		--RAISERROR(@Out_Err_Loc, 16, 1);
			return 0;
	END CATCH
END
