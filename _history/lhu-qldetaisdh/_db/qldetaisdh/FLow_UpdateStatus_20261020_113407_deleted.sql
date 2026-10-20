 
CREATE PROCEDURE [dbo].[FLow_UpdateStatus]
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
		DECLARE TASK_DETAIL_STATUS CURSOR LOCAL FOR
			WITH TASK_PARENT AS(
				SELECT TASK_PARENT, TASK_ID, FLOW_ID, 0 LV, TASK_REQUIRE, 0 FLOW_PARENT  FROM FLOW WHERE Process_ID = @Process_ID AND STUDENT_ID = @Student_ID AND Task_ID=@IN_Task_ID AND USE_YN=1
				UNION ALL
				SELECT A.TASK_PARENT, A.TASK_ID, A.FLOW_ID, LV+1 LV, A.TASK_REQUIRE, B.FLOW_ID FLOW_PARENT  FROM FLOW A INNER JOIN TASK_PARENT B ON A.TASK_ID = B.TASK_PARENT
				WHERE A.USE_YN=1
			)
			SELECT TASK_PARENT, Task_ID, LV, FLOW_ID, FLOW_PARENT
			FROM TASK_PARENT
			--WHERE TASK_PARENT <> @TASK_BEGIN
			ORDER BY LV
			;
			 
	BEGIN TRY  
			Open TASK_DETAIL_STATUS;
			FETCH NEXT FROM TASK_DETAIL_STATUS INTO @TASK_PARENT,@TASK_ID,@LV,@FLOW_ID,@FLOW_PARENT;
			set @Out_Err_code=0
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF(@LV=0)--last child task
				BEGIN					
					SET @NOW_STATUS = dbo.CheckStatusFlow(@Student_ID,@Process_ID,@FLOW_ID,@TASK_ID,@TASK_BEGIN);
					--set @Out_Err_Loc = @Out_Err_Loc + 'last-child--CheckStatusFlow('+@Student_ID+','+cast(@Process_ID as varchar)+','+cast(@FLOW_ID  as varchar)+','+cast(@TASK_ID as varchar)+','+cast(@TASK_BEGIN as varchar)+')='+@NOW_STATUS;
					IF(@NOW_STATUS=' ')
					BEGIN
						set @Out_Err_code =21;
						set @Out_Err_Loc = @Out_Err_Loc + '{FLOW} Update Flow Status error !'+'CheckStatusFlow('+@Student_ID+','+cast(@Process_ID as varchar)+','+cast(@FLOW_ID  as varchar)+','+cast(@TASK_ID as varchar)+','+cast(@TASK_BEGIN as varchar)+')';
						--CLOSE TASK_BY_TASK;
						--DEALLOCATE TASK_BY_TASK;  
						--RAISERROR(@Out_Err_Loc, 16, 1);
						break;
						--return 0;
					END;	
					UPDATE FLOW SET FLOW_STATUS = @NOW_STATUS, [Updated_By]=@user_id,[Updated_At]=getdate()
					WHERE Process_ID = @Process_ID AND STUDENT_ID = @Student_ID AND FLOW_ID = @FLOW_ID AND Task_ID=@TASK_ID AND USE_YN=1
					;
				END;
				--now task
				if(@TASK_PARENT <> @TASK_BEGIN)
				begin					
					SET @NOW_STATUS = dbo.CheckStatusFlow(@Student_ID,@Process_ID,@FLOW_PARENT,@TASK_PARENT,@TASK_BEGIN);
					--set @Out_Err_Loc = @Out_Err_Loc + 'now task--CheckStatusFlow('+@Student_ID+','+cast(@Process_ID  as varchar)+','+cast(@FLOW_PARENT as varchar)+','+cast(@TASK_PARENT as varchar)+','+cast(@TASK_BEGIN as varchar)+')='+@NOW_STATUS;
					IF(@NOW_STATUS=' ')
					BEGIN
						set @Out_Err_code =22;
						set @Out_Err_Loc = @Out_Err_Loc + '{FLOW} Update Flow Status error !'+'CheckStatusFlow('+@Student_ID+','+cast(@Process_ID  as varchar)+','+cast(@FLOW_PARENT as varchar)+','+cast(@TASK_PARENT as varchar)+','+cast(@TASK_BEGIN as varchar)+')';
						--CLOSE TASK_BY_TASK;
						--DEALLOCATE TASK_BY_TASK;  
						--RAISERROR(@Out_Err_Loc, 16, 1);
						--return 0;
						break;
					END;	
					UPDATE FLOW SET FLOW_STATUS = @NOW_STATUS, [Updated_By]=@user_id,[Updated_At]=getdate()
					WHERE Process_ID = @Process_ID AND STUDENT_ID = @Student_ID AND FLOW_ID = @FLOW_PARENT AND Task_ID=@TASK_PARENT AND USE_YN=1
					;
				end
				FETCH NEXT FROM TASK_DETAIL_STATUS INTO @TASK_PARENT,@TASK_ID,@LV,@FLOW_PARENT;
			END

			CLOSE TASK_DETAIL_STATUS;
			DEALLOCATE TASK_DETAIL_STATUS;
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
		CLOSE TASK_DETAIL_STATUS;
		DEALLOCATE TASK_DETAIL_STATUS;
		SET @Out_Err_code = @@ERROR;
		set @Out_Err_Loc= 'Flow['+ +cast(@Flow_ID as varchar) +']-Student[' + cast(@Student_ID as varchar)+']:' + @Out_Err_Loc;
		--RAISERROR(@Out_Err_Loc, 16, 1);
			return 0;
	END CATCH
END
