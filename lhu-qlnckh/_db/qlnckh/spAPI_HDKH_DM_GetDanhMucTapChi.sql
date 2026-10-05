CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_GetDanhMucTapChi]
    @sys_UserID VARCHAR(9), @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID as value, TenDanhMuc as title FROM dbo.tblHDKH_DM_DanhMucTapChi WHERE IsActive = 1 ORDER BY TenDanhMuc;
END