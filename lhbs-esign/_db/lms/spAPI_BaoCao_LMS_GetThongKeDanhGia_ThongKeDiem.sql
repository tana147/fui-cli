 
CREATE PROC spAPI_BaoCao_LMS_GetThongKeDanhGia_ThongKeDiem
@NienKhoa INT ,
@HocKi VARCHAR(100)  
AS
BEGIN
    
-- ============================================================
-- Bước 1: Tạo temp table KetQua
-- ============================================================
IF OBJECT_ID('tempdb..#KetQua') IS NOT NULL DROP TABLE #KetQua
IF OBJECT_ID('tempdb..#HocSinhDauNam') IS NOT NULL DROP TABLE #HocSinhDauNam

SELECT 
    kqht.HocSinhID,
    kqht.LopID,
    mh.MonHocName                                                        AS TenMon,
    hs.Nu,
    CAST(REPLACE(kqht.KetQuaDanhGia_VI, ',', '.') AS DECIMAL(5,2))      AS Diem
INTO #KetQua
FROM dbo.tblKetQuaHocTap kqht
INNER JOIN dbo.TemplateBangDiemChiTiet ct 
    ON ct.CotDiemID = kqht.CotDiemID 
    AND ct.Enable = 1
    AND ct.MaCotDiem = 'Diem' + @HocKi
INNER JOIN dbo.tblLop l 
    ON l.LopID = kqht.LopID 
    AND l.Enable = 1 
    AND l.CapID = 1
    AND l.NienKhoa = @NienKhoa
INNER JOIN dbo.tblMonHocLop mhl 
    ON mhl.MonHocLopID = kqht.MonHocLopID 
    AND mhl.Enable = 1
INNER JOIN dbo.tblMonHoc mh 
    ON mh.MonHocID = mhl.MonHocID 
    AND mh.Enable = 1
INNER JOIN dbo.tblHocSinh hs 
    ON hs.HocSinhID = kqht.HocSinhID
WHERE kqht.Enable = 1 
  AND kqht.NienKhoa = @NienKhoa
  AND kqht.KetQuaDanhGia_VI IS NOT NULL
  AND kqht.KetQuaDanhGia_VI != ''

-- ============================================================
-- Bước 2: Tạo temp table HocSinhDauNam
-- ============================================================
SELECT 
    hsl.LopID,
    COUNT(DISTINCT hsl.HocSinhID)                                        AS TsDauNam,
    COUNT(DISTINCT CASE WHEN hs.Nu = 1 THEN hsl.HocSinhID END)          AS TsNuDauNam
INTO #HocSinhDauNam
FROM dbo.tblHocSinhLop hsl
INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID
INNER JOIN dbo.tblLop l ON l.LopID = hsl.LopID AND l.NienKhoa = hsl.NienKhoa AND l.NienKhoa = @NienKhoa AND l.Enable = 1 AND l.CapID = 1
WHERE hsl.Enable = 1
  AND l.NienKhoa = @NienKhoa
GROUP BY hsl.LopID

-- ============================================================
-- SELECT 1: Theo từng Khối + Môn → FOR JSON PATH
-- ============================================================
;WITH ThongKeKhoi AS (
    SELECT
        l.KhoiID,
        kq.TenMon,
        COUNT(DISTINCT kq.HocSinhID)                                            AS TongSo,
        COUNT(DISTINCT CASE WHEN kq.Nu = 1 THEN kq.HocSinhID END)              AS TongSoNu,
        COUNT(CASE WHEN kq.Diem >= 1 AND kq.Diem < 2  THEN 1 END)              AS TS1,
        COUNT(CASE WHEN kq.Diem >= 2 AND kq.Diem < 3  THEN 1 END)              AS TS2,
        COUNT(CASE WHEN kq.Diem >= 3 AND kq.Diem < 4  THEN 1 END)              AS TS3,
        COUNT(CASE WHEN kq.Diem >= 4 AND kq.Diem < 5  THEN 1 END)              AS TS4,
        COUNT(CASE WHEN kq.Diem >= 5 AND kq.Diem < 6  THEN 1 END)              AS TS5,
        COUNT(CASE WHEN kq.Diem >= 6 AND kq.Diem < 7  THEN 1 END)              AS TS6,
        COUNT(CASE WHEN kq.Diem >= 7 AND kq.Diem < 8  THEN 1 END)              AS TS7,
        COUNT(CASE WHEN kq.Diem >= 8 AND kq.Diem < 9  THEN 1 END)              AS TS8,
        COUNT(CASE WHEN kq.Diem >= 9 AND kq.Diem < 10 THEN 1 END)              AS TS9,
        COUNT(CASE WHEN kq.Diem = 10                   THEN 1 END)              AS TS10,
        COUNT(CASE WHEN kq.Diem < 5                    THEN 1 END)              AS Duoi5,
        COUNT(CASE WHEN kq.Diem >= 5                   THEN 1 END)              AS Tren5,
        COUNT(CASE WHEN kq.Diem >= 5 AND kq.Diem < 7  THEN 1 END)              AS Diem56,
        COUNT(CASE WHEN kq.Diem >= 7 AND kq.Diem < 9  THEN 1 END)              AS Diem78,
        COUNT(CASE WHEN kq.Diem >= 9                   THEN 1 END)              AS Diem910
    FROM #KetQua kq
    INNER JOIN dbo.tblLop l ON l.LopID = kq.LopID AND l.NienKhoa = @NienKhoa
    GROUP BY l.KhoiID, kq.TenMon
),
DauNamTheoKhoi AS (
    SELECT
        l.KhoiID,
        SUM(dn.TsDauNam)   AS TsDauNam,
        SUM(dn.TsNuDauNam) AS TsNuDauNam
    FROM #HocSinhDauNam dn
    INNER JOIN dbo.tblLop l ON l.LopID = dn.LopID AND l.NienKhoa = @NienKhoa
    GROUP BY l.KhoiID
)
SELECT
    tk.KhoiID,
    tk.TenMon,
    dk.TsDauNam,
    dk.TsNuDauNam,
    tk.TongSo,
    tk.TongSoNu,
    tk.TS1, tk.TS2, tk.TS3, tk.TS4, tk.TS5,
    tk.TS6, tk.TS7, tk.TS8, tk.TS9, tk.TS10,
    tk.Duoi5,
    CAST(ROUND(tk.Duoi5  * 100.0 / NULLIF(tk.TongSo, 0), 1) AS DECIMAL(5,1)) AS TileDuoi5,
    tk.Tren5,
    CAST(ROUND(tk.Tren5  * 100.0 / NULLIF(tk.TongSo, 0), 1) AS DECIMAL(5,1)) AS TileTren5,
    tk.Diem56,
    CAST(ROUND(tk.Diem56 * 100.0 / NULLIF(tk.TongSo, 0), 1) AS DECIMAL(5,1)) AS Tile56,
    tk.Diem78,
    CAST(ROUND(tk.Diem78 * 100.0 / NULLIF(tk.TongSo, 0), 1) AS DECIMAL(5,1)) AS Tile78,
    tk.Diem910,
    CAST(ROUND(tk.Diem910* 100.0 / NULLIF(tk.TongSo, 0), 1) AS DECIMAL(5,1)) AS Tile910
FROM ThongKeKhoi tk
INNER JOIN DauNamTheoKhoi dk ON dk.KhoiID = tk.KhoiID
ORDER BY tk.KhoiID, tk.TenMon

-- ============================================================
-- SELECT 2: Tổng toàn trường (KhoiID = '')
-- ============================================================
;WITH ThongKeTong AS (
    SELECT
        kq.TenMon,
        COUNT(DISTINCT kq.HocSinhID)                                            AS TongSo,
        COUNT(DISTINCT CASE WHEN kq.Nu = 1 THEN kq.HocSinhID END)              AS TongSoNu,
        COUNT(CASE WHEN kq.Diem >= 1 AND kq.Diem < 2  THEN 1 END)              AS TS1,
        COUNT(CASE WHEN kq.Diem >= 2 AND kq.Diem < 3  THEN 1 END)              AS TS2,
        COUNT(CASE WHEN kq.Diem >= 3 AND kq.Diem < 4  THEN 1 END)              AS TS3,
        COUNT(CASE WHEN kq.Diem >= 4 AND kq.Diem < 5  THEN 1 END)              AS TS4,
        COUNT(CASE WHEN kq.Diem >= 5 AND kq.Diem < 6  THEN 1 END)              AS TS5,
        COUNT(CASE WHEN kq.Diem >= 6 AND kq.Diem < 7  THEN 1 END)              AS TS6,
        COUNT(CASE WHEN kq.Diem >= 7 AND kq.Diem < 8  THEN 1 END)              AS TS7,
        COUNT(CASE WHEN kq.Diem >= 8 AND kq.Diem < 9  THEN 1 END)              AS TS8,
        COUNT(CASE WHEN kq.Diem >= 9 AND kq.Diem < 10 THEN 1 END)              AS TS9,
        COUNT(CASE WHEN kq.Diem = 10                   THEN 1 END)              AS TS10,
        COUNT(CASE WHEN kq.Diem < 5                    THEN 1 END)              AS Duoi5,
        COUNT(CASE WHEN kq.Diem >= 5                   THEN 1 END)              AS Tren5,
        COUNT(CASE WHEN kq.Diem >= 5 AND kq.Diem < 7  THEN 1 END)              AS Diem56,
        COUNT(CASE WHEN kq.Diem >= 7 AND kq.Diem < 9  THEN 1 END)              AS Diem78,
        COUNT(CASE WHEN kq.Diem >= 9                   THEN 1 END)              AS Diem910
    FROM #KetQua kq
    GROUP BY kq.TenMon
),
DauNamTong AS (
    SELECT
        SUM(TsDauNam)   AS TsDauNam,
        SUM(TsNuDauNam) AS TsNuDauNam
    FROM #HocSinhDauNam
)
SELECT
    ''                                                                          AS KhoiID,
    tt.TenMon,
    dt.TsDauNam,
    dt.TsNuDauNam,
    tt.TongSo,
    tt.TongSoNu,
    tt.TS1, tt.TS2, tt.TS3, tt.TS4, tt.TS5,
    tt.TS6, tt.TS7, tt.TS8, tt.TS9, tt.TS10,
    tt.Duoi5,
    CAST(ROUND(tt.Duoi5  * 100.0 / NULLIF(tt.TongSo, 0), 1) AS DECIMAL(5,1)) AS TileDuoi5,
    tt.Tren5,
    CAST(ROUND(tt.Tren5  * 100.0 / NULLIF(tt.TongSo, 0), 1) AS DECIMAL(5,1)) AS TileTren5,
    tt.Diem56,
    CAST(ROUND(tt.Diem56 * 100.0 / NULLIF(tt.TongSo, 0), 1) AS DECIMAL(5,1)) AS Tile56,
    tt.Diem78,
    CAST(ROUND(tt.Diem78 * 100.0 / NULLIF(tt.TongSo, 0), 1) AS DECIMAL(5,1)) AS Tile78,
    tt.Diem910,
    CAST(ROUND(tt.Diem910* 100.0 / NULLIF(tt.TongSo, 0), 1) AS DECIMAL(5,1)) AS Tile910
FROM ThongKeTong tt
CROSS JOIN DauNamTong dt
ORDER BY tt.TenMon

-- ============================================================
-- Bước cuối: Dọn temp table
-- ============================================================
DROP TABLE #KetQua
DROP TABLE #HocSinhDauNam
END
