CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTraoCert_Ins_JSON]
    @JsonData   NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.tblGiayKhenPhongTraoCert
    (
        LoaiMau
      , HocSinhID
      , HoTen
      , TenLop
      , LopID
      , KhoiID
      , DanhHieu_VI
      , DanhHieu_EN
      , NgayCap_VI
      , NgayCap_EN
      , SoQuyetDinh
      , VaoSo
      , SoQuyetDinhVaKhenThuong
      , HocKy
      , NienKhoa
      , Is_DaIn
      , Enable
      , CreateUser
      , CreateTime
    )
    SELECT j.LoaiMau
         , j.HocSinhID
         , j.HoTen
         , j.TenLop
         , j.LopID
         , j.KhoiID
         , j.DanhHieu_VI
         , j.DanhHieu_EN
         , j.NgayCap_VI
         , j.NgayCap_EN
         , j.SoQuyetDinh
         , j.VaoSo
         , j.SoQuyetDinhVaKhenThuong
         , ISNULL(j.HocKy, 1)
         , ISNULL(j.NienKhoa, 2026)
         , 0
         , 1
         , @sys_UserID
         , GETDATE()
    FROM
           OPENJSON(@JsonData)
           WITH
           (
               LoaiMau                 INT
             , HocSinhID               INT
             , HoTen                   NVARCHAR(200)
             , TenLop                  VARCHAR(20)
             , LopID                   INT
             , KhoiID                  INT
             , DanhHieu_VI             NVARCHAR(500)
             , DanhHieu_EN             NVARCHAR(500)
             , NgayCap_VI              NVARCHAR(100)
             , NgayCap_EN              NVARCHAR(100)
             , SoQuyetDinh             NVARCHAR(50)
             , VaoSo                   INT
             , SoQuyetDinhVaKhenThuong NVARCHAR(100)
             , HocKy                   INT
             , NienKhoa                INT
           ) AS j;

    SELECT Inserted = @@ROWCOUNT;
END