CREATE PROC [dbo].[spAPI_Process_Class_Ins]
@Lop_ID VARCHAR(9),
@Prcoess_ID INT,
@Process_Action INT,
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

	IF EXISTS (
		SELECT 1
		FROM Process_Class
		WHERE Lop_ID = @Lop_ID AND Process_ID = @Prcoess_ID
        and ProcessClassStatus = 0
	)
	BEGIN
		SET @MsgError = N'Lớp đã tồn tại'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	INSERT INTO [dbo].[Process_Class]( [Lop_ID], [Process_ID], [Process_Action], [ProcessClassStatus])
	VALUES( @Lop_ID, @Prcoess_ID, @Process_Action, 0)
	
END
