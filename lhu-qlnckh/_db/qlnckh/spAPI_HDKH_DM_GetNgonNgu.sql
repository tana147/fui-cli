CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_GetNgonNgu]
AS
BEGIN
	SELECT ID as value, TenNgonNgu as title, HeSoNhan FROM dbo.tblHDKH_DM_NgonNgu WHERE IsActive = 1 ORDER BY TenNgonNgu;
END