

CREATE PROC spAPI_ThietLap_KiNang_Get
	@NienKhoa INT
AS
BEGIN
	SELECT * FROM dbo.tblThietLap_KiNang    
	WHERE Enable = 1 AND NienKhoa = @NienKhoa 
END