CREATE PROC [dbo].[spAPI_Student_Update_StudentID_Batch_TS]
	@JsonData NVARCHAR(MAX),
	@sys_UserID VARCHAR(9),
	@sys_SystemRight INT,
	@sys_GroupID INT,
	@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @MsgError NVARCHAR(500);

	-- Phân quyền: FunctionRight = 2 hoặc SystemRight IN (2, 3, 9)
	IF (@sys_SystemRight NOT IN (2, 3, 9) AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này (Yêu cầu quyền Tiến sĩ)';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	IF (@JsonData IS NULL OR ISJSON(@JsonData) = 0)
	BEGIN
		SET @MsgError = N'Dữ liệu JSON không hợp lệ hoặc rỗng';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	DECLARE @InputTable TABLE (
		RowIndex INT IDENTITY(1,1),
		MaHoSo VARCHAR(20),
		NienKhoa VARCHAR(10),
		NewStudentID VARCHAR(9)
	);

	INSERT INTO @InputTable (MaHoSo, NienKhoa, NewStudentID)
	SELECT 
		LTRIM(RTRIM(MaHoSo)),
		LTRIM(RTRIM(NienKhoa)),
		LTRIM(RTRIM(NewStudentID))
	FROM OPENJSON(@JsonData)
	WITH (
		MaHoSo VARCHAR(20) '$.MaHoSo',
		NienKhoa VARCHAR(10) '$.NienKhoa',
		NewStudentID VARCHAR(9) '$.NewStudentID'
	);

	DECLARE @ResultTable TABLE (
		MaHoSo VARCHAR(20),
		NienKhoa VARCHAR(10),
		OldStudentID VARCHAR(20),
		NewStudentID VARCHAR(9),
		Success BIT,
		Message NVARCHAR(500)
	);

	DECLARE @TotalRows INT = (SELECT COUNT(*) FROM @InputTable);
	DECLARE @CurrentRow INT = 1;

	DECLARE @CurMaHoSo VARCHAR(20);
	DECLARE @CurNienKhoa VARCHAR(10);
	DECLARE @CurNewStudentID VARCHAR(9);
	DECLARE @CurOldStudentID VARCHAR(20);

	WHILE @CurrentRow <= @TotalRows
	BEGIN
		SELECT 
			@CurMaHoSo = MaHoSo,
			@CurNienKhoa = NienKhoa,
			@CurNewStudentID = NewStudentID
		FROM @InputTable
		WHERE RowIndex = @CurrentRow;

		SET @CurOldStudentID = NULL;

		-- Validate dữ liệu dòng
		IF (@CurMaHoSo IS NULL OR @CurMaHoSo = '')
		BEGIN
			INSERT INTO @ResultTable VALUES (@CurMaHoSo, @CurNienKhoa, NULL, @CurNewStudentID, 0, N'Mã hồ sơ trống');
			SET @CurrentRow = @CurrentRow + 1;
			CONTINUE;
		END

		IF (@CurNewStudentID IS NULL OR LEN(@CurNewStudentID) <> 9 OR @CurNewStudentID LIKE '%[^0-9]%')
		BEGIN
			INSERT INTO @ResultTable VALUES (@CurMaHoSo, @CurNienKhoa, NULL, @CurNewStudentID, 0, N'Mã học viên mới không đúng định dạng 9 chữ số');
			SET @CurrentRow = @CurrentRow + 1;
			CONTINUE;
		END

		-- Kiểm tra xem trùng lặp trong chính danh sách batch không
		IF (SELECT COUNT(*) FROM @InputTable WHERE NewStudentID = @CurNewStudentID) > 1
		BEGIN
			INSERT INTO @ResultTable VALUES (@CurMaHoSo, @CurNienKhoa, NULL, @CurNewStudentID, 0, N'Mã học viên mới bị trùng lặp trong danh sách gửi lên');
			SET @CurrentRow = @CurrentRow + 1;
			CONTINUE;
		END

		-- Tìm học viên theo MaHoSo hoặc StudentID (kết hợp Niên khóa nếu có)
		SELECT TOP 1 @CurOldStudentID = StudentID
		FROM StudentInfo
		WHERE (MaHoSo = @CurMaHoSo OR StudentID = @CurMaHoSo)
		  AND (@CurNienKhoa IS NULL OR @CurNienKhoa = '' OR @CurNienKhoa = '0' OR NienKhoa = @CurNienKhoa);

		IF (@CurOldStudentID IS NULL)
		BEGIN
			INSERT INTO @ResultTable VALUES (@CurMaHoSo, @CurNienKhoa, NULL, @CurNewStudentID, 0, N'Không tìm thấy học viên có mã hồ sơ này' + CASE WHEN @CurNienKhoa IS NOT NULL AND @CurNienKhoa <> '' AND @CurNienKhoa <> '0' THEN N' trong niên khóa ' + @CurNienKhoa ELSE N'' END);
			SET @CurrentRow = @CurrentRow + 1;
			CONTINUE;
		END

		IF (@CurOldStudentID = @CurNewStudentID)
		BEGIN
			INSERT INTO @ResultTable VALUES (@CurMaHoSo, @CurNienKhoa, @CurOldStudentID, @CurNewStudentID, 0, N'Mã học viên mới trùng với mã hiện tại');
			SET @CurrentRow = @CurrentRow + 1;
			CONTINUE;
		END

		-- Kiểm tra trùng lặp trên DB
		IF EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = @CurNewStudentID AND (MaHoSo <> @CurMaHoSo OR MaHoSo IS NULL))
		BEGIN
			INSERT INTO @ResultTable VALUES (@CurMaHoSo, @CurNienKhoa, @CurOldStudentID, @CurNewStudentID, 0, N'Mã học viên mới đã tồn tại trên hệ thống');
			SET @CurrentRow = @CurrentRow + 1;
			CONTINUE;
		END

		-- Bắt đầu cập nhật dòng
		BEGIN TRANSACTION;
		BEGIN TRY
			-- 1. StudentInfo
			UPDATE StudentInfo
			SET StudentID = @CurNewStudentID,
				UpdateUser = ISNULL(@sys_UserID, UpdateUser),
				UpdateTime = GETDATE()
			WHERE (MaHoSo = @CurMaHoSo OR StudentID = @CurOldStudentID)
			  AND (@CurNienKhoa IS NULL OR @CurNienKhoa = '' OR @CurNienKhoa = '0' OR NienKhoa = @CurNienKhoa);

			-- 2. Process_Student
			UPDATE Process_Student
			SET Student_ID = @CurNewStudentID,
				Updated_By = ISNULL(@sys_UserID, Updated_By),
				Updated_At = GETDATE()
			WHERE Student_ID = @CurOldStudentID;

			-- 3. Flow
			UPDATE Flow
			SET Student_Id = @CurNewStudentID
			WHERE Student_Id = @CurOldStudentID;

			-- 4. Flow_His
			UPDATE Flow_His
			SET Student_ID = @CurNewStudentID
			WHERE Student_ID = @CurOldStudentID;

			-- 5. Flow_Detail_His
			UPDATE Flow_Detail_His
			SET Student_ID = @CurNewStudentID
			WHERE Student_ID = @CurOldStudentID;

			-- 6. Các bảng liên quan
			UPDATE Decision_Change_Thesis SET StudentID = @CurNewStudentID WHERE StudentID = @CurOldStudentID;
			UPDATE Decision_Graduate SET StudentID = @CurNewStudentID WHERE StudentID = @CurOldStudentID;
			UPDATE HoiDong SET StudentID = @CurNewStudentID WHERE StudentID = @CurOldStudentID;
			UPDATE HoiDongThanhVien SET StudentID = @CurNewStudentID WHERE StudentID = @CurOldStudentID;
			UPDATE Thesises SET StudentID = @CurNewStudentID WHERE StudentID = @CurOldStudentID;

			COMMIT TRANSACTION;

			INSERT INTO @ResultTable VALUES (@CurMaHoSo, @CurNienKhoa, @CurOldStudentID, @CurNewStudentID, 1, N'Cập nhật thành công');
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
			INSERT INTO @ResultTable VALUES (@CurMaHoSo, @CurNienKhoa, @CurOldStudentID, @CurNewStudentID, 0, ERROR_MESSAGE());
		END CATCH

		SET @CurrentRow = @CurrentRow + 1;
	END

	SELECT 
		MaHoSo,
		NienKhoa,
		OldStudentID,
		NewStudentID,
		Success,
		Message
	FROM @ResultTable;
END