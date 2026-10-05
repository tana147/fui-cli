create proc spAPI_DonVi_Get
AS
BEGIN
	SELECT MaDonVi, TenDonVi FROM  DonVi
	where Is_Xoa = 0
END