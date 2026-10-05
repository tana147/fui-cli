CREATE PROCEDURE [dbo].[spAPI_Process_Student_Ins]
@Process_Action int,
@Student_ID varchar(20),
@Expire_Date date,
@SYS_UserId varchar(50),
@insert_new bit
,@sys_SystemRight INT,
@sys_GroupID INT,
@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	
	IF @Process_Action = 4
	BEGIN
		-- Tiến sĩ (Gán quy trình chính): FunctionRight = 2 (hoặc SystemRight = 9 admin)
		IF (@sys_SystemRight <> 9 AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
		BEGIN
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END
	ELSE IF @Process_Action IN (5, 6)
	BEGIN
		-- Tiến sĩ (Đổi đề tài hoặc Gia hạn): Cho phép NCS chính chủ hoặc Admin/SDH/Học viên
		IF (@sys_SystemRight NOT IN (1, 2, 3, 9) AND ISNULL(@sys_GroupID, 0) <> 2 AND @SYS_UserId <> @Student_ID)
		BEGIN
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END
	ELSE
	BEGIN
		-- Thạc sĩ: giữ như cũ
		IF (@sys_SystemRight NOT IN (2,3,9) AND ISNULL(@sys_GroupID, 0) <> 2)
		BEGIN
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END

	declare @process_student_id int;
	declare @task_begin int;
	DECLARE @ERRCODE INT;
	DECLARE @err_location varchar(1000);

	DECLARE @StudentID VARCHAR(9)
	DECLARE @LopID VARCHAR(9)
	DECLARE @HeDaoTao NVARCHAR(50)
	DECLARE @NienKhoa VARCHAR(10)
	DECLARE @Process_ID INT

	-- Kiểm tra xem có bao nhiều lần đổi/điều chỉnh đề tài rồi (chỉ áp dụng khi tạo yêu cầu đổi đề tài: Action 2 hoặc Action 5)
	IF @Process_Action IN (2, 5)
	BEGIN
		IF (SELECT TOP 1 NganhID FROM StudentInfo WHERE StudentID = @Student_ID) = '106'
			AND (SELECT COUNT(*) FROM Process_Student WHERE Student_ID = @Student_ID AND Process_Student_Status = 'X') > 3
		BEGIN
			SET @MsgError = N'Học viên đã vượt quá 3 lần đổi đề tài'
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
		ELSE IF (SELECT COUNT(*) FROM Process_Student WHERE Student_ID = @Student_ID AND Process_Student_Status = 'X') > 2
		BEGIN
			SET @MsgError = N'Học viên đã vượt quá 2 lần đổi đề tài'
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END

	SELECT TOP 1 @HeDaoTao = S.HeDaoTao, @NienKhoa = S.NienKhoa, @LopID = S.LopID
		FROM StudentInfo S
			WHERE S.StudentID = @Student_ID

	-- Nếu là Tiến sĩ, tự tạo cấu hình lớp với 3 quy trình của Tiến sĩ nếu chưa có
	IF (@Process_Action IN (4, 5, 6) OR @HeDaoTao = 'Phd') AND ISNULL(@LopID, '') <> ''
	BEGIN
		-- 1. Quy trình đào tạo chính Tiến sĩ (Process_ID = 6, Action = 4)
		IF NOT EXISTS (SELECT 1 FROM Process_Class WHERE Lop_ID = @LopID AND Process_ID = 6 AND Process_Action = 4 AND ProcessClassStatus = 0)
		BEGIN
			INSERT INTO Process_Class (Lop_ID, Process_ID, Process_Action, ProcessClassStatus)
			VALUES (@LopID, 6, 4, 0);
		END

		-- 2. Quy trình đổi đề tài Tiến sĩ (Process_ID = 7, Action = 5)
		IF NOT EXISTS (SELECT 1 FROM Process_Class WHERE Lop_ID = @LopID AND Process_ID = 7 AND Process_Action = 5 AND ProcessClassStatus = 0)
		BEGIN
			INSERT INTO Process_Class (Lop_ID, Process_ID, Process_Action, ProcessClassStatus)
			VALUES (@LopID, 7, 5, 0);
		END

		-- 3. Quy trình gia hạn Tiến sĩ (Process_ID = 8, Action = 6)
		IF NOT EXISTS (SELECT 1 FROM Process_Class WHERE Lop_ID = @LopID AND Process_ID = 8 AND Process_Action = 6 AND ProcessClassStatus = 0)
		BEGIN
			INSERT INTO Process_Class (Lop_ID, Process_ID, Process_Action, ProcessClassStatus)
			VALUES (@LopID, 8, 6, 0);
		END
	END

	SET @Process_ID = (SELECT TOP 1 P.Process_ID
						FROM Process_Class P
						WHERE P.Lop_ID = @LopID AND P.Process_Action = @Process_Action
						AND P.ProcessClassStatus = 0 )
    print(@Process_ID)
	IF ISNULL(@Process_ID,'') =''
	BEGIN
		SET @MsgError = N'Bạn chưa cấu hình Process Đổi/Điều chỉnh đề tài cho lớp này'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
		--SET @Process_ID = 1 --DEFAULT
	END

	SET @err_location= 'Process['+ +cast(@Process_ID as varchar) +']-Student[' + cast(@Student_ID as varchar)+']';

	-- Kiểm tra nếu quy trình cùng loại trước đó chưa hoàn tất (chưa complete) thì không cho tạo mới
	IF EXISTS(
		SELECT 1 
		FROM Process_student 
		WHERE Process_ID = @Process_ID 
		  AND Student_id = @Student_ID 
		  AND use_yn = 1 
		  AND Process_Student_Status <> 'C'
	)
	BEGIN
		IF @Process_Action IN (2, 5)
			SET @MsgError = N'Quy trình đổi/điều chỉnh đề tài/GVHD trước đó chưa hoàn tất (chưa duyệt hoàn thành). Không thể tạo quy trình đổi mới!'
		ELSE IF @Process_Action IN (3, 6)
			SET @MsgError = N'Quy trình xin gia hạn thời gian trước đó chưa hoàn tất (chưa duyệt hoàn thành). Không thể tạo quy trình gia hạn mới!'
		ELSE
			SET @MsgError = N'Quy trình đào tạo trước đó chưa hoàn tất. Không thể tạo quy trình mới!'

		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	IF EXISTS(
		SELECT 1 
		FROM Flow 
		WHERE Process_ID = @Process_ID 
		  AND Student_id = @Student_ID 
		  AND use_yn = 1 
		  AND Flow_Status <> 'C'
	)
	BEGIN
		IF @Process_Action IN (2, 5)
			SET @MsgError = N'Các bước trong quy trình đổi đề tài trước đó chưa hoàn thành. Không thể tạo quy trình đổi mới!'
		ELSE IF @Process_Action IN (3, 6)
			SET @MsgError = N'Các bước trong quy trình gia hạn trước đó chưa hoàn thành. Không thể tạo quy trình gia hạn mới!'
		ELSE
			SET @MsgError = N'Các bước trong quy trình trước đó chưa hoàn thành. Không thể tạo quy trình mới!'

		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	if(@insert_new = 1 AND EXISTS(SELECT 1 FROM Process_student WHERE Process_ID=@Process_ID and Student_id =@Student_ID and (Process_Student_Status NOT IN ('C', 'X'))))
	begin
		RAISERROR(N'Student đã được đăng ký trong Proceess', 16, 1);
		return 0;
	end

	BEGIN TRY
		BEGIN TRANSACTION;
		set @err_location = 'Begin Insert Process_student[0]';
		if(@insert_new <> 1)
		begin

			update Process_student
				set use_yn = 0
			 where Process_ID=@Process_ID and Student_id =@Student_ID;

			 update Flow
				set use_yn=0
			where Process_ID=@Process_ID and Student_id =@Student_ID;

			update FLOW_DETAIL
				set use_yn = 0
			where Flow_ID in (select Flow_ID from flow where Process_ID=@Process_ID and Student_id =@Student_ID);

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
				,@SYS_UserId, getdate(),@SYS_UserId, getdate())
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
		SELECT  @process_student_id,@Process_ID,@Student_ID, a.TASK_PARENT, A.TASK_ID,A.SEQ,Task_Require,'W',1
				,@SYS_UserId, getdate(),@SYS_UserId, getdate()
		FROM TREE_TASK A
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
			,@SYS_UserId, getdate(),@SYS_UserId, getdate()
		from flow a inner join Task_detail b on a.task_id = b.task_id AND b.use_yn = 1
		WHERE A.Process_ID = @Process_ID 
			AND A.Student_ID = @Student_ID
			AND A.Process_Student_ID = @process_student_id
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