
CREATE   FUNCTION [dbo].[fnGetThongKeDanhGia_TheoMon]
(
    @HocKi     VARCHAR(100),
    @NienKhoa  INT,
    @MonHocIDs VARCHAR(MAX)
)
RETURNS TABLE
AS
RETURN
(
    WITH MonList AS
    (
        SELECT DISTINCT TRY_CAST([value] AS INT) AS MonHocID
        FROM STRING_SPLIT(@MonHocIDs, ',')
        WHERE TRY_CAST([value] AS INT) IS NOT NULL
    ),
    BaseData AS
    (
        SELECT 
            l.KhoiID,
            kqht.HocSinhID,
            mhl.MonHocID,
            kqht.KetQuaDanhGia_VI
        FROM dbo.tblKetQuaHocTap kqht
        INNER JOIN dbo.TemplateBangDiemChiTiet ct 
            ON ct.CotDiemID = kqht.CotDiemID 
            AND ct.Enable = 1
            AND ct.MaCotDiem LIKE 'MucDoDanhGia' + @HocKi
        INNER JOIN dbo.tblMonHocLop mhl 
            ON mhl.NienKhoa = @NienKhoa 
            AND mhl.MonHocLopID = kqht.MonHocLopID
        INNER JOIN dbo.tblLop l 
            ON l.LopID = kqht.LopID 
            AND l.NienKhoa = @NienKhoa
            AND l.LopID = mhl.LopNhomID 
            AND l.Enable = 1 
            AND l.CapID = 1
        INNER JOIN dbo.tblHocSinh hs 
            ON hs.HocSinhID = kqht.HocSinhID 
            AND hs.TinhTrang = 0
        INNER JOIN MonList ml
            ON ml.MonHocID = mhl.MonHocID
        WHERE kqht.Enable = 1 
          AND kqht.NienKhoa = @NienKhoa
          AND l.KhoiID IN (1,2,3,4,5)
    ),
    Agg AS
    (
        SELECT
            KhoiID,
            MonHocID,
            COUNT(DISTINCT HocSinhID) AS TongSL,
            SUM(CASE WHEN KetQuaDanhGia_VI = 'T' THEN 1 ELSE 0 END) AS Tot,
            SUM(CASE WHEN KetQuaDanhGia_VI = 'H' THEN 1 ELSE 0 END) AS HT,
            SUM(CASE WHEN KetQuaDanhGia_VI = 'C' THEN 1 ELSE 0 END) AS CHT
        FROM BaseData
        GROUP BY KhoiID, MonHocID
    )
    SELECT
        KhoiID,
        MonHocID,
        TongSL,
        Tot,
        CONVERT(VARCHAR(20), CAST(ROUND(CASE WHEN TongSL = 0 THEN 0 ELSE Tot * 100.0 / TongSL END, 2) AS DECIMAL(18,2))) AS TileTot,
        HT,
        CONVERT(VARCHAR(20), CAST(ROUND(CASE WHEN TongSL = 0 THEN 0 ELSE HT * 100.0 / TongSL END, 2) AS DECIMAL(18,2))) AS TileHT,
        CHT,
        CONVERT(VARCHAR(20), CAST(ROUND(CASE WHEN TongSL = 0 THEN 0 ELSE CHT * 100.0 / TongSL END, 2) AS DECIMAL(18,2))) AS TileCHT
    FROM Agg
);
