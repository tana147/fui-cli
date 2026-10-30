CREATE PROCEDURE [dbo].[spAPI_TemplateBangDiemChiTiet_Upd]
    @CotDiemID          INT
  , @TemplateBangDiemID INT
  , @IDHeThong          NVARCHAR(50)
  , @MaCotDiem          NVARCHAR(50)
  , @TenCotDiem_VI      NVARCHAR(200)
  , @TenCotDiem_EN      NVARCHAR(200)
  , @TenHienThi_VI      NVARCHAR(200)
  , @TenHienThi_EN      NVARCHAR(200)
  , @MotaCotDiem_VI     NVARCHAR(200)
  , @MotaCotDiem_EN     NVARCHAR(200)
  , @LoaiCotDiem        NVARCHAR(50)
  , @KieuDanhGiaID      INT
  , @GiaTriCotDiem      VARCHAR(50)
  , @LamTronBaoNhieuSo  INT
  , @Formula            NVARCHAR(255)
  , @ThuTuCotDiem       INT
  , @MaNhomCotDiem      NVARCHAR(50)
  , @TenNhomCotDiem_VI  NVARCHAR(500)
  , @TenNhomCotDiem_EN  NVARCHAR(500)
  , @ThuTuNhom          INT
  , @IsUserInput        BIT
  , @IsVisibleToParents BIT
  , @IsSendToManager    BIT
  ------------
  , @SYS_USERID         VARCHAR(9)
AS
BEGIN
    UPDATE dbo.TemplateBangDiemChiTiet
    SET    IDHeThong = @IDHeThong
         , MaCotDiem = @MaCotDiem
         , TenCotDiem_VI = @TenCotDiem_VI
         , TenCotDiem_EN = @TenCotDiem_EN
         , TenHienThi_VI = @TenHienThi_VI
         , TenHienThi_EN = @TenHienThi_EN
         , MotaCotDiem_VI = @MotaCotDiem_VI
         , MotaCotDiem_EN = @MotaCotDiem_EN
         , LoaiCotDiem = @LoaiCotDiem
         , KieuDanhGiaID = @KieuDanhGiaID
         , GiaTriCotDiem = @GiaTriCotDiem
         , LamTronBaoNhieuSo = @LamTronBaoNhieuSo
         , Formula = @Formula
         , ThuTuCotDiem = @ThuTuCotDiem
         , MaNhomCotDiem = @MaNhomCotDiem
         , TenNhomCotDiem_VI = @TenNhomCotDiem_VI
         , TenNhomCotDiem_EN = @TenNhomCotDiem_EN
         , ThuTuNhom = @ThuTuNhom
         , IsUserInput = @IsUserInput
         , IsVisibleToParents = @IsVisibleToParents
         , IsSendToManager = @IsSendToManager
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           CotDiemID         = @CotDiemID
      AND  TemplateBangDiemID = @TemplateBangDiemID;
END;
