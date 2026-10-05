
CREATE PROC [dbo].[spAPI_Student_XuLyHocVu]
@Student_ID VARCHAR(9),
@Sys_UserId VARCHAR(9),
@sys_SystemRight INT,
@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)

	DECLARE @IsTienSi BIT = 0
	IF EXISTS (
		SELECT 1 FROM StudentInfo 
		WHERE StudentID = @Student_ID 
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
		-- Thạc sĩ: giữ như cũ (1,2,9)
		IF (@sys_SystemRight NOT IN (1,2,9))
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END

	UPDATE StudentInfo
	SET IsXuLyHocVu = 1
	WHERE StudentID = @Student_ID
END