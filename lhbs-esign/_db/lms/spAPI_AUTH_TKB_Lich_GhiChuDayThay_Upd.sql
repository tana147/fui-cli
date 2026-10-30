CREATE PROCEDURE [dbo].[spAPI_AUTH_TKB_Lich_GhiChuDayThay_Upd]
    @TKBLichID int,
    @GhiChuDayThay nvarchar(1000),
    @sys_UserID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.tblTKB_Lich
    SET GhiChuDayThay = @GhiChuDayThay
    WHERE TKBLichID = @TKBLichID;

    SELECT @TKBLichID AS TKBLichID;
END