CREATE PROC spAPI_EL_Log_XemHocLieu_GetByLop
    @LopID VARCHAR(20),
    @MonHocID INT,
    @HocLieuID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
    DECLARE @IsNumber BIT;
    SET @IsNumber = CASE WHEN TRY_CAST(@LopID AS INT) IS NOT NULL THEN 1 ELSE 0 END;

    IF (@IsNumber = 1)
    BEGIN
        SELECT HS.HocSinhID,
               HS.Ho + ' ' + HS.Ten AS HoTen,
               HSL.SoDanhBo,
               CAST(CASE WHEN LOGS.HocSinhID IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsViewed,
               CONVERT(VARCHAR(16), LOGS.MaxViewTime, 120) AS LastViewedTime
        FROM dbo.tblHocSinh HS
        INNER JOIN dbo.tblHocSinhLop HSL ON HS.HocSinhID = HSL.HocSinhID
        INNER JOIN dbo.tblLop L ON HSL.LopID = L.LopID AND L.NienKhoa = @NienKhoa
        AND HSL.NienKhoa = L.NienKhoa
        LEFT JOIN (
            SELECT HocSinhID, MAX(ViewTime) AS MaxViewTime
            FROM dbo.tblEL_Log_XemHocLieu
            WHERE (@MonHocID IS NULL OR @MonHocID = 0 OR MonHocID = @MonHocID)
              AND (@HocLieuID IS NULL OR @HocLieuID = 0 OR HocLieuID = @HocLieuID)
            GROUP BY HocSinhID
        ) LOGS ON HS.HocSinhID = LOGS.HocSinhID
        WHERE HS.TinhTrang = 0 
          AND HSL.Enable = 1 
          AND (HSL.NienKhoa = @NienKhoa OR HSL.NienKhoa IS NULL)
          AND HSL.LopID = @LopID
        ORDER BY HSL.SoDanhBo;
    END
    ELSE
    BEGIN
        SELECT HS.HocSinhID,
               HS.Ho + ' ' + HS.Ten AS HoTen,
               HSL.SoDanhBo,
               CAST(CASE WHEN LOGS.HocSinhID IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsViewed,
               CONVERT(VARCHAR(16), LOGS.MaxViewTime, 120) AS LastViewedTime
        FROM dbo.tblHocSinh HS
        INNER JOIN dbo.tblHocSinhLop HSL ON HS.HocSinhID = HSL.HocSinhID
        INNER JOIN dbo.tblLop L ON L.LopID = HSL.LopID AND L.Enable = 1 AND L.NienKhoa = @NienKhoa
        AND HSL.NienKhoa = L.NienKhoa
        LEFT JOIN (
            SELECT HocSinhID, MAX(ViewTime) AS MaxViewTime
            FROM dbo.tblEL_Log_XemHocLieu
            WHERE (@MonHocID IS NULL OR @MonHocID = 0 OR MonHocID = @MonHocID)
              AND (@HocLieuID IS NULL OR @HocLieuID = 0 OR HocLieuID = @HocLieuID)
            GROUP BY HocSinhID
        ) LOGS ON HS.HocSinhID = LOGS.HocSinhID
        WHERE HS.TinhTrang = 0 
          AND HSL.Enable = 1 
          AND (HSL.NienKhoa = @NienKhoa OR HSL.NienKhoa IS NULL)
          AND L.TenLop = @LopID
        ORDER BY HSL.SoDanhBo;
    END
END
