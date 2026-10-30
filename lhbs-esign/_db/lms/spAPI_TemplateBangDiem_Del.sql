CREATE PROCEDURE [dbo].[spAPI_TemplateBangDiem_Del]
	@TemplateBangDiemID INT,
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
	
	UPDATE [dbo].[TemplateBangDiem]
	SET		[Enable] 		= 0
		,	[UpdateUser]	= @SYS_USERID
		,	UpdateTime		= GETDATE()
	WHERE [TemplateBangDiemID] = @TemplateBangDiemID


END
