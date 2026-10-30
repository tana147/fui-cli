CREATE PROCEDURE [dbo].[spAPI_Log_Diem_TongHop]
    @NienKhoa       int,
    @CapID          int,
    @KhoiID         int,
    @LopID          varchar(1000),
    @MonHocID       int,
    @MaNhomCotDiem  nvarchar(100),
    @HocSinhKeyword nvarchar(200),
    @NhapDiemUser   varchar(10),
    @FromDate       date,
    @ToDate         date
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FromDateTime datetime = CASE
        WHEN @FromDate IS NULL THEN NULL
        ELSE CAST(@FromDate AS datetime)
    END;

    DECLARE @ToDateExclusive datetime = CASE
        WHEN @ToDate IS NULL THEN NULL
        ELSE DATEADD(day, 1, CAST(@ToDate AS datetime))
    END;

    ;WITH LogSource AS
    (
        SELECT
            kqht.KQHTID,
            CAST(0 AS int) AS BackupID,
            kqht.MonHocLopID,
            kqht.HocSinhID,
            kqht.LopID,
            kqht.NienKhoa,
            kqht.CotDiemID,
            kqht.KetQuaDanhGia_VI,
            kqht.KetQuaDanhGia_EN,
            kqht.Lop_TinhTrangID,
            kqht.TinhTrang,
            kqht.Enable,
            kqht.CreateUser,
            kqht.CreateTime,
            kqht.UpdateUser,
            kqht.UpdateTime,
            kqht.NhapDiemUser,
            kqht.NhapDiemTime
        FROM dbo.tblKetQuaHocTap AS kqht

        UNION ALL

        SELECT
            kqht.KQHTID,
            kqht.BackupID,
            kqht.MonHocLopID,
            kqht.HocSinhID,
            kqht.LopID,
            kqht.NienKhoa,
            kqht.CotDiemID,
            kqht.KetQuaDanhGia_VI,
            kqht.KetQuaDanhGia_EN,
            kqht.Lop_TinhTrangID,
            kqht.TinhTrang,
            kqht.Enable,
            kqht.CreateUser,
            kqht.CreateTime,
            kqht.UpdateUser,
            kqht.UpdateTime,
            kqht.NhapDiemUser,
            kqht.NhapDiemTime
        FROM dbo.tbl_LOG_KetQuaHocTap AS kqht
    )
    SELECT TOP (10000)
        logData.KQHTID,
        logData.BackupID,
        CASE WHEN logData.BackupID = 0 THEN 'CURRENT' ELSE 'HISTORY' END AS RecordType,
        logData.MonHocLopID,
        logData.HocSinhID,
        logData.LopID,
        lop.TenLop,
        mhl.MonHocID,
        mh.TenMonHoc_HienThi,
        mh.Sort AS ThuTuMonHoc,
        khoi.KhoiID,
        khoi.TenKhoiHoc,
        cap.CapID,
        cap.TenCapHoc,
        logData.NienKhoa,
        logData.CotDiemID,
        tbdct.MaCotDiem,
        tbdct.TenCotDiem_VI,
        tbdct.MaNhomCotDiem,
        tbdct.TenNhomCotDiem_VI,
        tbdct.ThuTuNhom AS ThuTuNhomCotDiem,
        tbdct.ThuTuCotDiem,
        logData.KetQuaDanhGia_VI,
        logData.KetQuaDanhGia_EN,
        COALESCE(ltt.TinhTrang, logData.TinhTrang, 0) AS TinhTrang,
        dbo.RenderTinhTrang(COALESCE(ltt.TinhTrang, logData.TinhTrang, 0)) AS TenTinhTrang,
        dbo.RenderColorTinhTrang(COALESCE(ltt.TinhTrang, logData.TinhTrang, 0)) AS MauTinhTrang,
        ltt.NoiDungNhanXet,
        logData.NhapDiemUser,
        LTRIM(RTRIM(ISNULL(gv.HoGV, '') + ' ' + ISNULL(gv.TenGV, ''))) AS NhapDiemUserName,
        logData.NhapDiemTime,
        logData.CreateUser,
        logData.CreateTime,
        logData.UpdateUser,
        logData.UpdateTime,
        hs.Ho,
        hs.Ten,
        hs.Ho + ' ' + hs.Ten AS HoTen,
        hsl.SoDanhBo
    FROM LogSource AS logData
    INNER JOIN dbo.tblMonHocLop AS mhl
        ON mhl.MonHocLopID = logData.MonHocLopID
       AND mhl.MonHocID = ISNULL(@MonHocID, mhl.MonHocID)
       AND mhl.NienKhoa = logData.NienKhoa
       AND mhl.Enable = 1
    INNER JOIN dbo.tblLop AS lop
        ON lop.LopID = logData.LopID
       AND lop.NienKhoa = logData.NienKhoa
       AND lop.Enable = 1
    INNER JOIN dbo.tblKhoi AS khoi
        ON khoi.KhoiID = lop.KhoiID
       AND khoi.Enable = 1
    INNER JOIN dbo.tblCap AS cap
        ON cap.CapID = khoi.CapID
       AND cap.Enable = 1
    INNER JOIN dbo.tblMonHoc AS mh
        ON mh.MonHocID = mhl.MonHocID
       AND mh.Enable = 1
    INNER JOIN dbo.TemplateBangDiemChiTiet AS tbdct
        ON tbdct.CotDiemID = logData.CotDiemID
       AND tbdct.Enable = 1
    LEFT JOIN dbo.tblLop_TinhTrang AS ltt
        ON ltt.Lop_TinhTrangID = logData.Lop_TinhTrangID
    LEFT JOIN dbo.tblHocSinh AS hs
        ON hs.HocSinhID = logData.HocSinhID
    LEFT JOIN dbo.tblHocSinhLop AS hsl
        ON hsl.HocSinhID = logData.HocSinhID
       AND hsl.LopID = logData.LopID
       AND hsl.Enable = 1
    LEFT JOIN dbo.tblGiaoVien AS gv
        ON gv.GiaoVienID = logData.NhapDiemUser
    WHERE
        logData.NienKhoa = @NienKhoa
        AND (@CapID IS NULL OR @CapID = 0 OR cap.CapID = @CapID)
        AND (@KhoiID IS NULL OR @KhoiID = 0 OR khoi.KhoiID = @KhoiID)
        -- Lớp gộp truyền danh sách LopID thành viên dạng "11B1,11B2".
        -- STRING_SPLIT giữ tương thích với lớp đơn và cho phép xem đủ lịch sử các lớp con.
        AND (
            NULLIF(@LopID, '') IS NULL
            OR logData.LopID IN (
                SELECT LTRIM(RTRIM(value))
                FROM STRING_SPLIT(@LopID, ',')
                WHERE NULLIF(LTRIM(RTRIM(value)), '') IS NOT NULL
            )
        )
        AND (@MonHocID IS NULL OR @MonHocID = 0 OR mhl.MonHocID = @MonHocID)
        AND (
            NULLIF(@MaNhomCotDiem, '') IS NULL
            OR tbdct.MaNhomCotDiem = @MaNhomCotDiem
        )
        AND (
            NULLIF(@NhapDiemUser, '') IS NULL
            OR logData.NhapDiemUser = @NhapDiemUser
        )
        AND (
            @FromDateTime IS NULL
            OR logData.NhapDiemTime >= @FromDateTime
        )
        AND (
            @ToDateExclusive IS NULL
            OR logData.NhapDiemTime < @ToDateExclusive
        )
        AND (
            NULLIF(@HocSinhKeyword, '') IS NULL
            OR CONVERT(varchar(20), logData.HocSinhID) LIKE '%' + @HocSinhKeyword + '%'
            OR ISNULL(hsl.SoDanhBo, '') LIKE '%' + @HocSinhKeyword + '%'
            OR ISNULL(hs.Ho + ' ' + hs.Ten, '') LIKE '%' + @HocSinhKeyword + '%'
        )
    ORDER BY
        logData.NhapDiemTime DESC,
        logData.KQHTID DESC,
        logData.BackupID DESC;
END
