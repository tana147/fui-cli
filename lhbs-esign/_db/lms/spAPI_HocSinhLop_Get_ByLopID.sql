CREATE PROC [dbo].[spAPI_HocSinhLop_Get_ByLopID] 
    @LopID VARCHAR(20), 
    @MonHocID INT, 
    @HocLieuID INT, 
    @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    -- LopID có thể được tái sử dụng giữa các niên khóa; không tự đoán năm hiện hành.
    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
    BEGIN
        RAISERROR(N'NienKhoa là bắt buộc khi tra học sinh theo LopID.', 16, 1);
        RETURN;
    END;

    DECLARE @IsNumber BIT;
    SET @IsNumber = CASE WHEN TRY_CAST(@LopID AS INT) IS NOT NULL THEN 1 ELSE 0 END;

    IF (@IsNumber = 1)
    BEGIN
        -- Đồng bộ quy tắc sắp xếp với spAPI_HocSinhBangDiem_Get_ByMonHocID_MaNhom (màn hình nhap-diem):
        -- Nếu trong lớp có bất kỳ học sinh nào chưa có SoDanhBo thì sort toàn lớp theo Ten, Ho;
        -- ngược lại sort theo SoDanhBo, Ten, Ho.
        DECLARE @HasSoDanhBoNull BIT = 0;
        IF EXISTS (
            SELECT TOP 1 1
            FROM dbo.tblHocSinhLop AS hsl
                 INNER JOIN dbo.tblHocSinh AS hs ON hs.HocSinhID = hsl.HocSinhID
                                                AND hs.TinhTrang = 0
            WHERE hsl.SoDanhBo IS NULL
              AND hsl.LopID = @LopID
              AND hsl.Enable = 1
              AND hsl.NienKhoa = @NienKhoa
        )
        BEGIN
            SET @HasSoDanhBoNull = 1;
        END;

        SELECT HS.HocSinhID
             , HSL.HSLopID
             , HSL.SoDanhBo
             , HS.Ho
             , HS.Ten
             , HS.Ho + ' ' + HS.Ten AS HoTen
             , HS.NgaySinh
             , HS.Nu
             , HS.TinhTrang
             , HS.TenTinhTrang
             , l.CapID
             , l.TenLop
             , CAST(CASE WHEN LOGS.HocSinhID IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsViewed
             , ISNULL(LOGS.SoLuotXem, 0) AS SoLuotXem
             , CONVERT(VARCHAR(16), LOGS.MaxViewTime, 120) AS LastViewedTime
        FROM
               dbo.tblHocSinh               HS
               INNER JOIN dbo.tblHocSinhLop HSL ON HS.HocSinhID = HSL.HocSinhID
                                               AND HSL.Enable    = 1
                                               AND HSL.LopID     = @LopID
                                               AND HSL.NienKhoa  = @NienKhoa
               INNER JOIN dbo.tblLop        AS l ON l.LopID     = HSL.LopID
                                                AND l.NienKhoa  = HSL.NienKhoa
                                                AND l.Enable    = 1
                                                AND l.NienKhoa  = @NienKhoa
               LEFT JOIN (
                   SELECT TRY_CAST(HocSinhID AS INT) AS HocSinhID, COUNT(*) AS SoLuotXem, MAX(ViewTime) AS MaxViewTime
                   FROM dbo.tblEL_Log_XemHocLieu
                   WHERE (@MonHocID IS NULL OR @MonHocID = 0 OR MonHocID = @MonHocID)
                     AND (@HocLieuID IS NULL OR @HocLieuID = 0 OR HocLieuID = @HocLieuID)
                     AND TRY_CAST(HocSinhID AS INT) IS NOT NULL
                   GROUP BY TRY_CAST(HocSinhID AS INT)
               ) LOGS ON HS.HocSinhID = LOGS.HocSinhID
        WHERE
               HS.TinhTrang = 0
        ORDER BY
               CASE WHEN @HasSoDanhBoNull = 1 THEN NULL ELSE HSL.SoDanhBo END,
               HS.Ten,
               HS.Ho;

    END;
    ELSE
    BEGIN
        -- Đồng bộ quy tắc sắp xếp phân nhóm với spAPI_HocSinhBangDiem_Get_ByMonHocID_MaNhom (nhap-diem):
        -- Nếu trong nhóm có bất kỳ học sinh nào chưa có SoTT thì sort theo Ten, Ho;
        -- ngược lại sort theo SoTT, Ten, Ho.
        DECLARE @HasSoTTNull BIT = 0;
        IF EXISTS (
            SELECT TOP 1 1
            FROM dbo.tblHocSinhNhom AS hsn
                 INNER JOIN dbo.tblHocSinh AS hs ON hs.HocSinhID = hsn.HocSinhID
                                                AND hs.TinhTrang = 0
            WHERE hsn.NhomID = @LopID
              AND hsn.SoTT IS NULL
              AND hsn.Enable = 1
        )
        BEGIN
            SET @HasSoTTNull = 1;
        END;

        SELECT HS.HocSinhID
             , hsn.HSNhomID
             , hsn.SoTT
             , HS.Ho
             , HS.Ten
             , HS.Ho + ' ' + HS.Ten AS HoTen
             , HS.NgaySinh
             , HS.Nu
             , HS.TinhTrang
             , HS.TenTinhTrang
             , ISNULL(n.TenNhom, hsn.NhomID) AS TenLop
             , CAST(CASE WHEN LOGS.HocSinhID IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsViewed
             , ISNULL(LOGS.SoLuotXem, 0) AS SoLuotXem
             , CONVERT(VARCHAR(16), LOGS.MaxViewTime, 120) AS LastViewedTime
        FROM
               dbo.tblHocSinh                HS
               INNER JOIN dbo.tblHocSinhNhom AS hsn ON hsn.HocSinhID = HS.HocSinhID
                                                   AND hsn.Enable    = 1
                                                   AND hsn.NhomID    = @LopID
               INNER JOIN dbo.tblNhom        AS n   ON n.NhomID      = hsn.NhomID
                                                   AND n.Enable      = 1
                                                   AND n.NienKhoa    = @NienKhoa
               LEFT JOIN (
                   SELECT TRY_CAST(HocSinhID AS INT) AS HocSinhID, COUNT(*) AS SoLuotXem, MAX(ViewTime) AS MaxViewTime
                   FROM dbo.tblEL_Log_XemHocLieu
                   WHERE (@MonHocID IS NULL OR @MonHocID = 0 OR MonHocID = @MonHocID)
                     AND (@HocLieuID IS NULL OR @HocLieuID = 0 OR HocLieuID = @HocLieuID)
                     AND TRY_CAST(HocSinhID AS INT) IS NOT NULL
                   GROUP BY TRY_CAST(HocSinhID AS INT)
               ) LOGS ON HS.HocSinhID = LOGS.HocSinhID
        WHERE
               HS.TinhTrang = 0
        ORDER BY
               CASE WHEN @HasSoTTNull = 1 THEN NULL ELSE hsn.SoTT END,
               HS.Ten,
               HS.Ho;
    END;
END;