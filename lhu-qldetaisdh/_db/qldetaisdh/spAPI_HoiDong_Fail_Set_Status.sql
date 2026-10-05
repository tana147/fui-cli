
CREATE PROC [dbo].[spAPI_HoiDong_Fail_Set_Status]
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
	DECLARE @Flow_ID_Bao_Ve INT
	DECLARE @Flow_ID_Duyet_DeTai INT
	DECLARE @Flow_ID_Chinh_Sua INT
	DECLARE @ProcessID INT

	SELECT @Process_Student_ID = Process_Stu_ID, @ProcessID = Process_ID
	FROM Process_Student
	WHERE Student_ID = @StudentID AND Process_ID IN (1,4) AND Process_Student_Status <> 'X'

	-- Đăng ký bảo vệ luận văn/đồ án (B5)
	SELECT @Flow_ID_DK_BaoVe = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'signForDefendThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	-- Bảo vệ luận văn/đồ án (B7)
	SELECT @Flow_ID_Bao_Ve = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'defendThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	-- Duyệt đề tài (B6)
	SELECT @Flow_ID_Duyet_DeTai = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'reviewThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	-- Chỉnh sửa sau khi bảo vệ (B8)
	SELECT @Flow_ID_Chinh_Sua = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'reviseThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	-- Dùng cursor để lặp
	DECLARE 
		@Task_ID INT,
		@Task_Detail_ID INT,
		@Flow_Detail_Status VARCHAR(20),
		@Flow_ID INT

	DECLARE @AllFlow TABLE (
		Flow_ID INT
	)

	-- Tổng hợp các table vào 1 table tạm
	INSERT INTO @AllFlow
	--SELECT @Flow_ID_DK_BaoVe
	--UNION
	SELECT @Flow_ID_Bao_Ve
	UNION
	SELECT @Flow_ID_Duyet_DeTai
	UNION
	SELECT @Flow_ID_Chinh_Sua

	DECLARE cursor_all CURSOR FOR
	SELECT 
		fd.Flow_ID,
		fd.Task_ID,
		fd.Task_Detail_ID,
		fd.Flow_Detail_Status
	FROM Flow_Detail fd
	JOIN @AllFlow af ON fd.Flow_ID = af.Flow_ID

	OPEN cursor_all

	FETCH NEXT FROM cursor_all INTO @Flow_ID, @Task_ID, @Task_Detail_ID, @Flow_Detail_Status

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--EXEC [dbo].[spAPI_FlowDetail_UpdateStatus]
		--    @Student_ID = @StudentID,
		--    @Process_ID = @ProcessID,
		--    @Flow_ID = @Flow_ID,
		--    @Task_ID = @Task_ID,
		--    @Task_Detail_ID = @Task_Detail_ID,
		--    @Flow_Detail_Status = 'W',
		--    @sys_UserID = @sys_UserID,
		--    @sys_SystemRight = @sys_SystemRight

		FETCH NEXT FROM cursor_all INTO @Flow_ID, @Task_ID, @Task_Detail_ID, @Flow_Detail_Status
	END

	CLOSE cursor_all
	DEALLOCATE cursor_all

	-- Lặp cho Đăng ký bảo vệ luận văn, set status về P
	DECLARE cursor_bv CURSOR FOR
	SELECT 
		Flow_ID,
		Task_ID,
		Task_Detail_ID,
		Flow_Detail_Status
	FROM Flow_Detail
	WHERE Flow_ID = @Flow_ID_DK_BaoVe

	OPEN cursor_bv

	FETCH NEXT FROM cursor_bv INTO @Flow_ID, @Task_ID, @Task_Detail_ID, @Flow_Detail_Status

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC [dbo].[spAPI_FlowDetail_UpdateStatus]
		    @Student_ID = @StudentID,
		    @Process_ID = @ProcessID,
		    @Flow_ID = @Flow_ID,
		    @Task_ID = @Task_ID,
		    @Task_Detail_ID = @Task_Detail_ID,
		    @Flow_Detail_Status = 'P',
		    @sys_UserID = @sys_UserID,
		    @sys_SystemRight = @sys_SystemRight

		FETCH NEXT FROM cursor_bv INTO @Flow_ID, @Task_ID, @Task_Detail_ID, @Flow_Detail_Status
	END

	CLOSE cursor_bv
	DEALLOCATE cursor_bv
END
