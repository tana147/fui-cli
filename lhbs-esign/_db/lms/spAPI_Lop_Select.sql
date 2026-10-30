CREATE PROC [dbo].[spAPI_Lop_Select]
@NienKhoa INT = 2024
AS
BEGIN
    SELECT 
		LopID,
		TenLop,
		NienKhoa
	FROM dbo.tblLop 
	WHERE NienKhoa = @NienKhoa AND Enable = 1
	ORDER BY TenLop
END