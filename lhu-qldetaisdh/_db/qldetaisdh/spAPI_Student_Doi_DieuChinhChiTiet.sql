CREATE PROC [dbo].[spAPI_Student_Doi_DieuChinhChiTiet]
	@Student_ID INT,
	@Process_ID INT 
AS
BEGIN
	-- Các biến cần dùng trong vòng lặp
	DECLARE @ProcessStudentID INT
	DECLARE @FlowID INT
	DECLARE @FlowID_GVHD INT
	DECLARE @Task_Detail_ID INT

	-- Task IDs và TaskDetail IDs
	DECLARE @TaskID_DeCuong_NghienCuu INT = 2
	DECLARE @TaskID_DeCuong_UngDung INT = 20
	DECLARE @TaskID_GVHD_NghienCuu INT = 34
	DECLARE @TaskID_GVHD_UngDung INT = 35
	DECLARE @TaskDetailID_GVHD1_NghienCuu INT = 47
	DECLARE @TaskDetailID_GVHD1_UngDung INT = 60
	DECLARE @TaskDetailID_GVHD2_NghienCuu INT = 55
	DECLARE @TaskDetailID_GVHD2_UngDung INT = 62

	-- Bảng output kết quả cuối
	DECLARE @OutputTable TABLE (
		StudentID VARCHAR(9),
		HoSV NVARCHAR(50),
		TenSV NVARCHAR(30),
		NienKhoa VARCHAR(9),
		LopID VARCHAR(9),
		TenNganh NVARCHAR(50),
		TenDeTai NVARCHAR(MAX),
		GVHD1 NVARCHAR(MAX),
		GVHD2 NVARCHAR(MAX)
	)

	-- CURSOR duyệt từng dòng Process_Student
	DECLARE process_cursor CURSOR FOR
	SELECT ps.Process_Stu_ID
	FROM Process_Student ps
	WHERE ps.Student_ID = @Student_ID AND ps.Process_Student_Status = 'X' AND ps.use_yn = 0

	OPEN process_cursor
	FETCH NEXT FROM process_cursor INTO @ProcessStudentID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- TempTable để chứa kết quả spAPI_Get_RootFlow
		DECLARE @TempTable TABLE (
			Process_ID INT,
			Student_ID VARCHAR(20),
			Parent_Task_ID INT,
			Children_Task_ID INT,
			Task_Name NVARCHAR(500),
			Task_Description NVARCHAR(MAX),
			Seq INT,
			Task_Require INT,
			LV INT,
			Flow_Status VARCHAR(20),
			Flow_ID INT,
			Lock_Status INT
		)

		INSERT INTO @TempTable
		EXEC spAPI_Get_RootFlow @Student_ID, @ProcessStudentID, 1

		SELECT @FlowID = Flow_ID
		FROM @TempTable
		WHERE Children_Task_ID IN (@TaskID_DeCuong_NghienCuu, @TaskID_DeCuong_UngDung)

		SELECT @FlowID_GVHD = Flow_ID
		FROM @TempTable
		WHERE Children_Task_ID IN (@TaskID_GVHD_NghienCuu, @TaskID_GVHD_UngDung)

		SELECT @Task_Detail_ID = td.Task_Detail_ID
		FROM Task_Detail td
		WHERE td.FieldName = 'ThesisName' 
			AND (
				(@Process_ID = 1 AND td.Task_ID = @TaskID_DeCuong_NghienCuu) OR
				(@Process_ID = 4 AND td.Task_ID = @TaskID_DeCuong_UngDung)
			)
			AND td.USE_YN = 1 

		-- TempFlowDetailTable để chứa kết quả chi tiết
		DECLARE @TempFlowDetailTable TABLE (
			Flow_Detail_ID INT,
			Flow_ID INT,
			Task_ID INT,
			Task_Detail_Seq INT,
			Task_Detail_ID INT,
			Task_Detail_Description NVARCHAR(MAX),
			Task_Detail_Type NVARCHAR(500),
			File_URL NVARCHAR(500),
			File_ID VARCHAR(50),
			Text_Content NVARCHAR(MAX),
			File_Name NVARCHAR(255),
			File_Type NVARCHAR(50),
			Flow_Detail_Status VARCHAR(20),
			User_Input NVARCHAR(MAX),
			Task_Detail_Display INT,
			Task_Detail_StyleDisplay NVARCHAR(500),
			Data_Exp NVARCHAR(MAX),
			UI_Component NVARCHAR(MAX),
			FN_Check NVARCHAR(MAX),
			AllowNull CHAR(1),
			AllowFileType VARCHAR(50),
			Task_Help NVARCHAR(500)
		)

		INSERT INTO @TempFlowDetailTable
		EXEC spAPI_Get_FlowDetail_OldTree @FlowID;

		-- CTE để lấy GVHD1 và GVHD2
		WITH FD_CTE AS (
			SELECT TOP 1 *
			FROM Flow_Detail
			WHERE Flow_ID = @FlowID_GVHD
			AND (
				(@Process_ID = 1 AND Task_Detail_ID = @TaskDetailID_GVHD1_NghienCuu)
				OR (@Process_ID = 4 AND Task_Detail_ID = @TaskDetailID_GVHD1_UngDung)
			)
		),
		FD1_CTE AS (
			SELECT TOP 1 *
			FROM Flow_Detail
			WHERE Flow_ID = @FlowID_GVHD
			AND (
				(@Process_ID = 1 AND Task_Detail_ID = @TaskDetailID_GVHD2_NghienCuu)
				OR (@Process_ID = 4 AND Task_Detail_ID = @TaskDetailID_GVHD2_UngDung)
			)
		)

		INSERT INTO @OutputTable
		SELECT
			si.StudentID,
			si.HoSV,
			si.TenSV,
			si.NienKhoa,
			si.LopID,
			si.TenNganh,
			ttb.Text_Content,
			fd.Text_Content,
			fd1.Text_Content
		FROM (
			SELECT TOP 1 * FROM @TempFlowDetailTable
			WHERE Task_Detail_ID = @Task_Detail_ID
		) ttb
		JOIN StudentInfo si ON si.StudentID = @Student_ID
		CROSS APPLY (SELECT TOP 1 * FROM FD_CTE) fd
		CROSS APPLY (SELECT TOP 1 * FROM FD1_CTE) fd1

		-- 6. XÓA dữ liệu bảng tạm trước khi lặp sang Process_Stu_ID kế
		DELETE FROM @TempTable;
		DELETE FROM @TempFlowDetailTable;

		-- Lấy dòng tiếp theo
		FETCH NEXT FROM process_cursor INTO @ProcessStudentID
	END

	CLOSE process_cursor
	DEALLOCATE process_cursor

	-- Kết quả cuối
	SELECT * FROM @OutputTable
END