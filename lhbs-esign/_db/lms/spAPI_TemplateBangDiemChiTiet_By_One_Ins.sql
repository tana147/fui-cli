CREATE PROC [dbo].[spAPI_TemplateBangDiemChiTiet_By_One_Ins]
    @TemplateBangDiemID INT
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
  , @IsNegativeNumber   BIT
  , @Semester           VARCHAR(10)
  , @SYS_USERID         VARCHAR(9)
AS
BEGIN
    INSERT INTO dbo.TemplateBangDiemChiTiet
    (
        TemplateBangDiemID
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
      , Semester
      , Enable
      , CreateUser
      , CreateTime
    )
    VALUES
    (
        @TemplateBangDiemID
      , @IDHeThong
      , @MaCotDiem
      , @TenCotDiem_VI
      , @TenCotDiem_EN
      , @TenHienThi_VI
      , @TenHienThi_EN
      , @MotaCotDiem_VI
      , @MotaCotDiem_EN
      , @LoaiCotDiem
      , @KieuDanhGiaID
      , @GiaTriCotDiem
      , @LamTronBaoNhieuSo
      , @Formula
      , @ThuTuCotDiem
      , @MaNhomCotDiem
      , @TenNhomCotDiem_VI
      , @TenNhomCotDiem_EN
      , @ThuTuNhom
      , @IsUserInput
      , @IsVisibleToParents
      , @IsSendToManager
      , @IsNegativeNumber
      , @Semester
      , 1
      , @SYS_USERID
      , GETDATE()
    );
END;