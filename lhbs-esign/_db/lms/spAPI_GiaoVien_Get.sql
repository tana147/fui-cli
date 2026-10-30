CREATE PROC [dbo].[spAPI_GiaoVien_Get]
AS
BEGIN
	SELECT 
		 GiaoVienID, 
		 HoGV + ' ' + TenGV AS HoTenGV
	FROM dbo.tblGiaoVien
END