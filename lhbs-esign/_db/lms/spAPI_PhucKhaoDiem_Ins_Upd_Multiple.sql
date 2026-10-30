CREATE PROC [dbo].[spAPI_PhucKhaoDiem_Ins_Upd_Multiple]
    @Json_PhucKhao NVARCHAR(MAX)
  , @SYS_USERID    VARCHAR(9)
AS
BEGIN
    DECLARE @Table_PhucKhao TABLE
    (
        PhucKhaoID        INT
      , MonHocLopID       INT
      , HocSinhID         INT
      , CotDiemID         INT
      , KetQuaBanDau      NVARCHAR(2000)
      , PhucKhao_Lan1     NVARCHAR(2000)
      , PhucKhao_Lan2     NVARCHAR(2000)
      , PhucKhao_Lan3     NVARCHAR(2000)
      , PhucKhao_Lan4     NVARCHAR(2000)
      , PhucKhao_Lan5     NVARCHAR(2000)
      , LyDoPhucKhao_Lan1 NVARCHAR(2000)
      , LyDoPhucKhao_Lan2 NVARCHAR(2000)
      , LyDoPhucKhao_Lan3 NVARCHAR(2000)
      , LyDoPhucKhao_Lan4 NVARCHAR(2000)
      , LyDoPhucKhao_Lan5 NVARCHAR(2000)
      , NienKhoa          INT
    );
    INSERT INTO @Table_PhucKhao
    SELECT NULL AS PhucKhaoID
         , MonHocLopID
         , HocSinhID
         , CotDiemID
         , KetQuaBanDau
         , PhucKhao_Lan1
         , PhucKhao_Lan2
         , PhucKhao_Lan3
         , PhucKhao_Lan4
         , PhucKhao_Lan5
         , LyDoPhucKhao_Lan1
         , LyDoPhucKhao_Lan2
         , LyDoPhucKhao_Lan3
         , LyDoPhucKhao_Lan4
         , LyDoPhucKhao_Lan5
         , NienKhoa
    FROM
           OPENJSON(@Json_PhucKhao)
           WITH
           (
               MonHocLopID INT
             , HocSinhID INT
             , CotDiemID INT
             , KetQuaBanDau NVARCHAR(2000)
             , PhucKhao_Lan1 NVARCHAR(2000)
             , PhucKhao_Lan2 NVARCHAR(2000)
             , PhucKhao_Lan3 NVARCHAR(2000)
             , PhucKhao_Lan4 NVARCHAR(2000)
             , PhucKhao_Lan5 NVARCHAR(2000)
             , LyDoPhucKhao_Lan1 NVARCHAR(2000)
             , LyDoPhucKhao_Lan2 NVARCHAR(2000)
             , LyDoPhucKhao_Lan3 NVARCHAR(2000)
             , LyDoPhucKhao_Lan4 NVARCHAR(2000)
             , LyDoPhucKhao_Lan5 NVARCHAR(2000)
             , NienKhoa INT
           );

    UPDATE T
    SET    T.PhucKhaoID = pk.PhucKhaoID
    FROM
           @Table_PhucKhao           AS T
           LEFT JOIN dbo.tblPhucKhao pk ON pk.MonHocLopID = T.MonHocLopID
                                       AND pk.HocSinhID   = T.HocSinhID
                                       AND pk.CotDiemID   = T.CotDiemID


									   SELECT * FROM @Table_PhucKhao
 UPDATE pk
SET 
    pk.PhucKhao_Lan1 = t.PhucKhao_Lan1,
    pk.PhucKhao_Lan2 = t.PhucKhao_Lan2,
    pk.PhucKhao_Lan3 = t.PhucKhao_Lan3,
    pk.PhucKhao_Lan4 = t.PhucKhao_Lan4,
    pk.PhucKhao_Lan5 = t.PhucKhao_Lan5,
    pk.LyDoPhucKhao_Lan1 = t.LyDoPhucKhao_Lan1,
    pk.LyDoPhucKhao_Lan2 = t.LyDoPhucKhao_Lan2,
    pk.LyDoPhucKhao_Lan3 = t.LyDoPhucKhao_Lan3,
    pk.LyDoPhucKhao_Lan4 = t.LyDoPhucKhao_Lan4,
    pk.LyDoPhucKhao_Lan5 = t.LyDoPhucKhao_Lan5,
    pk.UpdateUser = @SYS_USERID,
    pk.UpdateTime = GETDATE()
FROM dbo.tblPhucKhao pk
INNER JOIN @Table_PhucKhao t ON t.PhucKhaoID = pk.PhucKhaoID
WHERE 
    (
        ISNULL(t.PhucKhao_Lan1, '') <> ISNULL(pk.PhucKhao_Lan1, '')
        AND ISNULL(t.LyDoPhucKhao_Lan1, '') <> ''
    )
 OR (
        ISNULL(t.PhucKhao_Lan2, '') <> ISNULL(pk.PhucKhao_Lan2, '')
        AND ISNULL(t.LyDoPhucKhao_Lan2, '') <> ''
    )
 OR (
        ISNULL(t.PhucKhao_Lan3, '') <> ISNULL(pk.PhucKhao_Lan3, '')
        AND ISNULL(t.LyDoPhucKhao_Lan3, '') <> ''
    )
 OR (
        ISNULL(t.PhucKhao_Lan4, '') <> ISNULL(pk.PhucKhao_Lan4, '')
        AND ISNULL(t.LyDoPhucKhao_Lan4, '') <> ''
    )
 OR (
        ISNULL(t.PhucKhao_Lan5, '') <> ISNULL(pk.PhucKhao_Lan5, '')
        AND ISNULL(t.LyDoPhucKhao_Lan5, '') <> ''
    );


    INSERT INTO tblPhucKhao
    (
        MonHocLopID
      , HocSinhID
      , CotDiemID
      , KetQuaBanDau
      , PhucKhao_Lan1
      , PhucKhao_Lan2
      , PhucKhao_Lan3
      , PhucKhao_Lan4
      , PhucKhao_Lan5
      , LyDoPhucKhao_Lan1
      , LyDoPhucKhao_Lan2
      , LyDoPhucKhao_Lan3
      , LyDoPhucKhao_Lan4
      , LyDoPhucKhao_Lan5
      , [Enable]
      , CreateUser
      , CreateTime
    )
    SELECT MonHocLopID
         , HocSinhID
         , CotDiemID
         , KetQuaBanDau
         , PhucKhao_Lan1
         , PhucKhao_Lan2
         , PhucKhao_Lan3
         , PhucKhao_Lan4
         , PhucKhao_Lan5
         , LyDoPhucKhao_Lan1
         , LyDoPhucKhao_Lan2
         , LyDoPhucKhao_Lan3
         , LyDoPhucKhao_Lan4
         , LyDoPhucKhao_Lan5
         , 1           AS [Enable]
         , @SYS_USERID AS CreateUser
         , GETDATE()   AS CreateTime
    FROM
           @Table_PhucKhao t
    WHERE
           NOT EXISTS
    (
        SELECT TOP 1
               *
        FROM
               tblPhucKhao pk
        WHERE
               pk.PhucKhaoID = t.PhucKhaoID
    );

END;