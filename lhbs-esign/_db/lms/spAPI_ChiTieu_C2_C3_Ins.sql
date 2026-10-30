CREATE PROC [dbo].[spAPI_ChiTieu_C2_C3_Ins]
    @JsonMonHoc      NVARCHAR(MAX) = N''
  , @SYS_USERID      VARCHAR(9)
AS
BEGIN
    DECLARE @Table_MonHoc TABLE
    (
        ChiTieuID       INT
      , KhoiID          INT
      , MonHocID        INT
      , NienKhoa        INT
      , ChiTieu_Tot     FLOAT
      , ChiTieu_Kha     FLOAT
      , ChiTieu_Dat     FLOAT
      , ChiTieu_ChuaDat FLOAT
    );
    INSERT INTO @Table_MonHoc
    (
        ChiTieuID
      , KhoiID
      , MonHocID
      , NienKhoa
      , ChiTieu_Tot
      , ChiTieu_Kha
      , ChiTieu_Dat
      , ChiTieu_ChuaDat
    )
    SELECT *
    FROM
           OPENJSON(@JsonMonHoc)
           WITH
           (
               ChiTieuID INT
             , KhoiID INT
             , MonHocID INT
             , NienKhoa INT
             , ChiTieu_Tot FLOAT
             , ChiTieu_Kha FLOAT
             , ChiTieu_Dat FLOAT
             , ChiTieu_ChuaDat FLOAT
           );

    UPDATE ct_ct
    SET    ct_ct.ChiTieu_Tot = ISNULL(t.ChiTieu_Tot, ct_ct.ChiTieu_Tot)
         , ct_ct.ChiTieu_Kha = ISNULL(t.ChiTieu_Kha, ct_ct.ChiTieu_Kha)
         , ct_ct.ChiTieu_Dat = ISNULL(t.ChiTieu_Dat, ct_ct.ChiTieu_Dat)
         , ct_ct.ChiTieu_ChuaDat = ISNULL(t.ChiTieu_ChuaDat, ct_ct.ChiTieu_ChuaDat)
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    FROM
           tblChiTieu_C2            AS ct_ct
           INNER JOIN @Table_MonHoc t ON t.KhoiID   = ct_ct.KhoiID
                                     AND t.MonHocID = ct_ct.MonHocID
                                     AND t.NienKhoa = ct_ct.NienKhoa;

    INSERT INTO tblChiTieu_C2
    (
        ChiTieu_Tot
      , ChiTieu_Kha
      , ChiTieu_Dat
      , ChiTieu_ChuaDat
      , KhoiID
      , MonHocID
      , NienKhoa
      , [Enable]
      , CreateUser
      , CreateTime
    )
    SELECT ChiTieu_Tot
         , ChiTieu_Kha
         , ChiTieu_Dat
         , ChiTieu_ChuaDat
         , t.KhoiID
         , MonHocID
         , NienKhoa
         , 1           AS [Enable]
         , @SYS_USERID AS CreateUser
         , GETDATE()   AS CreateTime
    FROM
           @Table_MonHoc AS t
    WHERE
           NOT EXISTS
    (
        SELECT *
        FROM
               dbo.tblChiTieu_C2 AS ct_ct
        WHERE
               t.KhoiID  = ct_ct.KhoiID
          AND  t.MonHocID = ct_ct.MonHocID
          AND  t.NienKhoa = ct_ct.NienKhoa
    );

END;
