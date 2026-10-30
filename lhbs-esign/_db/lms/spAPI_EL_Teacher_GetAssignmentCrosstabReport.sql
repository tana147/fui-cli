CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentCrosstabReport]
    @AssignToClassID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- === Bước 1: Khai báo biến và kiểm tra quyền ===
    DECLARE @AssignmentConfig NVARCHAR(MAX), @LopHoacNhomID VARCHAR(100), @NienKhoa INT;
    DECLARE @SqlStatement NVARCHAR(MAX), @PivotColumns NVARCHAR(MAX);

    -- Lấy thông tin cơ bản của lần giao bài và Niên khóa của MonHocLop
    SELECT 
        @AssignmentConfig = ISNULL(atc.AssignmentConfig, a.AssignmentConfig),
        @LopHoacNhomID = mhl.LopNhomID,
        @NienKhoa = mhl.NienKhoa
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE atc.AssignToClassID = @AssignToClassID and atc.IsDeleted = 0;

    IF @AssignmentConfig IS NULL BEGIN RAISERROR(N'Không tìm thấy bài tập hoặc bạn không có quyền truy cập.', 16, 1); RETURN; END

    -- === BẢNG 1: THÔNG TIN HEADER  ===
    SELECT
        COALESCE(l.TenLop, n.TenNhom) AS ClassName,
        a.Title AS AssignmentTitle
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID and a.IsDeleted = 0
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    LEFT JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID AND l.NienKhoa = @NienKhoa
    LEFT JOIN dbo.tblNhom n ON mhl.LopNhomID = n.NhomID AND n.NienKhoa = @NienKhoa
    WHERE atc.AssignToClassID = @AssignToClassID and atc.IsDeleted = 0;

    -- === BẢNG 2: DANH SÁCH CÂU HỎI (Header của bảng) ===
    -- Với pool RANDOM, chỉ hiển thị những câu đã thực sự xuất hiện trong ít nhất
    -- một snapshot lượt làm; không đưa các câu còn lại của nguồn vào báo cáo.
    IF EXISTS (
        SELECT 1
        FROM OPENJSON(@AssignmentConfig, '$.groups') source_group
        WHERE JSON_VALUE(source_group.value, '$.questionSelection.mode') = 'RANDOM'
    )
    BEGIN
        ;WITH SnapshotQuestions AS (
            SELECT
                JSON_VALUE(question_json.value, '$.id') AS QuestionID_InJSON,
                JSON_VALUE(question_json.value, '$.config.questionText') AS QuestionTitle,
                JSON_VALUE(question_json.value, '$.type') AS QuestionType,
                COALESCE(TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE(question_json.value, '$.points')), 1.00) AS MaxScore,
                ROW_NUMBER() OVER (
                    PARTITION BY JSON_VALUE(question_json.value, '$.id')
                    ORDER BY submission_snapshot.SubmissionID DESC
                ) AS rn
            FROM dbo.tblEL_Submissions submission_snapshot
            CROSS APPLY OPENJSON(CASE WHEN ISJSON(submission_snapshot.AssignmentConfig) = 1 THEN submission_snapshot.AssignmentConfig ELSE N'{}' END, '$.groups') snapshot_group
            CROSS APPLY OPENJSON(snapshot_group.value, '$.questions') question_json
            WHERE submission_snapshot.AssignToClassID = @AssignToClassID
              AND submission_snapshot.IsDeleted = 0
        )
        SELECT QuestionID_InJSON, QuestionTitle, QuestionType, MaxScore
        FROM SnapshotQuestions
        WHERE rn = 1;
    END
    ELSE
    BEGIN
        SELECT
            JSON_VALUE(q.value, '$.id') AS QuestionID_InJSON,
            JSON_VALUE(q.value, '$.config.questionText') AS QuestionTitle,
            JSON_VALUE(q.value, '$.type') AS QuestionType,
            COALESCE(TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE(q.value, '$.points')), 1.00) AS MaxScore
        FROM OPENJSON(@AssignmentConfig, '$.groups') g
        CROSS APPLY OPENJSON(g.value, '$.questions') q;
    END;

    -- === Bước 2: Chuẩn bị dữ liệu gốc trong bảng tạm  ===
    IF OBJECT_ID('tempdb..#RawResults') IS NOT NULL DROP TABLE #RawResults;
    CREATE TABLE #RawResults (
        HocSinhID INT, HoTen NVARCHAR(255), SoDanhBo VARCHAR(10), SoTT INT, SubmissionID BIGINT, FinalScore DECIMAL(5, 2),
        LanNop INT, QuestionID_InJSON VARCHAR(50), ResultJSON NVARCHAR(255)
    );

    -- Keep one row per active submission so teachers can compare every allowed attempt.
    CREATE TABLE #AllSubmissions (
        SubmissionID BIGINT NOT NULL PRIMARY KEY,
        HocSinhID INT NOT NULL,
        LanNop INT NULL
    );

    INSERT INTO #AllSubmissions (SubmissionID, HocSinhID, LanNop)
    SELECT SubmissionID, HocSinhID, LanNop
    FROM dbo.tblEL_Submissions
    WHERE AssignToClassID = @AssignToClassID
      AND IsDeleted = 0;

    -- Parse each attempt's question snapshot once before building the per-attempt rows and statistics.
    CREATE TABLE #ValidSnapshotSubmissions (
        SubmissionID BIGINT NOT NULL PRIMARY KEY
    );

    INSERT INTO #ValidSnapshotSubmissions (SubmissionID)
    SELECT s.SubmissionID
    FROM #AllSubmissions attempt
    INNER JOIN dbo.tblEL_Submissions s ON s.SubmissionID = attempt.SubmissionID
    WHERE ISJSON(s.AssignmentConfig) = 1;

    CREATE TABLE #SnapshotQuestionIDs (
        SubmissionID BIGINT NOT NULL,
        QuestionID_InJSON VARCHAR(50) NOT NULL,
        PRIMARY KEY (SubmissionID, QuestionID_InJSON)
    );

    INSERT INTO #SnapshotQuestionIDs (SubmissionID, QuestionID_InJSON)
    SELECT attempt.SubmissionID, parsed.QuestionID_InJSON
    FROM #AllSubmissions attempt
    INNER JOIN dbo.tblEL_Submissions s ON s.SubmissionID = attempt.SubmissionID
    CROSS APPLY (
        SELECT JSON_VALUE(question_json.value, '$.id') AS QuestionID_InJSON
        FROM OPENJSON(CASE WHEN ISJSON(s.AssignmentConfig) = 1 THEN s.AssignmentConfig ELSE N'{}' END, '$.groups') group_json
        CROSS APPLY OPENJSON(group_json.value, '$.questions') question_json
        UNION
        SELECT JSON_VALUE(question_json.value, '$.id') AS QuestionID_InJSON
        FROM OPENJSON(CASE WHEN ISJSON(s.AssignmentConfig) = 1 THEN s.AssignmentConfig ELSE N'{}' END, '$.questions') question_json
    ) parsed
    WHERE ISJSON(s.AssignmentConfig) = 1
      AND parsed.QuestionID_InJSON IS NOT NULL;

    -- Dùng CTE để lấy danh sách học sinh từ cả Lớp và Nhóm theo đúng Niên khóa của đợt giao bài
    ;WITH UnitStudents AS (
        SELECT hsl.HocSinhID, hsl.SoDanhBo, NULL AS SoTT 
        FROM dbo.tblHocSinhLop hsl
        INNER JOIN tblHocSinh hs on hs.HocSinhID = hsl.HocSinhID and hs.TinhTrang = 0
        WHERE hsl.LopID = @LopHoacNhomID 
          AND hsl.Enable = 1
          AND (@NienKhoa IS NULL OR hsl.NienKhoa = @NienKhoa)
        UNION
        SELECT hsn.HocSinhID, NULL AS SoDanhBo, hsn.SoTT
        FROM dbo.tblHocSinhNhom hsn
        INNER JOIN tblHocSinh hs on hs.HocSinhID = hsn.HocSinhID and hs.TinhTrang = 0 
        LEFT JOIN tblNhom n on hsn.NhomID = n.NhomID
        WHERE hsn.NhomID = @LopHoacNhomID 
          AND hsn.Enable = 1
          AND (@NienKhoa IS NULL OR n.NienKhoa = @NienKhoa)
    )
    INSERT INTO #RawResults (HocSinhID, HoTen, SoDanhBo, SoTT, SubmissionID, FinalScore, LanNop, QuestionID_InJSON, ResultJSON)
    SELECT
        us.HocSinhID, 
        hs.Ho + ' ' + hs.Ten, 
        us.SoDanhBo, 
        us.SoTT,
        s.SubmissionID, 
        s.Score,
        attempt.LanNop,
        ar.QuestionID_InJSON,
        CASE
            WHEN ar.QuestionType LIKE '%CHOICE%' THEN
                CASE ar.IsCorrect 
                    WHEN 1 THEN '{"status":"CORRECT"}' 
                    WHEN 0 THEN '{"status":"INCORRECT"}' 
                    ELSE '{"status":"NOT_ANSWERED"}' 
                END
            ELSE
                CASE
                    WHEN ar.Score IS NOT NULL THEN '{"status":"GRADED", "score":' + ISNULL(CAST(ar.Score AS VARCHAR), 'null') + '}'
                    WHEN s.SubmissionID IS NOT NULL THEN '{"status":"PENDING"}'
                    ELSE '{"status":"NOT_ANSWERED"}'
                END
        END
    FROM UnitStudents us
    JOIN dbo.tblHocSinh hs ON us.HocSinhID = hs.HocSinhID
    LEFT JOIN #AllSubmissions attempt ON us.HocSinhID = attempt.HocSinhID
    LEFT JOIN dbo.tblEL_Submissions s ON attempt.SubmissionID = s.SubmissionID
    LEFT JOIN dbo.tblEL_Analytics_QuestionResults ar
        ON  s.SubmissionID = ar.SubmissionID
        AND ar.IsDeleted = 0
        -- Valid snapshots restrict analytics rows to questions that appeared in that attempt.
        AND (
            NOT EXISTS (
                SELECT 1
                FROM #ValidSnapshotSubmissions valid_snapshot
                WHERE valid_snapshot.SubmissionID = s.SubmissionID
            )
            OR EXISTS (
                SELECT 1
                FROM #SnapshotQuestionIDs snapshot_question
                WHERE snapshot_question.SubmissionID = s.SubmissionID
                  AND snapshot_question.QuestionID_InJSON = ar.QuestionID_InJSON
            )
        );
    
    -- === BẢNG 3: DỮ LIỆU THỐNG KÊ CỘT ===
    -- Keep per-attempt counts so the UI can recalculate the footer when one attempt is selected.
    SELECT
        ar.QuestionID_InJSON,
        attempt.LanNop,
        SUM(CASE WHEN ar.IsCorrect = 1 THEN 1 ELSE 0 END) AS CorrectCount,
        COUNT(ar.ResultID) AS ResultCount,
        CAST(
            SUM(CASE WHEN ar.IsCorrect = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(ar.ResultID), 0)
            AS DECIMAL(5, 1)
        ) AS CorrectPercentage
    FROM dbo.tblEL_Analytics_QuestionResults ar
    INNER JOIN #AllSubmissions attempt ON ar.SubmissionID = attempt.SubmissionID
    LEFT JOIN #ValidSnapshotSubmissions valid_snapshot ON valid_snapshot.SubmissionID = ar.SubmissionID
    LEFT JOIN #SnapshotQuestionIDs snapshot_question
        ON snapshot_question.SubmissionID = ar.SubmissionID
       AND snapshot_question.QuestionID_InJSON = ar.QuestionID_InJSON
    WHERE ar.AssignToClassID = @AssignToClassID
      AND ar.QuestionID_InJSON IN (SELECT DISTINCT QuestionID_InJSON FROM #RawResults WHERE QuestionID_InJSON IS NOT NULL)
      AND ar.IsDeleted = 0
      AND (valid_snapshot.SubmissionID IS NULL OR snapshot_question.SubmissionID IS NOT NULL)
    GROUP BY ar.QuestionID_InJSON, attempt.LanNop;
    
    -- === Bước 3: Xây dựng và thực thi SQL Động để tạo BẢNG 4 ===
    SELECT @PivotColumns = STUFF((SELECT DISTINCT ',' + QUOTENAME(QuestionID_InJSON) FROM #RawResults WHERE QuestionID_InJSON IS NOT NULL FOR XML PATH('')), 1, 1, '');

    IF @PivotColumns IS NULL
    BEGIN
        -- Trả về danh sách học sinh của Lớp/Nhóm
        ;WITH UnitStudents AS (
            SELECT hsl.HocSinhID, SoDanhBo, NULL AS SoTT 
            FROM dbo.tblHocSinhLop hsl
            INNER JOIN tblHocSinh hs on hs.HocSinhID = hsl.HocSinhID and hs.TinhTrang = 0 
            WHERE hsl.LopID = @LopHoacNhomID 
              AND hsl.Enable = 1
              AND (@NienKhoa IS NULL OR hsl.NienKhoa = @NienKhoa)
            UNION
            SELECT hsn.HocSinhID, NULL AS SoDanhBo, SoTT
            FROM dbo.tblHocSinhNhom hsn
            INNER JOIN tblHocSinh hs on hs.HocSinhID = hsn.HocSinhID and hs.TinhTrang = 0 
            LEFT JOIN tblNhom n on hsn.NhomID = n.NhomID
            WHERE hsn.NhomID = @LopHoacNhomID 
              AND hsn.Enable = 1
              AND (@NienKhoa IS NULL OR n.NienKhoa = @NienKhoa)
        )
        SELECT 
            hs.HocSinhID, 
            hs.Ho + ' ' + hs.Ten as HoTen, 
            NULL AS FinalScore, 
            NULL AS LanNop,
            NULL AS SubmissionID,
            us.SoDanhBo,
            us.SoTT
        FROM UnitStudents us
        JOIN dbo.tblHocSinh hs ON us.HocSinhID = hs.HocSinhID 
        ORDER BY us.SoDanhBo, us.SoTT, hs.Ten;
    END
    ELSE
    BEGIN
        SET @SqlStatement = N'
        SELECT
            HocSinhID,
            HoTen,
            SubmissionID,
            FinalScore,
            LanNop,
            SoDanhBo,
            SoTT,
            ' + @PivotColumns + '
        FROM (
            SELECT HocSinhID, HoTen, SubmissionID, FinalScore, LanNop, SoDanhBo, SoTT, QuestionID_InJSON, ResultJSON
            FROM #RawResults
        ) AS SourceTable
        PIVOT (
            MAX(ResultJSON)
            FOR QuestionID_InJSON IN (' + @PivotColumns + ')
        ) AS PivotTable
        ORDER BY SoDanhBo, SoTT, HoTen, LanNop, SubmissionID;';

        EXEC sp_executesql @SqlStatement;
    END

    DROP TABLE #RawResults;
    DROP TABLE #SnapshotQuestionIDs;
    DROP TABLE #ValidSnapshotSubmissions;
    DROP TABLE #AllSubmissions;

END
