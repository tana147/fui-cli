-- API cho Vai Trò
create PROCEDURE dbo.spAPI_HDKH_DM_GetVaiTro
    @sys_UserID VARCHAR(9), @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID AS value, TenVaiTro AS title FROM dbo.tblHDKH_DM_VaiTro WHERE IsActive = 1 ORDER BY TenVaiTro;
END
