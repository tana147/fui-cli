CREATE PROC [dbo].[spAPI_DanhSachLop_Get]
AS
BEGIN
	DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai()
		SELECT 
			LopID
		  , MaDonVi
		  , TenLop
		  , KhoiID
		  , PhanBanID
		  , TenKhoiPhanBan
		  , NienKhoa
		  , GVCN
		FROM dbo.tblLop WHERE NienKhoa = @NienKhoa AND Enable = 1
		UNION
		SELECT 
		 NhomID	AS LopID 
		  , MaDonVi
		  , TenNhom AS TenLop
		  , KhoiID
		  , NULL AS PhanBanID
		  , NULL AS TenKhoiPhanBan
		  , NienKhoa
		  , GVCN
		FROM dbo.tblNhom WHERE NienKhoa = @NienKhoa AND Enable = 1 and IsNhomLMS_GiaoBai = 0 
		ORDER BY KhoiID, TenLop
END