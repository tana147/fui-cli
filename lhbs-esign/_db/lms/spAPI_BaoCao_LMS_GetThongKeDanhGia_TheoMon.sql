
CREATE   PROCEDURE dbo.spAPI_BaoCao_LMS_GetThongKeDanhGia_TheoMon
    @HocKi     VARCHAR(100),
    @NienKhoa  INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH D1 AS
    (
        SELECT *
        FROM dbo.fnGetThongKeDanhGia_TheoMon(@HocKi, @NienKhoa, '1,2,3,4')
    )
    SELECT
        KhoiID,
        MAX(TongSL) AS TongSL,

        MAX(CASE WHEN MonHocID = 1 THEN Tot END) AS TVTot,
        MAX(CASE WHEN MonHocID = 1 THEN TileTot END) AS TVTileTot,
        MAX(CASE WHEN MonHocID = 1 THEN HT END) AS TVHT,
        MAX(CASE WHEN MonHocID = 1 THEN TileHT END) AS TVTileHT,
        MAX(CASE WHEN MonHocID = 1 THEN CHT END) AS TVCHT,
        MAX(CASE WHEN MonHocID = 1 THEN TileCHT END) AS TVTileCHT,

        MAX(CASE WHEN MonHocID = 2 THEN Tot END) AS ToanTot,
        MAX(CASE WHEN MonHocID = 2 THEN TileTot END) AS ToanTileTot,
        MAX(CASE WHEN MonHocID = 2 THEN HT END) AS ToanHT,
        MAX(CASE WHEN MonHocID = 2 THEN TileHT END) AS ToanTileHT,
        MAX(CASE WHEN MonHocID = 2 THEN CHT END) AS ToanCHT,
        MAX(CASE WHEN MonHocID = 2 THEN TileCHT END) AS ToanTileCHT,

        MAX(CASE WHEN KhoiID IN (1,2,3) AND MonHocID = 3 THEN Tot
                 WHEN KhoiID IN (4,5)   AND MonHocID = 4 THEN Tot
            END) AS KHTNTot,
        MAX(CASE WHEN KhoiID IN (1,2,3) AND MonHocID = 3 THEN TileTot
                 WHEN KhoiID IN (4,5)   AND MonHocID = 4 THEN TileTot
            END) AS KHTNTileTot,
        MAX(CASE WHEN KhoiID IN (1,2,3) AND MonHocID = 3 THEN HT
                 WHEN KhoiID IN (4,5)   AND MonHocID = 4 THEN HT
            END) AS KHTNHT,
        MAX(CASE WHEN KhoiID IN (1,2,3) AND MonHocID = 3 THEN TileHT
                 WHEN KhoiID IN (4,5)   AND MonHocID = 4 THEN TileHT
            END) AS KHTNTileHT,
        MAX(CASE WHEN KhoiID IN (1,2,3) AND MonHocID = 3 THEN CHT
                 WHEN KhoiID IN (4,5)   AND MonHocID = 4 THEN CHT
            END) AS KHTNCHT,
        MAX(CASE WHEN KhoiID IN (1,2,3) AND MonHocID = 3 THEN TileCHT
                 WHEN KhoiID IN (4,5)   AND MonHocID = 4 THEN TileCHT
            END) AS KHTNTileCHT
    FROM D1
    GROUP BY KhoiID
    ORDER BY KhoiID;

    ;WITH D2 AS
    (
        SELECT *
        FROM dbo.fnGetThongKeDanhGia_TheoMon(@HocKi, @NienKhoa, '19,5,8')
    )
    SELECT
        KhoiID,
        MAX(TongSL) AS TongSL,

        MAX(CASE WHEN MonHocID = 19 THEN Tot END) AS LDTot,
        MAX(CASE WHEN MonHocID = 19 THEN TileTot END) AS LDTileTot,
        MAX(CASE WHEN MonHocID = 19 THEN HT END) AS LDHT,
        MAX(CASE WHEN MonHocID = 19 THEN TileHT END) AS LDTileHT,
        MAX(CASE WHEN MonHocID = 19 THEN CHT END) AS LDCHT,
        MAX(CASE WHEN MonHocID = 19 THEN TileCHT END) AS LDTileCHT,

        MAX(CASE WHEN MonHocID = 5 THEN Tot END) AS AVTot,
        MAX(CASE WHEN MonHocID = 5 THEN TileTot END) AS AVTileTot,
        MAX(CASE WHEN MonHocID = 5 THEN HT END) AS AVHT,
        MAX(CASE WHEN MonHocID = 5 THEN TileHT END) AS AVTileHT,
        MAX(CASE WHEN MonHocID = 5 THEN CHT END) AS AVCHT,
        MAX(CASE WHEN MonHocID = 5 THEN TileCHT END) AS AVTileCHT,

        MAX(CASE WHEN MonHocID = 8 THEN Tot END) AS DDTot,
        MAX(CASE WHEN MonHocID = 8 THEN TileTot END) AS DDTileTot,
        MAX(CASE WHEN MonHocID = 8 THEN HT END) AS DDHT,
        MAX(CASE WHEN MonHocID = 8 THEN TileHT END) AS DDTileHT,
        MAX(CASE WHEN MonHocID = 8 THEN CHT END) AS DDCHT,
        MAX(CASE WHEN MonHocID = 8 THEN TileCHT END) AS DDTileCHT
    FROM D2
    GROUP BY KhoiID
    ORDER BY KhoiID;

    ;WITH D3 AS
    (
        SELECT *
        FROM dbo.fnGetThongKeDanhGia_TheoMon(@HocKi, @NienKhoa, '9,10,11')
    )
    SELECT
        KhoiID,
        MAX(TongSL) AS TongSL,

        MAX(CASE WHEN MonHocID = 9 THEN Tot END) AS ANTot,
        MAX(CASE WHEN MonHocID = 9 THEN TileTot END) AS ANTileTot,
        MAX(CASE WHEN MonHocID = 9 THEN HT END) AS ANHT,
        MAX(CASE WHEN MonHocID = 9 THEN TileHT END) AS ANTileHT,
        MAX(CASE WHEN MonHocID = 9 THEN CHT END) AS ANCHT,
        MAX(CASE WHEN MonHocID = 9 THEN TileCHT END) AS ANTileCHT,

        MAX(CASE WHEN MonHocID = 10 THEN Tot END) AS MTTot,
        MAX(CASE WHEN MonHocID = 10 THEN TileTot END) AS MTTileTot,
        MAX(CASE WHEN MonHocID = 10 THEN HT END) AS MTHT,
        MAX(CASE WHEN MonHocID = 10 THEN TileHT END) AS MTTileHT,
        MAX(CASE WHEN MonHocID = 10 THEN CHT END) AS MTCHT,
        MAX(CASE WHEN MonHocID = 10 THEN TileCHT END) AS MTTileCHT,

        MAX(CASE WHEN MonHocID = 11 THEN Tot END) AS TCTot,
        MAX(CASE WHEN MonHocID = 11 THEN TileTot END) AS TCTileTot,
        MAX(CASE WHEN MonHocID = 11 THEN HT END) AS TCHT,
        MAX(CASE WHEN MonHocID = 11 THEN TileHT END) AS TCTileHT,
        MAX(CASE WHEN MonHocID = 11 THEN CHT END) AS TCCHT,
        MAX(CASE WHEN MonHocID = 11 THEN TileCHT END) AS TCTileCHT
    FROM D3
    GROUP BY KhoiID
    ORDER BY KhoiID;

    ;WITH D4 AS
    (
        SELECT *
        FROM dbo.fnGetThongKeDanhGia_TheoMon(@HocKi, @NienKhoa, '12,6,35')
    )
    SELECT
        KhoiID,
        MAX(TongSL) AS TongSL,

        MAX(CASE WHEN MonHocID = 12 THEN Tot END) AS TDTot,
        MAX(CASE WHEN MonHocID = 12 THEN TileTot END) AS TDTileTot,
        MAX(CASE WHEN MonHocID = 12 THEN HT END) AS TDHT,
        MAX(CASE WHEN MonHocID = 12 THEN TileHT END) AS TDTileHT,
        MAX(CASE WHEN MonHocID = 12 THEN CHT END) AS TDCHT,
        MAX(CASE WHEN MonHocID = 12 THEN TileCHT END) AS TDTileCHT,

        MAX(CASE WHEN MonHocID = 6 THEN Tot END) AS TinTot,
        MAX(CASE WHEN MonHocID = 6 THEN TileTot END) AS TinTileTot,
        MAX(CASE WHEN MonHocID = 6 THEN HT END) AS TinHT,
        MAX(CASE WHEN MonHocID = 6 THEN TileHT END) AS TinTileHT,
        MAX(CASE WHEN MonHocID = 6 THEN CHT END) AS TinCHT,
        MAX(CASE WHEN MonHocID = 6 THEN TileCHT END) AS TinTileCHT,

        MAX(CASE WHEN MonHocID = 35 THEN Tot END) AS CNgheTot,
        MAX(CASE WHEN MonHocID = 35 THEN TileTot END) AS CNgheTileTot,
        MAX(CASE WHEN MonHocID = 35 THEN HT END) AS CNgheHT,
        MAX(CASE WHEN MonHocID = 35 THEN TileHT END) AS CNgheTileHT,
        MAX(CASE WHEN MonHocID = 35 THEN CHT END) AS CNgheCHT,
        MAX(CASE WHEN MonHocID = 35 THEN TileCHT END) AS CNgheTileCHT
    FROM D4
    GROUP BY KhoiID
    ORDER BY KhoiID;
END
