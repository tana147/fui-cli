CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTraoCert_Upd_JSON]
    @JsonData   NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
    SET    t.HoTen                   = ISNULL(j.HoTen, t.HoTen)
         , t.TenLop                  = ISNULL(j.TenLop, t.TenLop)
         , t.KhoiID                  = ISNULL(j.KhoiID, t.KhoiID)
         , t.DanhHieu_VI             = j.DanhHieu_VI
         , t.DanhHieu_EN             = j.DanhHieu_EN
         , t.NgayCap_VI              = j.NgayCap_VI
         , t.NgayCap_EN              = j.NgayCap_EN
         , t.SoQuyetDinh             = j.SoQuyetDinh
         , t.VaoSo                   = j.VaoSo
         , t.SoQuyetDinhVaKhenThuong = j.SoQuyetDinhVaKhenThuong
         , t.UpdateUser              = @sys_UserID
         , t.UpdateTime              = GETDATE()
    FROM
           dbo.tblGiayKhenPhongTraoCert AS t
           INNER JOIN OPENJSON(@JsonData)
           WITH
           (
               PhongTraoCertID         INT
             , HoTen                   NVARCHAR(200)
             , TenLop                  VARCHAR(20)
             , KhoiID                  INT
             , DanhHieu_VI             NVARCHAR(500)
             , DanhHieu_EN             NVARCHAR(500)
             , NgayCap_VI              NVARCHAR(100)
             , NgayCap_EN              NVARCHAR(100)
             , SoQuyetDinh             NVARCHAR(50)
             , VaoSo                   INT
             , SoQuyetDinhVaKhenThuong NVARCHAR(100)
           ) AS j ON j.PhongTraoCertID = t.PhongTraoCertID
    WHERE
           t.Enable = 1;

    SELECT Updated = @@ROWCOUNT;
END