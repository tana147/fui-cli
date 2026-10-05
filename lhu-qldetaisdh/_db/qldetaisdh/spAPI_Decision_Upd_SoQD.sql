
 --[spAPI_Decision_Upd_SoQD] 32, '', '7BB60A91AADF42348EB54308229F357D','/FileData/7BB60A91AADF42348EB54308229F357D', '917000226'
 
CREATE PROC [dbo].[spAPI_Decision_Upd_SoQD]
@Decision_ID INT,
@Decision_SoQD NVARCHAR(50),
@Decision_NgayQD VARCHAR(2),
@Decision_ThangQD VARCHAR(2),
@Decision_NamQD VARCHAR(4),
@DecisionFile_ID NVARCHAR(50),
@DecisionFile_Url NVARCHAR(500),
@DecisionFile_Name NVARCHAR(255),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	SET @Decision_SoQD = LTRIM(RTRIM(@Decision_SoQD))

	IF ISNULL(@Decision_SoQD,'') = '' 
	BEGIN
		RAISERROR(N'Số Quyết định không thể bỏ trống', 16, 1)
		RETURN 0;
	END
	
	
	DECLARE @ERRCODE INT;
	DECLARE @err_location varchar(1000);

	DECLARE @Process_id int, @student_id varchar(9), @flow_id int, @task_id int,@task_detail_id int, @Fieldname varchar(50);
	DECLARE @SoQD_Old NVARCHAR(50) 

	DECLARE @Decision_NamQD_Old VARCHAR(10)
	DECLARE @Decision_NganhID_Old INT --NVARCHAR(200)
	SELECT @SoQD_Old = LTRIM(RTRIM(D.Decision_SoQD)), @Decision_NamQD_Old= D.Decision_NamQD, @Decision_NganhID_Old = D.Decision_NganhID
	FROM Decision  D WHERE D.Decision_ID = @Decision_ID

	
	DECLARE cur_student CURSOR LOCAL FOR
		select a.Process_id, a.student_id, a.flow_id, a.task_id ,b.task_detail_id, c.Fieldname  
			from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 and LTRIM(RTRIM(Text_Content)) = @SoQD_Old
						inner join StudentInfo s on s.StudentID = a.Student_ID AND s.NganhID = CAST(@Decision_NganhID_Old AS VARCHAR(10))
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'ThesisConfirmNo'
			where a.use_yn =1;
		BEGIN TRY
			set @ERRCODE=0;
			BEGIN TRANSACTION;  
			Open cur_student;
			FETCH NEXT FROM cur_student INTO @Process_id, @student_id, @flow_id, @task_id,@task_detail_id, @Fieldname;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				set @err_location= '[spAPI_Decision_Upd_SoQD-ThesisConfirmNo]-Student[' + cast(@Student_ID as varchar)+']-Process['+cast(@Process_ID as varchar)+']-Task['+ +cast(@Task_ID as varchar) +']-Task_Detail['+cast(@Task_Detail_ID as varchar)+']'; 
				-- 'ThesisConfirmNo'
					UPDATE Flow_Detail
					SET Flow_Detail.Text_Content = @Decision_SoQD 
						, Flow_Detail.Flow_Detail_Status ='C'
						, Updated_By = @SYS_UserID
						, Updated_At = GETDATE()
						WHERE  Flow_Detail.Text_Content = @SoQD_Old
							and flow_id=@flow_id
							and task_id=@task_id
							and task_detail_id=@task_detail_id
						;
				set @err_location= '[spAPI_Decision_Upd_SoQD-ThesisConfirm]-Student[' + cast(@Student_ID as varchar)+']-Process['+cast(@Process_ID as varchar)+']-Task['+ +cast(@Task_ID as varchar) +']-Task_Detail['+cast(@Task_Detail_ID as varchar)+']'; 
				--'ThesisConfirm'
					UPDATE b
					SET b.Flow_Detail_Status ='C'
						, b.File_ID = @DecisionFile_ID
						, b.File_URL = @DecisionFile_Url
						, b.File_Name = @DecisionFile_Name
						, b.Updated_By = @SYS_UserID
						, b.Updated_At = GETDATE()
						from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
								 inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'ThesisConfirm'
						where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id
							;
				set @err_location= '[spAPI_Decision_Upd_SoQD-FLow_UpdateStatusFull]-Student[' + cast(@Student_ID as varchar)+']-Process['+cast(@Process_ID as varchar)+']-Task['+ +cast(@Task_ID as varchar) +']-Task_Detail['+cast(@Task_Detail_ID as varchar)+']'; 
				exec dbo.FLow_UpdateStatusFull  @Student_ID, @Process_id, 0, @sys_UserID, @ERRCODE  out, @err_location   out;

				FETCH NEXT FROM cur_student INTO @Process_id, @student_id, @flow_id, @task_id,@task_detail_id, @Fieldname;
			END;

			set @err_location= '[spAPI_Decision_Upd_SoQD-Update Decision]-Decision_ID[' + cast(@Decision_ID as varchar)+']'; 
			UPDATE Decision
				SET Decision_SoQD  = @Decision_SoQD
				,	Decision_NgayQD = @Decision_NgayQD
				,	Decision_ThangQD = @Decision_ThangQD
				,	Decision_NamQD =  @Decision_NamQD
				,	DecisionFile_ID  =  @DecisionFile_ID
				,	DecisionFile_Url =  @DecisionFile_Url
				,	DecisionFile_Name = @DecisionFile_Name
				,	Decision_Status = 3
				,	Updated_By	= @SYS_UserID
				,	Updated_At = GETDATE()
				WHERE Decision_ID = @Decision_ID

				INSERT INTO [dbo].[Decision_Detail]([Decision_ID], [DecisionFile_ID], [DecisionFile_Url], [DecisionFile_Name], [Created_By], [Created_At])
				VALUES(@Decision_ID,@DecisionFile_ID,  @DecisionFile_Url, @DecisionFile_Name, @SYS_UserID,GETDATE())
				
			SET @ERRCODE = 0;
			set @err_location= 'OK';
		COMMIT TRANSACTION ;
		CLOSE cur_student;
		DEALLOCATE cur_student; 
	END TRY
	BEGIN CATCH
		CLOSE cur_student;
		DEALLOCATE cur_student; 
		ROLLBACK TRANSACTION ;
		SET @ERRCODE = @@ERROR;
		set @err_location= @err_location +  ERROR_MESSAGE();
		RAISERROR(@err_location, 16, 1);
			return 0;
	END CATCH
END