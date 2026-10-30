CREATE PROC [dbo].[spAPI_TemplateBangDiemChiTiet_DSCotDiem_Get_By_MaNhomCotDiem]
    @TemplateBangDiemID INT
  , @MaNhomCotDiem      NVARCHAR(100)
AS
BEGIN
    SELECT CotDiemID
         , TemplateBangDiemID
         , IDHeThong
         , MaCotDiem
         , TenCotDiem_VI
         , TenCotDiem_EN
         , TenHienThi_VI
         , TenHienThi_EN
         , MotaCotDiem_VI
         , MotaCotDiem_EN
         , LoaiCotDiem
         , KieuDanhGiaID
         , GiaTriCotDiem
         , LamTronBaoNhieuSo
         , DiemMin
         , DiemMax
         , Formula
         , ThuTuCotDiem
         , MaNhomCotDiem
         , TenNhomCotDiem_VI
         , TenNhomCotDiem_EN
         , ThuTuNhom
         , IsUserInput
         , IsVisibleToParents
         , IsSendToManager
         , CssClass
         , HexBackground
         , Semester
         , BaoCaoThang_DinhKy
         , QuyenNhapDiem
         , IsNegativeNumber
         , WidthCSS
    FROM
           dbo.TemplateBangDiemChiTiet
    WHERE
           TemplateBangDiemID = @TemplateBangDiemID
      AND  MaNhomCotDiem       = @MaNhomCotDiem
      AND  Enable              = 1
    ORDER BY
           ThuTuCotDiem;

END;