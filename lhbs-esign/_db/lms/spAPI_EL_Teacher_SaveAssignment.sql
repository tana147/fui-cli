CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_SaveAssignment]
    @AssignmentID              INT
  , @AssignToClassID           INT
  , @MonHocID                  INT
  , @KhoiID                    INT
  , @Title                     NVARCHAR(255)
  , @Instructions              NVARCHAR(MAX)
  , @AssignmentConfig          NVARCHAR(MAX)
  , @AssignmentConfig_NoAnswer NVARCHAR(MAX)
  , @MaxScore                  FLOAT
  , @NienKhoa                  INT
  , @HocKi                     TINYINT
  , @Is_Full_Quiz              BIT
  , @IsBlockCopy_Paste         BIT
  , @IntegrationSource         NVARCHAR(200)
  , @sys_UserID                VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    IF ISJSON(@AssignmentConfig) = 0
    BEGIN
        RAISERROR('AssignmentConfig is not a valid JSON.', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Bản cấu hình gốc là nguồn media dùng để đồng bộ xuống các bản snapshot.
        -- Lưu bản cũ trước khi UPDATE để có thể bỏ qua toàn bộ nhánh đồng bộ khi
        -- giáo viên chỉ sửa nội dung câu hỏi/thông tin bài, không sửa media.
        DECLARE @SyncAssignmentID    INT = NULL;
        DECLARE @SyncAssignToClassID INT = NULL;
        DECLARE @SyncConfig          NVARCHAR(MAX) = @AssignmentConfig;
        DECLARE @PreviousConfig      NVARCHAR(MAX) = NULL;
        DECLARE @PreviousNoAnswer    NVARCHAR(MAX) = NULL;
        DECLARE @SyncNoAnswer        NVARCHAR(MAX) = NULL;

        -- Kiểm tra @AssignToClassID có chưa?
        -- Nếu có thì update vô bảng AssignToClass; nếu không thì update bảng Assignment.
        IF (@AssignToClassID > 0)
        BEGIN
        SELECT @PreviousConfig = AssignmentConfig
             , @PreviousNoAnswer = AssignmentConfig_NoAnswer
        FROM dbo.tblEL_AssignToClass
        WHERE AssignToClassID = @AssignToClassID
          AND IsDeleted = 0;

        UPDATE dbo.tblEL_AssignToClass
        SET    AssignmentConfig = @AssignmentConfig
             , AssignmentConfig_NoAnswer = @AssignmentConfig_NoAnswer
             , MaxScore = @MaxScore
             , UpdateUser = @sys_UserID
             , UpdateTime = GETDATE()
             , Is_Full_Quiz = @Is_Full_Quiz
             , LimitAssigned = CASE WHEN @Is_Full_Quiz = 1 THEN LimitAssigned ELSE 1 END
        WHERE AssignToClassID = @AssignToClassID;

        SELECT @SyncAssignmentID = AssignmentID
        FROM dbo.tblEL_AssignToClass
        WHERE AssignToClassID = @AssignToClassID;

        SET @SyncAssignToClassID = @AssignToClassID;
        END;
        ELSE
        BEGIN
            IF @AssignmentID > 0
            BEGIN
            SELECT @PreviousConfig = AssignmentConfig
                 , @PreviousNoAnswer = AssignmentConfig_NoAnswer
            FROM dbo.tblEL_Assignments
            WHERE AssignmentID = @AssignmentID;

            UPDATE dbo.tblEL_Assignments
            SET    Title = ISNULL(@Title, Title)
                 , Instructions = ISNULL(@Instructions, Instructions)
                 , MonHocID = ISNULL(@MonHocID, MonHocID)
                 , KhoiID = ISNULL(@KhoiID, KhoiID)
                 , AssignmentConfig = ISNULL(@AssignmentConfig, AssignmentConfig)
                 , AssignmentConfig_NoAnswer = ISNULL(@AssignmentConfig_NoAnswer, AssignmentConfig_NoAnswer)
                 , HocKi = ISNULL(@HocKi, HocKi)
                 , IsBlockCopy_Paste = ISNULL(@IsBlockCopy_Paste, IsBlockCopy_Paste)
                 , MaxScore = ISNULL(@MaxScore, MaxScore)
                 , IntegrationSource = ISNULL(@IntegrationSource, IntegrationSource)
                 , UpdateTime = GETDATE()
                 , UpdateUser = @sys_UserID
            WHERE AssignmentID = @AssignmentID;

        SET @SyncAssignmentID = @AssignmentID;

            SELECT @SyncNoAnswer = AssignmentConfig_NoAnswer
            FROM dbo.tblEL_Assignments
            WHERE AssignmentID = @AssignmentID;

            SELECT *
            FROM dbo.tblEL_Assignments
            WHERE AssignmentID = @AssignmentID;
            END;
            ELSE
            BEGIN
            INSERT INTO dbo.tblEL_Assignments
            (
                MonHocID
              , KhoiID
              , Title
              , Instructions
              , AssignmentConfig
              , AssignmentConfig_NoAnswer
              , NienKhoa
              , HocKi
              , IsBlockCopy_Paste
              , MaxScore
              , IntegrationSource
              , CreateUser
            )
            VALUES
            (
                @MonHocID
              , @KhoiID
              , @Title
              , @Instructions
              , @AssignmentConfig
              , @AssignmentConfig_NoAnswer
              , @NienKhoa
              , @HocKi
              , @IsBlockCopy_Paste
              , @MaxScore
              , @IntegrationSource
              , @sys_UserID
            );

            SELECT AssignmentID = SCOPE_IDENTITY();
            END;
        END;

        /*
           Khi giáo viên lưu bài gốc hoặc cấu hình của một lớp, file/media phải đi
           cùng xuống snapshot lớp và snapshot học sinh. Chỉ thay $.media theo id
           nhóm, không ghi đè câu hỏi/câu trả lời đã làm của học sinh.
        */
        IF @SyncAssignmentID IS NOT NULL
       AND ISJSON(@SyncConfig) = 1
       AND JSON_QUERY(@SyncConfig, '$.groups') IS NOT NULL
        BEGIN
        DECLARE @SyncMediaChanged BIT = 0;
        DECLARE @SyncNoAnswerChanged BIT = 0;
        DECLARE @PreviousMedia TABLE
        (
            GroupID NVARCHAR(200) NULL,
            MediaJson NVARCHAR(MAX) NULL
        );
        DECLARE @CurrentMedia TABLE
        (
            GroupID NVARCHAR(200) NULL,
            MediaJson NVARCHAR(MAX) NULL
        );

        -- So sánh đúng phần media, không dùng hash đơn thuần để tránh rủi ro
        -- collision làm bỏ sót đồng bộ dữ liệu.
        IF ISJSON(@PreviousConfig) = 1
           AND JSON_QUERY(@PreviousConfig, '$.groups') IS NOT NULL
        BEGIN
            INSERT INTO @PreviousMedia (GroupID, MediaJson)
            SELECT JSON_VALUE(g.value, '$.id')
                 , JSON_QUERY(g.value, '$.media')
            FROM OPENJSON(@PreviousConfig, '$.groups') g;
        END;

        INSERT INTO @CurrentMedia (GroupID, MediaJson)
        SELECT JSON_VALUE(g.value, '$.id')
             , JSON_QUERY(g.value, '$.media')
        FROM OPENJSON(@SyncConfig, '$.groups') g;

        IF @PreviousConfig IS NULL
           OR ISJSON(@PreviousConfig) <> 1
           OR EXISTS
              (
                  SELECT GroupID, MediaJson FROM @PreviousMedia
                  EXCEPT
                  SELECT GroupID, MediaJson FROM @CurrentMedia
              )
           OR EXISTS
              (
                  SELECT GroupID, MediaJson FROM @CurrentMedia
                  EXCEPT
                  SELECT GroupID, MediaJson FROM @PreviousMedia
              )
        BEGIN
            SET @SyncMediaChanged = 1;
        END;

        -- Khi lưu bài gốc, no-answer và config vẫn phải được cập nhật xuống snapshot lớp
        -- như logic cũ; chỉ bỏ qua khi chuỗi cấu hình thực sự không đổi.
        IF @SyncAssignToClassID IS NULL
           AND ((@PreviousNoAnswer IS NULL AND @SyncNoAnswer IS NOT NULL)
             OR (@PreviousNoAnswer IS NOT NULL AND @SyncNoAnswer IS NULL)
             OR (@PreviousNoAnswer IS NOT NULL AND @SyncNoAnswer IS NOT NULL AND @PreviousNoAnswer <> @SyncNoAnswer))
        BEGIN
            SET @SyncNoAnswerChanged = 1;
        END;

        DECLARE @SyncConfigChanged BIT = 0;
        IF @SyncAssignToClassID IS NULL
           AND ((@PreviousConfig IS NULL AND @SyncConfig IS NOT NULL)
             OR (@PreviousConfig IS NOT NULL AND @SyncConfig IS NULL)
             OR (@PreviousConfig IS NOT NULL AND @SyncConfig IS NOT NULL AND @PreviousConfig <> @SyncConfig))
        BEGIN
            SET @SyncConfigChanged = 1;
        END;

        -- Không có thay đổi media hoặc cấu hình thì không cần parse/ghi lại toàn bộ snapshot.
        IF @SyncMediaChanged = 1 OR @SyncNoAnswerChanged = 1 OR @SyncConfigChanged = 1
        BEGIN
            DECLARE @SyncGroups TABLE
            (
                GroupNo INT IDENTITY(1, 1) PRIMARY KEY,
                GroupID NVARCHAR(200) NOT NULL,
                MasterMedia NVARCHAR(MAX) NULL
            );
            DECLARE @SyncTargets TABLE
            (
                TargetType CHAR(1) NOT NULL,
                TargetID BIGINT NOT NULL,
                TargetConfig NVARCHAR(MAX) NULL,
                TargetNoAnswer NVARCHAR(MAX) NULL,
                PRIMARY KEY (TargetType, TargetID)
            );

            INSERT INTO @SyncGroups (GroupID, MasterMedia)
            SELECT JSON_VALUE(g.value, '$.id')
                 , JSON_QUERY(g.value, '$.media')
            FROM OPENJSON(@SyncConfig, '$.groups') g
            WHERE JSON_VALUE(g.value, '$.id') IS NOT NULL;

            -- Tập target được đọc một lần. Cách này loại bỏ cursor lồng nhóm ×
            -- snapshot và đồng thời bao phủ cả giao bài trực tiếp cho học sinh.
            INSERT INTO @SyncTargets (TargetType, TargetID, TargetConfig, TargetNoAnswer)
            SELECT 'C'
                 , CONVERT(BIGINT, atc.AssignToClassID)
                 , atc.AssignmentConfig
                 , atc.AssignmentConfig_NoAnswer
            FROM dbo.tblEL_AssignToClass atc
            WHERE atc.AssignmentID = @SyncAssignmentID
              AND atc.IsDeleted = 0
              AND (@SyncAssignToClassID IS NULL OR atc.AssignToClassID = @SyncAssignToClassID)
            UNION ALL
            SELECT 'S'
                 , CONVERT(BIGINT, s.SubmissionID)
                 , s.AssignmentConfig
                 , CAST(NULL AS NVARCHAR(MAX))
            FROM dbo.tblEL_Submissions s
            INNER JOIN dbo.tblEL_AssignToClass atc
                ON atc.AssignToClassID = s.AssignToClassID
               AND atc.AssignmentID = @SyncAssignmentID
               AND atc.IsDeleted = 0
               AND (@SyncAssignToClassID IS NULL OR atc.AssignToClassID = @SyncAssignToClassID)
            WHERE s.IsDeleted = 0
              AND ISJSON(s.AssignmentConfig) = 1
              AND JSON_QUERY(s.AssignmentConfig, '$.groups') IS NOT NULL
            UNION ALL
            SELECT 'T'
                 , CONVERT(BIGINT, ats.AssignToStudentID)
                 , ats.AssignmentConfig
                 , ats.AssignmentConfig_NoAnswer
            FROM dbo.tblEL_AssignToStudent ats
            WHERE @SyncAssignToClassID IS NULL
              AND ats.AssignmentID = @SyncAssignmentID
              AND ats.IsDeleted = 0
            UNION ALL
            SELECT 'S'
                 , CONVERT(BIGINT, s.SubmissionID)
                 , s.AssignmentConfig
                 , CAST(NULL AS NVARCHAR(MAX))
            FROM dbo.tblEL_Submissions s
            INNER JOIN dbo.tblEL_AssignToStudent ats
                ON ats.AssignToStudentID = s.AssignToStudentID
               AND ats.AssignmentID = @SyncAssignmentID
               AND ats.IsDeleted = 0
            WHERE @SyncAssignToClassID IS NULL
              AND s.IsDeleted = 0
              AND ISJSON(s.AssignmentConfig) = 1
              AND JSON_QUERY(s.AssignmentConfig, '$.groups') IS NOT NULL;

            DECLARE @GroupNo INT = 1;
            DECLARE @GroupCount INT = (SELECT COUNT(*) FROM @SyncGroups);
            DECLARE @MasterGroupID NVARCHAR(200);
            DECLARE @MasterMedia NVARCHAR(MAX);

            -- Chỉ lặp theo số nhóm của bài, mỗi vòng cập nhật set target đã nạp
            -- trong memory; không còn cursor qua từng snapshot học sinh.
            WHILE @GroupNo <= @GroupCount
            BEGIN
                SELECT @MasterGroupID = GroupID
                     , @MasterMedia = MasterMedia
                FROM @SyncGroups
                WHERE GroupNo = @GroupNo;

                IF @MasterMedia IS NOT NULL
                BEGIN
                    UPDATE target
                    SET TargetConfig = JSON_MODIFY
                    (
                        target.TargetConfig,
                        CONCAT('$.groups[', groupJson.[key], '].media'),
                        JSON_QUERY(@MasterMedia)
                    )
                    FROM @SyncTargets target
                    CROSS APPLY OPENJSON(target.TargetConfig, '$.groups') groupJson
                    WHERE ISJSON(target.TargetConfig) = 1
                      AND JSON_VALUE(groupJson.value, '$.id') = @MasterGroupID;

                    IF @SyncAssignToClassID IS NOT NULL
                    BEGIN
                        UPDATE target
                        SET TargetNoAnswer = JSON_MODIFY
                        (
                            target.TargetNoAnswer,
                            CONCAT('$.groups[', groupJson.[key], '].media'),
                            JSON_QUERY(@MasterMedia)
                        )
                        FROM @SyncTargets target
                        CROSS APPLY OPENJSON(target.TargetNoAnswer, '$.groups') groupJson
                        WHERE target.TargetType IN ('C', 'T')
                          AND ISJSON(target.TargetNoAnswer) = 1
                          AND JSON_VALUE(groupJson.value, '$.id') = @MasterGroupID;
                    END;
                END;

                SET @GroupNo = @GroupNo + 1;
            END;

            IF @SyncAssignToClassID IS NULL
            BEGIN
                -- Bài gốc đồng bộ cả no-answer và full config xuống các lớp (C) và học sinh (T)
                IF @SyncNoAnswerChanged = 1
                BEGIN
                    UPDATE target
                    SET TargetNoAnswer = @SyncNoAnswer
                    FROM @SyncTargets target
                    WHERE target.TargetType IN ('C', 'T');
                END;

                IF @SyncConfigChanged = 1
                BEGIN
                    UPDATE target
                    SET TargetConfig = @SyncConfig
                    FROM @SyncTargets target
                    WHERE target.TargetType IN ('C', 'T');
                END;
            END;

            UPDATE atc
            SET    AssignmentConfig = target.TargetConfig
                 , AssignmentConfig_NoAnswer = target.TargetNoAnswer
                 , UpdateUser = @sys_UserID
                 , UpdateTime = GETDATE()
            FROM dbo.tblEL_AssignToClass atc
            INNER JOIN @SyncTargets target
                ON target.TargetType = 'C'
               AND target.TargetID = CONVERT(BIGINT, atc.AssignToClassID)
            WHERE atc.IsDeleted = 0;

            UPDATE ats
            SET    AssignmentConfig = target.TargetConfig
                 , AssignmentConfig_NoAnswer = target.TargetNoAnswer
                 , UpdateUser = @sys_UserID
                 , UpdateTime = GETDATE()
            FROM dbo.tblEL_AssignToStudent ats
            INNER JOIN @SyncTargets target
                ON target.TargetType = 'T'
               AND target.TargetID = CONVERT(BIGINT, ats.AssignToStudentID)
            WHERE ats.IsDeleted = 0;

            UPDATE s
            SET    AssignmentConfig = target.TargetConfig
                 , UpdateUser = @sys_UserID
                 , UpdateTime = GETDATE()
            FROM dbo.tblEL_Submissions s
            INNER JOIN @SyncTargets target
                ON target.TargetType = 'S'
               AND target.TargetID = CONVERT(BIGINT, s.SubmissionID)
            WHERE s.IsDeleted = 0;
        END;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
