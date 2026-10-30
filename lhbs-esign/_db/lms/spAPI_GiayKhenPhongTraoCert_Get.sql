CREATE   PROCEDURE [dbo].[spAPI_GiayKhenPhongTraoCert_Get]
    @NienKhoa INT
  , @HocKy    INT
  , @KhoiID   INT
  , @LoaiMau  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT PhongTraoCertID
         , LoaiMau
         , HocSinhID
         , HoTen
         , TenLop
         , LopID
         , KhoiID
         , DanhHieu_VI
         , DanhHieu_EN
         , NgayCap_VI
         , NgayCap_EN
         , SoQuyetDinh
         , VaoSo
         , SoQuyetDinhVaKhenThuong
         , HocKy
         , NienKhoa
         , Is_DaIn
    FROM dbo.tblGiayKhenPhongTraoCert
    WHERE Enable = 1
      AND NienKhoa = @NienKhoa
      AND (@HocKy = 0 OR HocKy = @HocKy)
      AND (@KhoiID = 0 OR KhoiID IS NULL OR KhoiID = 0 OR KhoiID = @KhoiID)
      AND (@LoaiMau = 0 OR LoaiMau = @LoaiMau)
    ORDER BY LoaiMau, VaoSo, KhoiID, TenLop, HoTen
END