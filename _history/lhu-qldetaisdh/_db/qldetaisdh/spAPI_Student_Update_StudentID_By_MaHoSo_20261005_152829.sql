CREATE PROC [dbo].[spAPI_Student_Update_StudentID_By_MaHoSo]
	@MaHoSo VARCHAR(20),
	@NewStudentID VARCHAR(9),
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

	SET @MaHoSo = LTRIM(RTRIM(@MaHoSo));
	SET @NewStudentID = LTRIM(RTRIM(@NewStudentID));

	IF (@MaHoSo IS NULL OR @MaHoSo = '')
	BEGIN
		SET @MsgError = N'Mã hồ sơ không được để trống';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	IF (@NewStudentID IS NULL OR LEN(@NewStudentID) <> 9 OR @NewStudentID LIKE '%[^0-9]%')
	BEGIN
		SET @MsgError = N'Mã học viên mới không hợp lệ. Bắt buộc phải gồm đúng 9 chữ số.';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	-- Tìm học viên theo MaHoSo hoặc StudentID
	DECLARE @OldStudentID VARCHAR(20);
	SELECT TOP 1 @OldStudentID = StudentID
	FROM StudentInfo
	WHERE MaHoSo = @MaHoSo OR StudentID = @MaHoSo;

	IF (@OldStudentID IS NULL)
	BEGIN
		SET @MsgError = N'Không tìm thấy học viên có mã hồ sơ: ' + @MaHoSo;
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	IF (@OldStudentID = @NewStudentID)
	BEGIN
		SET @MsgError = N'Mã học viên mới trùng với mã học viên hiện tại.';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	-- Kiểm tra NewStudentID đã tồn tại ở bản ghi khác chưa
	IF EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = @NewStudentID AND (MaHoSo <> @MaHoSo OR MaHoSo IS NULL))
	BEGIN
		SET @MsgError = N'Mã học viên ' + @NewStudentID + N' đã tồn tại trong hệ thống. Vui lòng kiểm tra lại.';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	BEGIN TRANSACTION;
	BEGIN TRY
		-- 1. Cập nhật StudentInfo (giữ nguyên MaHoSo gốc để đối soát lịch sử)
		UPDATE StudentInfo
		SET StudentID = @NewStudentID,
			UpdateUser = ISNULL(@sys_UserID, UpdateUser),
			UpdateTime = GETDATE()
		WHERE (MaHoSo = @MaHoSo OR StudentID = @OldStudentID);

		-- 2. Cập nhật Process_Student
		UPDATE Process_Student
		SET Student_ID = @NewStudentID,
			Updated_By = ISNULL(@sys_UserID, Updated_By),
			Updated_At = GETDATE()
		WHERE Student_ID = @OldStudentID;

		-- 3. Cập nhật Flow
		UPDATE Flow
		SET Student_Id = @NewStudentID
		WHERE Student_Id = @OldStudentID;

		-- 4. Cập nhật Flow_His
		UPDATE Flow_His
		SET Student_ID = @NewStudentID
		WHERE Student_ID = @OldStudentID;

		-- 5. Cập nhật Flow_Detail_His
		UPDATE Flow_Detail_His
		SET Student_ID = @NewStudentID
		WHERE Student_ID = @OldStudentID;

		-- 6. Cập nhật các bảng liên quan khác nếu có
		UPDATE Decision_Change_Thesis SET StudentID = @NewStudentID WHERE StudentID = @OldStudentID;
		UPDATE Decision_Graduate SET StudentID = @NewStudentID WHERE StudentID = @OldStudentID;
		UPDATE HoiDong SET StudentID = @NewStudentID WHERE StudentID = @OldStudentID;
		UPDATE HoiDongThanhVien SET StudentID = @NewStudentID WHERE StudentID = @OldStudentID;
		UPDATE Thesises SET StudentID = @NewStudentID WHERE StudentID = @OldStudentID;

		COMMIT TRANSACTION;

		SELECT 1 AS Success, N'Cập nhật mã học viên thành công' AS Message, @OldStudentID AS OldStudentID, @NewStudentID AS NewStudentID, @MaHoSo AS MaHoSo;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		SET @MsgError = ERROR_MESSAGE();
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END CATCH
END