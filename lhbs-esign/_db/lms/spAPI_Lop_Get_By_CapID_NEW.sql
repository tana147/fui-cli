-- [dbo].[spAPI_Lop_Get_By_CapID]  1, 'NV0000195', '5'
CREATE PROC [dbo].[spAPI_Lop_Get_By_CapID_NEW]
@NienKhoa INT,
    @CapID           INT
  , @SYS_USERID      VARCHAR(9)
  , @sys_SystemRight INT
AS
BEGIN
    DECLARE @KhoiID INT;
	--SELECT @sys_SystemRight
    IF (@sys_SystemRight = 5)
    BEGIN
        SET @KhoiID =
        (
            SELECT KhoiID
            FROM
                   dbo.tblLop
            WHERE
                   GVCN = @SYS_USERID
              AND  NienKhoa = @NienKhoa
              AND  Enable = 1
        );
        SELECT LopID
             , MaDonVi
             , TenLop
             , KhoiID
             , PhanBanID
             , TenKhoiPhanBan
             , NienKhoa
             , GVCN
        FROM
               dbo.tblLop
        WHERE
               CapID   = @CapID
          AND  KhoiID   = @KhoiID
          AND  Enable   = 1
          AND  NienKhoa = @NienKhoa
        ORDER BY
               KhoiID;
    END;
    ELSE IF (@sys_SystemRight IN (3, 7, 9))
    BEGIN
        SELECT LopID
             , MaDonVi
             , TenLop
             , KhoiID
             , PhanBanID
             , TenKhoiPhanBan
             , NienKhoa
             , GVCN
        FROM
               dbo.tblLop
        WHERE
               CapID   = @CapID
          AND  Enable   = 1
          AND  NienKhoa = @NienKhoa
        ORDER BY
               KhoiID;
    END;
    ELSE
    BEGIN
        SELECT l.LopID
             , l.MaDonVi
             , l.TenLop
             , l.KhoiID
             , l.PhanBanID
             , l.TenKhoiPhanBan
             , l.NienKhoa
             , l.GVCN
             , l.CapID
			 , @sys_SystemRight AS SystemRight
        FROM
               dbo.tblLop AS l
        WHERE
               l.CapID   = @CapID
          AND  l.GVCN     = @SYS_USERID
          AND  l.NienKhoa = @NienKhoa
        ORDER BY
               l.KhoiID;
    END;
END;
