CREATE PROCEDURE dbo.spAPI_AUTH_TKB_MN_Lich_GhiChuDayThay_Upd
    @TKBLichID INT,
    @GhiChuDayThay NVARCHAR(1000),
    @sys_UserID VARCHAR(20),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'[Unauthorized]Bạn không có quyền cập nhật ghi chú dạy thay.', 16, 1);
        RETURN;
    END;

    UPDATE dbo.tblTKB_Lich
    SET GhiChuDayThay = @GhiChuDayThay
    WHERE TKBLichID = @TKBLichID;
    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'Không tìm thấy tiết học cần cập nhật.', 16, 1);
        RETURN;
    END;
    SELECT @TKBLichID AS TKBLichID;
END
