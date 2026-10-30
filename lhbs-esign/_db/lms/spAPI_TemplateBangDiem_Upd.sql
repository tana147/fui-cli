CREATE PROCEDURE [dbo].[spAPI_TemplateBangDiem_Upd]
	@TemplateBangDiemID INT,
    @TemplateBangDiemName NVARCHAR(200),
    @SYS_USERID VARCHAR(9),
	@Sys_GroupID INT
AS
BEGIN
	
	DECLARE @MsgError NVARCHAR(500)
	--IF @Sys_GroupID <> 1
	--BEGIN
	--	SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
	--	RAISERROR(@MsgError, 16, 1)
	--	RETURN 0;
	--END
	--ELSE
	 

	UPDATE [dbo].[TemplateBangDiem]
	SET [TemplateBangDiemName]	= @TemplateBangDiemName
		, [UpdateUser]			= @SYS_USERID
		, UpdateTime			= GETDATE()
	WHERE [TemplateBangDiemID] = @TemplateBangDiemID
    
END
