CREATE PROC [dbo].[spAPI_DanhSachHocSinh_Get_By_TenLop]
	@TenLop NVARCHAR(20)
AS
BEGIN
	
	DECLARE @LopID VARCHAR(20)
	DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai()
	
	SELECT @LopID = NhomID 
	FROM dbo.tblNhom 
	WHERE NienKhoa = @NienKhoa AND TenNhom = @TenLop and IsNhomLMS_GiaoBai = 0
	
	IF @LopID IS NULL
	BEGIN
		SELECT @LopID = LopID FROM dbo.tblLop WHERE NienKhoa = @NienKhoa AND TenLop = @TenLop;
	END
	 EXEC [dbo].[spAPI_HocSinhLop_Get_ByLopID]
	     @LopID = @LopID, @MonHocID = 0, @HocLieuID = 0, @NienKhoa = @NienKhoa
END