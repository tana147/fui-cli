CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_DanhDauViPham]
    @DangKyHocSinhID  INT
  , @IsViPham         BIT
  , @GhiChuViPham     NVARCHAR(500)
  , @sys_UserID       VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblDangKyMangLaptop_HocSinh
    SET    IsViPham = @IsViPham, GhiChuViPham = @GhiChuViPham,
           NguoiDanhDauViPham = @sys_UserID, ThoiGianDanhDauViPham = GETDATE(),
           UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE  DangKyHocSinhID = @DangKyHocSinhID;

    SELECT Updated = @@ROWCOUNT;
END
