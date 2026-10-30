
CREATE FUNCTION [dbo].[fn_GetGiaoVienTheoMonLop]
(
    @MonHocID        INT
  , @LopHoacNhomID   VARCHAR(20)
  , @NienKhoa        INT
  , @GiaoVienID      VARCHAR(20)
  , @SYS_SystemRight INT
)
RETURNS @Result TABLE
(
    GiaoVienID         VARCHAR(20)
  , MonHocID           INT
  , LopID              VARCHAR(20)
  , KhoiID             INT
  , Is_PhanCong_QLDiem BIT
)
AS
BEGIN
    IF (@SYS_SystemRight IN (3, 5, 9))
    BEGIN
        INSERT INTO @Result
        SELECT gvl.GiaoVienID
             , gvl.MonHocID
             , gvl.LopID
             , gvl.KhoiID
             , gvl.Is_PhanCong_QLDiem
        FROM
               dbo.tblEL_GiaoVienLop AS gvl
        WHERE
               gvl.MonHocID = @MonHocID
          AND  gvl.Enable    = 1
          AND  gvl.NienKhoa  = @NienKhoa;

        INSERT INTO @Result
        SELECT gvl2.GiaoVienID
             , gvl2.MonHocID
             , gvl2.LopID
             , gvl2.KhoiID
             , gvl2.Is_PhanCong_QLDiem
        FROM
               dbo.tblGiaoVienLop AS gvl2
        WHERE
               gvl2.MonHocID = @MonHocID
          AND  gvl2.Enable    = 1
          AND  gvl2.NienKhoa  = @NienKhoa;
    END;
    ELSE
    BEGIN
        INSERT INTO @Result
        SELECT gvl.GiaoVienID
             , gvl.MonHocID
             , gvl.LopID
             , gvl.KhoiID
             , gvl.Is_PhanCong_QLDiem
        FROM
               dbo.tblEL_GiaoVienLop AS gvl
        WHERE
               gvl.MonHocID  = @MonHocID
          AND  gvl.Enable     = 1
          AND  gvl.NienKhoa   = @NienKhoa
          AND
               (
                   gvl.LopID      = @LopHoacNhomID
              OR   @LopHoacNhomID = ''
               )
          AND  gvl.GiaoVienID = @GiaoVienID;

        INSERT INTO @Result
        SELECT gvl2.GiaoVienID
             , gvl2.MonHocID
             , gvl2.LopID
             , gvl2.KhoiID
             , gvl2.Is_PhanCong_QLDiem
        FROM
               dbo.tblGiaoVienLop AS gvl2
        WHERE
               gvl2.MonHocID  = @MonHocID
          AND  gvl2.Enable     = 1
          AND  gvl2.NienKhoa   = @NienKhoa
          AND
               (
                   gvl2.LopID      = @LopHoacNhomID
              OR   @LopHoacNhomID  = ''
               )
          AND  gvl2.GiaoVienID = @GiaoVienID;
    END;

    RETURN;
END;
