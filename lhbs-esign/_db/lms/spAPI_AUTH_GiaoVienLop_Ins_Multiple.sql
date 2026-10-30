--
CREATE PROC [dbo].[spAPI_AUTH_GiaoVienLop_Ins_Multiple]
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
      , NienKhoa   INT
    );
    INSERT INTO @Table_GiaoVienLop
    (
        GiaoVienID
      , KhoiID
      , LopID
      , MonHocCode
      , HocKy
      , NienKhoa
    )
    SELECT GiaoVienID
         , KhoiID
         , LopID
         , MonHocID  AS MonHocCode
         , HocKy
         --, MaDonVi
         --, VaiTro
         , NamHoc
    FROM
           OPENJSON(@JsonData)
           WITH
           (
               GiaoVienID VARCHAR(10)
             , KhoiID INT
             , LopID VARCHAR(9)
             , MonHocID NVARCHAR(50)
             , HocKy NVARCHAR(50)
             , NamHoc INT
           );




    UPDATE t_gvl
    SET    t_gvl.MonHocID = mh.MonHocID
         , t_gvl.KhoiID = l.KhoiID
    FROM
           @Table_GiaoVienLop       t_gvl
           INNER JOIN dbo.tblLop    l ON l.LopID        = t_gvl.LopID
                                     AND l.NienKhoa     = t_gvl.NienKhoa
                                     AND l.Enable       = 1
           INNER JOIN dbo.tblMonHoc mh ON mh.MonHocCode = t_gvl.MonHocCode
                                      AND mh.Enable     = 1
                                      AND mh.CapID      = CASE WHEN l.KhoiID >= 10 THEN 3 WHEN l.KhoiID >= 6 THEN 2 ELSE 1 END;

    UPDATE gvl
    SET    gvl.GiaoVienID = t_gvl.GiaoVienID
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    FROM
           dbo.tblGiaoVienLop            AS gvl
           INNER JOIN @Table_GiaoVienLop AS t_gvl ON gvl.MonHocID           = t_gvl.MonHocID
                                                 AND t_gvl.NienKhoa         = gvl.NienKhoa
                                                 AND t_gvl.HocKy            = gvl.HocKy
                                                 AND t_gvl.LopID            = gvl.LopID
                                                 AND gvl.Is_PhanCong_QLDiem = 1
    WHERE
           gvl.Enable = 1
      AND  t_gvl.MonHocID IS NOT NULL
      AND  t_gvl.KhoiID IS NOT NULL
      AND  t_gvl.LopID IS NOT NULL;

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
      , Is_PhanCong_QLDiem
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
         , 1          AS Is_PhanCong_QLDiem
         , @SYS_USERID
         , GETDATE()
    FROM
           @Table_GiaoVienLop t_gvl
    WHERE
           t_gvl.MonHocID IS NOT NULL
      AND  t_gvl.KhoiID IS NOT NULL
      AND  t_gvl.LopID IS NOT NULL
      AND  NOT EXISTS
    (
        SELECT *
        FROM
               dbo.tblGiaoVienLop gvl
        WHERE
               t_gvl.LopID           = gvl.LopID
          AND  t_gvl.GiaoVienID       = gvl.GiaoVienID
          AND  t_gvl.MonHocID         = gvl.MonHocID
          AND  t_gvl.NienKhoa         = gvl.NienKhoa
          AND  t_gvl.HocKy            = gvl.HocKy
          AND  gvl.Is_PhanCong_QLDiem = 1
          AND  gvl.Enable             = 1
    );
END;

GRANT EXECUTE ON [dbo].[spAPI_AUTH_GiaoVienLop_Ins_Multiple] TO [lmslhbs];
