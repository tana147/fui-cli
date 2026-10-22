CREATE PROCEDURE [dbo].[spAPI_SDH_Reject_Defend_Thesis]
	@Student_ID VARCHAR(20),
	@Flow_ID INT,
	@Task_ID INT,
	@LyDo NVARCHAR(500),
	@File_ID_DaoVan VARCHAR(50),
	@File_Name_DaoVan NVARCHAR(255),
	@File_URL_DaoVan NVARCHAR(500),
	@sys_UserID VARCHAR(9)
AS
BEGIN
	SET NOCOUNT ON;

	IF (@Flow_ID IS NULL OR @Flow_ID <= 0)
	BEGIN
		RAISERROR(N'Flow_ID không hợp lệ', 16, 1);
		RETURN 0;
	END;

	IF (@LyDo IS NULL OR LTRIM(RTRIM(@LyDo)) = '')
	BEGIN
		RAISERROR(N'Vui lòng nhập lý do từ chối', 16, 1);
		RETURN 0;
	END;

	IF (@File_ID_DaoVan IS NULL OR LTRIM(RTRIM(@File_ID_DaoVan)) = '')
	BEGIN
		RAISERROR(N'Vui lòng upload file kết quả kiểm tra đạo văn trước khi từ chối hồ sơ', 16, 1);
		RETURN 0;
	END;

	IF (@File_Name_DaoVan IS NOT NULL AND LOWER(RIGHT(LTRIM(RTRIM(@File_Name_DaoVan)), 4)) <> '.pdf')
	BEGIN
		RAISERROR(N'File kết quả kiểm tra đạo văn bắt buộc phải là định dạng PDF (.pdf)', 16, 1);
		RETURN 0;
	END;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- 1. Nếu SDH có upload file check đạo văn, cập nhật vào Flow_Detail của tiêu chí đạo văn
		IF (@File_ID_DaoVan IS NOT NULL AND @File_ID_DaoVan <> '')
		BEGIN
			UPDATE fd
			SET File_ID = @File_ID_DaoVan,
				File_Name = @File_Name_DaoVan,
				File_URL = @File_URL_DaoVan,
				File_Type = 'application/pdf',
				Flow_Detail_Status = 'C',
				Updated_By = @sys_UserID,
				Updated_At = GETDATE()
			FROM FLOW_DETAIL fd
			INNER JOIN TASK_DETAIL td ON fd.TASK_DETAIL_ID = td.TASK_DETAIL_ID
			WHERE fd.FLOW_ID = @Flow_ID AND td.FieldName = 'fileCheckDaoVan';
		END;

		-- 2. CHỈ LƯU LẠI FILE LIÊN QUAN ĐẾN LUẬN VĂN:
		-- 5.6 File Luận Văn PDF, 5.7 File Luận Văn WORD và kết quả đạo văn
		INSERT INTO Flow_Detail_His
		(
			Student_ID, Flow_Detail_ID, Flow_ID, Task_ID, Task_Detail_ID,
			File_URL, Text_Content, File_Name, File_ID, File_Type,
			Flow_Detail_Status, LyDo, use_yn, Created_By, Created_At
		)
		SELECT 
			@Student_ID, fd.Flow_Detail_ID, fd.Flow_ID, fd.Task_ID, fd.Task_Detail_ID,
			fd.File_URL, fd.Text_Content, fd.File_Name, fd.File_ID, fd.File_Type,
			fd.Flow_Detail_Status, @LyDo, 1, @sys_UserID, GETDATE()
		FROM FLOW_DETAIL fd
		INNER JOIN TASK_DETAIL td ON fd.TASK_DETAIL_ID = td.TASK_DETAIL_ID
		WHERE fd.FLOW_ID = @Flow_ID 
		  AND fd.USE_YN = 1
		  AND td.FieldName IN ('fileLuanVanPDF', 'fileLuanVanWORD', 'fileCheckDaoVan');

		-- 3. CHỈ RESET FILE LIÊN QUAN ĐẾN LUẬN VĂN (5.6 File Luận Văn PDF, 5.7 File Luận Văn WORD) ĐỂ HỌC VIÊN NỘP LẠI
		-- TẤT CẢ CÁC MỤC CÒN LẠI (Lý lịch khoa học, đơn đăng ký, nhận xét GVHD, điểm, học phí...) GIỮ NGUYÊN HOÀN TOÀN
		UPDATE fd
		SET File_ID = NULL,
			File_Name = NULL,
			File_URL = NULL,
			Flow_Detail_Status = 'R',
			Updated_By = @sys_UserID,
			Updated_At = GETDATE()
		FROM FLOW_DETAIL fd
		INNER JOIN TASK_DETAIL td ON fd.TASK_DETAIL_ID = td.TASK_DETAIL_ID
		WHERE fd.FLOW_ID = @Flow_ID 
		  AND td.FieldName IN ('fileLuanVanPDF', 'fileLuanVanWORD');

		-- 4. Cập nhật trạng thái Flow sang 'R' (Rejected / Yêu cầu nộp lại luận văn)
		UPDATE FLOW
		SET Flow_Status = 'R',
			Updated_By = @sys_UserID,
			Updated_At = GETDATE()
		WHERE Flow_ID = @Flow_ID;

		COMMIT TRANSACTION;

		SELECT 1 AS Result, N'Đã từ chối và lưu lịch sử phiên nộp luận văn thành công' AS Message;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		DECLARE @ErrMsg NVARCHAR(1000) = ERROR_MESSAGE();
		RAISERROR(@ErrMsg, 16, 1);
		RETURN 0;
	END CATCH;
END;
