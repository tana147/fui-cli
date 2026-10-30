CREATE PROCEDURE [dbo].[spAPI_GiayKhenTapTheCert_Get]
    @NienKhoa INT
  , @HocKy    INT
  , @KhoiID   INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT GiayKhenCertID
         , HocSinhID
         , HoTen
         , TenLop
         , LopID
         , KhoiID
         , NgaySinh
         , DanhHieu AS MucHocBong
         , HocKy
         , NienKhoa
         , TieuChi_VI
         , TieuChi_EN
         , SoQuyetDinh
         , VaoSo
         , NgayCap_VI
         , NgayCap_EN
         , Is_DaIn
    FROM dbo.tblGiayKhenTapTheCert
    WHERE Enable = 1
      AND NienKhoa = @NienKhoa
      AND (@HocKy = 0 OR HocKy = @HocKy)
      AND (@KhoiID = 0 OR KhoiID = @KhoiID)
    ORDER BY KhoiID, TenLop, HoTen
END