CREATE PROC [dbo].[spAPI_HoiDong_Upd_FileScan]
@HoiDongID INT
,@StudentID VARCHAR(9)
,@DiemHoiDongObj NVARCHAR(MAX)
,@HoiDongThanhVienObj_Arr NVARCHAR(MAX)
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

	---- 1. Update file scan vào table HoiDong
	UPDATE [dbo].[HoiDong]
	SET 
		[FileNhanXetID]		=	json.FileNhanXetID
		,[FileNhanXetName]	=	json.FileNhanXetName
		,[FileKiemPhieuID]	=	json.FileKiemPhieuID
		,[FileKiemPhieuName]	=	json.FileKiemPhieuName
		,[Updated_By]		=	@SYS_UserID
		,[Updated_At]		=	GETDATE()
	FROM OPENJSON(@DiemHoiDongObj)
	WITH (
		FileNhanXetID varchar(32),
		FileNhanXetName NVARCHAR(200),
		FileKiemPhieuID varchar(32),
		FileKiemPhieuName NVARCHAR(200)
	) AS json
	WHERE [dbo].[HoiDong].HoiDongID = @HoiDongID

	---- 2. Update file scan vào table HoiDongThanhVien
	UPDATE [dbo].[HoiDongThanhVien]
	SET 
		[FileNhanXetID]		=	json.FileNhanXetID
		,[FileNhanXetName]	=	json.FileNhanXetName
		,[FileDiemID]		=	json.FileDiemID
		,[FileDiemName]		=	json.FileDiemName
		,[Updated_By]		=	@SYS_UserID
		,[Updated_At]		=	GETDATE()
	FROM OPENJSON(@HoiDongThanhVienObj_Arr)
	WITH (
		TVHDID INT,
		FileNhanXetID varchar(32),
		FileNhanXetName NVARCHAR(200),
		FileDiemID varchar(32),
		FileDiemName NVARCHAR(200)
	) AS json
	WHERE [dbo].[HoiDongThanhVien].TVHDID = json.TVHDID

	---- 3. Đồng bộ lại các file scan vào flow_detail (nếu học viên có flow)
	IF (@StudentID IS NOT NULL AND @StudentID != '')
	BEGIN
		DECLARE @Process_id int, @flow_id int, @task_id int;

		SELECT @Process_id = a.Process_id
				, @flow_id = a.flow_id
				, @task_id = a.task_id 
		FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 and a.Student_ID = @StudentID
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMeetingID'
		WHERE a.use_yn = 1

		IF (@flow_id IS NOT NULL)
		BEGIN
			DECLARE @FileMeeting_ID VARCHAR(32)
			DECLARE @FileMeeting_Name NVARCHAR(200)
			DECLARE @FileKiemPhieu_ID VARCHAR(32)
			DECLARE @FileKiemPhieu_Name NVARCHAR(200)
			
			SELECT @FileMeeting_ID = FileNhanXetID
				, @FileMeeting_Name = FileNhanXetName
				, @FileKiemPhieu_ID = FileKiemPhieuID
				, @FileKiemPhieu_Name = FileKiemPhieuName
			FROM HoiDong WHERE HoiDongID = @HoiDongID

			-- 3.1 Update FileMeetingID
			UPDATE b
			SET 
				b.File_ID = @FileMeeting_ID
				, b.File_URL = CASE WHEN @FileMeeting_ID IS NOT NULL AND @FileMeeting_ID != '' THEN '/FileData/' + @FileMeeting_ID ELSE NULL END
				, b.File_Name = @FileMeeting_Name
				, b.Updated_By = @SYS_UserID
				, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMeetingID'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			-- 3.2 Update FileKiemPhieu
			UPDATE b
			SET 
				b.File_ID = @FileKiemPhieu_ID
				, b.File_URL = CASE WHEN @FileKiemPhieu_ID IS NOT NULL AND @FileKiemPhieu_ID != '' THEN '/FileData/' + @FileKiemPhieu_ID ELSE NULL END
				, b.File_Name = @FileKiemPhieu_Name
				, b.Updated_By = @SYS_UserID
				, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileKiemPhieu'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			-- 3.3 Update FileCommentID1..5 và FileMark1..5 cho từng thành viên theo ChucTrach.Sort
			DECLARE @File_ID VARCHAR(32), @File_Name NVARCHAR(200), @FileDiem_ID VARCHAR(32), @FileDiem_Name NVARCHAR(200);

			-- Sort 1
			SELECT @File_ID = TV.FileNhanXetID, @File_Name = TV.FileNhanXetName, @FileDiem_ID = TV.FileDiemID, @FileDiem_Name = TV.FileDiemName
			FROM HoiDongThanhVien TV INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach WHERE CT.Sort = 1 AND TV.Is_Xoa = 0 AND TV.HoiDongID = @HoiDongID

			UPDATE b SET b.File_ID = @File_ID, b.File_URL = CASE WHEN @File_ID IS NOT NULL AND @File_ID != '' THEN '/FileData/' + @File_ID ELSE NULL END, b.File_Name = @File_Name, b.Updated_By = @SYS_UserID, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileCommentID1'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			UPDATE b SET b.File_ID = @FileDiem_ID, b.File_URL = CASE WHEN @FileDiem_ID IS NOT NULL AND @FileDiem_ID != '' THEN '/FileData/' + @FileDiem_ID ELSE NULL END, b.File_Name = @FileDiem_Name, b.Updated_By = @SYS_UserID, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMark1'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			-- Sort 2
			SELECT @File_ID = TV.FileNhanXetID, @File_Name = TV.FileNhanXetName, @FileDiem_ID = TV.FileDiemID, @FileDiem_Name = TV.FileDiemName
			FROM HoiDongThanhVien TV INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach WHERE CT.Sort = 2 AND TV.Is_Xoa = 0 AND TV.HoiDongID = @HoiDongID

			UPDATE b SET b.File_ID = @File_ID, b.File_URL = CASE WHEN @File_ID IS NOT NULL AND @File_ID != '' THEN '/FileData/' + @File_ID ELSE NULL END, b.File_Name = @File_Name, b.Updated_By = @SYS_UserID, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileCommentID2'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			UPDATE b SET b.File_ID = @FileDiem_ID, b.File_URL = CASE WHEN @FileDiem_ID IS NOT NULL AND @FileDiem_ID != '' THEN '/FileData/' + @FileDiem_ID ELSE NULL END, b.File_Name = @FileDiem_Name, b.Updated_By = @SYS_UserID, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMark2'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			-- Sort 3
			SELECT @File_ID = TV.FileNhanXetID, @File_Name = TV.FileNhanXetName, @FileDiem_ID = TV.FileDiemID, @FileDiem_Name = TV.FileDiemName
			FROM HoiDongThanhVien TV INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach WHERE CT.Sort = 3 AND TV.Is_Xoa = 0 AND TV.HoiDongID = @HoiDongID

			UPDATE b SET b.File_ID = @File_ID, b.File_URL = CASE WHEN @File_ID IS NOT NULL AND @File_ID != '' THEN '/FileData/' + @File_ID ELSE NULL END, b.File_Name = @File_Name, b.Updated_By = @SYS_UserID, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileCommentID3'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			UPDATE b SET b.File_ID = @FileDiem_ID, b.File_URL = CASE WHEN @FileDiem_ID IS NOT NULL AND @FileDiem_ID != '' THEN '/FileData/' + @FileDiem_ID ELSE NULL END, b.File_Name = @FileDiem_Name, b.Updated_By = @SYS_UserID, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMark3'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			-- Sort 4
			SELECT @File_ID = TV.FileNhanXetID, @File_Name = TV.FileNhanXetName, @FileDiem_ID = TV.FileDiemID, @FileDiem_Name = TV.FileDiemName
			FROM HoiDongThanhVien TV INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach WHERE CT.Sort = 4 AND TV.Is_Xoa = 0 AND TV.HoiDongID = @HoiDongID

			UPDATE b SET b.File_ID = @File_ID, b.File_URL = CASE WHEN @File_ID IS NOT NULL AND @File_ID != '' THEN '/FileData/' + @File_ID ELSE NULL END, b.File_Name = @File_Name, b.Updated_By = @SYS_UserID, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileCommentID4'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			UPDATE b SET b.File_ID = @FileDiem_ID, b.File_URL = CASE WHEN @FileDiem_ID IS NOT NULL AND @FileDiem_ID != '' THEN '/FileData/' + @FileDiem_ID ELSE NULL END, b.File_Name = @FileDiem_Name, b.Updated_By = @SYS_UserID, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMark4'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			-- Sort 5
			SELECT @File_ID = TV.FileNhanXetID, @File_Name = TV.FileNhanXetName, @FileDiem_ID = TV.FileDiemID, @FileDiem_Name = TV.FileDiemName
			FROM HoiDongThanhVien TV INNER JOIN ChucTrach CT ON TV.ChucTrach = CT.ChucTrach WHERE CT.Sort = 5 AND TV.Is_Xoa = 0 AND TV.HoiDongID = @HoiDongID

			UPDATE b SET b.File_ID = @File_ID, b.File_URL = CASE WHEN @File_ID IS NOT NULL AND @File_ID != '' THEN '/FileData/' + @File_ID ELSE NULL END, b.File_Name = @File_Name, b.Updated_By = @SYS_UserID, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileCommentID5'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID

			UPDATE b SET b.File_ID = @FileDiem_ID, b.File_URL = CASE WHEN @FileDiem_ID IS NOT NULL AND @FileDiem_ID != '' THEN '/FileData/' + @FileDiem_ID ELSE NULL END, b.File_Name = @FileDiem_Name, b.Updated_By = @SYS_UserID, b.Updated_At = GETDATE()
			FROM flow a inner join flow_detail b on a.flow_id = b.flow_id and b.use_yn = 1 
						inner join task_detail c on b.task_detail_id = c.task_detail_id and c.Fieldname = 'FileMark5'
			WHERE a.use_yn = 1 and a.process_id = @Process_id and a.flow_id = @flow_id and a.task_id = @task_id and a.Student_ID = @StudentID
		END
	END
END
