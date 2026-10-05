CREATE PROC [dbo].[spAPI_Decision_Del] 
@Decision_ID INT,
@SYS_UserID VARCHAR(9),
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

	UPDATE Decision
	SET Decision_Status = 10,
		Updated_By = @SYS_UserID,
		Updated_At = GETDATE()
	WHERE Decision_ID = @Decision_ID


END