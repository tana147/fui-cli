CREATE PROC [dbo].[spAPI_KhoiHocByCapHoc_Get]
    @CapID           INT
  , @HocKi           INT
  , @NienKhoa        INT
  , @SYS_USERID      VARCHAR(9)
  , @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
        SET @NienKhoa = dbo.fn_GetNienKhoa_HienTai();

    IF @sys_SystemRight IN (3, 5, 9)
    BEGIN
        SELECT KH.KhoiID
             , KH.TenKhoiHoc
             , KH.KhoiHocCode
             , KH.CapID
        FROM
               dbo.tblKhoi KH
        WHERE
               KH.Enable = 1
          AND  (@CapID IS NULL OR @CapID = 0 OR KH.CapID = @CapID)
        ORDER BY
               KH.KhoiID;
    END;
    ELSE
    BEGIN
        SELECT KH.KhoiID
             , KH.TenKhoiHoc
             , KH.KhoiHocCode
             , KH.CapID
        FROM
               dbo.tblKhoi KH
        WHERE
               KH.Enable = 1
          AND  KH.KhoiID IN
               (
                   SELECT gvl.KhoiID
                   FROM
                         dbo.tblGiaoVienLop gvl
                   WHERE
                         gvl.GiaoVienID = @SYS_USERID
                     AND  gvl.KhoiID     = KH.KhoiID
                     AND  (@NienKhoa IS NULL OR gvl.NienKhoa = @NienKhoa)
                     AND  (@HocKi IS NULL OR @HocKi = 0 OR TRY_CAST(gvl.HocKy AS INT) = @HocKi OR gvl.HocKy IS NULL OR gvl.HocKy = '')
               )
          AND  (@CapID IS NULL OR @CapID = 0 OR KH.CapID = @CapID)
        UNION
        -- Thêm khối của GVCN nữa
        SELECT KH.KhoiID
             , KH.TenKhoiHoc
             , KH.KhoiHocCode
             , KH.CapID
        FROM
               dbo.tblKhoi           KH
               INNER JOIN dbo.tblLop AS l ON l.CapID    = KH.CapID
                                         AND l.KhoiID   = KH.KhoiID
                                         AND l.GVCN     = @SYS_USERID
                                         AND (@NienKhoa IS NULL OR l.NienKhoa = @NienKhoa)
        WHERE
               KH.Enable = 1
          AND  (@CapID IS NULL OR @CapID = 0 OR KH.CapID = @CapID)
        ORDER BY
            KH.KhoiID;
    END;
END;
