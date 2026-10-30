CREATE PROC [dbo].[spAPI_BaoCaoLMS_XuHuong_HocTap]
    @NienKhoa INT,
    @LopID    VARCHAR(100),
    @MonHocID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsNumber BIT = CASE WHEN TRY_CAST(@LopID AS INT) IS NOT NULL THEN 1 ELSE 0 END;

    ---------------------------------------------------------
    -- 1. Lấy danh sách học sinh hợp lệ theo Niên khóa
    ---------------------------------------------------------
    ;WITH HS AS
    (
        SELECT 
              hs.HocSinhID,
              hs.Ho + ' ' + hs.Ten AS HoTen,
              hsl.SoDanhBo
        FROM dbo.tblHocSinh hs
        INNER JOIN dbo.tblHocSinhLop hsl ON hsl.HocSinhID = hs.HocSinhID
                                        AND hsl.LopID     = @LopID
                                        AND hsl.NienKhoa  = @NienKhoa
                                        AND hsl.Enable    = 1
        INNER JOIN dbo.tblLop l          ON l.LopID       = hsl.LopID
                                        AND l.NienKhoa    = @NienKhoa
                                        AND l.Enable      = 1
        WHERE hs.TinhTrang = 0
          AND @IsNumber = 1

        UNION ALL

        SELECT 
              hs.HocSinhID,
              hs.Ho + ' ' + hs.Ten AS HoTen,
              CAST(hsn.SoTT AS VARCHAR(10)) AS SoDanhBo
        FROM dbo.tblHocSinh hs
        INNER JOIN dbo.tblHocSinhNhom hsn ON hsn.HocSinhID = hs.HocSinhID
                                         AND hsn.NhomID    = @LopID
                                         AND hsn.Enable    = 1
        INNER JOIN dbo.tblNhom n          ON n.NhomID      = hsn.NhomID
                                         AND n.NienKhoa    = @NienKhoa
                                         AND n.Enable      = 1
        WHERE hs.TinhTrang = 0
          AND @IsNumber = 0
    ),
    ---------------------------------------------------------
    -- 2. Lấy toàn bộ ATC của lớp – môn – năm
    ---------------------------------------------------------
    ATC AS
    (
        SELECT 
              atc.AssignToClassID,
              atc.AssignmentID,
              atc.MaxScore,
              asm.Title
        FROM dbo.tblEL_AssignToClass atc
            INNER JOIN dbo.tblEL_Assignments asm 
                   ON asm.AssignmentID = atc.AssignmentID
                  AND asm.IsDeleted = 0
				  AND asm.MonHocID = @MonHocID
                  AND ISNULL(asm.IsDev, 0) <> 1
            INNER JOIN dbo.tblMonHocLop mhl 
                   ON mhl.MonHocLopID = atc.MonHocLopID
                  AND mhl.Enable = 1
                  AND mhl.LopNhomID = @LopID
                  AND mhl.MonHocID = @MonHocID
                  AND mhl.NienKhoa = @NienKhoa
        WHERE atc.IsDeleted = 0
    ),
    ---------------------------------------------------------
    -- 3. Lấy submission mới nhất cho mỗi HS × ATC
    ---------------------------------------------------------
    LatestSubmission AS
    (
        SELECT 
              s.SubmissionID,
              s.HocSinhID,
              s.AssignToClassID,
              s.Score,
              ROW_NUMBER() OVER (
                    PARTITION BY s.HocSinhID, s.AssignToClassID
                    ORDER BY s.SubmissionID DESC
              ) AS rn
        FROM dbo.tblEL_Submissions s
        WHERE s.IsDeleted = 0
    )

    ---------------------------------------------------------
    -- 4. CROSS JOIN HS × ATC → lấy toàn bộ bài, LEFT JOIN SUB
    ---------------------------------------------------------
    SELECT 
          ls.SubmissionID
        , hs.HocSinhID
        , hs.HoTen
        , atc.Title
        , atc.AssignmentID
        , ls.Score
        , atc.MaxScore
        , hs.SoDanhBo
        , CASE
              WHEN ls.Score IS NULL OR atc.MaxScore = 0 THEN NULL
              ELSE CAST(ROUND((ls.Score / atc.MaxScore) * 100.0, 2) AS DECIMAL(5, 2))
          END AS [PERCENT]
    FROM ATC atc
    CROSS JOIN HS hs  -- lấy đầy đủ HS × ATC
    LEFT JOIN LatestSubmission ls 
           ON ls.HocSinhID = hs.HocSinhID
          AND ls.AssignToClassID = atc.AssignToClassID
          AND ls.rn = 1         -- chỉ lấy submission mới nhất
    ORDER BY hs.SoDanhBo, hs.HocSinhID, atc.AssignToClassID;
END;
