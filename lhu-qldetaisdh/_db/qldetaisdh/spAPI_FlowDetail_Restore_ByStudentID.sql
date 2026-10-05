
CREATE PROC [dbo].[spAPI_FlowDetail_Restore_ByStudentID]
@Task_ID INT,
@DataRestore NVARCHAR(MAX),
@LoaiThs TINYINT, --1 là Thạc sĩ Nghiên cứu; 4 Là Thạc Sĩ Ứng dụng
@SYS_UserID varchar(9),
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

	BEGIN TRANSACTION; 

		DECLARE @StudentID VARCHAR(9);
		DECLARE @FieldName NVARCHAR(20);
		DECLARE @Text_Content NVARCHAR(500);
		DECLARE @Flow_Detail_ID INT;
		DECLARE @Flow_ID	INT;
		DECLARE @Task_Detail_ID INT;
		DECLARE @Process_ID INT  ;

		SET @Process_ID = @LoaiThs;
		--SELECT @Process_ID = ISNULL(P.Process_ID,1) FROM StudentInfo S INNER JOIN Process_Class P ON S.LopID = P.Lop_ID AND P.Process_Action = 1 WHERE S.StudentID  = @StudentID

		DECLARE json_cursor CURSOR FOR
		SELECT StudentID, FieldName, Text_Content
		FROM OPENJSON(@DataRestore)
		WITH (
			StudentID VARCHAR(9),
			FieldName NVARCHAR(20),
			Text_Content NVARCHAR(500)
		);

		OPEN json_cursor;
		FETCH NEXT FROM json_cursor INTO @StudentID, @FieldName, @Text_Content;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Lấy Flow_Detail_ID từ câu truy vấn
			SELECT @Flow_ID = F.Flow_ID, @Flow_Detail_ID = FD.Flow_Detail_ID, @Task_Detail_ID = TD.Task_Detail_ID
			FROM Flow F
			INNER JOIN Flow_Detail FD ON FD.Flow_ID = F.Flow_ID
			INNER JOIN Task_Detail TD ON TD.Task_Detail_ID = FD.Task_Detail_ID
			WHERE F.Task_ID = @Task_ID
			AND TD.FieldName = @FieldName
			AND F.Student_ID = @StudentID;

			-- Thực hiện UPDATE cho mỗi phần tử trong đối tượng JSON
			UPDATE [dbo].[Flow_Detail]
			SET
				Text_Content = @Text_Content
			WHERE Flow_Detail_ID = @Flow_Detail_ID; -- Sử dụng Flow_Detail_ID để xác định hàng cần cập nhật

			-- Gọi stored procedure sau khi cập nhật dữ liệu
			EXEC [dbo].[spAPI_FlowDetail_UpdateStatus] 	@StudentID , @Process_ID, @Flow_ID, @Task_ID, @Task_Detail_ID, 'C', @SYS_UserID , @sys_SystemRight 


			FETCH NEXT FROM json_cursor INTO @StudentID, @FieldName, @Text_Content;
		END;

		CLOSE json_cursor;
		DEALLOCATE json_cursor;
	COMMIT TRANSACTION;

END

