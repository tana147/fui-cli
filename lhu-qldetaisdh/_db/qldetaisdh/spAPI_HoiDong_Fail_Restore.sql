CREATE PROC [dbo].[spAPI_HoiDong_Fail_Restore]
@StudentID VARCHAR(9),

@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	DECLARE @Process_Student_ID INT
	DECLARE @Flow_ID_DK_BaoVe INT

	-- Lấy Process student ID hiện tại của HV
	SELECT @Process_Student_ID = Process_Stu_ID
	FROM Process_Student
	WHERE Student_ID = @StudentID AND Process_ID IN (1,4) AND Process_Student_Status <> 'X'

	IF (@Process_Student_ID IS NULL)
	BEGIN
		SET @MsgError = N'Không tìm thấy quy trình hợp lệ của học viên ' + @StudentID
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	-- Đăng ký bảo vệ luận văn/đồ án (Task_Description = 'signForDefendThesis')
	SELECT @Flow_ID_DK_BaoVe = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'signForDefendThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	IF (@Flow_ID_DK_BaoVe IS NULL)
	BEGIN
		SET @MsgError = N'Không tìm thấy bước đăng ký bảo vệ của học viên ' + @StudentID
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	-- Kiểm tra xem trong Flow_Detail_Old có dữ liệu lịch sử của bước này không
	IF NOT EXISTS (
		SELECT 1 FROM Flow_Detail_Old 
		WHERE Flow_ID = @Flow_ID_DK_BaoVe 
		  AND (File_URL IS NOT NULL OR (Text_Content IS NOT NULL AND LTRIM(RTRIM(Text_Content)) <> '') OR File_Name IS NOT NULL)
	)
	BEGIN
		SET @MsgError = N'Không tìm thấy dữ liệu bảo vệ chưa đạt để đồng bộ cho học viên ' + @StudentID
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	-- Đồng bộ dữ liệu từ Flow_Detail_Old sang Flow_Detail cho bước Đăng ký bảo vệ
	UPDATE fd
	SET 
		fd.File_URL = fdo.File_URL,
		fd.Text_Content = fdo.Text_Content,
		fd.File_Name = fdo.File_Name,
		fd.File_ID = fdo.File_ID,
		fd.File_Type = fdo.File_Type,
		fd.Flow_Detail_Status = CASE 
			WHEN fdo.File_URL IS NOT NULL OR (fdo.Text_Content IS NOT NULL AND LTRIM(RTRIM(fdo.Text_Content)) <> '') THEN 'C' 
			ELSE fd.Flow_Detail_Status 
		END,
		fd.Updated_By = @SYS_UserID,
		fd.Updated_At = GETDATE()
	FROM Flow_Detail fd
	INNER JOIN (
		SELECT Task_Detail_ID, File_URL, Text_Content, File_Name, File_ID, File_Type,
		       ROW_NUMBER() OVER (PARTITION BY Task_Detail_ID ORDER BY Flow_Detail_Old_ID DESC) AS rn
		FROM Flow_Detail_Old
		WHERE Flow_ID = @Flow_ID_DK_BaoVe
		  AND History_Type = 'SignDefendThesis'
		  AND (File_URL IS NOT NULL OR (Text_Content IS NOT NULL AND LTRIM(RTRIM(Text_Content)) <> '') OR File_Name IS NOT NULL)
	) fdo ON fd.Task_Detail_ID = fdo.Task_Detail_ID AND fdo.rn = 1
	WHERE fd.Flow_ID = @Flow_ID_DK_BaoVe;

	-- Cập nhật trạng thái bước Đăng ký bảo vệ thành 'C' (Complete)
	UPDATE Flow
	SET Flow_Status = 'C',
	    Updated_By = @SYS_UserID,
	    Updated_At = GETDATE()
	WHERE Flow_ID = @Flow_ID_DK_BaoVe;

	SELECT 1 AS Result, N'Đồng bộ dữ liệu thành công' AS Message;
END
