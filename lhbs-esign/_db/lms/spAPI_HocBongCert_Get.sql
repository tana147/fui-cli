CREATE PROCEDURE [dbo].[spAPI_HocBongCert_Get]
    @NienKhoa INT
  , @HocKy    INT
  , @KhoiID   INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT HocBongCertID
         , HocSinhID
         , HoTen
         , TenLop
         , LopID
         , KhoiID
         , NgaySinh
         , MucHocBong
         , HocKy
         , NienKhoa
         , TieuChi_VI
         , TieuChi_EN
         , SoQuyetDinh
         , VaoSo
         , NgayCap_VI
         , NgayCap_EN
         , Is_DaIn
    FROM dbo.tblHocBongCert
    WHERE Enable = 1
      AND NienKhoa = @NienKhoa
      AND (@HocKy = 0 OR HocKy = @HocKy)
      AND (@KhoiID = 0 OR KhoiID = @KhoiID)
    ORDER BY KhoiID, TenLop, HoTen
END
