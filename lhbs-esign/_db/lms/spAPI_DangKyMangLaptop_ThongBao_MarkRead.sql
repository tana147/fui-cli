CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_ThongBao_MarkRead]
    @ThongBaoID  INT
  , @sys_UserID  VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblDangKyMangLaptop_ThongBao
    SET    IsRead = 1, ReadTime = GETDATE()
    WHERE  ThongBaoID = @ThongBaoID AND TargetUserID = @sys_UserID;

    SELECT Updated = @@ROWCOUNT;
END
