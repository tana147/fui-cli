
CREATE PROC [dbo].[spAPI_Nganh_GetAll]
AS
BEGIN
	SELECT DISTINCT NganhID AS Nganh_ID, TenNganh AS Ten_Nganh FROM Nganh 

END