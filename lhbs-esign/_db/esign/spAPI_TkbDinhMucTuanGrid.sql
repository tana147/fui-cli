CREATE PROCEDURE spAPI_TkbDinhMucTuanGrid
    @Khoi       varchar(2),
    @HocKy      varchar(4),
    @NamHoc     varchar(9),
    @sys_UserID varchar(9)
AS
BEGIN
    -- Dung DUNG logic loc tuan da co trong spAPI_TkbChayAuto (TuanApDungTu/Den, ApDungTuanChan, R18)
    -- de dam bao luoi hien thi khop 100% voi nhu cau thuc te se duoc gui cho solver — tranh 2 nguon
    -- su that lech nhau (bai hoc tu vu phan cong trung lap GV Tieng Anh phat hien 2026-08-27).
    -- HK1 = tuan 1-22, HK2 = tuan 23-49 (xac nhan tu du lieu tblTKB_Tuan/TKB_Tuan_Get moc "Bat dau CT HK2").
    ;WITH pcf AS (
        SELECT pc.MaMon, pc.MaGV, pc.MaLop, l.Khoi AS LopKhoi,
            t.TuanTrongNam, t.TenTuan, t.NgayBatDau, t.NgayKetThuc, pc.SoTietChuanTuan
        FROM tblTKB_Tuan t
        CROSS JOIN tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE t.NamHoc = @NamHoc AND t.Enable = 1
          AND l.Khoi = @Khoi AND l.Enable = 1
          AND pc.Enable = 1 AND pc.HocKy = @HocKy
          AND ((@HocKy = 'HK1' AND t.TuanTrongNam BETWEEN 1 AND 22) OR (@HocKy = 'HK2' AND t.TuanTrongNam BETWEEN 23 AND 49))
          AND (pc.TuanApDungTu IS NULL OR t.TuanTrongNam >= pc.TuanApDungTu)
          AND (pc.TuanApDungDen IS NULL OR t.TuanTrongNam <= pc.TuanApDungDen)
          AND (pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN t.TuanTrongNam % 2 = 0 THEN 1 ELSE 0 END)
    ),
    gvLop AS (
        -- Gom danh sach lop (chi lay phan chu sau ma Khoi, vd "04C" -> "C") theo tung GV
        SELECT p.MaMon, p.TuanTrongNam, p.MaGV, gv.HoTen,
            STRING_AGG(CAST(RIGHT(p.MaLop, LEN(p.MaLop) - LEN(p.LopKhoi)) AS NVARCHAR(50)), N',') WITHIN GROUP (ORDER BY p.MaLop) AS DsLop
        FROM pcf p
        LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = p.MaGV
        GROUP BY p.MaMon, p.TuanTrongNam, p.MaGV, gv.HoTen
    ),
    gvAgg AS (
        -- Gop thanh chuoi "Ten GV (A,B,C); Ten GV khac (D,E)"
        SELECT MaMon, TuanTrongNam,
            STRING_AGG(CAST(ISNULL(HoTen, CAST(MaGV AS NVARCHAR(20))) + N' (' + DsLop + N')' AS NVARCHAR(MAX)), N'; ') WITHIN GROUP (ORDER BY HoTen) AS GVInfo
        FROM gvLop
        GROUP BY MaMon, TuanTrongNam
    ),
    quyTac AS (
        -- Quy tac ap dung cho mon nay (rieng Khoi hien tai hoac ap dung moi khoi)
        SELECT MaMon, STRING_AGG(CAST(LoaiQuyTac AS NVARCHAR(50)), N', ') WITHIN GROUP (ORDER BY LoaiQuyTac) AS QuyTacInfo
        FROM tblTKB_MonQuyTac
        WHERE Enable = 1 AND (Khoi IS NULL OR Khoi = @Khoi)
        GROUP BY MaMon
    )
    SELECT p.MaMon, m.TenMon, p.TuanTrongNam, p.TenTuan, p.NgayBatDau, p.NgayKetThuc,
        MIN(p.SoTietChuanTuan) AS SoTietMin, MAX(p.SoTietChuanTuan) AS SoTietMax,
        COUNT(DISTINCT p.MaLop) AS SoLop, COUNT(DISTINCT p.MaGV) AS SoGV,
        MAX(ga.GVInfo) AS GVInfo, MAX(qt.QuyTacInfo) AS QuyTacInfo
    FROM pcf p
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = p.MaMon
    LEFT JOIN gvAgg ga ON ga.MaMon = p.MaMon AND ga.TuanTrongNam = p.TuanTrongNam
    LEFT JOIN quyTac qt ON qt.MaMon = p.MaMon
    GROUP BY p.MaMon, m.TenMon, p.TuanTrongNam, p.TenTuan, p.NgayBatDau, p.NgayKetThuc
    ORDER BY m.TenMon, p.TuanTrongNam
END
