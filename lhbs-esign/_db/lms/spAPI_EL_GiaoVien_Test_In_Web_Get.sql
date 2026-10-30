CREATE PROC [dbo].[spAPI_EL_GiaoVien_Test_In_Web_Get]
AS
BEGIN
	SELECT u.*, '(' + SYS_USERID +') '+ gv.HoGV + ' ' + gv.TenGV AS HoTenGV 
	FROM tblEL_User_Assign u
		INNER JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = u.SYS_USERID
		
END