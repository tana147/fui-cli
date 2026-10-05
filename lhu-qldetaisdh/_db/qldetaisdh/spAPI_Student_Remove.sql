--[dbo].[spAPI_Student_Remove] '922000041', 9
CREATE PROC [dbo].[spAPI_Student_Remove] 
@StudentID VARCHAR(9),
@sys_SystemRight INT,
@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)

	DECLARE @IsTienSi BIT = 0
	IF EXISTS (
		SELECT 1 FROM StudentInfo 
		WHERE StudentID = @StudentID 
		  AND (HeDaoTao = 'Phd' OR SUBSTRING(LopID, 3, 1) = 'N' OR NganhID IN ('43', '44'))
	)
	BEGIN
		SET @IsTienSi = 1
	END

	IF @IsTienSi = 1
	BEGIN
		-- Tiến sĩ: FunctionRight = 2 (hoặc SystemRight = 9 admin)
		IF (@sys_SystemRight <> 9 AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
		BEGIN
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END
	ELSE
	BEGIN
		-- Thạc sĩ: giữ như cũ
		IF (@sys_SystemRight NOT IN (2,3,9))
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END
	---- KIỂM TRA SINH VIÊN NÀY ĐÃ LÀM GÌ CHƯA
	--IF EXISTS (SELECT TOP 1 *  FROM Flow F WHERE F.Student_ID = @StudentID AND F.Flow_Status <> 'W')
	--BEGIN
	--	SET @MsgError = N'Không thể xóa học viên này, vì Học viên đã có thao tác lên hệ thống.'
	--	RAISERROR(@MsgError, 16, 1)
	--	RETURN 0;
	--END
	--ELSE
	--BEGIN
		
		DELETE Flow_Detail WHERE Flow_ID  IN (SELECT Flow_ID FROM FLOW  WHERE Student_ID = @StudentID)
		DELETE FLOW  WHERE Student_ID = @StudentID
		DELETE Process_Student WHERE Student_ID = @StudentID
		DELETE StudentInfo WHERE StudentID = @StudentID
	--END
END
