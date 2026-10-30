CREATE PROC spAPI_GiaoVienLop_Ins_Multiple
    @JsonData   NVARCHAR(MAX)
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    DECLARE @Table_GiaoVienLop TABLE
    (
        GiaoVienID VARCHAR(10)
      , KhoiID     INT
      , LopID      VARCHAR(9)
      , MonHocID   INT
      , MonHocCode NVARCHAR(50)
      , HocKy      NVARCHAR(50)
      --, MaDonVi    INT
      --, VaiTro     TINYINT
      , NienKhoa   INT
    );
    INSERT INTO @Table_GiaoVienLop
    (
        GiaoVienID
      , KhoiID
      , LopID
      , MonHocCode
      , HocKy
      --, MaDonVi
      --, VaiTro
      , NienKhoa
    )
    SELECT GiaoVienID
         , KhoiID
         , LopID
         , MonHocID  AS MonHocCode
         , HocKy
         --, MaDonVi
         --, VaiTro
         , NienKhoa
    FROM
           OPENJSON(@JsonData)
           WITH
           (
               GiaoVienID VARCHAR(10)
             , KhoiID INT
             , LopID VARCHAR(9)
             , MonHocID NVARCHAR(50)
             , HocKy NVARCHAR(50)
             --, MaDonVi INT
             --, VaiTro TINYINT
             , NienKhoa INT
           );

    UPDATE t_gvl
    SET    t_gvl.MonHocID = mh.MonHocID
         , t_gvl.KhoiID = l.KhoiID
    FROM
           @Table_GiaoVienLop       t_gvl
           INNER JOIN dbo.tblMonHoc mh ON mh.MonHocCode = t_gvl.MonHocCode
                                      AND mh.Enable     = 1
           INNER JOIN dbo.tblLop    l ON l.LopID        = t_gvl.LopID
                                     AND l.NienKhoa     = t_gvl.NienKhoa
                                     AND l.Enable       = 1;

    UPDATE gvl
    SET    gvl.Enable = 0
         , gvl.UpdateUser = @SYS_USERID
         , gvl.UpdateTime = GETDATE()
    FROM
           dbo.tblGiaoVienLop            AS gvl
           INNER JOIN @Table_GiaoVienLop t_gvl ON t_gvl.LopID      = gvl.LopID
                                              AND t_gvl.GiaoVienID = gvl.GiaoVienID
                                              AND t_gvl.MonHocID   = gvl.MonHocID
                                              AND t_gvl.HocKy      = gvl.HocKy
                                              AND t_gvl.NienKhoa   = gvl.NienKhoa
    WHERE
           gvl.Enable = 1;

    INSERT INTO dbo.tblGiaoVienLop
    (
        GiaoVienID
      , KhoiID
      , LopID
      , MonHocID
      , MaDonVi
      , Enable
      , VaiTro
      , NienKhoa
      , HocKy
      , CreateUser
      , CreateTime
    )
    SELECT t_gvl.GiaoVienID
         , t_gvl.KhoiID
         , t_gvl.LopID
         , t_gvl.MonHocID
         , 1          AS MaDonVi
         , 1          AS Enable
         , 3          AS VaiTro
         , t_gvl.NienKhoa
         , t_gvl.HocKy
         , @SYS_USERID
         , GETDATE()
    FROM
           @Table_GiaoVienLop t_gvl
    WHERE
           NOT EXISTS
    (
        SELECT *
        FROM
               dbo.tblGiaoVienLop gvl
        WHERE
               t_gvl.LopID     = gvl.LopID
          AND  t_gvl.GiaoVienID = gvl.GiaoVienID
          AND  t_gvl.MonHocID   = gvl.MonHocID
          AND  t_gvl.NienKhoa   = gvl.NienKhoa
          AND  t_gvl.HocKy      = gvl.HocKy
          AND  gvl.Enable       = 1
    );
END;
