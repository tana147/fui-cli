CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_GetThoiLuong]
AS
BEGIN
	SELECT ID as value, TenThoiLuong as title FROM dbo.tblHDKH_DM_ThoiLuong WHERE IsActive = 1 ORDER BY TenThoiLuong;
END