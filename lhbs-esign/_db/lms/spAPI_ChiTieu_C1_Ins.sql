CREATE PROC [dbo].[spAPI_ChiTieu_C1_Ins]
    @JsonMonHoc      NVARCHAR(MAX) = N''
  , @JsonMonHoc_NLPC NVARCHAR(MAX) = N''
  , @SYS_USERID      VARCHAR(9)
AS
BEGIN
    DECLARE @Table_MonHoc TABLE
    (
        ChiTieuID             INT
      , KhoiID                INT
      , MonHocID              INT
      , Is_MonHoc             BIT
      , NienKhoa              INT
      , ChiTieu_HoanThanhTot  FLOAT
      , ChiTieu_HoanThanh     FLOAT
      , ChiTieu_ChuaHoanThanh FLOAT
      , ChiTieu_Tot           FLOAT
      , ChiTieu_Dat           FLOAT
      , ChiTieu_CanCoGang     FLOAT
    );
    INSERT INTO @Table_MonHoc
    (
        ChiTieuID
      , KhoiID
      , MonHocID
      , Is_MonHoc
      , NienKhoa
      , ChiTieu_HoanThanhTot
      , ChiTieu_HoanThanh
      , ChiTieu_ChuaHoanThanh
      , ChiTieu_Tot
      , ChiTieu_Dat
      , ChiTieu_CanCoGang
    )
    SELECT *
    FROM
           OPENJSON(@JsonMonHoc)
           WITH
           (
               ChiTieuID INT
             , KhoiID INT
             , MonHocID INT
             , Is_MonHoc BIT
             , NienKhoa INT
             , ChiTieu_HoanThanhTot FLOAT
             , ChiTieu_HoanThanh FLOAT
             , ChiTieu_ChuaHoanThanh FLOAT
             , ChiTieu_Tot FLOAT
             , ChiTieu_Dat FLOAT
             , ChiTieu_CanCoGang FLOAT
           )
    UNION
    SELECT *
    FROM
           OPENJSON(@JsonMonHoc_NLPC)
           WITH
           (
               ChiTieuID INT
             , KhoiID INT
             , MonHocID INT
             , Is_MonHoc BIT
             , NienKhoa INT
             , ChiTieu_HoanThanhTot FLOAT
             , ChiTieu_HoanThanh FLOAT
             , ChiTieu_ChuaHoanThanh FLOAT
             , ChiTieu_Tot FLOAT
             , ChiTieu_Dat FLOAT
             , ChiTieu_CanCoGang FLOAT
           );

    UPDATE ct_ct
    SET    ct_ct.ChiTieu_HoanThanhTot = ISNULL(t.ChiTieu_HoanThanhTot, ct_ct.ChiTieu_HoanThanhTot)
         , ct_ct.ChiTieu_HoanThanh = ISNULL(t.ChiTieu_HoanThanh, ct_ct.ChiTieu_HoanThanh)
         , ct_ct.ChiTieu_ChuaHoanThanh = ISNULL(t.ChiTieu_ChuaHoanThanh, ct_ct.ChiTieu_ChuaHoanThanh)
         , ct_ct.ChiTieu_Tot = ISNULL(t.ChiTieu_Tot, ct_ct.ChiTieu_Tot)
         , ct_ct.ChiTieu_Dat = ISNULL(t.ChiTieu_Dat, ct_ct.ChiTieu_Dat)
         , ct_ct.ChiTieu_CanCoGang = ISNULL(t.ChiTieu_CanCoGang, ct_ct.ChiTieu_CanCoGang)
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    FROM
           tblChiTieu_C1            AS ct_ct
           INNER JOIN @Table_MonHoc t ON t.KhoiID = ct_ct.KhoiID AND t.MonHocID= ct_ct.MonHocID AND t.NienKhoa = ct_ct.NienKhoa;

    INSERT INTO tblChiTieu_C1
    (
        ChiTieu_HoanThanhTot
      , ChiTieu_HoanThanh
      , ChiTieu_ChuaHoanThanh
      , ChiTieu_Tot
      , ChiTieu_Dat
      , ChiTieu_CanCoGang
      , KhoiID
      , MonHocID
      , NienKhoa
      , [Enable]
      , CreateUser
      , CreateTime
    )
    SELECT ChiTieu_HoanThanhTot
         , ChiTieu_HoanThanh
         , ChiTieu_ChuaHoanThanh
         , ChiTieu_Tot
         , ChiTieu_Dat
         , ChiTieu_CanCoGang
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
               dbo.tblChiTieu_C1 AS ct_ct
        WHERE
            t.KhoiID = ct_ct.KhoiID AND t.MonHocID= ct_ct.MonHocID AND t.NienKhoa = ct_ct.NienKhoa
    );

END;
