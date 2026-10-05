CREATE PROCEDURE [dbo].[spAPI_HDKH_DM_GetLoaiHinhPhanBien]
AS
BEGIN
	SELECT ID as value, TenLoaiHinh as title FROM dbo.tblHDKH_DM_LoaiHinhPhanBien WHERE IsActive = 1 ORDER BY TenLoaiHinh;
END