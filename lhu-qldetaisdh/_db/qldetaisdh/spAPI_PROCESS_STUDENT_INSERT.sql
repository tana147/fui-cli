
CREATE PROCEDURE [dbo].[spAPI_PROCESS_STUDENT_INSERT]
@Process_ID int, 
@Student_ID varchar(20),  
@Expire_Date date,
@User_Id varchar(50),
@insert_new bit
AS
BEGIN
	declare @process_student_id int; 
	declare @task_begin int;
	DECLARE @ERRCODE INT;
	DECLARE @err_location varchar(1000);
	set @err_location= 'Process['+ +cast(@Process_ID as varchar) +']-Student[' + cast(@Student_ID as varchar)+']';
	
	if(@insert_new = 1 and exists(select 1 from Process_student where Process_ID=@Process_ID and Student_id =@Student_ID and Process_Student_Status <>'STOP'))
	begin
		--RAISERROR(N'Student' + cast(@Student_ID as nvarchar) +N' đã được đăng ký trong Proceess['+cast(@Process_ID as nvarchar)+']', 16, 1);
		RAISERROR(N'Student đã được đăng ký trong Proceess', 16, 1);
		return 0;
	end

	BEGIN TRY	 
		BEGIN TRANSACTION;
		set @err_location = 'Begin Insert Process_student[0]';
		if(@insert_new <> 1)
		begin 
			 
			update Process_student
				set Process_Student_Status ='X', use_yn = 0
			 where Process_ID=@Process_ID and Student_id =@Student_ID
				and Process_Student_Status <>'C';

			 update Flow
				set Flow_Status ='X', use_yn=0
			where Process_ID=@Process_ID and Student_id =@Student_ID
				and FLOW_STATUS <>'C';			

			update FLOW_DETAIL
				set Flow_Detail_Status ='X', use_yn = 0
			where Task_id in(select TASK_ID from flow where Process_ID=@Process_ID and Student_id =@Student_ID and FLOW_STATUS ='X') 
			and Flow_Detail_Status <>'C'
			;

		end
	--Insert process_Student
		select @task_begin=task_begin from process where process_id=@Process_ID;

		INSERT INTO Process_Student
				(Process_ID ,Student_ID --,Student_Name ,Student_ClassID ,Student_DepartmentID ,Student_Major ,Student_Level ,Student_Year
				,Expire_Date ,Expire_Date_1 ,Expire_Date_2 ,Expire_Date_3
				,Process_Student_Status, use_yn, Task_Begin
				,Created_By ,Created_At ,Updated_By ,Updated_At)
			VALUES (@Process_ID, @Student_ID--, @Student_Name ,@Student_ClassID, @Student_DepartmentID, @Student_Major,@Student_Level,@Student_Year
				, @Expire_Date,null,null,null
				,'W',1, @task_begin
				,@User_Id, getdate(),@User_Id, getdate())
		;
		set @err_location = 'Ater Insert Process_student[1]';
		set @process_student_id = @@IDENTITY;		

		set @err_location = 'Begin Insert Flow[2]';
		--Insert FLOW
		with TREE_TASK as(
		select TASK_PARENT, TASK_ID, SEQ, TASK_Require, 0 lv from TASK_TASK where TASK_PARENT = @task_begin
		union all
		select a.TASK_PARENT, a.TASK_ID, a.SEQ, a.TASK_Require, b.lv + 1 lv
		from TASK_TASK a inner join TREE_TASK b on a.TASK_PARENT = b.TASK_ID
		)
		INSERT INTO Flow
				   (Process_Student_ID,Process_ID,Student_Id,TASK_PARENT, TASK_ID, Seq,Task_Require,Flow_Status,use_yn
				   ,Created_By,Created_At,Updated_By  ,Updated_At) 
		select  @process_student_id,@Process_ID,@Student_ID, a.TASK_PARENT, A.TASK_ID,A.SEQ,Task_Require,'W',1
				,@User_Id, getdate(),@User_Id, getdate()
		from TREE_TASK A
			 ;
		set @err_location = 'Begin Insert Flow_Detail[3]';
		--Insert Flow_Detail
		INSERT INTO Flow_Detail
			   (Flow_ID,Task_ID,Task_Detail_id
			   --,[File_Content],[Text_Content],[File_Name],[File_Type]
			   ,Flow_Detail_Status,use_yn
			   ,Created_By,Created_At,Updated_By,Updated_At) 
		select Flow_id, b.Task_id, b.task_detail_ID
			,'W', 1
			,@User_Id, getdate(),@User_Id, getdate()
		from flow a inner join Task_detail b on a.task_id = b.task_id
		WHERE A.Process_ID=@Process_ID AND A.Student_ID=@Student_ID
			;
		set @err_location = 'After Insert Flow_Detail[4]';
		COMMIT TRANSACTION ;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION ;
		SET @ERRCODE = @@ERROR;
		set @err_location= 'Process['+ +cast(@Process_ID as varchar) +']-Student[' + cast(@Student_ID as varchar)+']:' + @err_location;
		RAISERROR(@err_location, 16, 1);
			return 0;
	END CATCH
END
