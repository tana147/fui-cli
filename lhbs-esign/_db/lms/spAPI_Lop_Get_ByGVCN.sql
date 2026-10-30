CREATE PROCEDURE [dbo].[spAPI_Lop_Get_ByGVCN]
    @NienKhoa     INT
  , @sys_UserID   VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT LopID, TenLop, KhoiID
    FROM dbo.tblLop
    WHERE GVCN = @sys_UserID AND NienKhoa = @NienKhoa AND Enable = 1
    ORDER BY TenLop;
END
