CREATE PROC [dbo].[spAPI_Lop_Get_ByNienKhoa]
@NienKhoa INT,
@SYS_USERID VARCHAR(9) = NULL
AS
BEGIN
	SELECT LopID
	, MaDonVi 
	, TenLop
	, CASE WHEN MaDonVi =1 THEN TenLop + N' - [Biên Hòa]'
			WHEN MaDonVi =2 THEN TenLop + N' - [Long Khánh]' END AS TenLopHienThi
	, KhoiID , NienKhoa , GVCN , Enable
	, CapID
	FROM dbo.tblLop
	WHERE NienKhoa = @NienKhoa AND Enable = 1
	ORDER BY MaDonVi, KhoiID, TenLop
END