CREATE PROC [dbo].[spAPI_HocSinh_KeoDiem] @JsonHocSinh_KeoDiem NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Table_HocSinh TABLE
    (
        LopID     NVARCHAR(50)
      , TenLop    NVARCHAR(50)
      , HocKy     INT
      , STT       INT
      , MonHocID  NVARCHAR(50)
      , HocSinhID INT
      , HoTen     NVARCHAR(200)
      , NgaySinh  NVARCHAR(50)
      , TX1       FLOAT
      , TX2       FLOAT
      , TX3       FLOAT
      , TX4       FLOAT
      , GK        FLOAT
      , CK        FLOAT
      , DTB       FLOAT
    );

    INSERT INTO @Table_HocSinh
    (
        LopID
      , TenLop
      , HocKy
      , STT
      , MonHocID
      , HocSinhID
      , HoTen
      , NgaySinh
      , TX1
      , TX2
      , TX3
      , TX4
      , GK
      , CK
      , DTB
    )
    SELECT LopID
         , TenLop
         , HocKy
         , STT
         , MonHocID
         , HocSinhID
         , HoTen
         , NgaySinh
         , TX1
         , TX2
         , TX3
         , TX4
         , GK
         , CK
         , DTB
    FROM
           OPENJSON(@JsonHocSinh_KeoDiem)
           WITH
           (
               LopID NVARCHAR(50)
             , TenLop NVARCHAR(50)
             , HocKy INT
             , STT INT
             , MonHocID NVARCHAR(50)
             , HocSinhID INT
             , HoTen NVARCHAR(200)
             , NgaySinh NVARCHAR(50)
             , TX1 FLOAT
             , TX2 FLOAT
             , TX3 FLOAT
             , TX4 FLOAT
             , GK FLOAT
             , CK FLOAT
             , DTB FLOAT
           );

    UPDATE d
    SET    d.STT = t.STT
         , d.TX1 = t.TX1
         , d.TX2 = t.TX2
         , d.TX3 = t.TX3
         , d.TX4 = t.TX4
         , d.GK = t.GK
         , d.CK = t.CK
         , d.DTB = t.DTB
         , d.LuotCapNhat = d.LuotCapNhat + 1
    FROM
           dbo.tblDiem_HocSinh_Keo_Diem AS d
           INNER JOIN @Table_HocSinh    AS t ON t.LopID     = d.LopID
                                            AND t.HocKy     = d.HocKy
                                            AND t.MonHocID  = d.MonHocID
                                            AND t.HocSinhID = d.HocSinhID;

    INSERT INTO dbo.tblDiem_HocSinh_Keo_Diem
    (
        LopID
      , TenLop
      , HocKy
      , STT
      , MonHocID
      , HocSinhID
      , HoTen
      , NgaySinh
      , TX1
      , TX2
      , TX3
      , TX4
      , GK
      , CK
      , DTB
	  , LuotCapNhat 
    )
    SELECT LopID
         , TenLop
         , HocKy
         , STT
         , MonHocID
         , HocSinhID
         , HoTen
         , NgaySinh
         , TX1
         , TX2
         , TX3
         , TX4
         , GK
         , CK
         , DTB
		 , 0
    FROM
           @Table_HocSinh AS t
    WHERE
          NOT EXISTS
    (
        SELECT *
        FROM
               dbo.tblDiem_HocSinh_Keo_Diem AS d
        WHERE
               t.LopID    = d.LopID
          AND  t.HocKy     = d.HocKy
          AND  t.MonHocID  = d.MonHocID
          AND  t.HocSinhID = d.HocSinhID
    );
END;