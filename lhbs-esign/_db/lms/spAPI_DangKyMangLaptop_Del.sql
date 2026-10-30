CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_Del]
    @DangKyID    INT
  , @sys_UserID  VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblDangKyMangLaptop
    SET    Enable = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE  DangKyID = @DangKyID AND GiaoVienDangKyID = @sys_UserID AND Enable = 1;

    SELECT Deleted = @@ROWCOUNT;
END
