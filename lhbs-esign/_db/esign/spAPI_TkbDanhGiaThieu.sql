CREATE PROCEDURE spAPI_TkbDanhGiaThieu
    @RunID INT,
    @HocKy VARCHAR(4),
    @TuanHienTai INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-25: danh sach (lop, mon) con THIEU tiet + ly do uoc luong (o trong cua lop / o ranh cua GV / GV thinh giang).
    -- LopTrong, GVRanh la UOC LUONG: lop khoi <10 = 40 o, khoi >=10 = 45 o; GV khong co lich bao ban = 40 o; co lich bao ban = 50 o tru o bao ban; tru so tiet da day.
    SET @HocKy = ISNULL(NULLIF(@HocKy, ''), 'HK1');
    -- 2026-10-06: 0 = khong truyen (UI Bang dieu khien chi biet RunID) -> lay tuan cua RunID.
    IF ISNULL(@TuanHienTai, 0) = 0 SELECT @TuanHienTai = TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;

    ;WITH D AS (
        SELECT pc.MaLop, pc.MaMon, MAX(pc.MaGV) AS MaGV, SUM(pc.SoTietChuanTuan) AS Can
        FROM tblTKB_PhanCongGiangDay pc
        WHERE pc.Enable = 1 AND pc.HocKy = @HocKy
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
        GROUP BY pc.MaLop, pc.MaMon
    ),
    X AS (SELECT MaLop, MaMon, COUNT(*) AS Xep FROM tblTKB_KetQuaXep WHERE RunID = @RunID GROUP BY MaLop, MaMon),
    LopDay AS (SELECT MaLop, COUNT(*) AS N FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaMon <> 'HOP' GROUP BY MaLop),
    GVDay AS (SELECT MaGV, COUNT(*) AS N FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaMon <> 'HOP' AND MaGV IS NOT NULL GROUP BY MaGV),
    Cam AS (
        SELECT c.MaGV, COUNT(DISTINCT CAST(c.Thu AS VARCHAR(2)) + b.B + CAST(t.T AS VARCHAR(2))) AS N
        FROM tblTKB_GVCamTuyetDoi_Tuan c
        CROSS APPLY (VALUES ('Sang'), ('Chieu')) b(B)
        CROSS APPLY (VALUES (1), (2), (3), (4), (5)) t(T)
        WHERE c.Tuan = @TuanHienTai AND (ISNULL(c.Buoi, '') = '' OR c.Buoi = b.B) AND (c.Tiet IS NULL OR c.Tiet = t.T)
        GROUP BY c.MaGV
    )
    SELECT d.MaLop, l.Khoi, d.MaMon, mh.TenMon, d.MaGV, g.HoTen, CAST(ISNULL(g.LaThinhGiang, 0) AS BIT) AS ThinhGiang,
           d.Can, ISNULL(x.Xep, 0) AS Xep, d.Can - ISNULL(x.Xep, 0) AS Thieu,
           (CASE WHEN l.Khoi < '10' THEN 40 ELSE 45 END) - ISNULL(ld.N, 0) AS LopTrong,
           (CASE WHEN cm.N IS NULL THEN 40 ELSE 50 - cm.N END) - ISNULL(gd.N, 0) AS GVRanh,
           CASE
             WHEN (CASE WHEN l.Khoi < '10' THEN 40 ELSE 45 END) - ISNULL(ld.N, 0) <= 0 THEN N'Lớp đã kín ô, cần hoán đổi với môn khác'
             WHEN (CASE WHEN cm.N IS NULL THEN 40 ELSE 50 - cm.N END) - ISNULL(gd.N, 0) <= 0 THEN N'GV đã dạy hết ô được phép'
             WHEN ISNULL(g.LaThinhGiang, 0) = 1 OR cm.N IS NOT NULL THEN N'GV thỉnh giảng / có lịch bận, ô được phép hẹp và không trùng ô trống của lớp'
             ELSE N'Ô trống của lớp không trùng ô rảnh của GV, cần hoán đổi qua nhiều lớp'
           END AS LyDo
    FROM D d
    INNER JOIN tblTKB_Lop l ON l.MaLop = d.MaLop
    LEFT JOIN X x ON x.MaLop = d.MaLop AND x.MaMon = d.MaMon
    LEFT JOIN LopDay ld ON ld.MaLop = d.MaLop
    LEFT JOIN GVDay gd ON gd.MaGV = d.MaGV
    LEFT JOIN Cam cm ON cm.MaGV = d.MaGV
    LEFT JOIN tblTKB_GiaoVien g ON g.MaGV = d.MaGV
    LEFT JOIN tblTKB_MonHoc mh ON mh.MaMon = d.MaMon
    WHERE d.Can > ISNULL(x.Xep, 0)
    ORDER BY d.Can - ISNULL(x.Xep, 0) DESC, d.MaLop, d.MaMon;
END
