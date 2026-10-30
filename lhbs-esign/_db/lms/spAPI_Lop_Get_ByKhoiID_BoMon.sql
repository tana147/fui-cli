CREATE PROC [dbo].[spAPI_Lop_Get_ByKhoiID_BoMon]
    @NienKhoa   INT
  , @HocKi      INT
  , @KhoiID     INT
  , @SYS_USERID VARCHAR(9)
AS
BEGIN

    DECLARE @Table_Lop TABLE
    (
        LopID   VARCHAR(10)
      , MaDonVi INT
      , TenLop  NVARCHAR(200)
      , KhoiID  INT
      , GVCN    VARCHAR(200)
    );
    INSERT INTO @Table_Lop
    (
        LopID
      , MaDonVi
      , TenLop
      , KhoiID
      , GVCN
    )
    SELECT LopID
         , MaDonVi
         , TenLop
         , KhoiID
         , GVCN
    FROM
           dbo.tblLop
    WHERE
           NienKhoa = @NienKhoa
      AND  [Enable]  = 1
      AND  KhoiID    = @KhoiID
    UNION
    SELECT NhomID
         , MaDonVi
         , TenNhom
         , KhoiID
         , GVCN
    FROM
           dbo.tblNhom
    WHERE
           NienKhoa         = @NienKhoa
      AND  [Enable]          = 1
      AND  KhoiID            = @KhoiID
      AND  IsNhomLMS_GiaoBai = 0
    ORDER BY
        TenLop ASC;

    SELECT DISTINCT
           t_l.LopID
         , t_l.TenLop
         , t_l.KhoiID
         , t_l.GVCN
    FROM
           @Table_Lop                AS t_l
           INNER JOIN tblGiaoVienLop gvl ON gvl.GiaoVienID = @SYS_USERID
                                        AND gvl.LopID      = t_l.LopID
                                        AND gvl.NienKhoa   = @NienKhoa
                                        AND gvl.VaiTro     = 3
                                        AND gvl.Enable     = 1
                                        AND gvl.HocKy      = @HocKi;
END;