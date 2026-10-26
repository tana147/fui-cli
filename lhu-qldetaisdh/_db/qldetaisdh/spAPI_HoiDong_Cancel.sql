CREATE PROC [dbo].[spAPI_HoiDong_Cancel]
@HoiDong_ID INT,
@Student_ID VARCHAR(9),
@LyDoHuy NVARCHAR(500),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @MsgError NVARCHAR(500);
	IF (@sys_SystemRight NOT IN (1, 2, 3, 9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END;

	-- 1. Soft delete HoiDong và cập nhật Lý do hủy
	UPDATE HoiDong
	SET Is_Xoa = 1,
	    LyDoHuy = CASE 
	                WHEN @LyDoHuy IS NOT NULL AND LTRIM(RTRIM(@LyDoHuy)) <> '' 
	                THEN @LyDoHuy 
	                ELSE LyDoHuy 
	              END,
	    Updated_By = @SYS_UserID,
	    Updated_At = GETDATE()
	WHERE HoiDongID = @HoiDong_ID;

	-- 2. Soft delete các thành viên trong HoiDongThanhVien
	UPDATE HoiDongThanhVien
	SET Is_Xoa = 1,
	    Updated_By = @SYS_UserID,
	    Updated_At = GETDATE()
	WHERE HoiDongID = @HoiDong_ID;

	-- 3. Reset tiến trình bước 6 (reviewThesis / Duyệt luận văn & defendThesis / Bảo vệ)
	DECLARE @ProcessStuID INT;
	DECLARE @ProcessID INT;
	DECLARE @TaskID_Review INT;
	DECLARE @TaskID_Defend INT;
	DECLARE @FlowID_Review INT;
	DECLARE @FlowID_Defend INT;

	SELECT TOP 1 
		@ProcessStuID = Process_Stu_ID,
		@ProcessID = Process_ID
	FROM Process_Student
	WHERE Student_ID = @Student_ID 
	  AND Process_ID IN (1, 4) 
	  AND Process_Student_Status <> 'X'
	ORDER BY Process_Stu_ID DESC;

	IF (@ProcessStuID IS NOT NULL)
	BEGIN
		-- Xác định Task reviewThesis (B6 ThS04 hoặc ThSUD04)
		SELECT @TaskID_Review = Task_ID
		FROM Tasks
		WHERE Task_Description = 'reviewThesis'
		  AND Task_Code = CASE WHEN @ProcessID = 1 THEN 'ThS04' ELSE 'ThSUD04' END;

		-- Xác định Task defendThesis (B7 ThS05 hoặc ThSUD05)
		SELECT @TaskID_Defend = Task_ID
		FROM Tasks
		WHERE Task_Description = 'defendThesis'
		  AND Task_Code = CASE WHEN @ProcessID = 1 THEN 'ThS05' ELSE 'ThSUD05' END;

		-- Lấy Flow_ID
		SELECT @FlowID_Review = Flow_ID FROM Flow WHERE Process_Student_ID = @ProcessStuID AND Task_ID = @TaskID_Review;
		SELECT @FlowID_Defend = Flow_ID FROM Flow WHERE Process_Student_ID = @ProcessStuID AND Task_ID = @TaskID_Defend;

		-- Reset Flow_Detail của bước Review (Duyệt luận văn/hội đồng)
		IF (@FlowID_Review IS NOT NULL)
		BEGIN
			UPDATE Flow_Detail
			SET Text_Content = NULL,
			    File_URL = NULL,
			    File_Name = NULL,
			    File_ID = NULL,
			    Flow_Detail_Status = 'P',
			    Updated_By = @SYS_UserID,
			    Updated_At = GETDATE()
			WHERE Flow_ID = @FlowID_Review
			  AND Task_Detail_ID IN (
			      SELECT Task_Detail_ID FROM Task_Detail 
			      WHERE Task_ID = @TaskID_Review 
			        AND FieldName IN ('QDThanhLapHoiDongConfirm', 'QDThanhLapHoiDong_No', 'QDThanhLapHoiDong_ThoiGian', 'HoiDongID')
			  );

			UPDATE Flow
			SET Flow_Status = 'P',
			    Updated_By = @SYS_UserID,
			    Updated_At = GETDATE()
			WHERE Flow_ID = @FlowID_Review;
		END;

		-- Reset Flow & Flow_Detail của bước Defend (Bảo vệ luận văn)
		IF (@FlowID_Defend IS NOT NULL)
		BEGIN
			UPDATE Flow_Detail
			SET Text_Content = NULL,
			    File_URL = NULL,
			    File_Name = NULL,
			    File_ID = NULL,
			    Flow_Detail_Status = 'W',
			    Updated_By = @SYS_UserID,
			    Updated_At = GETDATE()
			WHERE Flow_ID = @FlowID_Defend;

			UPDATE Flow
			SET Flow_Status = 'W',
			    Updated_By = @SYS_UserID,
			    Updated_At = GETDATE()
			WHERE Flow_ID = @FlowID_Defend;
		END;
	END;

	SELECT 1 AS Success, N'Hủy hội đồng và reset tiến trình thành công' AS Message;
END;
