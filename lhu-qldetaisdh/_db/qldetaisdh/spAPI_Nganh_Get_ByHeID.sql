CREATE PROC [dbo].[spAPI_Nganh_Get_ByHeID] --'C'
@HeID VARCHAR(1)
AS
BEGIN
	SELECT DISTINCT N.NganhID AS Nganh_ID
		, N.TenNganh AS Ten_Nganh 
		, N.MaNganh
		, CASE WHEN @HeID = 'C' THEN N'Thạc sĩ ' + N.TenNganh 
				WHEN @HeID = 'N' THEN N'Tiến sĩ ' + N.TenNganh 
		END Ten_Nganh_HienThi
	FROM Nganh N
	WHERE (@HeID = 'C' AND (N.HeDaoTao = 'Master' OR N.MaNganh LIKE '8%'))
	   OR (@HeID = 'N' AND (N.HeDaoTao = 'Phd' OR N.MaNganh LIKE '9%'))
END
