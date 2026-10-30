CREATE PROCEDURE [dbo].[spAPI_TemplateBangDiem_Ins]
    @TemplateBangDiemName NVARCHAR(200),
	@CapID INT,
	@NienKhoa INT,
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


	IF EXISTS(SELECT TOP 1 * FROM TemplateBangDiem WHERE TemplateBangDiemName = @TemplateBangDiemName)
	BEGIN
		SET @MsgError = N'Templapte bảng điểm này bị trùng tên.'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

    INSERT INTO dbo.TemplateBangDiem(
        TemplateBangDiemName,
		CapID,
		NienKhoa,
        CreateUser,
        CreateTime
    )
    VALUES(
        @TemplateBangDiemName,
		@CapID,
		@NienKhoa,
        @SYS_USERID,
        GETDATE()
    )
END
