CREATE PROC spAPI_ChiTieu_DanhHieu_CuoiNam_Get
@NienKhoa INT
AS
BEGIN
    SELECT ChiTieuID
         , CapID
         , NienKhoa
         , KhoiID
         , DanhHieu_HS_XuatSac
         , DanhHieu_HS_Gioi
	FROM  [dbo].[tblChiTieu_DanhHieu_CuoiNam]
	WHERE Enable = 1
	AND NienKhoa = @NienKhoa
END;
