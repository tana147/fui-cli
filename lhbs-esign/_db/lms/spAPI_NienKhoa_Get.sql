
CREATE PROCEDURE [dbo].[spAPI_NienKhoa_Get]
AS
BEGIN
	SELECT * FROM tblNienKhoa
	ORDER BY NienKhoa desc, HocKi desc

END