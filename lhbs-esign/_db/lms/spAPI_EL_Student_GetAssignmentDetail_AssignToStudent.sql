CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetAssignmentDetail_AssignToStudent]
    @AssignToStudentID INT,
    @HocSinhID INT,
    @LanNop INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanNop = COALESCE(@LanNop, 1);

    IF @AssignToStudentID IS NULL
    OR NOT EXISTS (
        SELECT 1
        FROM dbo.tblEL_AssignToStudent
        WHERE AssignToStudentID = @AssignToStudentID
          AND HocSinhID = @HocSinhID
          AND IsDeleted = 0
    )
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin giao bài.', 16, 1);
        RETURN;
    END;

    DECLARE @SubmissionStatus INT;
    DECLARE @AssignmentConfig_Submission NVARCHAR(MAX);
    DECLARE @StoredAttemptMaxScore DECIMAL(10,2);
    DECLARE @SubmissionID_Current INT;
    DECLARE @PreviousAssignmentConfig NVARCHAR(MAX);
    DECLARE @AssignmentConfigHistory NVARCHAR(MAX);

    SELECT TOP 1
        @SubmissionID_Current = SubmissionID,
        @SubmissionStatus = SubmissionStatus,
        -- Chuỗi JSON 'null' hoặc config lỗi từ dữ liệu cũ không phải snapshot
        -- có thể hiển thị. Bỏ qua để trả về AssignmentConfig_NoAnswer của bài gốc.
        @AssignmentConfig_Submission = CASE
            WHEN ISJSON(AssignmentConfig) = 1
             AND JSON_QUERY(AssignmentConfig, '$.groups') IS NOT NULL
            THEN AssignmentConfig
            ELSE NULL
        END
      , @StoredAttemptMaxScore = AttemptMaxScore
    FROM dbo.tblEL_Submissions
    WHERE AssignToStudentID = @AssignToStudentID
      AND HocSinhID = @HocSinhID
      AND IsDeleted = 0
      AND (LanNop IS NULL OR LanNop = @LanNop)
    ORDER BY CASE WHEN LanNop = @LanNop THEN 0 ELSE 1 END,
             LanNop DESC,
             SubmissionID DESC;

    SELECT TOP 1 @PreviousAssignmentConfig = AssignmentConfig
    FROM dbo.tblEL_Submissions
    WHERE AssignToStudentID = @AssignToStudentID
      AND HocSinhID = @HocSinhID
      AND IsDeleted = 0
      AND LanNop < @LanNop
      AND AssignmentConfig IS NOT NULL
    ORDER BY LanNop DESC, SubmissionID DESC;

    SELECT @AssignmentConfigHistory = (
        -- Trả kèm nội dung trả lời của các lượt trước để frontend có thể nhận diện
        -- câu đã làm sai và dành một tỷ lệ nhỏ cho câu đó quay lại trong nhóm RANDOM.
        -- Các lượt cũ không có SubmissionContent vẫn hợp lệ; frontend sẽ bỏ qua phần
        -- ưu tiên câu sai nếu không có dữ liệu chấm.
        SELECT AssignmentConfig, SubmissionContent, SubmissionStatus, LanNop, SubmissionID
        FROM dbo.tblEL_Submissions
        WHERE AssignToStudentID = @AssignToStudentID
          AND HocSinhID = @HocSinhID
          AND IsDeleted = 0
          AND LanNop < @LanNop
          AND AssignmentConfig IS NOT NULL
        ORDER BY LanNop DESC, SubmissionID DESC
        FOR JSON PATH
    );

    -- AttemptMaxScore đã được lưu theo từng submission: NULL cho flow thường,
    -- khác NULL cho lượt RANDOM. MaxScore của assignment luôn giữ nguyên metadata nguồn.

    DECLARE @MasterConfig NVARCHAR(MAX);
    DECLARE @Is_Full_Quiz BIT;
    SELECT TOP 1 
        @MasterConfig = CASE
            WHEN ISJSON(ISNULL(ats.AssignmentConfig, asm.AssignmentConfig)) = 1
                THEN ISNULL(ats.AssignmentConfig, asm.AssignmentConfig)
            ELSE NULL
        END,
        @Is_Full_Quiz = ats.Is_Full_Quiz
    FROM dbo.tblEL_AssignToStudent ats
    JOIN dbo.tblEL_Assignments asm ON ats.ResourceID = asm.AssignmentID AND ats.ResourceType = 'ASSIGNMENT'
    WHERE ats.AssignToStudentID = @AssignToStudentID AND ats.IsDeleted = 0;

    DECLARE @AssignmentConfig_HadAnswer NVARCHAR(MAX) = '';

    IF @SubmissionStatus = 4 OR (@SubmissionStatus >= 2 AND ISNULL(@Is_Full_Quiz, 0) = 1)
    BEGIN
        IF @AssignmentConfig_Submission IS NOT NULL AND @MasterConfig IS NOT NULL
        BEGIN
            IF JSON_QUERY(@AssignmentConfig_Submission, '$.groups') IS NOT NULL
            BEGIN
                SELECT @AssignmentConfig_HadAnswer = (
                    SELECT 
                        JSON_VALUE(@AssignmentConfig_Submission, '$.version') AS [version],
                        JSON_VALUE(@AssignmentConfig_Submission, '$.type') AS [type],
                        JSON_QUERY((
                            -- Dựng JSON bằng FOR JSON PATH để tự escape newline, dấu quote,
                            -- backslash và ký tự điều khiển trong nội dung nhóm.
                            SELECT
                                ISNULL(JSON_VALUE(g1.value, '$.id'), N'') AS [id],
                                ISNULL(JSON_VALUE(g1.value, '$.title'), N'') AS [title],
                                ISNULL(JSON_VALUE(g1.value, '$.description'), N'') AS [description],
                                JSON_QUERY(g1.value, '$.media') AS [media],
                                JSON_QUERY(
                                    N'[' + ISNULL(STUFF((
                                        SELECT ',' +
                                            JSON_MODIFY(
                                                sq.value,
                                                '$.config',
                                                JSON_QUERY(
                                                    CASE
                                                        WHEN JSON_VALUE(mq.value, '$.config.correctAnswer') IS NOT NULL
                                                        THEN JSON_MODIFY(JSON_QUERY(sq.value, '$.config'), '$.correctAnswer', JSON_VALUE(mq.value, '$.config.correctAnswer'))
                                                        WHEN JSON_QUERY(mq.value, '$.config.correctAnswers') IS NOT NULL
                                                        THEN JSON_MODIFY(JSON_QUERY(sq.value, '$.config'), '$.correctAnswers', JSON_QUERY(mq.value, '$.config.correctAnswers'))
                                                        WHEN JSON_QUERY(mq.value, '$.config.parts') IS NOT NULL
                                                        THEN JSON_MODIFY(JSON_QUERY(sq.value, '$.config'), '$.parts', JSON_QUERY(mq.value, '$.config.parts'))
                                                        WHEN JSON_QUERY(mq.value, '$.config.options') IS NOT NULL AND JSON_VALUE(mq.value, '$.config.options[0].correctAnswer') IS NOT NULL
                                                        THEN JSON_MODIFY(JSON_QUERY(sq.value, '$.config'), '$.options', JSON_QUERY(mq.value, '$.config.options'))
                                                        ELSE JSON_QUERY(mq.value, '$.config')
                                                    END
                                                )
                                            )
                                        FROM OPENJSON(
                                            CASE
                                                WHEN ISJSON(JSON_QUERY(g1.value, '$.questions')) = 1
                                                    THEN JSON_QUERY(g1.value, '$.questions')
                                                ELSE N'[]'
                                            END
                                        ) sq
                                        CROSS APPLY (
                                            SELECT mq1.value
                                            FROM OPENJSON(
                                                CASE WHEN ISJSON(@MasterConfig) = 1 THEN @MasterConfig ELSE N'{}' END,
                                                '$.groups'
                                            ) mg1
                                            CROSS APPLY OPENJSON(
                                                CASE
                                                    WHEN ISJSON(JSON_QUERY(mg1.value, '$.questions')) = 1
                                                        THEN JSON_QUERY(mg1.value, '$.questions')
                                                    ELSE N'[]'
                                                END
                                            ) mq1
                                            WHERE JSON_VALUE(mq1.value, '$.id') = JSON_VALUE(sq.value, '$.id')
                                            UNION ALL
                                            SELECT mq2.value
                                            FROM OPENJSON(
                                                CASE WHEN ISJSON(@MasterConfig) = 1 THEN @MasterConfig ELSE N'{}' END,
                                                '$.questions'
                                            ) mq2
                                            WHERE JSON_VALUE(mq2.value, '$.id') = JSON_VALUE(sq.value, '$.id')
                                        ) mq
                                        ORDER BY TRY_CONVERT(INT, sq.[key])
                                        FOR XML PATH(''), TYPE
                                    ).value('.', 'NVARCHAR(MAX)'), 1, 1, ''), N'') + N']'
                                ) AS [questions]
                            FROM OPENJSON(@AssignmentConfig_Submission, '$.groups') g1
                            ORDER BY TRY_CONVERT(INT, g1.[key])
                            FOR JSON PATH, INCLUDE_NULL_VALUES
                        )) AS [groups]
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                );
            END
            ELSE
            BEGIN
                SELECT @AssignmentConfig_HadAnswer = (
                    SELECT 
                        JSON_VALUE(@AssignmentConfig_Submission, '$.version') AS [version],
                        JSON_VALUE(@AssignmentConfig_Submission, '$.type') AS [type],
                        JSON_QUERY(
                            '[' + STUFF((
                                SELECT ',' + 
                                    JSON_MODIFY(
                                        sq.value,
                                        '$.config',
                                        JSON_QUERY(
                                            CASE 
                                                WHEN JSON_VALUE(mq.value, '$.config.correctAnswer') IS NOT NULL
                                                THEN JSON_MODIFY(JSON_QUERY(sq.value, '$.config'), '$.correctAnswer', JSON_VALUE(mq.value, '$.config.correctAnswer'))
                                                WHEN JSON_QUERY(mq.value, '$.config.correctAnswers') IS NOT NULL
                                                THEN JSON_MODIFY(JSON_QUERY(sq.value, '$.config'), '$.correctAnswers', JSON_QUERY(mq.value, '$.config.correctAnswers'))
                                                WHEN JSON_QUERY(mq.value, '$.config.parts') IS NOT NULL
                                                THEN JSON_MODIFY(JSON_QUERY(sq.value, '$.config'), '$.parts', JSON_QUERY(mq.value, '$.config.parts'))
                                                WHEN JSON_QUERY(mq.value, '$.config.options') IS NOT NULL AND JSON_VALUE(mq.value, '$.config.options[0].correctAnswer') IS NOT NULL
                                                THEN JSON_MODIFY(JSON_QUERY(sq.value, '$.config'), '$.options', JSON_QUERY(mq.value, '$.config.options'))
                                                ELSE JSON_QUERY(mq.value, '$.config')
                                            END
                                        )
                                    )
                                FROM OPENJSON(
                                    CASE
                                        WHEN ISJSON(JSON_QUERY(@AssignmentConfig_Submission, '$.questions')) = 1
                                            THEN JSON_QUERY(@AssignmentConfig_Submission, '$.questions')
                                        ELSE N'[]'
                                    END
                                ) sq
                                CROSS APPLY (
                                    SELECT mq1.value
                                    FROM OPENJSON(
                                        CASE WHEN ISJSON(@MasterConfig) = 1 THEN @MasterConfig ELSE N'{}' END,
                                        '$.groups'
                                    ) mg1
                                    CROSS APPLY OPENJSON(
                                        CASE
                                            WHEN ISJSON(JSON_QUERY(mg1.value, '$.questions')) = 1
                                                THEN JSON_QUERY(mg1.value, '$.questions')
                                            ELSE N'[]'
                                        END
                                    ) mq1
                                    WHERE JSON_VALUE(mq1.value, '$.id') = JSON_VALUE(sq.value, '$.id')
                                    UNION ALL
                                    SELECT mq2.value
                                    FROM OPENJSON(
                                        CASE WHEN ISJSON(@MasterConfig) = 1 THEN @MasterConfig ELSE N'{}' END,
                                        '$.questions'
                                    ) mq2
                                    WHERE JSON_VALUE(mq2.value, '$.id') = JSON_VALUE(sq.value, '$.id')
                                ) mq
                                ORDER BY CAST(sq.[key] AS INT)
                                FOR XML PATH(''), TYPE
                            ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') + ']'
                        ) AS [questions]
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                );
            END
        END
        
        IF ISNULL(@AssignmentConfig_HadAnswer, '') = ''
        BEGIN
            SET @AssignmentConfig_HadAnswer = ISNULL(@AssignmentConfig_Submission, @MasterConfig);
        END
    END;

    SELECT
        ats.AssignmentID,
        asm.Title,
        asm.Instructions,
        CASE WHEN @AssignmentConfig_Submission IS NULL THEN ats.AssignmentConfig_NoAnswer ELSE @AssignmentConfig_Submission END AS AssignmentConfig,
        @AssignmentConfig_HadAnswer AS AssignmentConfig_HadAnswer,
        ats.DueDate,
        ats.MaxScore AS MaxScore,
        ISNULL(ats.LimitAssigned, 1) AS LimitAssigned,
        @StoredAttemptMaxScore AS AttemptMaxScore,
        mh.MonHocName,
        ats.AssignToStudentID,
        asm.KhoiID,
        asm.MonHocID,
        asm.IsBlockCopy_Paste,
        ats.Is_Full_Quiz,
        CASE WHEN @AssignmentConfig_Submission IS NULL THEN 0 ELSE 1 END AS Is_Shuffle,
        @PreviousAssignmentConfig AS PreviousAssignmentConfig,
        @AssignmentConfigHistory AS AssignmentConfigHistory,
        lcb.Reason,
        asm.IntegrationSource
    FROM dbo.tblEL_AssignToStudent ats
    INNER JOIN dbo.tblEL_Assignments asm
        ON ats.ResourceID = asm.AssignmentID
       AND ats.ResourceType = 'ASSIGNMENT'
       AND asm.IsDeleted = 0
    INNER JOIN dbo.tblMonHocLop mhl ON ats.MonHocLopID = mhl.MonHocLopID
    INNER JOIN dbo.tblMonHoc mh ON asm.MonHocID = mh.MonHocID
    LEFT JOIN dbo.tblEL_Submissions s
        ON ats.AssignToStudentID = s.AssignToStudentID
       AND s.HocSinhID = @HocSinhID
       AND s.IsDeleted = 0
       AND s.SubmissionID = @SubmissionID_Current
    LEFT JOIN dbo.tblEL_Log_ChamBai lcb ON lcb.Log_ChamBaiID = s.Log_ChamBaiID
    WHERE ats.AssignToStudentID = @AssignToStudentID
      AND ats.IsDeleted = 0;

    SELECT TOP 1
        SubmissionID,
        SubmissionContent,
        SubmissionStatus,
        Score,
        TeacherComment,
        GradedDate,
        GradedByTeacherID,
        LanNop
    FROM dbo.tblEL_Submissions
    WHERE AssignToStudentID = @AssignToStudentID
      AND HocSinhID = @HocSinhID
      AND IsDeleted = 0
      AND (LanNop IS NULL OR LanNop = @LanNop)
    ORDER BY LanNop DESC, SubmissionID DESC;
END
