CREATE PROCEDURE dbo.spAPI_SoGVCNThongTinHocSinhLop
    @NienKhoa int,
    @CapID varchar(20),
    @LopID varchar(10),
    @sys_UserID varchar(20),
    @sys_SystemRight int
AS
BEGIN
    SET NOCOUNT ON;

    WITH LopMoi AS
    (
        SELECT
            l.LopID,
            l.TenLop,
            l.KhoiID,
            l.CapID,
            LopKey = SUBSTRING(l.TenLop, PATINDEX('%[^0-9]%', l.TenLop + 'A'), 50)
        FROM dbo.tblLop l
        WHERE l.NienKhoa = @NienKhoa
          AND l.Enable = 1
          AND (
              @CapID = ''
              OR CHARINDEX(',' + CAST(l.CapID AS varchar(10)) + ',', ',' + @CapID + ',') > 0
              OR (@CapID = '23' AND l.KhoiID BETWEEN 6 AND 12)
          )
    ),
    LopCu AS
    (
        SELECT
            hsl.HocSinhID,
            hsl.HSLopID,
            hsl.SoDanhBo,
            LopCuID = l.LopID,
            TenLopCu = l.TenLop,
            l.KhoiID,
            LopKey = SUBSTRING(l.TenLop, PATINDEX('%[^0-9]%', l.TenLop + 'A'), 50)
        FROM dbo.tblHocSinhLop hsl
        INNER JOIN dbo.tblLop l
            ON l.LopID = hsl.LopID
           AND l.NienKhoa = @NienKhoa - 1
           AND l.Enable = 1
        AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.Enable = 1
    ),
    Nguon AS
    (
        SELECT
            hsl.HSLopID,
            hsl.HocSinhID,
            SoDanhBo = hsl.SoDanhBo,
            LopID = lm.LopID,
            LopMoi = lm.TenLop,
            LopCuID = ISNULL(lc.LopCuID, ''),
            LopCu = ISNULL(lc.TenLopCu, N''),
            lm.KhoiID
        FROM dbo.tblHocSinhLop hsl
        INNER JOIN LopMoi lm
            ON lm.LopID = hsl.LopID
        LEFT JOIN LopCu lc
            ON lc.HocSinhID = hsl.HocSinhID
        WHERE hsl.Enable = 1

        UNION ALL

        SELECT
            lc.HSLopID,
            lc.HocSinhID,
            SoDanhBo = lc.SoDanhBo,
            LopID = lm.LopID,
            LopMoi = lm.TenLop,
            LopCuID = lc.LopCuID,
            LopCu = lc.TenLopCu,
            lm.KhoiID
        FROM LopCu lc
        INNER JOIN LopMoi lm
            ON lm.KhoiID = lc.KhoiID + 1
           AND lm.LopKey = lc.LopKey
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.tblHocSinhLop hslNew
            WHERE hslNew.LopID = lm.LopID
              AND hslNew.Enable = 1
        )
    )
    SELECT
        STT = ROW_NUMBER() OVER (ORDER BY n.KhoiID, n.LopMoi, hs.Ten, hs.Ho),
        n.HSLopID,
        hs.HocSinhID,
        MaHocSinh = CONVERT(varchar(20), hs.HocSinhID),
        HoTen = CONCAT(hs.Ho, N' ', hs.Ten),
        n.LopID,
        n.LopMoi,
        LopCuID = ISNULL(n.LopCuID, ''),
        LopCu = ISNULL(n.LopCu, N''),
        n.KhoiID,
        KQRL = ISNULL(kqrl.KQRL_Sau, ISNULL(kqrl.KQRL_Truoc, N'')),
        KQHT = CAST(N'' AS nvarchar(200)),
        NhanXetGVCN = ISNULL(nx.NhanXetGVCN, N''),
        Cha = CAST(N'' AS nvarchar(200)),
        NgheNghiepCha = CAST(N'' AS nvarchar(200)),
        SDTCha = CAST(N'' AS nvarchar(50)),
        Me = CAST(N'' AS nvarchar(200)),
        NgheNghiepMe = CAST(N'' AS nvarchar(200)),
        SDTMe = CAST(N'' AS nvarchar(50)),
        NguoiDoDau = CAST(N'' AS nvarchar(200)),
        SDTNguoiDoDau = CAST(N'' AS nvarchar(50)),
        DiaChi = CAST(N'' AS nvarchar(500)),
        GhiChu = CAST(N'' AS nvarchar(500))
    FROM Nguon n
    INNER JOIN dbo.tblHocSinh hs
        ON hs.HocSinhID = n.HocSinhID
       AND hs.TinhTrang = 0
    LEFT JOIN
    (
        SELECT
            nxt.HocSinhID,
            NhanXetGVCN = MAX(NULLIF(LTRIM(RTRIM(nxt.NhanXet_ChuanBiNienKhoaSau)), N''))
        FROM dbo.tblNhanXetThang_Lop nxtl
        INNER JOIN dbo.tblNhanXetThang nxt
            ON nxt.Lop_NhanXetThangID = nxtl.Lop_NhanXetThangID
           AND nxt.Enable = 1
        WHERE nxtl.NienKhoa = @NienKhoa - 1
          AND nxtl.Enable = 1
          AND nxt.NhanXet_ChuanBiNienKhoaSau IS NOT NULL
          AND LTRIM(RTRIM(nxt.NhanXet_ChuanBiNienKhoaSau)) <> N''
        GROUP BY nxt.HocSinhID
    ) nx
        ON nx.HocSinhID = hs.HocSinhID
    LEFT JOIN dbo.tblXetKetQuaRenLuyen kqrl
        ON kqrl.HocSinhID = hs.HocSinhID
       AND kqrl.LopID = n.LopCuID
       AND kqrl.NienKhoa = @NienKhoa - 1
    WHERE (@LopID = '' OR n.LopID = @LopID)
    ORDER BY n.KhoiID, n.LopMoi, hs.Ten, hs.Ho;
END
