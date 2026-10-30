CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_ThongBao_Get]
    @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT tb.ThongBaoID, tb.DangKyID, tb.NoiDung, tb.IsRead, tb.CreateTime
    FROM dbo.tblDangKyMangLaptop_ThongBao tb
    WHERE tb.TargetUserID = @sys_UserID AND tb.Enable = 1
    ORDER BY tb.CreateTime DESC;
END
