CREATE PROCEDURE spAPI_TkbMonQuyTacDelete
    @url1_ID    int,
    @sys_UserID varchar(9)
AS
BEGIN
    UPDATE tblTKB_MonQuyTac
    SET Enable = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE ID = @url1_ID

    SELECT mess = N'Đã xoá', id = @url1_ID
END
