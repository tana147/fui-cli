CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTraoChiTiet_Ins_JSON]
    @JsonData   NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.tblGiayKhenPhongTraoChiTiet
    (
        PhongTraoID
      , HocSinhID
      , HoTen
      , TenLop
      , LopID
      , KhoiID
      , VaoSo
      , DanhHieu_VI
      , DanhHieu_EN
      , SoQuyetDinhVaKhenThuong
      , Is_DaIn
      , Enable
      , CreateUser
      , CreateTime
    )
    SELECT j.PhongTraoID
         , j.HocSinhID
         , j.HoTen
         , j.TenLop
         , j.LopID
         , j.KhoiID
         , j.VaoSo
         , j.DanhHieu_VI
         , j.DanhHieu_EN
         , j.SoQuyetDinhVaKhenThuong
         , 0
         , 1
         , @sys_UserID
         , GETDATE()
    FROM
           OPENJSON(@JsonData)
           WITH
           (
               PhongTraoID             INT
             , HocSinhID               INT
             , HoTen                   NVARCHAR(200)
             , TenLop                  VARCHAR(20)
             , LopID                   INT
             , KhoiID                  INT
             , VaoSo                   INT
             , DanhHieu_VI             NVARCHAR(500)
             , DanhHieu_EN             NVARCHAR(500)
             , SoQuyetDinhVaKhenThuong NVARCHAR(100)
           ) AS j;

    SELECT Inserted = @@ROWCOUNT;
END
