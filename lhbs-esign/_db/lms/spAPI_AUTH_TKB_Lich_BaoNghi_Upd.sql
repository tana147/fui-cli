CREATE PROCEDURE [dbo].[spAPI_AUTH_TKB_Lich_BaoNghi_Upd]
    @TKBLichID int,
    @TinhTrangXepLich tinyint,
    @sys_UserID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.tblTKB_Lich
    SET TinhTrangXepLich = @TinhTrangXepLich
    WHERE TKBLichID = @TKBLichID;

    SELECT @TKBLichID AS TKBLichID;
END