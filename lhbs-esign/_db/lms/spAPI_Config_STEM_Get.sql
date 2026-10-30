
CREATE PROC [dbo].[spAPI_Config_STEM_Get]
    @NienKhoa     INT
  , @KhoiID       INT             -- Thêm mới: lọc theo khối
  , @SYS_USERID   VARCHAR(9)
  , @Sys_GroupID  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
           cfg.ConfigID
         , cfg.NienKhoa
         , cfg.KhoiID
         , cfg.HocKi
         , LTRIM(RTRIM(cfg.HocKi_LayTongDiemChuDe)) AS HocKi_LayTongDiemChuDe
         , cfg.Enable
    FROM   dbo.tblConfig_STEM cfg
    WHERE  cfg.NienKhoa = @NienKhoa
      AND  cfg.KhoiID   = @KhoiID
      AND  cfg.Enable   = 1
    ORDER BY
           cfg.HocKi;

END;
