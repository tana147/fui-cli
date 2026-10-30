CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_ThongBaoPH_MarkDone]
    @LopID        INT
  , @NgayApDung   DATE
  , @sys_UserID   VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblDangKyMangLaptop
    SET IsDaThongBaoPH = 1
      , NguoiThongBaoPH = @sys_UserID
      , ThoiGianThongBaoPH = GETDATE()
    WHERE LopID = @LopID
      AND NgayApDung = @NgayApDung
      AND Enable = 1;

    SELECT SoDong = @@ROWCOUNT;
END
