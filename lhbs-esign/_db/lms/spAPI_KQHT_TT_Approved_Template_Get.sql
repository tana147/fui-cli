CREATE PROC spAPI_KQHT_TT_Approved_Template_Get
    @LopID      NVARCHAR(20)
  ------
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    DECLARE @Table TABLE
    (
        TemplateBangDiemID   INT
      , TemplateBangDiemName NVARCHAR(500)
      , MaNhomCotDiem        NVARCHAR(100)
      , TenNhomCotDiem_VI    NVARCHAR(100)
      , CotDiemID            INT
    );
    INSERT INTO @Table
    (
        TemplateBangDiemID
      , TemplateBangDiemName
      , MaNhomCotDiem
      , TenNhomCotDiem_VI
      , CotDiemID
    )
    SELECT DISTINCT
           tbd.TemplateBangDiemID
         , tbd.TemplateBangDiemName
         , tbdct.MaNhomCotDiem
         , tbdct.TenNhomCotDiem_VI
         , kqht.CotDiemID
    FROM
           dbo.tblKetQuaHocTap                    kqht
           INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID      = kqht.CotDiemID
                                                       AND tbdct.Enable         = 1
           INNER JOIN dbo.TemplateBangDiem        tbd ON tbd.TemplateBangDiemID = tbdct.TemplateBangDiemID
                                                     AND tbd.Enable             = 1
           INNER JOIN dbo.tblMonHocLop            mhl ON mhl.MonHocLopID        = kqht.MonHocLopID
                                                     AND mhl.LopNhomID          = @LopID
                                                     AND mhl.Enable             = 1
    WHERE
           kqht.Enable   = 1
      AND  kqht.TinhTrang = 4;
    SELECT DISTINCT
           TemplateBangDiemID
         , TemplateBangDiemName
         , TenNhomCotDiem_VI
         , MaNhomCotDiem
    FROM
           @Table;
END;