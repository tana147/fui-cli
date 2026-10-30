CREATE PROCEDURE [dbo].[spAPI_WF_Tag_Delete]
    @sys_UserID VARCHAR(9),
    @Tag VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tblWF_Tag WHERE Tag = @Tag AND [Enable] = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy nhãn hoặc nhãn đã bị xóa.', 16, 1);
        RETURN;
    END

    UPDATE dbo.tblWF_Tag
    SET [Enable]    = 0,
        UpdateUser  = @sys_UserID,
        UpdateTime  = GETDATE()
    WHERE Tag = @Tag;

    SELECT Message = N'Xóa nhãn thành công.', Tag = @Tag;
END

