CREATE PROCEDURE [dbo].[spAPI_AUTH_TKB_Lich_DayThay_Upd]
    @TKBLichID int,
    @GiaoVienDayThayID varchar(10),
    @sys_UserID varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.tblTKB_Lich
    SET GiaoVienDayThayID = CASE WHEN @GiaoVienDayThayID = '0' OR @GiaoVienDayThayID = '' THEN NULL ELSE @GiaoVienDayThayID END
    WHERE TKBLichID = @TKBLichID;

    SELECT @TKBLichID AS TKBLichID;
END