CREATE PROCEDURE [dbo].[spAPI_TemplateBangDiemChiTiet_Ins]
    @TemplateBangDiemID INT
  , @JsonData           NVARCHAR(MAX)
  , @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
AS
BEGIN
    -- Tạo bảng tạm để chứa dữ liệu từ JSON
    DECLARE @TempTable TABLE
    (
        IDHeThong          NVARCHAR(50)
      , MaCotDiem          NVARCHAR(50)
      , TenCotDiem_VI      NVARCHAR(200)
      , TenCotDiem_EN      NVARCHAR(200)
      , TenHienThi_VI      NVARCHAR(200)
      , TenHienThi_EN      NVARCHAR(200)
      , MotaCotDiem_VI     NVARCHAR(200)
      , MotaCotDiem_EN     NVARCHAR(200)
      , LoaiCotDiem        NVARCHAR(50)
      , KieuDanhGiaID      TINYINT
      , GiaTriCotDiem      VARCHAR(50)
      , LamTronBaoNhieuSo  TINYINT
      , Formula            NVARCHAR(255)
      , ThuTuCotDiem       TINYINT
      , MaNhomCotDiem      NVARCHAR(50)
      , TenNhomCotDiem_VI  NVARCHAR(500)
      , TenNhomCotDiem_EN  NVARCHAR(500)
      , ThuTuNhom          TINYINT
      , IsUserInput        BIT
      , IsVisibleToParents BIT
      , IsSendToManager    BIT
      , IsNegativeNumber   BIT
      , Semester           VARCHAR(3)
    );

    -- Chuyển đổi JSON sang bảng tạm
    INSERT INTO @TempTable
    (
        IDHeThong
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
    )
    SELECT IDHeThong
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
    FROM
           OPENJSON(@JsonData)
           WITH
           (
               IDHeThong NVARCHAR(50) '$.IDHeThong'
             , MaCotDiem NVARCHAR(50) '$.MaCotDiem'
             , TenCotDiem_VI NVARCHAR(200) '$.TenCotDiem_VI'
             , TenCotDiem_EN NVARCHAR(200) '$.TenCotDiem_EN'
             , TenHienThi_VI NVARCHAR(200) '$.TenHienThi_VI'
             , TenHienThi_EN NVARCHAR(200) '$.TenHienThi_EN'
             , MotaCotDiem_VI NVARCHAR(200) '$.MotaCotDiem_VI'
             , MotaCotDiem_EN NVARCHAR(200) '$.MotaCotDiem_EN'
             , LoaiCotDiem NVARCHAR(50) '$.LoaiCotDiem'
             , KieuDanhGiaID TINYINT '$.KieuDanhGiaID'
             , GiaTriCotDiem VARCHAR(50) '$.GiaTriCotDiem'
             , LamTronBaoNhieuSo TINYINT '$.LamTronBaoNhieuSo'
             , Formula NVARCHAR(255) '$.Formula'
             , ThuTuCotDiem TINYINT '$.ThuTuCotDiem'
             , MaNhomCotDiem NVARCHAR(50) '$.MaNhomCotDiem'
             , TenNhomCotDiem_VI NVARCHAR(500) '$.TenNhomCotDiem_VI'
             , TenNhomCotDiem_EN NVARCHAR(500) '$.TenNhomCotDiem_EN'
             , ThuTuNhom TINYINT '$.ThuTuNhom'
             , IsUserInput BIT '$.IsUserInput'
             , IsVisibleToParents BIT '$.IsVisibleToParents'
             , IsSendToManager BIT '$.IsSendToManager'
             , IsNegativeNumber BIT '$.IsNegativeNumber'
             , Semester VARCHAR(3) '$.Semester'
           );

    -- Chèn dữ liệu từ bảng tạm vào bảng chính
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
      , CreateUser
      , CreateTime
    )
    SELECT @TemplateBangDiemID
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
         , @SYS_USERID
         , GETDATE()
    FROM
           @TempTable;
END;
