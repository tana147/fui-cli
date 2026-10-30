CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetKhoiDay]
    @SYS_USERID VARCHAR(9)
  , @HocKi      INT
  , @NienKhoa   INT
AS
BEGIN
    SELECT KH.KhoiID
         , KH.TenKhoiHoc
         , KH.KhoiHocCode
    FROM
           dbo.tblKhoi KH
    WHERE
           KH.Enable = 1
      AND  KH.KhoiID IN
           (
               SELECT KhoiID
               FROM
                      dbo.tblGiaoVienLop gvl
               WHERE
                      gvl.GiaoVienID = @SYS_USERID
                 AND  gvl.KhoiID      = KH.KhoiID
                 AND  NienKhoa        = @NienKhoa
                 AND  gvl.HocKy       = @HocKi
           );
END;