CREATE PROCEDURE dbo.spAPI_TKB_QuyTac_Del
    @QuyTacID INT,
    @sys_UserID VARCHAR(20),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'Bạn không có quyền xóa quy tắc thời khóa biểu.', 16, 1);
        RETURN;
    END;

    UPDATE dbo.tblTKB_QuyTac
    SET Enable = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE QuyTacID = @QuyTacID AND Enable = 1;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'Không tìm thấy quy tắc cần xóa.', 16, 1);
        RETURN;
    END;

    SELECT @QuyTacID AS QuyTacID;
END
