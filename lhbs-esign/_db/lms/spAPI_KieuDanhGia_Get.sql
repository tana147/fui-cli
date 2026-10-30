CREATE PROC	 spAPI_KieuDanhGia_Get
AS
BEGIN
    SELECT KieuDanhGiaID
         , KieuDanhGia
         , KieuDanhGiaType
         , TenGiaTri1_VI
         , TenGiaTri2_VI
         , TenGiaTri3_VI
         , TenGiaTri4_VI
         , TenGiaTri5_VI
         , TenGiaTri1_EN
         , TenGiaTri2_EN
         , TenGiaTri3_EN
         , TenGiaTri4_EN
         , TenGiaTri5_EN
	FROM dbo.tblDinhNghiaKieuDanhGia
END