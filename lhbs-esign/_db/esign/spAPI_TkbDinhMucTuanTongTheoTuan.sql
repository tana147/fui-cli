CREATE PROCEDURE spAPI_TkbDinhMucTuanTongTheoTuan
    @Khoi       varchar(2),
    @HocKy      varchar(4),
    @NamHoc     varchar(9),
    @sys_UserID varchar(9)
AS
BEGIN
    -- Tong dinh muc tiet/tuan cho 1 khoi — dung CHO CUNG logic loc tuan (R18) nhu spAPI_TkbDinhMucTuanGrid
    -- va spAPI_TkbChayAuto (nguon duy nhat, khong tao bang rieng). Tinh theo TUNG LOP roi lay MIN/MAX
    -- giua cac lop trong khoi cho moi tuan — neu MIN<>MAX nghia la cac lop trong khoi dang co dinh muc
    -- LECH NHAU (bat thuong, thuong la loi du lieu — xem vu 04B..G lech 04A phat hien 2026-08-28), neu
    -- MAX>40 hoac MIN<40 nghia la vuot/hut suc chua chuan (40 tiet/tuan, Tieu hoc 4 tiet x 2 buoi x 5 ngay).
    ;WITH pcf AS (
        SELECT pc.MaLop, t.TuanTrongNam, t.TenTuan, pc.SoTietChuanTuan
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
    perLop AS (
        SELECT MaLop, TuanTrongNam, TenTuan, SUM(SoTietChuanTuan) AS Tong
        FROM pcf
        GROUP BY MaLop, TuanTrongNam, TenTuan
    )
    SELECT TuanTrongNam, TenTuan,
        COUNT(DISTINCT MaLop) AS SoLop,
        MIN(Tong) AS TongMin, MAX(Tong) AS TongMax,
        CASE WHEN MIN(Tong) <> MAX(Tong) OR MAX(Tong) > 40 OR MIN(Tong) < 40 THEN 1 ELSE 0 END AS BatThuong
    FROM perLop
    GROUP BY TuanTrongNam, TenTuan
    ORDER BY TuanTrongNam
END