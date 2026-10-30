CREATE PROC [dbo].[spAPI_TemplateBangDiemChiTiet_Multiple_Upd] @JSON_CotDiem NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Table_CotDiem TABLE
    (
        TemplateBangDiemID INT
      , CotDiemID          INT
      , IDHeThong          NVARCHAR(50)
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
      , Formula            NVARCHAR(1000)
      , ThuTuCotDiem       TINYINT
      , MaNhomCotDiem      NVARCHAR(50)
      , TenNhomCotDiem_VI  NVARCHAR(500)
      , TenNhomCotDiem_EN  NVARCHAR(500)
      , ThuTuNhom          TINYINT
      , IsUserInput        BIT
      , IsVisibleToParents BIT
      , IsSendToManager    BIT
      , IsNegativeNumber   BIT
      , WidthCSS           INT
      , Semester           VARCHAR(10)
      , DiemMin            FLOAT
      , DiemMax            FLOAT
    );

    INSERT INTO @Table_CotDiem
    SELECT *
    FROM
           OPENJSON(@JSON_CotDiem)
           WITH
           (
               TemplateBangDiemID INT
             , CotDiemID INT
             , IDHeThong NVARCHAR(50)
             , MaCotDiem NVARCHAR(50)
             , TenCotDiem_VI NVARCHAR(200)
             , TenCotDiem_EN NVARCHAR(200)
             , TenHienThi_VI NVARCHAR(200)
             , TenHienThi_EN NVARCHAR(200)
             , MotaCotDiem_VI NVARCHAR(200)
             , MotaCotDiem_EN NVARCHAR(200)
             , LoaiCotDiem NVARCHAR(50)
             , KieuDanhGiaID TINYINT
             , GiaTriCotDiem VARCHAR(50)
             , LamTronBaoNhieuSo TINYINT
             , Formula NVARCHAR(1000)
             , ThuTuCotDiem TINYINT
             , MaNhomCotDiem NVARCHAR(50)
             , TenNhomCotDiem_VI NVARCHAR(500)
             , TenNhomCotDiem_EN NVARCHAR(500)
             , ThuTuNhom TINYINT
             , IsUserInput BIT
             , IsVisibleToParents BIT
             , IsSendToManager BIT
             , IsNegativeNumber BIT
             , WidthCSS INT
             , Semester VARCHAR(10)
             , DiemMin FLOAT
             , DiemMax FLOAT
           );

    UPDATE tbdct
    SET    tbdct.IDHeThong = t_cd.IDHeThong
         , tbdct.MaCotDiem = t_cd.MaCotDiem
         , tbdct.TenCotDiem_VI = t_cd.TenCotDiem_VI
         , tbdct.TenCotDiem_EN = t_cd.TenCotDiem_EN
         , tbdct.TenHienThi_VI = t_cd.TenHienThi_VI
         , tbdct.TenHienThi_EN = t_cd.TenHienThi_EN
         , tbdct.MotaCotDiem_VI = t_cd.MotaCotDiem_VI
         , tbdct.MotaCotDiem_EN = t_cd.MotaCotDiem_EN
         , tbdct.LoaiCotDiem = t_cd.LoaiCotDiem
         , tbdct.KieuDanhGiaID = t_cd.KieuDanhGiaID
         , tbdct.GiaTriCotDiem = t_cd.GiaTriCotDiem
         , tbdct.LamTronBaoNhieuSo = t_cd.LamTronBaoNhieuSo
         , tbdct.Formula = t_cd.Formula
         , tbdct.ThuTuCotDiem = t_cd.ThuTuCotDiem
         , tbdct.IsUserInput = t_cd.IsUserInput
         , tbdct.IsVisibleToParents = t_cd.IsVisibleToParents
         , tbdct.IsSendToManager = t_cd.IsSendToManager
         , tbdct.IsNegativeNumber = t_cd.IsNegativeNumber
         , tbdct.WidthCSS = t_cd.WidthCSS
         , tbdct.Semester = t_cd.Semester
         , tbdct.DiemMin = t_cd.DiemMin
         , tbdct.DiemMax = t_cd.DiemMax
    FROM
           dbo.TemplateBangDiemChiTiet AS tbdct
           INNER JOIN @Table_CotDiem   AS t_cd ON t_cd.TemplateBangDiemID = tbdct.TemplateBangDiemID
                                              AND t_cd.MaNhomCotDiem      = tbdct.MaNhomCotDiem
                                              AND t_cd.CotDiemID          = tbdct.CotDiemID;

END;