CREATE PROCEDURE [dbo].[spAPI_SDH_StudentChangeThesis]
@Process_ID_Request int, 
@Student_ID varchar(20), 
@LoaiDieuChinh int, -- 1: Đổi tên đề tài, 2: Đổi GVHD, 3: Đổi cả 2
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

	DECLARE @ERRCODE INT;
	DECLARE @err_location varchar(1000);
	
	DECLARE @Process_Stu_ID_Main int;
	DECLARE @Process_Stu_ID_Req int;
	DECLARE @Flow_ID_Req_Submit int;
	
	DECLARE @ThesisNameNew NVARCHAR(500) = NULL;
	DECLARE @ThesisesProf1New NVARCHAR(500) = NULL;
	DECLARE @ThesisesProf2New NVARCHAR(500) = NULL;

	DECLARE @QDFile_URL NVARCHAR(MAX) = NULL;
	DECLARE @QDFile_ID NVARCHAR(200) = NULL;
	DECLARE @QDFile_Name NVARCHAR(500) = NULL;
	DECLARE @QDFile_Type NVARCHAR(100) = NULL;
	DECLARE @QDSoQD NVARCHAR(200) = NULL;

	-- 1. Tìm cây quy trình chính (Process 1 hoặc 4 hoặc 6) đang active
	SELECT TOP 1 @Process_Stu_ID_Main = Process_Stu_ID 
	FROM Process_Student 
	WHERE Student_ID = @Student_ID 
	AND Process_ID IN (1, 4, 6) 
	AND Process_Student_Status NOT IN ('X') 
	AND use_yn = 1 
	ORDER BY Process_Stu_ID DESC;
	
	IF (@Process_Stu_ID_Main IS NULL)
	BEGIN
		RAISERROR(N'Không tìm thấy cây quy trình chính của học viên', 16, 1);
		RETURN 0;
	END

	-- 2. Tìm cây Đơn xin đổi (Process 2 hoặc 5 hoặc 7)
	SELECT TOP 1 @Process_Stu_ID_Req = Process_Stu_ID
	FROM Process_Student
	WHERE Student_ID = @Student_ID
	AND Process_ID = @Process_ID_Request
	AND Process_Student_Status NOT IN ('X')
	AND use_yn = 1
	ORDER BY Process_Stu_ID DESC;
	
	IF (@Process_Stu_ID_Req IS NULL)
	BEGIN
		RAISERROR(N'Không tìm thấy đơn xin đổi hợp lệ của học viên', 16, 1);
		RETURN 0;
	END

	-- Lấy Flow_ID của bước Đơn xin đổi (Task 13, 37, 49)
	SELECT TOP 1 @Flow_ID_Req_Submit = Flow_ID
	FROM Flow
	WHERE Process_Student_ID = @Process_Stu_ID_Req
	AND Task_ID IN (13, 37, 49)
	AND use_yn = 1;

	-- 3. Lấy dữ liệu thay đổi từ bước Sinh viên nộp đơn
	SELECT 
		@ThesisNameNew = MAX(CASE WHEN b.FieldName = 'ThesisNameNew' THEN a.Text_Content END),
		@ThesisesProf1New = MAX(CASE WHEN b.FieldName = 'ThesisesProf1New' THEN a.Text_Content END),
		@ThesisesProf2New = MAX(CASE WHEN b.FieldName = 'ThesisesProf2New' THEN a.Text_Content END)
	FROM Flow_Detail a
	INNER JOIN Task_Detail b ON a.Task_Detail_ID = b.Task_Detail_ID
	WHERE a.Flow_ID = @Flow_ID_Req_Submit AND a.use_yn = 1;

	-- Lấy thông tin Quyết định (File QĐ & Số QĐ) từ bước Duyệt (Task 14, 38, 50)
	SELECT TOP 1
		@QDFile_URL = a.File_URL,
		@QDFile_ID = a.File_ID,
		@QDFile_Name = a.File_Name,
		@QDFile_Type = a.File_Type
	FROM Flow_Detail a
	INNER JOIN Flow f ON a.Flow_ID = f.Flow_ID
	WHERE f.Process_Student_ID = @Process_Stu_ID_Req
	  AND f.Task_ID IN (14, 38, 50)
	  AND a.Task_Detail_ID IN (11, 129, 255)
	  AND a.use_yn = 1
	  AND a.File_URL IS NOT NULL AND RTRIM(LTRIM(a.File_URL)) <> '';

	SELECT TOP 1
		@QDSoQD = a.Text_Content
	FROM Flow_Detail a
	INNER JOIN Flow f ON a.Flow_ID = f.Flow_ID
	WHERE f.Process_Student_ID = @Process_Stu_ID_Req
	  AND f.Task_ID IN (14, 38, 50)
	  AND a.Task_Detail_ID IN (12, 130, 256)
	  AND a.use_yn = 1
	  AND a.Text_Content IS NOT NULL AND RTRIM(LTRIM(a.Text_Content)) <> '';

	BEGIN TRY
		BEGIN TRANSACTION;
		
		set @err_location = 'Update Change Request Status'; 
		
		-- 4. Đảm bảo trạng thái Đơn xin đổi là Hoàn tất ('C')
		UPDATE Process_Student
		SET Process_Student_Status = 'C',
		    Updated_At = GETDATE(),
		    Updated_By = @SYS_UserID
		WHERE Process_Stu_ID = @Process_Stu_ID_Req;
		
		UPDATE Flow
		SET Flow_Status = 'C',
		    Updated_At = GETDATE(),
		    Updated_By = @SYS_UserID
		WHERE Process_Student_ID = @Process_Stu_ID_Req
		  AND Task_ID IN (14, 38, 50); -- Task Duyệt đổi đề tài

		UPDATE Flow_Detail
		SET Flow_Detail_Status = 'C',
		    File_Type = CAST(@LoaiDieuChinh AS VARCHAR(10)),
		    Updated_At = GETDATE(),
		    Updated_By = @SYS_UserID
		WHERE Flow_ID IN (
			SELECT Flow_ID FROM Flow 
			WHERE Process_Student_ID = @Process_Stu_ID_Req AND Task_ID IN (14, 38, 50)
		);

		-- 5. Cập nhật dữ liệu vào cây quy trình chính
		set @err_location = 'Sync Data to Main Process'; 

		-- 5.1 Tên đề tài (Task_Detail_ID: 46, 56, 59, 111, 119, 279)
		IF (@LoaiDieuChinh IN (1, 3) AND @ThesisNameNew IS NOT NULL AND RTRIM(LTRIM(@ThesisNameNew)) <> '')
		BEGIN
			SELECT Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, File_Name, File_Type, File_URL, File_ID
			INTO #TempThesisName
			FROM Flow_Detail
			WHERE Flow_ID IN (SELECT Flow_ID FROM Flow WHERE Process_Student_ID = @Process_Stu_ID_Main AND use_yn = 1)
			AND Task_Detail_ID IN (46, 56, 59, 111, 119, 279)
			AND use_yn = 1;

			-- Fallback: Nếu là Tiến sĩ mà chưa có bản ghi Flow_Detail cho Task_Detail 279 (Task 41)
			IF NOT EXISTS (SELECT 1 FROM #TempThesisName WHERE Task_Detail_ID = 279)
			BEGIN
				INSERT INTO #TempThesisName (Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, File_Name, File_Type, File_URL, File_ID)
				SELECT Flow_ID, Task_ID, 279, 'C', NULL, NULL, NULL, NULL
				FROM Flow
				WHERE Process_Student_ID = @Process_Stu_ID_Main AND Task_ID = 41 AND use_yn = 1;
			END

			UPDATE Flow_Detail
			SET use_yn = 0, Updated_At = GETDATE(), Updated_By = @SYS_UserID
			WHERE Flow_ID IN (SELECT Flow_ID FROM #TempThesisName)
			AND Task_Detail_ID IN (46, 56, 59, 111, 119, 279)
			AND use_yn = 1;

			INSERT INTO Flow_Detail (Flow_ID, Task_ID, Task_Detail_ID, Text_Content, Flow_Detail_Status, use_yn, Created_By, Created_At, Updated_By, Updated_At, File_Name, File_Type, File_URL, File_ID)
			SELECT Flow_ID, Task_ID, Task_Detail_ID, @ThesisNameNew, Flow_Detail_Status, 1, @SYS_UserID, GETDATE(), @SYS_UserID, GETDATE(), File_Name, File_Type, File_URL, File_ID
			FROM #TempThesisName;

			-- Cập nhật tên đề tài cho Hội đồng (nếu đã có Hội đồng)
			UPDATE HoiDong
			SET DeTai = @ThesisNameNew, Updated_By = @SYS_UserID, Updated_At = GETDATE()
			WHERE StudentID = @Student_ID AND KetQuaHoiDong <> 2 AND Is_Xoa = 0;
			
			DROP TABLE #TempThesisName;
		END

		-- 5.2 GVHD chính (Task_Detail_ID: 47, 57, 60, 112, 280)
		IF (@LoaiDieuChinh IN (2, 3) AND @ThesisesProf1New IS NOT NULL AND RTRIM(LTRIM(@ThesisesProf1New)) <> '')
		BEGIN
			SELECT Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, File_Name, File_Type, File_URL, File_ID
			INTO #TempProf1
			FROM Flow_Detail
			WHERE Flow_ID IN (SELECT Flow_ID FROM Flow WHERE Process_Student_ID = @Process_Stu_ID_Main AND use_yn = 1)
			AND Task_Detail_ID IN (47, 57, 60, 112, 280)
			AND use_yn = 1;

			-- Fallback: Nếu là Tiến sĩ mà chưa có bản ghi Flow_Detail cho Task_Detail 280 (Task 41)
			IF NOT EXISTS (SELECT 1 FROM #TempProf1 WHERE Task_Detail_ID = 280)
			BEGIN
				INSERT INTO #TempProf1 (Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, File_Name, File_Type, File_URL, File_ID)
				SELECT Flow_ID, Task_ID, 280, 'C', NULL, NULL, NULL, NULL
				FROM Flow
				WHERE Process_Student_ID = @Process_Stu_ID_Main AND Task_ID = 41 AND use_yn = 1;
			END

			UPDATE Flow_Detail
			SET use_yn = 0, Updated_At = GETDATE(), Updated_By = @SYS_UserID
			WHERE Flow_ID IN (SELECT Flow_ID FROM #TempProf1)
			AND Task_Detail_ID IN (47, 57, 60, 112, 280)
			AND use_yn = 1;

			INSERT INTO Flow_Detail (Flow_ID, Task_ID, Task_Detail_ID, Text_Content, Flow_Detail_Status, use_yn, Created_By, Created_At, Updated_By, Updated_At, File_Name, File_Type, File_URL, File_ID)
			SELECT Flow_ID, Task_ID, Task_Detail_ID, @ThesisesProf1New, Flow_Detail_Status, 1, @SYS_UserID, GETDATE(), @SYS_UserID, GETDATE(), File_Name, File_Type, File_URL, File_ID
			FROM #TempProf1;

			DROP TABLE #TempProf1;
		END

		-- 5.3 GVHD phụ (Task_Detail_ID: 55, 62, 281)
		IF (@LoaiDieuChinh IN (2, 3) AND @ThesisesProf2New IS NOT NULL AND RTRIM(LTRIM(@ThesisesProf2New)) <> '')
		BEGIN
			SELECT Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, File_Name, File_Type, File_URL, File_ID
			INTO #TempProf2
			FROM Flow_Detail
			WHERE Flow_ID IN (SELECT Flow_ID FROM Flow WHERE Process_Student_ID = @Process_Stu_ID_Main AND use_yn = 1)
			AND Task_Detail_ID IN (55, 62, 281)
			AND use_yn = 1;

			-- Fallback: Nếu là Tiến sĩ mà chưa có bản ghi Flow_Detail cho Task_Detail 281 (Task 41)
			IF NOT EXISTS (SELECT 1 FROM #TempProf2 WHERE Task_Detail_ID = 281)
			BEGIN
				INSERT INTO #TempProf2 (Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, File_Name, File_Type, File_URL, File_ID)
				SELECT Flow_ID, Task_ID, 281, 'C', NULL, NULL, NULL, NULL
				FROM Flow
				WHERE Process_Student_ID = @Process_Stu_ID_Main AND Task_ID = 41 AND use_yn = 1;
			END

			UPDATE Flow_Detail
			SET use_yn = 0, Updated_At = GETDATE(), Updated_By = @SYS_UserID
			WHERE Flow_ID IN (SELECT Flow_ID FROM #TempProf2)
			AND Task_Detail_ID IN (55, 62, 281)
			AND use_yn = 1;

			INSERT INTO Flow_Detail (Flow_ID, Task_ID, Task_Detail_ID, Text_Content, Flow_Detail_Status, use_yn, Created_By, Created_At, Updated_By, Updated_At, File_Name, File_Type, File_URL, File_ID)
			SELECT Flow_ID, Task_ID, Task_Detail_ID, @ThesisesProf2New, Flow_Detail_Status, 1, @SYS_UserID, GETDATE(), @SYS_UserID, GETDATE(), File_Name, File_Type, File_URL, File_ID
			FROM #TempProf2;

			DROP TABLE #TempProf2;
		END

		-- 5.4 Cập nhật File Quyết định vào cây chính (Task_Detail_ID: 3, 63, 219)
		IF (@QDFile_URL IS NOT NULL AND RTRIM(LTRIM(@QDFile_URL)) <> '')
		BEGIN
			SELECT Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, Text_Content
			INTO #TempQDFile
			FROM Flow_Detail
			WHERE Flow_ID IN (SELECT Flow_ID FROM Flow WHERE Process_Student_ID = @Process_Stu_ID_Main AND use_yn = 1)
			AND Task_Detail_ID IN (3, 63, 219)
			AND use_yn = 1;

			UPDATE Flow_Detail
			SET use_yn = 0, Updated_At = GETDATE(), Updated_By = @SYS_UserID
			WHERE Flow_ID IN (SELECT Flow_ID FROM #TempQDFile)
			AND Task_Detail_ID IN (3, 63, 219)
			AND use_yn = 1;

			INSERT INTO Flow_Detail (Flow_ID, Task_ID, Task_Detail_ID, Text_Content, Flow_Detail_Status, use_yn, Created_By, Created_At, Updated_By, Updated_At, File_Name, File_Type, File_URL, File_ID)
			SELECT Flow_ID, Task_ID, Task_Detail_ID, Text_Content, Flow_Detail_Status, 1, @SYS_UserID, GETDATE(), @SYS_UserID, GETDATE(), @QDFile_Name, @QDFile_Type, @QDFile_URL, @QDFile_ID
			FROM #TempQDFile;

			DROP TABLE #TempQDFile;
		END

		-- 5.5 Cập nhật Số Quyết định vào cây chính (Task_Detail_ID: 4, 64)
		IF (@QDSoQD IS NOT NULL AND RTRIM(LTRIM(@QDSoQD)) <> '')
		BEGIN
			SELECT Flow_ID, Task_ID, Task_Detail_ID, Flow_Detail_Status, File_Name, File_Type, File_URL, File_ID
			INTO #TempQDNo
			FROM Flow_Detail
			WHERE Flow_ID IN (SELECT Flow_ID FROM Flow WHERE Process_Student_ID = @Process_Stu_ID_Main AND use_yn = 1)
			AND Task_Detail_ID IN (4, 64)
			AND use_yn = 1;

			UPDATE Flow_Detail
			SET use_yn = 0, Updated_At = GETDATE(), Updated_By = @SYS_UserID
			WHERE Flow_ID IN (SELECT Flow_ID FROM #TempQDNo)
			AND Task_Detail_ID IN (4, 64)
			AND use_yn = 1;

			INSERT INTO Flow_Detail (Flow_ID, Task_ID, Task_Detail_ID, Text_Content, Flow_Detail_Status, use_yn, Created_By, Created_At, Updated_By, Updated_At, File_Name, File_Type, File_URL, File_ID)
			SELECT Flow_ID, Task_ID, Task_Detail_ID, @QDSoQD, Flow_Detail_Status, 1, @SYS_UserID, GETDATE(), @SYS_UserID, GETDATE(), File_Name, File_Type, File_URL, File_ID
			FROM #TempQDNo;

			DROP TABLE #TempQDNo;
		END

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @ERRCODE = @@ERROR;
		set @err_location = 'Process[' + CAST(@Process_ID_Request AS varchar) + ']-Student[' + CAST(@Student_ID AS varchar) + ']:' + @err_location + ' Error: ' + ERROR_MESSAGE();
		RAISERROR(@err_location, 16, 1);
		RETURN 0;
	END CATCH
END
