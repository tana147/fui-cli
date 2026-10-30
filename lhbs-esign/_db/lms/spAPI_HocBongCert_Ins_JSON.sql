CREATE PROCEDURE [dbo].[spAPI_HocBongCert_Ins_JSON]
    @JsonData   NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.tblHocBongCert
    (
        HocSinhID
      , HoTen
      , TenLop
      , LopID
      , KhoiID
      , NgaySinh
      , MucHocBong
      , HocKy
      , NienKhoa
      , TieuChi_VI
      , TieuChi_EN
      , SoQuyetDinh
      , VaoSo
      , NgayCap_VI
      , NgayCap_EN
      , Is_DaIn
      , Enable
      , CreateUser
      , CreateTime
    )
    SELECT j.HocSinhID
         , hs.Ho + N' ' + hs.Ten
         , j.TenLop
         , l.LopID
         , TRY_CAST(SUBSTRING(j.TenLop, 1, 2) AS INT)
         , j.NgaySinh
         , j.MucHocBong
         , j.HocKy
         , j.NienKhoa
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , 0
         , 1
         , @sys_UserID
         , GETDATE()
    FROM
           OPENJSON(@JsonData)
           WITH
           (
               HocSinhID   INT
             , TenLop      VARCHAR(10)
             , NgaySinh    VARCHAR(20)
             , MucHocBong  NVARCHAR(100)
             , HocKy       INT
             , NienKhoa    INT
           ) AS j
           INNER JOIN dbo.tblHocSinh AS hs ON hs.HocSinhID = j.HocSinhID
           LEFT JOIN dbo.tblLop AS l ON l.TenLop = j.TenLop AND l.NienKhoa = j.NienKhoa AND l.Enable = 1
    WHERE
           NOT EXISTS
           (
               SELECT 1
               FROM dbo.tblHocBongCert AS existing
               WHERE existing.Enable = 1
                 AND existing.HocSinhID = j.HocSinhID
                 AND existing.HocKy = j.HocKy
                 AND existing.NienKhoa = j.NienKhoa
           );

    SELECT Inserted = @@ROWCOUNT;
END
