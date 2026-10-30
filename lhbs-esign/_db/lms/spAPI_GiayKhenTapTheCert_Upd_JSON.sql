CREATE PROCEDURE [dbo].[spAPI_GiayKhenTapTheCert_Upd_JSON]
    @JsonData   NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
    SET    t.DanhHieu    = j.MucHocBong
         , t.TieuChi_VI  = j.TieuChi_VI
         , t.TieuChi_EN  = j.TieuChi_EN
         , t.SoQuyetDinh = j.SoQuyetDinh
         , t.VaoSo       = j.VaoSo
         , t.NgayCap_VI  = j.NgayCap_VI
         , t.NgayCap_EN  = j.NgayCap_EN
         , t.UpdateUser  = @sys_UserID
         , t.UpdateTime  = GETDATE()
    FROM
           dbo.tblGiayKhenTapTheCert AS t
           INNER JOIN OPENJSON(@JsonData)
           WITH
           (
               HocBongCertID INT
             , MucHocBong    NVARCHAR(100)
             , TieuChi_VI    NVARCHAR(500)
             , TieuChi_EN    NVARCHAR(500)
             , SoQuyetDinh   NVARCHAR(50)
             , VaoSo         INT
             , NgayCap_VI    NVARCHAR(100)
             , NgayCap_EN    NVARCHAR(100)
           ) AS j ON j.HocBongCertID = t.GiayKhenCertID
    WHERE
           t.Enable = 1;

    SELECT Updated = @@ROWCOUNT;
END