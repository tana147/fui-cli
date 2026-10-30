CREATE PROCEDURE spAPI_TkbDinhMucLopRun
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-10-06: dinh muc tung (lop, mon) cua TOAN TRUONG cho 1 RunID — Can (theo phan cong giang day cua
    -- tuan/hoc ky cua RunID, cung cong thuc spAPI_TkbDanhGiaThieu) va Xep (so tiet dang co trong RunID).
    -- Gom ca mon da xep nhung khong co trong dinh muc (Can = 0, vd SH/HDTN1/khoa phong) de tong khop voi luoi.
    -- Dung cho tab "Toan truong" trang Bang dieu khien: cot dinh muc canh moi lop + hop thoai lop.
    DECLARE @Tuan INT, @HocKy VARCHAR(4);
    SELECT @Tuan = TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
    SELECT @HocKy = ISNULL(MAX(HocKy), 'HK1') FROM tblTKB_ChayNhanh WHERE RunID = @RunID;

    ;WITH D AS (
        SELECT pc.MaLop, pc.MaMon, MAX(pc.MaGV) AS MaGV, SUM(pc.SoTietChuanTuan) AS Can
        FROM tblTKB_PhanCongGiangDay pc
        WHERE pc.Enable = 1 AND pc.HocKy = @HocKy
          AND (@Tuan IS NULL OR pc.TuanApDungTu IS NULL OR @Tuan >= pc.TuanApDungTu)
          AND (@Tuan IS NULL OR pc.TuanApDungDen IS NULL OR @Tuan <= pc.TuanApDungDen)
          AND (@Tuan IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @Tuan % 2 = 0 THEN 1 ELSE 0 END)
        GROUP BY pc.MaLop, pc.MaMon
    ),
    X AS (
        SELECT MaLop, MaMon, MAX(MaGV) AS MaGV, COUNT(*) AS Xep
        FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaMon <> 'HOP'
        GROUP BY MaLop, MaMon
    )
    SELECT COALESCE(d.MaLop, x.MaLop) AS MaLop, l.Khoi, COALESCE(d.MaMon, x.MaMon) AS MaMon, mh.TenMon,
           COALESCE(d.MaGV, x.MaGV) AS MaGV, g.HoTen,
           CAST(CASE WHEN d.MaMon IS NULL THEN 0 ELSE 1 END AS BIT) AS CoDinhMuc,
           ISNULL(d.Can, 0) AS Can, ISNULL(x.Xep, 0) AS Xep,
           CASE WHEN d.MaMon IS NULL THEN 0 ELSE ISNULL(d.Can, 0) - ISNULL(x.Xep, 0) END AS Thieu
    FROM D d
    FULL OUTER JOIN X x ON x.MaLop = d.MaLop AND x.MaMon = d.MaMon
    LEFT JOIN tblTKB_Lop l ON l.MaLop = COALESCE(d.MaLop, x.MaLop)
    LEFT JOIN tblTKB_GiaoVien g ON g.MaGV = COALESCE(d.MaGV, x.MaGV)
    LEFT JOIN tblTKB_MonHoc mh ON mh.MaMon = COALESCE(d.MaMon, x.MaMon)
    WHERE x.MaLop IS NOT NULL OR d.MaLop IN (SELECT DISTINCT MaLop FROM tblTKB_KetQuaXep WHERE RunID = @RunID)
    ORDER BY COALESCE(d.MaLop, x.MaLop), CASE WHEN d.MaMon IS NULL THEN 1 ELSE 0 END, COALESCE(d.MaMon, x.MaMon);
END
