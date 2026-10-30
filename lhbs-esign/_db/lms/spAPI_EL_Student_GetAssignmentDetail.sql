CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetAssignmentDetail]
    @AssignToClassID INT,
    @HocSinhID INT,
    @LanNop INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanNop = COALESCE(@LanNop, 1);
    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();
    DECLARE @AssignedUnitID VARCHAR(100);

    IF @AssignToClassID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin giao bài.', 16, 1);
        RETURN;
    END;

    SELECT @AssignedUnitID = mhl.LopNhomID
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE atc.AssignToClassID = @AssignToClassID AND atc.IsDeleted = 0;

    IF @AssignedUnitID IS NULL
    OR NOT EXISTS (
        SELECT 1
        FROM (
            SELECT l.LopID AS UnitID
            FROM dbo.tblHocSinhLop hsl
            JOIN dbo.tblLop l ON hsl.LopID = l.LopID AND l.NienKhoa = @NienKhoa_HienTai
            AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = @HocSinhID AND hsl.Enable = 1 AND hsl.NienKhoa = @NienKhoa_HienTai
            UNION
            SELECT n.NhomID
            FROM dbo.tblHocSinhNhom hsn
            JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa_HienTai
            WHERE hsn.HocSinhID = @HocSinhID AND hsn.Enable = 1
        ) AS MyUnits
        WHERE MyUnits.UnitID = @AssignedUnitID
    )
    BEGIN
        RAISERROR(N'[Unauthorized] Bài tập này không thuộc lớp hoặc niên khóa hiện tại của học sinh.', 16, 1);
        RETURN;
    END;

    DECLARE @SubmissionID_Current INT;
    DECLARE @SubmissionStatus INT;
    DECLARE @AssignmentConfig_Sub NVARCHAR(MAX);
    DECLARE @StoredAttemptMaxScore DECIMAL(10,2);
    DECLARE @PreviousAssignmentConfig NVARCHAR(MAX);
    DECLARE @AssignmentConfigHistory NVARCHAR(MAX);
    DECLARE @Log_ChamBaiID_Current INT;

    SELECT TOP 1
        @SubmissionID_Current = SubmissionID,
        @SubmissionStatus = SubmissionStatus,
        -- Chuỗi JSON 'null' hoặc config lỗi từ dữ liệu cũ không phải snapshot
        -- có thể hiển thị. Bỏ qua để trả về AssignmentConfig_NoAnswer của bài gốc.
        @AssignmentConfig_Sub = CASE
            WHEN ISJSON(AssignmentConfig) = 1
             AND JSON_QUERY(AssignmentConfig, '$.groups') IS NOT NULL
            THEN AssignmentConfig
            ELSE NULL
        END,
        @StoredAttemptMaxScore = AttemptMaxScore,
        @Log_ChamBaiID_Current = Log_ChamBaiID
    FROM dbo.tblEL_Submissions
    WHERE AssignToClassID = @AssignToClassID
      AND HocSinhID = @HocSinhID
      AND IsDeleted = 0
      AND (LanNop IS NULL OR LanNop = @LanNop)
    ORDER BY LanNop DESC;

    SELECT TOP 1 @PreviousAssignmentConfig = AssignmentConfig
    FROM dbo.tblEL_Submissions
    WHERE AssignToClassID = @AssignToClassID
      AND HocSinhID = @HocSinhID
      AND IsDeleted = 0
      AND LanNop < @LanNop
      AND AssignmentConfig IS NOT NULL
    ORDER BY LanNop DESC, SubmissionID DESC;

    SELECT @AssignmentConfigHistory = (
        SELECT AssignmentConfig, SubmissionContent, SubmissionStatus, LanNop, SubmissionID
        FROM dbo.tblEL_Submissions
        WHERE AssignToClassID = @AssignToClassID
          AND HocSinhID = @HocSinhID
          AND IsDeleted = 0
          AND LanNop < @LanNop
          AND AssignmentConfig IS NOT NULL
        ORDER BY LanNop DESC, SubmissionID DESC
        FOR JSON PATH
    );

    DECLARE @MasterConfig NVARCHAR(MAX);
    DECLARE @AsmMasterConfig NVARCHAR(MAX);
    DECLARE @Is_Full_Quiz BIT;
    SELECT TOP 1 
        @MasterConfig = CASE
            WHEN ISJSON(ISNULL(atc.AssignmentConfig, asm.AssignmentConfig)) = 1
                THEN ISNULL(atc.AssignmentConfig, asm.AssignmentConfig)
            ELSE NULL
        END,
        @AsmMasterConfig = CASE WHEN ISJSON(asm.AssignmentConfig) = 1 THEN asm.AssignmentConfig ELSE NULL END,
        @Is_Full_Quiz = atc.Is_Full_Quiz
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments asm ON atc.ResourceID = asm.AssignmentID AND atc.ResourceType = 'ASSIGNMENT'
    WHERE atc.AssignToClassID = @AssignToClassID AND atc.IsDeleted = 0;

    DECLARE @AssignmentConfig_HadAnswer NVARCHAR(MAX) = '';

    IF @SubmissionStatus = 4 OR (@SubmissionStatus >= 2 AND ISNULL(@Is_Full_Quiz, 0) = 1)
    BEGIN
        IF @AssignmentConfig_Sub IS NOT NULL AND (@MasterConfig IS NOT NULL OR @AsmMasterConfig IS NOT NULL)
        BEGIN
            IF JSON_QUERY(@AssignmentConfig_Sub, '$.groups') IS NOT NULL
            BEGIN
                SELECT @AssignmentConfig_HadAnswer = (
                    SELECT 
                        JSON_VALUE(@AssignmentConfig_Sub, '$.version') AS [version],
                        JSON_VALUE(@AssignmentConfig_Sub, '$.type') AS [type],
                        JSON_QUERY(
                            '[' + STUFF((
                                SELECT ',' + 
                                    '{"id":"' + STRING_ESCAPE(ISNULL(g.id,''), 'json') + '","title":"' + STRING_ESCAPE(ISNULL(g.title,''), 'json') + '","description":"' + STRING_ESCAPE(ISNULL(g.description,''), 'json') + '","media":' + ISNULL(g.media_str, 'null') + ',"questions":[' + ISNULL(g.q_list, '') + ']}'
                                FROM (
                                    SELECT 
                                        JSON_VALUE(g1.value, '$.id') AS id,
                                        JSON_VALUE(g1.value, '$.title') AS title,
                                        JSON_VALUE(g1.value, '$.description') AS description,
                                        JSON_QUERY(g1.value, '$.media') AS media_str,
                                        STUFF((
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
                                                            WHEN mq.value IS NOT NULL
                                                            THEN JSON_QUERY(mq.value, '$.config')
                                                            ELSE JSON_QUERY(sq.value, '$.config')
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
                                            OUTER APPLY (
                                                SELECT TOP 1 mq_union.value
                                                FROM (
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
                                                    UNION ALL
                                                    SELECT mq3.value
                                                    FROM OPENJSON(
                                                        CASE WHEN ISJSON(@AsmMasterConfig) = 1 THEN @AsmMasterConfig ELSE N'{}' END,
                                                        '$.groups'
                                                    ) mg3
                                                    CROSS APPLY OPENJSON(
                                                        CASE
                                                            WHEN ISJSON(JSON_QUERY(mg3.value, '$.questions')) = 1
                                                                THEN JSON_QUERY(mg3.value, '$.questions')
                                                            ELSE N'[]'
                                                        END
                                                    ) mq3
                                                    WHERE JSON_VALUE(mq3.value, '$.id') = JSON_VALUE(sq.value, '$.id')
                                                ) mq_union
                                            ) mq
                                            ORDER BY CAST(sq.[key] AS INT)
                                            FOR XML PATH(''), TYPE
                                        ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS q_list
                                    FROM OPENJSON(@AssignmentConfig_Sub, '$.groups') g1
                                ) g
                                FOR XML PATH(''), TYPE
                            ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') + ']'
                        ) AS [groups]
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                );
            END
            ELSE
            BEGIN
                SELECT @AssignmentConfig_HadAnswer = (
                    SELECT 
                        JSON_VALUE(@AssignmentConfig_Sub, '$.version') AS [version],
                        JSON_VALUE(@AssignmentConfig_Sub, '$.type') AS [type],
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
                                                WHEN mq.value IS NOT NULL
                                                THEN JSON_QUERY(mq.value, '$.config')
                                                ELSE JSON_QUERY(sq.value, '$.config')
                                            END
                                        )
                                    )
                                FROM OPENJSON(
                                    CASE
                                        WHEN ISJSON(JSON_QUERY(@AssignmentConfig_Sub, '$.questions')) = 1
                                            THEN JSON_QUERY(@AssignmentConfig_Sub, '$.questions')
                                        ELSE N'[]'
                                    END
                                ) sq
                                OUTER APPLY (
                                    SELECT TOP 1 mq_union.value
                                    FROM (
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
                                        UNION ALL
                                        SELECT mq3.value
                                        FROM OPENJSON(
                                            CASE WHEN ISJSON(@AsmMasterConfig) = 1 THEN @AsmMasterConfig ELSE N'{}' END,
                                            '$.groups'
                                        ) mg3
                                        CROSS APPLY OPENJSON(
                                            CASE
                                                WHEN ISJSON(JSON_QUERY(mg3.value, '$.questions')) = 1
                                                    THEN JSON_QUERY(mg3.value, '$.questions')
                                                ELSE N'[]'
                                            END
                                        ) mq3
                                        WHERE JSON_VALUE(mq3.value, '$.id') = JSON_VALUE(sq.value, '$.id')
                                    ) mq_union
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
           OR (JSON_QUERY(@AssignmentConfig_HadAnswer, '$.groups') IS NOT NULL AND JSON_QUERY(@AssignmentConfig_HadAnswer, '$.groups[0].questions[0]') IS NULL)
           OR (JSON_QUERY(@AssignmentConfig_HadAnswer, '$.questions') IS NOT NULL AND JSON_QUERY(@AssignmentConfig_HadAnswer, '$.questions[0]') IS NULL)
        BEGIN
            SET @AssignmentConfig_HadAnswer = ISNULL(@AssignmentConfig_Sub, ISNULL(@MasterConfig, @AsmMasterConfig));
        END
    END;

    SELECT
        atc.AssignmentID,
        asm.Title,
        asm.Instructions,
        CASE WHEN @AssignmentConfig_Sub IS NULL THEN atc.AssignmentConfig_NoAnswer ELSE @AssignmentConfig_Sub END AS AssignmentConfig,
        @AssignmentConfig_HadAnswer AS AssignmentConfig_HadAnswer,
        atc.DueDate,
        atc.MaxScore AS MaxScore,
        ISNULL(atc.LimitAssigned, 1) AS LimitAssigned,
        @StoredAttemptMaxScore AS AttemptMaxScore,
        mh.MonHocName,
        atc.AssignToClassID,
        asm.KhoiID,
        asm.MonHocID,
        asm.IsBlockCopy_Paste,
        atc.Is_Full_Quiz,
        CASE WHEN @AssignmentConfig_Sub IS NULL THEN 0 ELSE 1 END AS Is_Shuffle,
        @PreviousAssignmentConfig AS PreviousAssignmentConfig,
        @AssignmentConfigHistory AS AssignmentConfigHistory,
        lcb.Reason,
        CONCAT(gv.HoGV, ' ', gv.TenGV) AS TeacherAssigned,
        asm.IntegrationSource
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments asm ON atc.ResourceID = asm.AssignmentID
       AND atc.ResourceType = 'ASSIGNMENT' AND asm.IsDeleted = 0
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    JOIN dbo.tblMonHoc mh ON asm.MonHocID = mh.MonHocID
    LEFT JOIN dbo.tblEL_Log_ChamBai lcb ON lcb.Log_ChamBaiID = @Log_ChamBaiID_Current
    LEFT JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = atc.CreateUser
    WHERE atc.AssignToClassID = @AssignToClassID AND atc.IsDeleted = 0;

    SELECT
        SubmissionID,
        SubmissionContent,
        SubmissionStatus,
        Score,
        TeacherComment,
        GradedDate,
        GradedByTeacherID,
        LanNop,
        AccessTime,
        ISNULL(DurationTime, 0) AS DurationTime
    FROM dbo.tblEL_Submissions
    WHERE SubmissionID = @SubmissionID_Current AND IsDeleted = 0;
END
