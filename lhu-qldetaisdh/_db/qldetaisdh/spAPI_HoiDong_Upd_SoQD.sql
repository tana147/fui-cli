
 --[spAPI_Decision_Upd_SoQD] 32, '', '7BB60A91AADF42348EB54308229F357D','/FileData/7BB60A91AADF42348EB54308229F357D', '917000226'
 
CREATE PROC [dbo].[spAPI_HoiDong_Upd_SoQD]
@Decision_ID INT,
@Decision_SoQD NVARCHAR(50),
@Decision_NgayQD VARCHAR(2),
@Decision_ThangQD VARCHAR(2),
@Decision_NamQD VARCHAR(4),
@DecisionFile_ID NVARCHAR(50),
@DecisionFile_Url NVARCHAR(500),
@DecisionFile_Name NVARCHAR(255),
@HoiDong_ID INT,
@Student_ID VARCHAR(9),
@SYS_UserID VARCHAR(9),
@sys_GroupID INT,
@sys_SystemRight INT,
@sys_RawData nvarchar(max) -- chứa toàn bộ chuỗi json nguyên thuỷ từ client gửi lên
AS
BEGIN
		--QDThanhLapHoiDongConfirm
		--QDThanhLapHoiDong_No
		--QDThanhLapHoiDong_ThoiGian
		--HoiDongID

		DECLARE @MsgError NVARCHAR(500)
		IF (@sys_SystemRight NOT IN (1,2,3,9))
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END


		DECLARE @ERRCODE INT;
		DECLARE @err_location varchar(1000);
		DECLARE @ThoiGianBaoVe VARCHAR(10);

		SELECT @ThoiGianBaoVe = ThoiGianBaoVe FROM HoiDong WHERE HoiDongID = @HoiDong_ID
		update HoiDong  SET HoiDong_Status = 1  WHERE HoiDongID = @HoiDong_ID

		UPDATE Decision
				SET Decision_SoQD  = @Decision_SoQD
				,	Decision_NgayQD = @Decision_NgayQD
				,	Decision_ThangQD = @Decision_ThangQD
				,	Decision_NamQD = @Decision_NamQD
				,	DecisionFile_ID  = @DecisionFile_ID
				,	DecisionFile_Url = @DecisionFile_Url
				,	DecisionFile_Name = @DecisionFile_Name
				,	Decision_Status = 3
				,	Updated_By	= @SYS_UserID
				,	Updated_At = GETDATE()
				WHERE Decision_ID = @Decision_ID


			DECLARE @Process_id int, @flow_id int, @task_id int,@task_detail_id int, @Fieldname varchar(50);


			--1. Update 'QDThanhLapHoiDongConfirm'
			select @Process_id = a.Process_id
				, @flow_id = a.flow_id
				, @task_id = a.task_id 
				, @task_detail_id = b.task_detail_id
			from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 and a.Student_ID = @Student_ID
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'QDThanhLapHoiDongConfirm'
			where a.use_yn =1

			exec spAPI_FlowDetail_Update_SQD_HoiDong_Data @Student_ID, @Process_id, @flow_id, @task_id, @task_detail_id, @DecisionFile_Url, @Decision_SoQD, @DecisionFile_Name, @DecisionFile_ID, NULL, @sys_UserID, @sys_GroupID, @sys_RawData
			exec spAPI_FlowDetail_UpdateStatus @Student_ID, @Process_id, @flow_id, @task_id, @task_detail_id, 'C', @SYS_UserID, @sys_SystemRight
			
			--2. Update'QDThanhLapHoiDong_No'
			select @Process_id = a.Process_id
				, @flow_id = a.flow_id
				, @task_id = a.task_id 
				, @task_detail_id = b.task_detail_id
			from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 and a.Student_ID = @Student_ID
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'QDThanhLapHoiDong_No'
			where a.use_yn =1
			
			exec spAPI_FlowDetail_Update_SQD_HoiDong_Data 
			@Student_ID, 
			@Process_id, 
			@flow_id, 
			@task_id, 
			@task_detail_id, 
			NULL, 
			@Decision_SoQD, 
			NULL, 
			NULL, 
			NULL, 
			@sys_UserID, 
			@sys_GroupID,
			@sys_RawData

			exec spAPI_FlowDetail_UpdateStatus @Student_ID, @Process_id, @flow_id, @task_id, @task_detail_id, 'C', @SYS_UserID, @sys_SystemRight
	
			--3. Update 'QDThanhLapHoiDong_ThoiGian'
			select @Process_id = a.Process_id
				, @flow_id = a.flow_id
				, @task_id = a.task_id 
				, @task_detail_id = b.task_detail_id
			from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 and a.Student_ID = @Student_ID
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'QDThanhLapHoiDong_ThoiGian'
			where a.use_yn =1

			exec spAPI_FlowDetail_Update_SQD_HoiDong_Data @Student_ID, @Process_id, @flow_id, @task_id, @task_detail_id, NULL, @ThoiGianBaoVe, NULL, NULL, NULL, @sys_UserID, @sys_GroupID, @sys_RawData
			exec spAPI_FlowDetail_UpdateStatus @Student_ID, @Process_id, @flow_id, @task_id, @task_detail_id, 'C', @SYS_UserID, @sys_SystemRight

			
			--4. Update 'HoiDongID'
		
			select @Process_id = a.Process_id
				, @flow_id = a.flow_id
				, @task_id = a.task_id 
				, @task_detail_id = b.task_detail_id
			from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 and a.Student_ID = @Student_ID
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'HoiDongID'
			where a.use_yn =1

			exec spAPI_FlowDetail_Update_SQD_HoiDong_Data @Student_ID, @Process_id, @flow_id, @task_id, @task_detail_id, NULL, @HoiDong_ID, NULL, NULL, NULL, @sys_UserID, @sys_GroupID, @sys_RawData
			exec spAPI_FlowDetail_UpdateStatus @Student_ID, @Process_id, @flow_id, @task_id, @task_detail_id, 'C', @SYS_UserID, @sys_SystemRight

			
END


--select * from HoiDong
--select * from hoi
