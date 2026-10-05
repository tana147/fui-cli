CREATE PROC [dbo].[spAPI_HoiDong_Pub_Diem]
@HoiDong_ID INT
,@Student_ID VARCHAR(9)
,@SYS_UserID VARCHAR(9)
,@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	DECLARE @ERRCODE INT;
	DECLARE @err_location varchar(1000);
	DECLARE @Process_id int, @flow_id int, @task_id int,@task_detail_id int, @Fieldname varchar(50);

	SELECT @Process_id = a.Process_id
			, @flow_id = a.flow_id
			, @task_id = a.task_id 
			, @task_detail_id = b.task_detail_id
	FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 and a.Student_ID = @Student_ID
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMeetingID'
	WHERE a.use_yn =1


	DECLARE @FileMeeting_ID VARCHAR(32)
	DECLARE @FileMeeting_Name NVARCHAR(200)
	DECLARE @FileKiemPhieu_ID VARCHAR(32)
	DECLARE @FileKiemPhieu_Name NVARCHAR(200)
	DECLARE @DiemTB FLOAT = 0.0
	
	SELECT @FileMeeting_ID = FileNhanXetID
		, @FileMeeting_Name = FileNhanXetName
		, @FileKiemPhieu_ID = FileKiemPhieuID
		, @FileKiemPhieu_Name = FileKiemPhieuName
		, @DiemTB = DiemHoiDong
		FROM HoiDong HD WHERE HD.HoiDongID = @HoiDong_ID

	-- 1. Update Task FileMeetingId
	UPDATE b
	SET 
			b.File_ID = @FileMeeting_ID
		, b.File_URL = '/FileData/' + @FileMeeting_ID
		, b.File_Name = @FileMeeting_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMeetingID'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	-- 2. Update Task FileKiemPhieu		
	UPDATE b
	SET 
			b.File_ID = @FileKiemPhieu_ID
		, b.File_URL = '/FileData/' + @FileKiemPhieu_ID
		, b.File_Name = @FileKiemPhieu_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileKiemPhieu'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID

	-- 3. Update Task MarkAVG		
	UPDATE b
	SET 
		  b.Text_Content = @DiemTB
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'MarkAVG'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID

	-- 4. Update Task FileCommentID1, Mark1
	DECLARE @File_ID VARCHAR(32)
	DECLARE @File_Name NVARCHAR(200)
	DECLARE @FileDiem_ID VARCHAR(32)
	DECLARE @FileDiem_Name NVARCHAR(200)
	DECLARE @Diem FLOAT = 0.0

	SELECT @File_ID = TV.FileNhanXetID, @File_Name = TV.FileNhanXetName, @Diem = TV.Diem, @FileDiem_ID = TV.FileDiemID, @FileDiem_Name = TV.FileDiemName
	FROM HoiDongThanhVien TV INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach WHERE CT.Sort = 1 AND TV.Is_Xoa = 0 AND TV.HoiDongID = @HoiDong_ID
	UPDATE b
	SET 
		  b.File_ID = @File_ID
		, b.File_URL = '/FileData/' + @File_ID
		, b.File_Name = @File_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileCommentID1'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID

	UPDATE b
	SET 
		  b.File_ID = @FileDiem_ID
		, b.File_URL = '/FileData/' + @FileDiem_ID
		, b.File_Name = @FileDiem_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMark1'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	UPDATE b
	SET 
		  b.Text_Content = @Diem
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'Mark1'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID

	-- 5. Update Task FileCommentID2, Mark2
	SELECT @File_ID = TV.FileNhanXetID, @File_Name = TV.FileNhanXetName, @Diem = TV.Diem, @FileDiem_ID = TV.FileDiemID, @FileDiem_Name = TV.FileDiemName
	FROM HoiDongThanhVien TV INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach WHERE CT.Sort = 2 AND TV.Is_Xoa = 0 AND TV.HoiDongID = @HoiDong_ID
	UPDATE b
	SET 
		  b.File_ID = @File_ID
		, b.File_URL = '/FileData/' + @File_ID
		, b.File_Name = @File_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileCommentID2'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	UPDATE b
	SET 
		  b.File_ID = @FileDiem_ID
		, b.File_URL = '/FileData/' + @FileDiem_ID
		, b.File_Name = @FileDiem_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMark2'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	UPDATE b
	SET 
		  b.Text_Content = @Diem
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'Mark2'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	-- 6. Update Task FileCommentID3, Mark3
	SELECT @File_ID = TV.FileNhanXetID, @File_Name = TV.FileNhanXetName, @Diem = TV.Diem, @FileDiem_ID = TV.FileDiemID, @FileDiem_Name = TV.FileDiemName
	FROM HoiDongThanhVien TV INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach WHERE CT.Sort = 3 AND TV.Is_Xoa = 0 AND TV.HoiDongID = @HoiDong_ID
	UPDATE b
	SET 
		  b.File_ID = @File_ID
		, b.File_URL = '/FileData/' + @File_ID
		, b.File_Name = @File_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileCommentID3'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	UPDATE b
	SET 
		  b.File_ID = @FileDiem_ID
		, b.File_URL = '/FileData/' + @FileDiem_ID
		, b.File_Name = @FileDiem_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMark3'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	UPDATE b
	SET 
		  b.Text_Content = @Diem
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'Mark3'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	-- 7. Update Task FileCommentID4, Mark4
	SELECT @File_ID = TV.FileNhanXetID, @File_Name = TV.FileNhanXetName, @Diem = TV.Diem, @FileDiem_ID = TV.FileDiemID, @FileDiem_Name = TV.FileDiemName
	FROM HoiDongThanhVien TV INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach WHERE CT.Sort = 4 AND TV.Is_Xoa = 0 AND TV.HoiDongID = @HoiDong_ID
	UPDATE b
	SET 
		  b.File_ID = @File_ID
		, b.File_URL = '/FileData/' + @File_ID
		, b.File_Name = @File_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileCommentID4'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	UPDATE b
	SET 
		  b.File_ID = @FileDiem_ID
		, b.File_URL = '/FileData/' + @FileDiem_ID
		, b.File_Name = @FileDiem_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMark4'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID

	UPDATE b
	SET 
		  b.Text_Content = @Diem
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'Mark4'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
		
	-- 8. Update Task FileCommentID5, Mark5
	SELECT @File_ID = TV.FileNhanXetID, @File_Name = TV.FileNhanXetName, @Diem = TV.Diem, @FileDiem_ID = TV.FileDiemID, @FileDiem_Name = TV.FileDiemName
	FROM HoiDongThanhVien TV INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach WHERE CT.Sort = 5 AND TV.Is_Xoa = 0 AND TV.HoiDongID = @HoiDong_ID
	UPDATE b
	SET 
		  b.File_ID = @File_ID
		, b.File_URL = '/FileData/' + @File_ID
		, b.File_Name = @File_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileCommentID5'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	UPDATE b
	SET 
		  b.File_ID = @FileDiem_ID
		, b.File_URL = '/FileData/' + @FileDiem_ID
		, b.File_Name = @FileDiem_Name
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMark5'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID
	
	UPDATE b
	SET 
		  b.Text_Content = @Diem
		, b.Flow_Detail_Status ='C'
		, b.Updated_By = @SYS_UserID
		, b.Updated_At = GETDATE()
		from flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
					inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'Mark5'
		where a.use_yn =1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id =@task_id and a.Student_ID = @Student_ID

	-- UPDATE IS_PUBLISHDIEM
	UPDATE HoiDongThanhVien 
	SET [Is_PublishDiem]= 1, [Updated_By] = @SYS_UserID, [Updated_At] = GETDATE()
	WHERE HoiDongID = @HoiDong_ID

	UPDATE HoiDong 
	SET [Is_PublishDiem]= 1, [Updated_By] = @SYS_UserID, [Updated_At] = GETDATE()
	WHERE HoiDongID = @HoiDong_ID


		exec dbo.FLow_UpdateStatusFull  @Student_ID, @Process_id, 0, @sys_UserID, @ERRCODE  out, @err_location   out;


END

