CREATE PROC [dbo].[spAPI_HocSinhNhom_Ins]
    @Json_HocSinhNhom NVARCHAR(MAX)
  , @NhomID           VARCHAR(50)
  , @SYS_USERID       VARCHAR(9)
AS
BEGIN
    DECLARE @Table_HocSinhNhom TABLE
    (
        HSNhomID   INT
      , HocSinhID  INT
      , LopID      INT
      , NhomID     VARCHAR(50)
      , NhomID_HK1 VARCHAR(10)
      , SoDanhBo   VARCHAR(10)
      , SoTT       INT
    );

    DECLARE @Table_Log_HocSinhNhom TABLE
    (
        HSNhomID  INT
      , HocSinhID INT
      , LopID     INT
      , NhomID    VARCHAR(50)
      --, NhomID_HK1 VARCHAR(10)
      , SoDanhBo  VARCHAR(10)
      , SoTT      INT
    );

    INSERT INTO @Table_HocSinhNhom
    (
        HocSinhID
      , LopID
      , NhomID
      , SoTT
    )
    SELECT HocSinhID
         , LopID
         , @NhomID
         , SoTT
    FROM
           OPENJSON(@Json_HocSinhNhom)
           WITH
           (
               HocSinhID INT
             , LopID INT
             , SoTT INT
           );

    IF EXISTS
    (
        SELECT 1
        FROM
               @Table_HocSinhNhom            t
               INNER JOIN dbo.tblHocSinhNhom hsn ON hsn.HocSinhID = t.HocSinhID
                                                AND hsn.LopID     = t.LopID
                                                AND hsn.NhomID    = t.NhomID
                                                AND hsn.Enable    = 1
               INNER JOIN dbo.tblNhom        n ON n.NhomID        = hsn.NhomID
                                              AND n.NhomID        = t.NhomID
                                              AND n.NienKhoa      = dbo.fn_GetNienKhoa_HienTai()
                                              AND n.Enable        = 1
											  AND n.IsNhomLMS_GiaoBai = 0
    )
    BEGIN
        DECLARE @ErrMsg NVARCHAR(MAX);

        SELECT TOP 1
               @ErrMsg = N'Học sinh (HocSinhID=' + CAST(t.HocSinhID AS NVARCHAR) + N') đã tồn tại trong nhóm (NhomID=' + t.NhomID + N')'
        FROM
               @Table_HocSinhNhom            t
               INNER JOIN dbo.tblHocSinhNhom hsn ON hsn.HocSinhID = t.HocSinhID
                                                AND hsn.LopID     = t.LopID
                                                AND hsn.NhomID    = t.NhomID
                                                AND hsn.Enable    = 1;

        RAISERROR(@ErrMsg, 16, 1);
        RETURN;
    END;
    UPDATE t_hsn
    SET    t_hsn.SoDanhBo = hsl.SoDanhBo
    FROM
           @Table_HocSinhNhom           AS t_hsn
           INNER JOIN dbo.tblHocSinhLop AS hsl ON hsl.HocSinhID = t_hsn.HocSinhID
                                              AND hsl.LopID     = t_hsn.LopID;

    UPDATE hsn
    SET    hsn.NhomID = t_hsn.NhomID
         , hsn.UpdateUser = @SYS_USERID
         , hsn.UpdateTime = GETDATE()
    OUTPUT Inserted.HSNhomID
         , Inserted.HocSinhID
         , Inserted.LopID
         , Inserted.NhomID
         , Inserted.SoDanhBo
         , Inserted.SoTT
    INTO @Table_Log_HocSinhNhom
    FROM
           dbo.tblHocSinhNhom            AS hsn
           INNER JOIN @Table_HocSinhNhom AS t_hsn ON t_hsn.HocSinhID = hsn.HocSinhID
                                                 AND t_hsn.LopID     = hsn.LopID
                                                 AND t_hsn.NhomID    = hsn.NhomID
    WHERE
           hsn.Enable = 1;

    INSERT INTO dbo.tblHocSinhNhom
    (
        HocSinhID
      , LopID
      , NhomID
      , SoDanhBo
      , SoTT
      , CreateUser
      , CreateTime
    )
    OUTPUT Inserted.HSNhomID
         , Inserted.HocSinhID
         , Inserted.LopID
         , Inserted.NhomID
         , Inserted.SoDanhBo
         , Inserted.SoTT
    INTO @Table_Log_HocSinhNhom
    SELECT t_hsn.HocSinhID
         , t_hsn.LopID
         , t_hsn.NhomID
         , t_hsn.SoDanhBo
         , t_hsn.SoTT
         , @SYS_USERID
         , GETDATE()
    FROM
           @Table_HocSinhNhom AS t_hsn
    WHERE
           NOT EXISTS
    (
        SELECT *
        FROM
               dbo.tblHocSinhNhom AS hsn
        WHERE
               hsn.Enable     = 1
          AND  t_hsn.HocSinhID = hsn.HocSinhID
          AND  t_hsn.LopID     = hsn.LopID
          AND  t_hsn.NhomID    = hsn.NhomID
    );

    --Insert log
    INSERT INTO dbo.tbl_LOG_HocSinhNhom
    (
        HSNhomID
      , HocSinhID
      , LopID
      , NhomID
      , SoDanhBo
      , SoTT
      , Enable
      , CreateUser
      , CreateTime
    )
    SELECT HSNhomID
         , HocSinhID
         , LopID
         , NhomID
         , SoDanhBo
         , SoTT
         , 1
         , @SYS_USERID
         , GETDATE()
    FROM
           @Table_Log_HocSinhNhom;
END;


