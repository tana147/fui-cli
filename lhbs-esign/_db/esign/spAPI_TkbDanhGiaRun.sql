CREATE PROCEDURE spAPI_TkbDanhGiaRun
    @RunID INT,
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @Moc VARCHAR(20) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-25: DANH GIA ket qua 1 RunID theo tung khoi: nhu cau (PCGD tuan nay) so voi so tiet da xep. Da xep tinh
    -- MIN(nhu cau, so tiet co) theo (lop, mon) de khong bi thoi phong boi tiet du (bai hoc RunID 1344 "99,2%" gia).
    -- @Moc (vd 'R5', 'R9') khac NULL -> luu lai ket qua theo khoi vao tblTKB_DanhGiaRound de xem tien trinh theo Round
    -- (spAPI_TkbDanhGiaLichSu). Tra ve 1 result set: moi khoi 1 dong + dong 'Toan truong'.
    SET @HocKy = ISNULL(NULLIF(@HocKy, ''), 'HK1');
    IF @TuanHienTai IS NULL SELECT @TuanHienTai = TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;

    CREATE TABLE #KQ (Khoi VARCHAR(12), TongCan INT, DaXep INT);
    INSERT INTO #KQ (Khoi, TongCan, DaXep)
    SELECT l.Khoi, SUM(d.Can), SUM(CASE WHEN ISNULL(x.Xep, 0) < d.Can THEN ISNULL(x.Xep, 0) ELSE d.Can END)
    FROM (
        SELECT pc.MaLop, pc.MaMon, SUM(pc.SoTietChuanTuan) AS Can
        FROM tblTKB_PhanCongGiangDay pc
        WHERE pc.Enable = 1 AND pc.HocKy = @HocKy
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
        GROUP BY pc.MaLop, pc.MaMon
    ) d
    INNER JOIN tblTKB_Lop l ON l.MaLop = d.MaLop
    LEFT JOIN (
        SELECT MaLop, MaMon, COUNT(*) AS Xep FROM tblTKB_KetQuaXep WHERE RunID = @RunID GROUP BY MaLop, MaMon
    ) x ON x.MaLop = d.MaLop AND x.MaMon = d.MaMon
    GROUP BY l.Khoi;

    IF @Moc IS NOT NULL AND LEN(@Moc) > 0
    BEGIN
        DELETE FROM tblTKB_DanhGiaRound WHERE RunID = @RunID AND Moc = @Moc;
        INSERT INTO tblTKB_DanhGiaRound (RunID, Moc, Khoi, TongCan, DaXep) SELECT @RunID, @Moc, Khoi, TongCan, DaXep FROM #KQ;
    END

    SELECT Khoi, TongCan, DaXep, TongCan - DaXep AS Thieu,
           CAST(100.0 * DaXep / NULLIF(TongCan, 0) AS DECIMAL(5, 1)) AS PhanTram, 0 AS Thu
    FROM #KQ
    UNION ALL
    SELECT N'Toàn trường', SUM(TongCan), SUM(DaXep), SUM(TongCan) - SUM(DaXep),
           CAST(100.0 * SUM(DaXep) / NULLIF(SUM(TongCan), 0) AS DECIMAL(5, 1)), 1
    FROM #KQ
    ORDER BY Thu, Khoi;
END
