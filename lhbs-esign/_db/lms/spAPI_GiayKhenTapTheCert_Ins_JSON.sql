CREATE PROCEDURE [dbo].[spAPI_GiayKhenTapTheCert_Ins_JSON]
    @JsonData   NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.tblGiayKhenTapTheCert
    (
        HocSinhID
      , HoTen
      , TenLop
      , LopID
      , KhoiID
      , NgaySinh
      , DanhHieu
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
    SELECT ISNULL(j.HocSinhID, 0)
         , ISNULL(j.HoTen, N'Tập thể Lớp ' + j.TenLop)
         , j.TenLop
         , j.LopID
         , ISNULL(j.KhoiID, TRY_CAST(SUBSTRING(j.TenLop, 1, 2) AS INT))
         , NULL
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
             , HoTen       NVARCHAR(200)
             , TenLop      VARCHAR(10)
             , LopID       INT
             , KhoiID      INT
             , MucHocBong  NVARCHAR(100)
             , HocKy       INT
             , NienKhoa    INT
           ) AS j
    WHERE
           NOT EXISTS
           (
               SELECT 1
               FROM dbo.tblGiayKhenTapTheCert AS existing
               WHERE existing.Enable = 1
                 AND existing.TenLop = j.TenLop
                 AND existing.HocKy = j.HocKy
                 AND existing.NienKhoa = j.NienKhoa
           );

    SELECT Inserted = @@ROWCOUNT;
END