CREATE PROC [dbo].[spAPI_BaoCao_LMS_GetThongKeDanhGia_TheoNLPC]
    @HocKi    VARCHAR(100),
    @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MonHocIDs VARCHAR(MAX) = '20,21,22,23,24,25,26,27,28,29,30,31,32,33,34';

    SELECT
        fn.KhoiID,
        MAX(fn.TongSL)                                                                                      AS TongSL,
        MAX(fn.SLNu)                                                                                        AS SLNu,

        -- NL1 (20: Tự chủ và tự học)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 20 THEN fn.Tot               END), 0)                           AS NL1Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 20 THEN fn.TileTot           END), '0.00')                      AS NL1TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 20 THEN fn.HoanThanh         END), 0)                           AS NL1HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 20 THEN fn.TileHoanThanh     END), '0.00')                      AS NL1TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 20 THEN fn.ChuaHoanThanh     END), 0)                           AS NL1ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 20 THEN fn.TileChuaHoanThanh END), '0.00')                      AS NL1TileChuaHoanThanh,

        -- NL2 (21: Giao tiếp và hợp tác)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 21 THEN fn.Tot               END), 0)                           AS NL2Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 21 THEN fn.TileTot           END), '0.00')                      AS NL2TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 21 THEN fn.HoanThanh         END), 0)                           AS NL2HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 21 THEN fn.TileHoanThanh     END), '0.00')                      AS NL2TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 21 THEN fn.ChuaHoanThanh     END), 0)                           AS NL2ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 21 THEN fn.TileChuaHoanThanh END), '0.00')                      AS NL2TileChuaHoanThanh,

        -- NL3 (22: Giải quyết vấn đề và sáng tạo)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 22 THEN fn.Tot               END), 0)                           AS NL3Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 22 THEN fn.TileTot           END), '0.00')                      AS NL3TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 22 THEN fn.HoanThanh         END), 0)                           AS NL3HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 22 THEN fn.TileHoanThanh     END), '0.00')                      AS NL3TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 22 THEN fn.ChuaHoanThanh     END), 0)                           AS NL3ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 22 THEN fn.TileChuaHoanThanh END), '0.00')                      AS NL3TileChuaHoanThanh,

        -- NL4 (28: Ngôn ngữ)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 28 THEN fn.Tot               END), 0)                           AS NL4Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 28 THEN fn.TileTot           END), '0.00')                      AS NL4TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 28 THEN fn.HoanThanh         END), 0)                           AS NL4HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 28 THEN fn.TileHoanThanh     END), '0.00')                      AS NL4TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 28 THEN fn.ChuaHoanThanh     END), 0)                           AS NL4ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 28 THEN fn.TileChuaHoanThanh END), '0.00')                      AS NL4TileChuaHoanThanh,

        -- NL5 (29: Tính toán)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 29 THEN fn.Tot               END), 0)                           AS NL5Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 29 THEN fn.TileTot           END), '0.00')                      AS NL5TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 29 THEN fn.HoanThanh         END), 0)                           AS NL5HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 29 THEN fn.TileHoanThanh     END), '0.00')                      AS NL5TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 29 THEN fn.ChuaHoanThanh     END), 0)                           AS NL5ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 29 THEN fn.TileChuaHoanThanh END), '0.00')                      AS NL5TileChuaHoanThanh,

        -- NL6 (30: Khoa học)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 30 THEN fn.Tot               END), 0)                           AS NL6Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 30 THEN fn.TileTot           END), '0.00')                      AS NL6TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 30 THEN fn.HoanThanh         END), 0)                           AS NL6HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 30 THEN fn.TileHoanThanh     END), '0.00')                      AS NL6TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 30 THEN fn.ChuaHoanThanh     END), 0)                           AS NL6ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 30 THEN fn.TileChuaHoanThanh END), '0.00')                      AS NL6TileChuaHoanThanh,

        -- NL7 (31: Công nghệ)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 31 THEN fn.Tot               END), 0)                           AS NL7Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 31 THEN fn.TileTot           END), '0.00')                      AS NL7TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 31 THEN fn.HoanThanh         END), 0)                           AS NL7HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 31 THEN fn.TileHoanThanh     END), '0.00')                      AS NL7TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 31 THEN fn.ChuaHoanThanh     END), 0)                           AS NL7ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 31 THEN fn.TileChuaHoanThanh END), '0.00')                      AS NL7TileChuaHoanThanh,

        -- NL8 (32: Tin học)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 32 THEN fn.Tot               END), 0)                           AS NL8Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 32 THEN fn.TileTot           END), '0.00')                      AS NL8TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 32 THEN fn.HoanThanh         END), 0)                           AS NL8HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 32 THEN fn.TileHoanThanh     END), '0.00')                      AS NL8TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 32 THEN fn.ChuaHoanThanh     END), 0)                           AS NL8ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 32 THEN fn.TileChuaHoanThanh END), '0.00')                      AS NL8TileChuaHoanThanh,

        -- NL9 (33: Thẩm mĩ)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 33 THEN fn.Tot               END), 0)                           AS NL9Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 33 THEN fn.TileTot           END), '0.00')                      AS NL9TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 33 THEN fn.HoanThanh         END), 0)                           AS NL9HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 33 THEN fn.TileHoanThanh     END), '0.00')                      AS NL9TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 33 THEN fn.ChuaHoanThanh     END), 0)                           AS NL9ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 33 THEN fn.TileChuaHoanThanh END), '0.00')                      AS NL9TileChuaHoanThanh,

        -- NL10 (34: Thể chất)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 34 THEN fn.Tot               END), 0)                           AS NL10Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 34 THEN fn.TileTot           END), '0.00')                      AS NL10TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 34 THEN fn.HoanThanh         END), 0)                           AS NL10HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 34 THEN fn.TileHoanThanh     END), '0.00')                      AS NL10TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 34 THEN fn.ChuaHoanThanh     END), 0)                           AS NL10ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 34 THEN fn.TileChuaHoanThanh END), '0.00')                      AS NL10TileChuaHoanThanh,

        -- PC1 (23: Yêu nước)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 23 THEN fn.Tot               END), 0)                           AS PC1Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 23 THEN fn.TileTot           END), '0.00')                      AS PC1TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 23 THEN fn.HoanThanh         END), 0)                           AS PC1HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 23 THEN fn.TileHoanThanh     END), '0.00')                      AS PC1TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 23 THEN fn.ChuaHoanThanh     END), 0)                           AS PC1ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 23 THEN fn.TileChuaHoanThanh END), '0.00')                      AS PC1TileChuaHoanThanh,

        -- PC2 (24: Nhân ái)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 24 THEN fn.Tot               END), 0)                           AS PC2Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 24 THEN fn.TileTot           END), '0.00')                      AS PC2TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 24 THEN fn.HoanThanh         END), 0)                           AS PC2HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 24 THEN fn.TileHoanThanh     END), '0.00')                      AS PC2TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 24 THEN fn.ChuaHoanThanh     END), 0)                           AS PC2ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 24 THEN fn.TileChuaHoanThanh END), '0.00')                      AS PC2TileChuaHoanThanh,

        -- PC3 (25: Chăm chỉ)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 25 THEN fn.Tot               END), 0)                           AS PC3Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 25 THEN fn.TileTot           END), '0.00')                      AS PC3TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 25 THEN fn.HoanThanh         END), 0)                           AS PC3HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 25 THEN fn.TileHoanThanh     END), '0.00')                      AS PC3TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 25 THEN fn.ChuaHoanThanh     END), 0)                           AS PC3ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 25 THEN fn.TileChuaHoanThanh END), '0.00')                      AS PC3TileChuaHoanThanh,

        -- PC4 (26: Trung thực)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 26 THEN fn.Tot               END), 0)                           AS PC4Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 26 THEN fn.TileTot           END), '0.00')                      AS PC4TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 26 THEN fn.HoanThanh         END), 0)                           AS PC4HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 26 THEN fn.TileHoanThanh     END), '0.00')                      AS PC4TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 26 THEN fn.ChuaHoanThanh     END), 0)                           AS PC4ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 26 THEN fn.TileChuaHoanThanh END), '0.00')                      AS PC4TileChuaHoanThanh,

        -- PC5 (27: Trách nhiệm)
        ISNULL(MAX(CASE WHEN fn.MonHocID = 27 THEN fn.Tot               END), 0)                           AS PC5Tot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 27 THEN fn.TileTot           END), '0.00')                      AS PC5TileTot,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 27 THEN fn.HoanThanh         END), 0)                           AS PC5HoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 27 THEN fn.TileHoanThanh     END), '0.00')                      AS PC5TileHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 27 THEN fn.ChuaHoanThanh     END), 0)                           AS PC5ChuaHoanThanh,
        ISNULL(MAX(CASE WHEN fn.MonHocID = 27 THEN fn.TileChuaHoanThanh END), '0.00')                      AS PC5TileChuaHoanThanh

    FROM dbo.fnGetThongKeDanhGia_TheoNLPC(@HocKi, @NienKhoa, @MonHocIDs) fn
    GROUP BY fn.KhoiID
    ORDER BY fn.KhoiID;
END;