CREATE PROCEDURE spAPI_TkbTuanMoi_XacDinhAnhHuong
    @RunIDCu INT,
    @TuanMoi INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- So sanh PhanCongGiangDay hieu luc TUAN CU (cua RunIDCu) vs TUAN MOI, dung DUNG cong thuc loc
    -- R18 (TuanApDungTu/Den/ApDungTuanChan) nhu spAPI_TkbChayAuto.sql — chi tra ve (Lop,Mon) THAT SU
    -- doi (GV khac / SoTiet khac / mon moi xuat hien / mon nghi), khong tra dong khong doi.

    DECLARE @TuanCu INT, @Khoi VARCHAR(50), @HocKy VARCHAR(4) = 'HK1';
    SELECT @TuanCu = TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunIDCu;
    SELECT @Khoi = STRING_AGG(x.Khoi, ',') FROM (
        SELECT DISTINCT l.Khoi FROM tblTKB_KetQuaXep k INNER JOIN tblTKB_Lop l ON l.MaLop = k.MaLop WHERE k.RunID = @RunIDCu
    ) x;
    SET @Khoi = ISNULL(@Khoi, '');

    ;WITH PCGDCu AS (
        SELECT pc.MaLop, pc.MaMon, pc.MaGV, pc.SoTietChuanTuan,
               ROW_NUMBER() OVER (PARTITION BY pc.MaLop, pc.MaMon, pc.HocKy
                   ORDER BY CASE WHEN pc.MaMon IN ('ENG1', 'TANN', 'SU') THEN pc.PhanCongID END) AS rn
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE pc.Enable = 1
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@TuanCu IS NULL OR pc.TuanApDungTu IS NULL OR @TuanCu >= pc.TuanApDungTu)
          AND (@TuanCu IS NULL OR pc.TuanApDungDen IS NULL OR @TuanCu <= pc.TuanApDungDen)
          AND (@TuanCu IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanCu % 2 = 0 THEN 1 ELSE 0 END)
    ),
    Cu AS (
        SELECT MaLop, MaMon, MaGV, SoTietChuanTuan AS SoTiet FROM PCGDCu
        WHERE (MaMon NOT IN ('ENG1', 'TANN', 'SU') OR rn = 1) AND MaMon <> 'SH'
    ),
    PCGDMoi AS (
        SELECT pc.MaLop, pc.MaMon, pc.MaGV, pc.SoTietChuanTuan,
               ROW_NUMBER() OVER (PARTITION BY pc.MaLop, pc.MaMon, pc.HocKy
                   ORDER BY CASE WHEN pc.MaMon IN ('ENG1', 'TANN', 'SU') THEN pc.PhanCongID END) AS rn
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE pc.Enable = 1
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@TuanMoi IS NULL OR pc.TuanApDungTu IS NULL OR @TuanMoi >= pc.TuanApDungTu)
          AND (@TuanMoi IS NULL OR pc.TuanApDungDen IS NULL OR @TuanMoi <= pc.TuanApDungDen)
          AND (@TuanMoi IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanMoi % 2 = 0 THEN 1 ELSE 0 END)
    ),
    Moi AS (
        SELECT MaLop, MaMon, MaGV, SoTietChuanTuan AS SoTiet FROM PCGDMoi
        WHERE (MaMon NOT IN ('ENG1', 'TANN', 'SU') OR rn = 1) AND MaMon <> 'SH'
    )
    SELECT COALESCE(c.MaLop, m.MaLop) AS MaLop, COALESCE(c.MaMon, m.MaMon) AS MaMon,
           c.MaGV AS MaGVCu, c.SoTiet AS SoTietCu, m.MaGV AS MaGVMoi, m.SoTiet AS SoTietMoi,
           CASE
             WHEN c.MaLop IS NULL THEN N'Môn mới'
             WHEN m.MaLop IS NULL THEN N'Môn nghỉ'
             WHEN c.MaGV <> m.MaGV THEN N'Đổi GV'
             WHEN c.SoTiet <> m.SoTiet THEN N'Đổi số tiết'
             ELSE N'Không đổi'
           END AS LyDo
    FROM Cu c
    FULL OUTER JOIN Moi m ON m.MaLop = c.MaLop AND m.MaMon = c.MaMon
    WHERE NOT (c.MaLop IS NOT NULL AND m.MaLop IS NOT NULL AND c.MaGV = m.MaGV AND c.SoTiet = m.SoTiet)
    ORDER BY MaLop, MaMon;
END
