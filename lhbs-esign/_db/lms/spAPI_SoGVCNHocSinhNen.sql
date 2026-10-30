CREATE PROCEDURE dbo.spAPI_SoGVCNHocSinhNen
    @NienKhoa varchar(10),
    @LopID varchar(10),
    @sys_UserID varchar(10),
    @sys_SystemRight varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    WITH LopCu AS
    (
        SELECT
            hsl.HocSinhID,
            LopCuID = MAX(l.LopID),
            TenLopCu = MAX(l.TenLop)
        FROM dbo.tblHocSinhLop hsl
        INNER JOIN dbo.tblLop l
            ON l.LopID = hsl.LopID
           AND l.NienKhoa = CAST(@NienKhoa AS int) - 1
           AND l.Enable = 1
        AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.Enable = 1
          AND hsl.NienKhoa = CAST(@NienKhoa AS int) - 1
        GROUP BY hsl.HocSinhID
    )
    SELECT
        STT = ROW_NUMBER() OVER (ORDER BY hs.Ten, hs.Ho),
        hsl.HSLopID,
        hs.HocSinhID,
        MaHocSinh = hsl.SoDanhBo,
        HoTen = CONCAT(hs.Ho, N' ', hs.Ten),
        l.LopID,
        LopMoi = l.TenLop,
        LopCuID = ISNULL(lc.LopCuID, ''),
        LopCu = ISNULL(lc.TenLopCu, N''),
        l.KhoiID,
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
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN dbo.tblHocSinh hs
        ON hs.HocSinhID = hsl.HocSinhID
       AND hs.TinhTrang = 0
    INNER JOIN dbo.tblLop l
        ON l.LopID = hsl.LopID
       AND l.NienKhoa = @NienKhoa
       AND l.Enable = 1
    AND hsl.NienKhoa = l.NienKhoa
        LEFT JOIN
    (
        SELECT
            nxt.HocSinhID,
            nxtl.LopID,
            NhanXetGVCN = MAX(NULLIF(LTRIM(RTRIM(nxt.NhanXet_ChuanBiNienKhoaSau)), N''))
        FROM dbo.tblNhanXetThang_Lop nxtl
        INNER JOIN dbo.tblNhanXetThang nxt
            ON nxt.Lop_NhanXetThangID = nxtl.Lop_NhanXetThangID
           AND nxt.Enable = 1
        WHERE nxtl.NienKhoa = @NienKhoa
          AND nxtl.Enable = 1
        GROUP BY nxt.HocSinhID, nxtl.LopID
    ) nx
        ON nx.HocSinhID = hs.HocSinhID
       AND nx.LopID = hsl.LopID
    LEFT JOIN LopCu lc
        ON lc.HocSinhID = hs.HocSinhID
    LEFT JOIN dbo.tblXetKetQuaRenLuyen kqrl
        ON kqrl.HocSinhID = hs.HocSinhID
       AND kqrl.LopID = hsl.LopID
       AND kqrl.NienKhoa = CAST(@NienKhoa AS int) - 1
    WHERE hsl.LopID = @LopID
      AND hsl.NienKhoa = @NienKhoa
      AND hsl.Enable = 1
    ORDER BY hs.Ten, hs.Ho;
END
