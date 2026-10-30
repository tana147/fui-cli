CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetSubmissionSummary]
    @SubmissionID INT,
    @HocSinhID    INT,
    @sys_UserID   VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- ── Bảng tạm: gom cả 2 scope CLASS + STUDENT ─────────────────────────────
    DECLARE @t TABLE (
        AssignmentConfig  NVARCHAR(MAX),
        MaxScore          DECIMAL(10,2),
        AttemptMaxScore   DECIMAL(10,2),
        Title             NVARCHAR(255),
        AssignmentID      INT,
        Score             DECIMAL(10,2),
        TeacherComment    NVARCHAR(MAX),
        LanNop            INT,
        AssignToClassID   INT,
        SubmissionContent NVARCHAR(MAX)
    );

    -- Scope CLASS
    INSERT INTO @t (AssignmentConfig, MaxScore, AttemptMaxScore, Title, AssignmentID, Score, TeacherComment, LanNop, AssignToClassID, SubmissionContent)
    SELECT TOP 1
        CASE 
            WHEN ISJSON(s.AssignmentConfig) = 1 AND s.AssignmentConfig NOT IN ('null', '') THEN s.AssignmentConfig
            WHEN ISJSON(atc.AssignmentConfig) = 1 AND atc.AssignmentConfig NOT IN ('null', '') THEN atc.AssignmentConfig
            ELSE NULL 
        END,
        atc.MaxScore,
        s.AttemptMaxScore,
        a.Title,
        a.AssignmentID,
        s.Score,
        s.TeacherComment,
        s.LanNop,
        s.AssignToClassID,
        s.SubmissionContent
    FROM dbo.tblEL_Submissions       s
    JOIN dbo.tblEL_AssignToClass     atc ON s.AssignToClassID = atc.AssignToClassID
                                         AND atc.IsDeleted     = 0
    JOIN dbo.tblEL_Assignments       a   ON atc.ResourceID    = a.AssignmentID
                                         AND a.IsDeleted       = 0
    WHERE s.SubmissionID = @SubmissionID
      AND s.HocSinhID    = @HocSinhID
      AND s.IsDeleted    = 0;

    -- Scope STUDENT (chỉ insert nếu CLASS không tìm thấy)
    IF NOT EXISTS (SELECT 1 FROM @t)
    INSERT INTO @t (AssignmentConfig, MaxScore, AttemptMaxScore, Title, AssignmentID, Score, TeacherComment, LanNop, AssignToClassID, SubmissionContent)
    SELECT TOP 1
        CASE 
            WHEN ISJSON(s.AssignmentConfig) = 1 AND s.AssignmentConfig NOT IN ('null', '') THEN s.AssignmentConfig
            WHEN ISJSON(ats.AssignmentConfig) = 1 AND ats.AssignmentConfig NOT IN ('null', '') THEN ats.AssignmentConfig
            ELSE NULL 
        END,
        ats.MaxScore,
        s.AttemptMaxScore,
        a.Title,
        a.AssignmentID,
        s.Score,
        s.TeacherComment,
        s.LanNop,
        NULL,   -- không có AssignToClassID
        s.SubmissionContent
    FROM dbo.tblEL_Submissions       s
    JOIN dbo.tblEL_AssignToStudent   ats ON s.AssignToStudentID = ats.AssignToStudentID
                                          AND ats.IsDeleted      = 0
    JOIN dbo.tblEL_Assignments       a   ON ats.ResourceID      = a.AssignmentID
                                          AND a.IsDeleted        = 0
    WHERE s.SubmissionID = @SubmissionID
      AND s.HocSinhID    = @HocSinhID
      AND ats.HocSinhID  = @HocSinhID
      AND s.IsDeleted    = 0;

    -- ── Kiểm tra quyền ────────────────────────────────────────────────────────
    IF NOT EXISTS (SELECT 1 FROM @t)
    BEGIN
        RAISERROR(N'Không tìm thấy bài nộp hoặc bạn không có quyền xem.', 16, 1);
        RETURN;
    END;

    -- ── Lấy vào biến để dùng cho Bảng 2 và tính ComputedMaxScore ───────────────
    DECLARE @AssignmentConfig NVARCHAR(MAX);
    DECLARE @SubmissionContent NVARCHAR(MAX);
    DECLARE @DefaultMaxScore DECIMAL(10,2);
    DECLARE @StoredAttemptMaxScore DECIMAL(10,2);
    DECLARE @ComputedMaxScore DECIMAL(10,2);

    SELECT TOP 1 
        @AssignmentConfig = AssignmentConfig,
        @SubmissionContent = SubmissionContent,
        @DefaultMaxScore = MaxScore,
        @StoredAttemptMaxScore = AttemptMaxScore
    FROM @t;

    IF @AssignmentConfig IS NOT NULL AND ISJSON(@AssignmentConfig) = 1
    BEGIN
        SELECT @ComputedMaxScore = SUM(q.Points)
        FROM (
            SELECT ISNULL(Points, 1.00) AS Points
            FROM OPENJSON(@AssignmentConfig, '$.groups')
                WITH (questions NVARCHAR(MAX) '$.questions' AS JSON) AS Groups
            CROSS APPLY OPENJSON(Groups.questions)
                WITH (Points DECIMAL(10,2) '$.points')
            UNION ALL
            SELECT ISNULL(Points, 1.00) AS Points
            FROM OPENJSON(@AssignmentConfig, '$.questions')
                WITH (Points DECIMAL(10,2) '$.points')
        ) q;
    END;

    -- ── Bảng 1: Thông tin tổng quan ───────────────────────────────────────────
    SELECT
        @SubmissionID   AS SubmissionID,
        Title,
        Score,
        COALESCE(@StoredAttemptMaxScore, @ComputedMaxScore, MaxScore) AS MaxScore,
        TeacherComment,
        AssignmentID,
        AssignToClassID,
        LanNop
    FROM @t;

    -- ── Bảng 2: Phân tích chi tiết từng câu hỏi ──────────────────────────────
    IF EXISTS (SELECT 1 FROM dbo.tblEL_Analytics_QuestionResults WHERE SubmissionID = @SubmissionID)
    BEGIN
        SELECT
            ar.QuestionID_InJSON AS QuestionID,
            q.QuestionText,
            'N/A'                AS StudentAnswer,
            ar.IsCorrect,
            ar.Score,
            ar.MaxScore
        FROM dbo.tblEL_Analytics_QuestionResults ar
        LEFT JOIN (
            SELECT QuestionID, QuestionText, ordinalNumber
            FROM OPENJSON(@AssignmentConfig, '$.groups')
                WITH (questions NVARCHAR(MAX) '$.questions' AS JSON) AS Groups
            CROSS APPLY OPENJSON(Groups.questions)
                WITH (
                    QuestionID    VARCHAR(100)  '$.id',
                    QuestionText  NVARCHAR(MAX) '$.config.questionText',
                    ordinalNumber INT           '$.ordinalNumber'
                )
            UNION ALL
            SELECT QuestionID, QuestionText, ordinalNumber
            FROM OPENJSON(@AssignmentConfig, '$.questions')
                WITH (
                    QuestionID    VARCHAR(100)  '$.id',
                    QuestionText  NVARCHAR(MAX) '$.config.questionText',
                    ordinalNumber INT           '$.ordinalNumber'
                )
        ) AS q ON ar.QuestionID_InJSON = q.QuestionID
        WHERE ar.SubmissionID = @SubmissionID
        ORDER BY q.ordinalNumber;
    END
    ELSE
    BEGIN
        WITH ConfigQuestions AS (
            SELECT 
                QuestionID,
                QuestionText,
                ISNULL(Points, 1.00) AS MaxScore,
                ordinalNumber
            FROM OPENJSON(@AssignmentConfig, '$.groups')
                WITH (questions NVARCHAR(MAX) '$.questions' AS JSON) AS Groups
            CROSS APPLY OPENJSON(Groups.questions)
                WITH (
                    QuestionID    VARCHAR(100)  '$.id',
                    QuestionText  NVARCHAR(MAX) '$.config.questionText',
                    Points        DECIMAL(10,2) '$.points',
                    ordinalNumber INT           '$.ordinalNumber'
                )
            UNION ALL
            SELECT 
                QuestionID,
                QuestionText,
                ISNULL(Points, 1.00) AS MaxScore,
                ordinalNumber
            FROM OPENJSON(@AssignmentConfig, '$.questions')
                WITH (
                    QuestionID    VARCHAR(100)  '$.id',
                    QuestionText  NVARCHAR(MAX) '$.config.questionText',
                    Points        DECIMAL(10,2) '$.points',
                    ordinalNumber INT           '$.ordinalNumber'
                )
        ),
        StudentAnswers AS (
            SELECT 
                [key] AS QuestionID,
                JSON_VALUE(value, '$.answerData') AS StudentAnswer,
                ISNULL(TRY_CAST(JSON_VALUE(value, '$.grading.manualScore') AS DECIMAL(10,2)),
                       ISNULL(TRY_CAST(JSON_VALUE(value, '$.grading.autoScore') AS DECIMAL(10,2)), 0)) AS Score
            FROM OPENJSON(@SubmissionContent, '$.answers')
        )
        SELECT 
            q.QuestionID,
            q.QuestionText,
            ISNULL(ans.StudentAnswer, 'N/A') AS StudentAnswer,
            CASE 
                WHEN ans.Score >= q.MaxScore AND q.MaxScore > 0 THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
            END AS IsCorrect,
            ISNULL(ans.Score, 0.00) AS Score,
            q.MaxScore
        FROM ConfigQuestions q
        LEFT JOIN StudentAnswers ans ON q.QuestionID = ans.QuestionID
        ORDER BY q.ordinalNumber;
    END;

END;
