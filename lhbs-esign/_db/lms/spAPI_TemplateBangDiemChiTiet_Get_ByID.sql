-- [dbo].[spAPI_TemplateBangDiemChiTiet_Get_ByID] 3, '',0
CREATE PROC [dbo].[spAPI_TemplateBangDiemChiTiet_Get_ByID]
    @TemplateBangDiemID INT
  , @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
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
         , ISNULL(KieuDanhGiaID, 0) AS KieuDanhGiaID
         , GiaTriCotDiem
         , ISNULL(LamTronBaoNhieuSo, 0) AS LamTronBaoNhieuSo
         , Formula
         , ThuTuCotDiem
         , MaNhomCotDiem
         , TenNhomCotDiem_VI
         , TenNhomCotDiem_EN
         , ThuTuNhom
         , IsUserInput
         , IsVisibleToParents
         , IsSendToManager
         , IsNegativeNumber
         , CssClass
         , Semester
    FROM
           dbo.TemplateBangDiemChiTiet
    WHERE
           TemplateBangDiemID = @TemplateBangDiemID
      AND  Enable              = 1
    ORDER BY
           Semester
         , ThuTuNhom
         , ThuTuCotDiem;

END;