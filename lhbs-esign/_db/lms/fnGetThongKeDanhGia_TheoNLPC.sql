CREATE FUNCTION [dbo].[fnGetThongKeDanhGia_TheoNLPC]
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
            kqht.KetQuaDanhGia_VI,
            hs.Nu
        FROM dbo.tblKetQuaHocTap kqht
        INNER JOIN dbo.TemplateBangDiemChiTiet ct 
            ON ct.CotDiemID = kqht.CotDiemID 
            AND ct.Enable = 1
            AND ct.MaCotDiem = 'MucDoDanhGia' + @HocKi
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
    TongSLCTE AS
    (
        SELECT
            KhoiID,
            COUNT(DISTINCT HocSinhID)                           AS TongSL,
            COUNT(DISTINCT CASE WHEN Nu = 1 THEN HocSinhID END) AS SLNu
        FROM BaseData
        GROUP BY KhoiID
    ),
    Agg AS
    (
        SELECT
            KhoiID,
            MonHocID,
            SUM(CASE WHEN KetQuaDanhGia_VI = 'T' THEN 1 ELSE 0 END) AS Tot,
            SUM(CASE WHEN KetQuaDanhGia_VI = N'Đ' THEN 1 ELSE 0 END) AS HoanThanh,
            SUM(CASE WHEN KetQuaDanhGia_VI = 'C' THEN 1 ELSE 0 END) AS ChuaHoanThanh
        FROM BaseData
        GROUP BY KhoiID, MonHocID
    )

    SELECT
        a.KhoiID,
        a.MonHocID,
        t.TongSL,
        t.SLNu,

        a.Tot,
        CAST(ROUND(a.Tot * 100.0 / NULLIF(t.TongSL,0), 1) AS DECIMAL(18,1)) AS TileTot,

        a.HoanThanh,
        CAST(ROUND(a.HoanThanh * 100.0 / NULLIF(t.TongSL,0), 1) AS DECIMAL(18,1)) AS TileHoanThanh,

        a.ChuaHoanThanh,
        CAST(ROUND(a.ChuaHoanThanh * 100.0 / NULLIF(t.TongSL,0), 1) AS DECIMAL(18,1)) AS TileChuaHoanThanh

    FROM Agg a
    INNER JOIN TongSLCTE t ON t.KhoiID = a.KhoiID
);