CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTraoChiTiet_Upd_JSON]
    @JsonData   NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
    SET    t.HocSinhID               = ISNULL(j.HocSinhID, t.HocSinhID)
         , t.HoTen                   = ISNULL(j.HoTen, t.HoTen)
         , t.TenLop                  = ISNULL(j.TenLop, t.TenLop)
         , t.LopID                   = ISNULL(j.LopID, t.LopID)
         , t.KhoiID                  = ISNULL(j.KhoiID, t.KhoiID)
         , t.VaoSo                   = j.VaoSo
         , t.DanhHieu_VI             = j.DanhHieu_VI
         , t.DanhHieu_EN             = j.DanhHieu_EN
         , t.SoQuyetDinhVaKhenThuong = j.SoQuyetDinhVaKhenThuong
         , t.UpdateUser              = @sys_UserID
         , t.UpdateTime              = GETDATE()
    FROM
           dbo.tblGiayKhenPhongTraoChiTiet AS t
           INNER JOIN OPENJSON(@JsonData)
           WITH
           (
               ChiTietID               INT
             , HocSinhID               INT
             , HoTen                   NVARCHAR(200)
             , TenLop                  VARCHAR(20)
             , LopID                   INT
             , KhoiID                  INT
             , VaoSo                   INT
             , DanhHieu_VI             NVARCHAR(500)
             , DanhHieu_EN             NVARCHAR(500)
             , SoQuyetDinhVaKhenThuong NVARCHAR(100)
           ) AS j ON j.ChiTietID = t.ChiTietID
    WHERE
           t.Enable = 1;

    SELECT Updated = @@ROWCOUNT;
END
