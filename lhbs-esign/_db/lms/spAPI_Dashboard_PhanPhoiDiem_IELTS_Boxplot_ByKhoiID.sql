CREATE PROC [dbo].[spAPI_Dashboard_PhanPhoiDiem_IELTS_Boxplot_ByKhoiID]
    @KhoiID   INT,
    @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tất cả lớp/nhóm
    DECLARE @Table_Lop TABLE (LopNhomID VARCHAR(200));
    INSERT INTO @Table_Lop 
    SELECT NhomID FROM dbo.tblNhom
    WHERE KhoiID = @KhoiID AND NienKhoa = @NienKhoa AND MonHocID = 76 AND IsNhomLMS_GiaoBai = 0; 

    -- Bảng tạm kết quả boxplot
    DECLARE @Table TABLE (
        x           VARCHAR(50),
        Semester    VARCHAR(20),
        LopNhomID   NVARCHAR(20),
        y_min       FLOAT,
        y_q1        FLOAT,
        y_median    FLOAT,
        y_q3        FLOAT,
        y_max       FLOAT,
        Outliers    NVARCHAR(MAX)
    );

    -- Dữ liệu điểm IELTS
    WITH ScoreData AS
    (
        SELECT ct.MaNhomCotDiem,
               ct.Semester,
               mhl.LopNhomID,
               CASE WHEN ISNUMERIC(kqht.KetQuaDanhGia_VI) = 1 
                    THEN CAST(kqht.KetQuaDanhGia_VI AS FLOAT)
                    ELSE NULL
               END AS Score
        FROM dbo.tblKetQuaHocTap kqht
        INNER JOIN dbo.TemplateBangDiemChiTiet ct 
                ON ct.CotDiemID = kqht.CotDiemID
               AND ct.Enable = 1
               AND ct.MaCotDiem LIKE '%IELTS_Band_Conv%'
        INNER JOIN dbo.tblMonHocLop mhl 
                ON mhl.MonHocLopID = kqht.MonHocLopID
               AND mhl.NienKhoa = @NienKhoa
               AND mhl.Enable = 1
        INNER JOIN dbo.tblNhom n 
                ON n.NhomID = mhl.LopNhomID
               AND n.Enable = 1
               AND n.NienKhoa = @NienKhoa
               AND n.KhoiID = @KhoiID
        WHERE kqht.NienKhoa = @NienKhoa
          AND kqht.Enable = 1
          AND ISNUMERIC(kqht.KetQuaDanhGia_VI) = 1
    ),
    RankedScores AS
    (
        SELECT MaNhomCotDiem,
               Semester,
               LopNhomID,
               Score,
               ROW_NUMBER() OVER (PARTITION BY MaNhomCotDiem, Semester, LopNhomID ORDER BY Score) AS RowNum,
               COUNT(*) OVER (PARTITION BY MaNhomCotDiem, Semester, LopNhomID) AS TotalCount
        FROM ScoreData
        WHERE Score IS NOT NULL
    ),
    Quartiles AS
    (
        SELECT MaNhomCotDiem,
               Semester,
               LopNhomID,
               MAX(CASE WHEN RowNum = CEILING(TotalCount * 0.25) THEN Score END) AS Q1,
               MAX(CASE WHEN RowNum = CEILING(TotalCount * 0.50) THEN Score END) AS Median,
               MAX(CASE WHEN RowNum = CEILING(TotalCount * 0.75) THEN Score END) AS Q3
        FROM RankedScores
        GROUP BY MaNhomCotDiem, Semester, LopNhomID
    )

    -- Tính boxplot + outliers cho IELTS
    INSERT INTO @Table
    SELECT q.MaNhomCotDiem AS x,
           q.Semester,
           q.LopNhomID,
           COALESCE(
               (SELECT MIN(Score) 
                FROM ScoreData s
                WHERE s.MaNhomCotDiem = q.MaNhomCotDiem
                  AND s.Semester = q.Semester
                  AND s.LopNhomID = q.LopNhomID
                  AND s.Score BETWEEN q.Q1 - 1.5*(q.Q3 - q.Q1) AND q.Q3 + 1.5*(q.Q3 - q.Q1)
               ),
               (SELECT MIN(Score) 
                FROM ScoreData s
                WHERE s.MaNhomCotDiem = q.MaNhomCotDiem
                  AND s.Semester = q.Semester
                  AND s.LopNhomID = q.LopNhomID
               )
           ) AS y_min,
           q.Q1 AS y_q1,
           q.Median AS y_median,
           q.Q3 AS y_q3,
           COALESCE(
               (SELECT MAX(Score) 
                FROM ScoreData s
                WHERE s.MaNhomCotDiem = q.MaNhomCotDiem
                  AND s.Semester = q.Semester
                  AND s.LopNhomID = q.LopNhomID
                  AND s.Score BETWEEN q.Q1 - 1.5*(q.Q3 - q.Q1) AND q.Q3 + 1.5*(q.Q3 - q.Q1)
               ),
               (SELECT MAX(Score) 
                FROM ScoreData s
                WHERE s.MaNhomCotDiem = q.MaNhomCotDiem
                  AND s.Semester = q.Semester
                  AND s.LopNhomID = q.LopNhomID
               )
           ) AS y_max,
           ISNULL(
               STUFF((
                   SELECT ',' + CAST(s.Score AS NVARCHAR(10))
                   FROM ScoreData s
                   WHERE s.MaNhomCotDiem = q.MaNhomCotDiem
                     AND s.Semester = q.Semester
                     AND s.LopNhomID = q.LopNhomID
                     AND (s.Score < q.Q1 - 1.5*(q.Q3 - q.Q1) 
                          OR s.Score > q.Q3 + 1.5*(q.Q3 - q.Q1))
                   ORDER BY s.Score
                   FOR XML PATH(''), TYPE
               ).value('.', 'NVARCHAR(MAX)'), 1, 1, ''), ''
           ) AS Outliers
    FROM Quartiles q;

    -- ===== DÒNG TỔNG HỢP ALL_IELTS (gộp tất cả nhóm từ S1_Mid_IELTS) =====
    WITH ScoreData_ALL AS
    (
        SELECT ct.MaNhomCotDiem,
               ct.Semester,
               CASE WHEN ISNUMERIC(kqht.KetQuaDanhGia_VI) = 1 
                    THEN CAST(kqht.KetQuaDanhGia_VI AS FLOAT)
                    ELSE NULL
               END AS Score
        FROM dbo.tblKetQuaHocTap kqht
        INNER JOIN dbo.TemplateBangDiemChiTiet ct 
                ON ct.CotDiemID = kqht.CotDiemID
               AND ct.Enable = 1
               AND ct.MaCotDiem LIKE '%IELTS_Band_Conv%'
        INNER JOIN dbo.tblMonHocLop mhl 
                ON mhl.MonHocLopID = kqht.MonHocLopID
               AND mhl.NienKhoa = @NienKhoa
               AND mhl.Enable = 1
        INNER JOIN dbo.tblNhom n 
                ON n.NhomID = mhl.LopNhomID
               AND n.Enable = 1
               AND n.NienKhoa = @NienKhoa
               AND n.KhoiID = @KhoiID
        WHERE kqht.NienKhoa = @NienKhoa
          AND kqht.Enable = 1
          AND ISNUMERIC(kqht.KetQuaDanhGia_VI) = 1
    ),
    RankedScores_ALL AS
    (
        SELECT MaNhomCotDiem,
               Semester,
               Score,
               ROW_NUMBER() OVER (PARTITION BY MaNhomCotDiem, Semester ORDER BY Score) AS RowNum,
               COUNT(*) OVER (PARTITION BY MaNhomCotDiem, Semester) AS TotalCount
        FROM ScoreData_ALL
        WHERE Score IS NOT NULL
    ),
    Quartiles_ALL AS
    (
        SELECT MaNhomCotDiem,
               Semester,
               MAX(CASE WHEN RowNum = CEILING(TotalCount * 0.25) THEN Score END) AS Q1,
               MAX(CASE WHEN RowNum = CEILING(TotalCount * 0.50) THEN Score END) AS Median,
               MAX(CASE WHEN RowNum = CEILING(TotalCount * 0.75) THEN Score END) AS Q3
        FROM RankedScores_ALL
        GROUP BY MaNhomCotDiem, Semester
    )

    -- Thêm dòng ALL_IELTS
    INSERT INTO @Table
    SELECT q.MaNhomCotDiem AS x,
           q.Semester,
           'ALL_IELTS' AS LopNhomID,
           COALESCE(
               (SELECT MIN(Score) 
                FROM ScoreData_ALL s
                WHERE s.MaNhomCotDiem = q.MaNhomCotDiem
                  AND s.Semester = q.Semester
                  AND s.Score BETWEEN q.Q1 - 1.5*(q.Q3 - q.Q1) AND q.Q3 + 1.5*(q.Q3 - q.Q1)
               ),
               (SELECT MIN(Score) 
                FROM ScoreData_ALL s
                WHERE s.MaNhomCotDiem = q.MaNhomCotDiem
                  AND s.Semester = q.Semester
               )
           ) AS y_min,
           q.Q1 AS y_q1,
           q.Median AS y_median,
           q.Q3 AS y_q3,
           COALESCE(
               (SELECT MAX(Score) 
                FROM ScoreData_ALL s
                WHERE s.MaNhomCotDiem = q.MaNhomCotDiem
                  AND s.Semester = q.Semester
                  AND s.Score BETWEEN q.Q1 - 1.5*(q.Q3 - q.Q1) AND q.Q3 + 1.5*(q.Q3 - q.Q1)
               ),
               (SELECT MAX(Score) 
                FROM ScoreData_ALL s
                WHERE s.MaNhomCotDiem = q.MaNhomCotDiem
                  AND s.Semester = q.Semester
               )
           ) AS y_max,
           ISNULL(
               STUFF((
                   SELECT ',' + CAST(s.Score AS NVARCHAR(10))
                   FROM ScoreData_ALL s
                   WHERE s.MaNhomCotDiem = q.MaNhomCotDiem
                     AND s.Semester = q.Semester
                     AND (s.Score < q.Q1 - 1.5*(q.Q3 - q.Q1) 
                          OR s.Score > q.Q3 + 1.5*(q.Q3 - q.Q1))
                   ORDER BY s.Score
                   FOR XML PATH(''), TYPE
               ).value('.', 'NVARCHAR(MAX)'), 1, 1, ''), ''
           ) AS Outliers
    FROM Quartiles_ALL q;

    -- Tạo danh sách TenNhom (CHỈ các nhóm có điểm)
    DECLARE @AllTenNhom NVARCHAR(MAX);
    SELECT @AllTenNhom = STUFF((
        SELECT ', ' + TenNhom
        FROM (
            SELECT DISTINCT n.TenNhom
            FROM dbo.tblNhom n
            INNER JOIN @Table t ON t.LopNhomID = n.NhomID AND t.LopNhomID <> 'ALL_IELTS'
        ) AS DistinctNames
        ORDER BY TenNhom
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

    -- LEFT JOIN để lấy tất cả dữ liệu (bao gồm cả nhóm không có điểm)
    SELECT l.LopNhomID,
           n.TenNhom,
           t.x,
           t.Semester,
           t.y_min,
           t.y_q1,
           t.y_median,
           t.y_q3,
           t.y_max,
           t.Outliers,
           REPLACE(ct.TrinhDo, 'IELTS ', '') AS ChiTieu,
           0 AS SortOrder
    FROM @Table_Lop l
    LEFT JOIN @Table t ON l.LopNhomID = t.LopNhomID
    LEFT JOIN dbo.tblNhom n ON n.NhomID = l.LopNhomID
    LEFT JOIN dbo.tbl_ChiTieu ct 
        ON ct.NhomID IS NOT NULL
       AND ct.Is_GroupName = 0
       AND (t.Semester IS NOT NULL AND REPLACE(t.Semester, 'HK', '') = ct.HocKi)
       AND ct.NhomID = l.LopNhomID
    
    UNION ALL
    
    -- Dòng ALL_IELTS (cuối cùng)
    SELECT 'ALL_IELTS' AS LopNhomID,
           @AllTenNhom AS TenNhom,
           t.x,
           t.Semester,
           t.y_min,
           t.y_q1,
           t.y_median,
           t.y_q3,
           t.y_max,
           t.Outliers,
           NULL AS ChiTieu,
           1 AS SortOrder
    FROM @Table t
    WHERE t.LopNhomID = 'ALL_IELTS'
    
    ORDER BY SortOrder, LopNhomID, x;
END;