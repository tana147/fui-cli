CREATE PROCEDURE [dbo].[spAPI_EL_Student_SaveSubmission_AssignToStudent]
    @AssignToStudentID INT
  , @HocSinhID         INT
  , @SubmissionContent NVARCHAR(MAX)
       , @SubmissionStatus  TINYINT -- status 1 Draft, status 2 Submitted, status 4 Graded
  , @Score             DECIMAL(10, 2)
         , @Is_Full_Quiz      BIT
       , @SubmitToken       VARCHAR(128)
  , @LanNop             INT
  , @sys_UserID        VARCHAR(9)
AS
BEGIN
              SET NOCOUNT ON;

              -- Submission đã chấm phải có payload JSON để tạo đầy đủ QuestionResults.
              IF @SubmissionStatus = 4 AND ISNULL(ISJSON(@SubmissionContent), 0) <> 1
              BEGIN
                            RAISERROR(N'Không thể ghi trạng thái đã chấm khi SubmissionContent không phải JSON hợp lệ.', 16, 1);
                            RETURN;
              END;

              IF @SubmissionStatus = 4 AND @Score IS NULL AND ISJSON(@SubmissionContent) = 1
              BEGIN
                            SELECT @Score = ROUND(SUM(
                                   COALESCE(
                                          TRY_CAST(JSON_VALUE(ans.[value], '$.grading.manualScore') AS DECIMAL(10, 2)),
                                          TRY_CAST(JSON_VALUE(ans.[value], '$.grading.autoScore') AS DECIMAL(10, 2))
                                   )
                            ), 2)
                            FROM OPENJSON(JSON_QUERY(@SubmissionContent, '$.answers')) ans
                            WHERE JSON_VALUE(ans.[value], '$.grading.manualScore') IS NOT NULL
                               OR JSON_VALUE(ans.[value], '$.grading.autoScore') IS NOT NULL;
              END;

              -- Không cho phép trạng thái đã chấm tồn tại mà không có điểm tổng.
              -- Frontend mới sẽ hạ về Submitted khi chưa đủ answer key; các client cũ phải bị chặn tại DB.
              IF @SubmissionStatus = 4 AND @Score IS NULL
              BEGIN
                            RAISERROR(N'Không thể ghi trạng thái đã chấm khi Score bị thiếu.', 16, 1);
                            RETURN;
              END;

              IF @SubmissionStatus >= 2
              BEGIN
                            DECLARE @SubmitTokenNorm VARCHAR(128) = NULLIF(LTRIM(RTRIM(@SubmitToken)), '');
                            DECLARE @TokenHash VARBINARY(32) = NULL;
                            IF @SubmitTokenNorm IS NOT NULL
                                   SET @TokenHash = HASHBYTES('SHA2_256', @SubmitTokenNorm);

                            DECLARE @ConsumedRows INT = 0;

                            ;WITH TokenPick AS
                            (
                                          SELECT TOP 1 SubmitTokenID
                                          FROM dbo.tblEL_Student_SubmitTokens WITH (UPDLOCK, ROWLOCK, READPAST)
                                          WHERE HocSinhID = @HocSinhID
                                                 AND AssignToStudentID = @AssignToStudentID
                                                 AND AssignToClassID IS NULL
                                                 AND (@TokenHash IS NULL OR TokenHash = @TokenHash)
                                                 AND IsUsed = 0
                                                 AND ExpireTime >= SYSDATETIME()
                                          ORDER BY SubmitTokenID DESC
                            )
                            UPDATE tok
                                    SET IsUsed = 1,
                                                  UsedTime = SYSDATETIME()
                            FROM dbo.tblEL_Student_SubmitTokens tok
                            JOIN TokenPick pick ON tok.SubmitTokenID = pick.SubmitTokenID;

                            SET @ConsumedRows = @@ROWCOUNT;

                            IF @ConsumedRows = 0
                            BEGIN
                                          RAISERROR(N'Khong tim thay one-time token hop le. Vui long yeu cau token moi va nop lai.', 16, 1);
                                          RETURN;
                            END;
              END;

    DECLARE @SubmissionID_Out BIGINT;
    -- Khi client biết lượt đang mở, ưu tiên đúng lượt đó. Nếu caller truyền null/0
    -- thì giữ fallback tính lượt mới như contract trước đây.
    DECLARE @RequestedLanNop INT = NULLIF(@LanNop, 0);
    DECLARE @EffectiveLanNop INT;
    IF @RequestedLanNop IS NULL
    BEGIN
        DECLARE @CheckLanNop INT;
        SET @CheckLanNop = ISNULL((
                                      SELECT TOP 1 LanNop
                                      FROM tblEL_Submissions
                                      WHERE HocSinhID = @HocSinhID
                                        AND AssignToStudentID = @AssignToStudentID
                                        AND IsDeleted = 0
                                        AND SubmissionStatus >= 2
                                      ORDER BY LanNop DESC
                                  ), 0);
        SET @EffectiveLanNop = @CheckLanNop + 1;
    END
    ELSE
    BEGIN
        SET @EffectiveLanNop = @RequestedLanNop;
    END;
    DECLARE @Is_OverDue BIT = 0;
    DECLARE @Duedate DATETIME;
    SET @Duedate =
    (
        SELECT [DueDate]
        FROM
               tblEL_AssignToStudent
        WHERE
               AssignToStudentID = @AssignToStudentID
          AND  IsDeleted          = 0
    );
    IF GETDATE() > @Duedate
        SET @Is_OverDue = 1;

    DECLARE @LatestSubmissionID BIGINT;
    SELECT TOP 1 @LatestSubmissionID = SubmissionID
    FROM dbo.tblEL_Submissions
    WHERE AssignToStudentID = @AssignToStudentID
      AND HocSinhID = @HocSinhID
      AND IsDeleted = 0
      AND (@RequestedLanNop IS NULL OR LanNop = @EffectiveLanNop)
    ORDER BY ISNULL(LanNop, 1) DESC, SubmissionID DESC;

    -- Lấy AssignmentID
    DECLARE @AssignmentID INT;

    SELECT TOP 1
           @AssignmentID = ats.AssignmentID
    FROM
           dbo.tblEL_AssignToStudent ats
    WHERE
           ats.AssignToStudentID = @AssignToStudentID
      AND  ats.HocSinhID          = @HocSinhID
      AND  ats.IsDeleted          = 0;
    -- Chỉ match submission mới nhất để phase auto-grade của lượt mới không cập nhật
    -- nhầm submission cũ đã chấm của cùng học sinh.
    MERGE dbo.tblEL_Submissions AS target
    USING
    (
        SELECT @AssignToStudentID AS AssignToStudentID
             , @HocSinhID         AS HocSinhID
             , @LatestSubmissionID AS SubmissionID
    ) AS source
    ON (
           target.SubmissionID = source.SubmissionID
     AND   target.AssignToStudentID = source.AssignToStudentID
     AND   target.HocSinhID = source.HocSinhID
     AND   target.IsDeleted = 0
       )

           -- Khi đã có bản ghi: luôn cho cập nhật nháp; cho cập nhật bài đã nộp nếu là full-quiz hoặc status=4
           WHEN MATCHED AND (
                  target.SubmissionStatus < 2
                  OR (@Is_Full_Quiz = 1 AND @SubmissionStatus >= 2)
                  OR (@SubmissionStatus = 4)
           ) THEN UPDATE SET SubmissionContent = @SubmissionContent
                                                                                                          , SubmissionStatus = @SubmissionStatus
                                                                                                          , SubmissionTime = CASE
                                                                                                                                             WHEN @SubmissionStatus >= 2 THEN GETDATE()
                                                                                                                                             ELSE target.SubmissionTime
                                                                                                                                      END
                                                                                                          , Score = CASE
                                                                                                                            WHEN @SubmissionStatus >= 2 AND @Score IS NOT NULL THEN @Score
                                                                                                                            WHEN @SubmissionStatus >= 2 THEN target.Score
                                                                                                                            ELSE target.Score
                                                                                                                     END
                                                                                                          , GradedDate = CASE
                                                                                                                             WHEN @SubmissionStatus = 4 THEN GETDATE()
                                                                                                                             ELSE target.GradedDate
                                                                                                                        END
                                                                                                          , IsOverDue = @Is_OverDue
                                                                                                          , UpdateTime = GETDATE()
                                                                                                          , UpdateUser = @HocSinhID

       -- Khi chưa có bản ghi nào
    WHEN NOT MATCHED THEN INSERT
                          (
                              AssignToStudentID
                            , AssignToClassID
                            , HocSinhID
                            , SubmissionContent
                            , SubmissionStatus
                            , SubmissionTime
                            , Score
                            , GradedDate
                            , Log_ChamBaiID
                            , CreateUser
                            , CreateTime
                            , IsOverDue
                            , LanNop
                          )
                          VALUES
                          (
                              @AssignToStudentID
                            , -1
                            , @HocSinhID
                            , @SubmissionContent
                            , @SubmissionStatus
                                                                                                  , CASE WHEN @SubmissionStatus >= 2 THEN GETDATE() ELSE NULL END
                                                                                                  , @Score
                                                                                                  , CASE WHEN @SubmissionStatus = 4 THEN GETDATE() ELSE NULL END
                                                                                                  , NULL
                            , @HocSinhID
                            , GETDATE()
                            , @Is_OverDue
                            , @EffectiveLanNop
                          );

    -- Lấy ID của bản ghi vừa được tác động để ghi log
    -- SCOPE_IDENTITY() chỉ hoạt động cho INSERT, nên cần SELECT lại để chắc chắn
    SELECT TOP 1
           @SubmissionID_Out = SubmissionID
    FROM
           dbo.tblEL_Submissions
    WHERE
           AssignToStudentID = @AssignToStudentID
      AND  HocSinhID          = @HocSinhID
      AND  IsDeleted          = 0
      AND  (@RequestedLanNop IS NULL OR LanNop = @EffectiveLanNop)
    ORDER BY ISNULL(LanNop, 1) DESC, SubmissionID DESC;

    -- Chỉ ghi log khi nộp bài thành công (Status=2), không ghi khi lưu nháp (Status=1)
       IF @SubmissionStatus >= 2
   AND @SubmissionID_Out IS NOT NULL
    BEGIN
        -- Ghi log, sử dụng SubmissionID vừa lấy được
        INSERT INTO dbo.tblEL_Activity_Logs
        (
            HocSinhID
          , ActivityType
          , ResourceID
          , ResourceType
          , CreateUser
          , CreateTime
        )
        VALUES
        (
            @HocSinhID
          , 'SUBMISSION_NEW'
          , @SubmissionID_Out
          , 'SUBMISSION'
          , @HocSinhID
          , GETDATE()
        );

        DECLARE @CurrentTime DATETIME = GETDATE();
        --insert log nộp bài
        EXEC spAPI_EL_Log_NopBai_Ins @SubmissionID = @SubmissionID_Out
                                   , @SubmissionContent = @SubmissionContent
                                   , @SubmissionTime = @CurrentTime
                                   , @SYS_USERID = @HocSinhID;

              IF @SubmissionStatus = 4
              BEGIN
                     DECLARE @Log_ChamBaiID_New INT = NULL;
                     DECLARE @AssignmentConfig_Log NVARCHAR(MAX) = NULL;

                     SELECT TOP 1 @AssignmentConfig_Log = AssignmentConfig
                     FROM dbo.tblEL_Submissions
                     WHERE SubmissionID = @SubmissionID_Out
                       AND IsDeleted = 0;

                     INSERT INTO dbo.tblEL_Log_ChamBai
                     (
                            SubmissionID,
                            AssignToClassID,
                            AssignToStudentID,
                            AssignmentConfig,
                            SubmissionStatus,
                            SubmissionContent,
                            Reason,
                            CreateUser,
                            CreateTime,
                            UpdateUser,
                            UpdateTime
                     )
                     VALUES
                     (
                            @SubmissionID_Out,
                            NULL,
                            @AssignToStudentID,
                            @AssignmentConfig_Log,
                            @SubmissionStatus,
                            @SubmissionContent,
                            NULL,
                            @HocSinhID,
                            GETDATE(),
                            @HocSinhID,
                            GETDATE()
                     );

                     SET @Log_ChamBaiID_New = SCOPE_IDENTITY();

                     UPDATE dbo.tblEL_Submissions
                     SET GradedDate = GETDATE(),
                            Log_ChamBaiID = @Log_ChamBaiID_New,
                            UpdateTime = GETDATE(),
                            UpdateUser = @HocSinhID
                     WHERE SubmissionID = @SubmissionID_Out
                       AND IsDeleted = 0;
              END;
    END;
    -- Chấm tự động không đi qua PublishGrade; đồng bộ từ snapshot của chính lượt làm để báo cáo có từng câu, kể cả bài random.
    IF @SubmissionStatus = 4
       AND @SubmissionID_Out IS NOT NULL
       AND ISJSON(@SubmissionContent) = 1
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
            DECLARE @AnalyticsLockResult INT
                  , @AnalyticsLockResource NVARCHAR(255);
            SET @AnalyticsLockResource = N'EL_Analytics_QuestionResults:' + CONVERT(NVARCHAR(20), @SubmissionID_Out);
            EXEC @AnalyticsLockResult = sys.sp_getapplock
                 @Resource = @AnalyticsLockResource,
                 @LockMode = 'Exclusive',
                 @LockOwner = 'Transaction',
                 @LockTimeout = 15000;
            IF @AnalyticsLockResult < 0
                THROW 51001, N'Không lấy được khóa đồng bộ analytics theo SubmissionID.', 1;
        -- === BƯỚC 2: ĐỒNG BỘ DỮ LIỆU SANG BẢNG ANALYTICS ===
            DELETE FROM
            dbo.tblEL_Analytics_QuestionResults
            WHERE
                SubmissionID = @SubmissionID_Out;

            DECLARE @AssignmentConfig NVARCHAR(MAX)
                      , @LopID             VARCHAR(10)
                      , @NienKhoa          INT
                      , @MonHocLopID       INT
                      , @MonHocID          INT
                      , @SubmissionTime    DATETIME;

            SELECT @AssignToStudentID = s.AssignToStudentID
                 , @HocSinhID         = s.HocSinhID
                 , @SubmissionContent = s.SubmissionContent -- Read the persisted payload while holding the analytics lock.
                 , @SubmissionTime    = ISNULL(s.SubmissionTime, s.CreateTime)
                 -- Snapshot của submission là nguồn chuẩn để đồng bộ analytics:
                 -- bài random chỉ có các câu học sinh thực sự nhận, còn ats/a là pool gốc.
                 , @AssignmentConfig = CASE
                     WHEN ISJSON(s.AssignmentConfig)=1 AND (JSON_QUERY(CASE WHEN ISJSON(s.AssignmentConfig)=1 THEN s.AssignmentConfig ELSE N'{}' END, '$.groups') IS NOT NULL OR JSON_QUERY(CASE WHEN ISJSON(s.AssignmentConfig)=1 THEN s.AssignmentConfig ELSE N'{}' END, '$.questions') IS NOT NULL) THEN s.AssignmentConfig
                     WHEN ISJSON(ats.AssignmentConfig)=1 AND (JSON_QUERY(CASE WHEN ISJSON(ats.AssignmentConfig)=1 THEN ats.AssignmentConfig ELSE N'{}' END, '$.groups') IS NOT NULL OR JSON_QUERY(CASE WHEN ISJSON(ats.AssignmentConfig)=1 THEN ats.AssignmentConfig ELSE N'{}' END, '$.questions') IS NOT NULL) THEN ats.AssignmentConfig
                     WHEN ISJSON(a.AssignmentConfig)=1 AND (JSON_QUERY(CASE WHEN ISJSON(a.AssignmentConfig)=1 THEN a.AssignmentConfig ELSE N'{}' END, '$.groups') IS NOT NULL OR JSON_QUERY(CASE WHEN ISJSON(a.AssignmentConfig)=1 THEN a.AssignmentConfig ELSE N'{}' END, '$.questions') IS NOT NULL) THEN a.AssignmentConfig
                     ELSE NULL
                 END
                 , @AssignmentID      = a.AssignmentID
                 , @LopID             = mhl.LopNhomID
                 , @NienKhoa          = a.NienKhoa
                 , @MonHocLopID       = ats.MonHocLopID
                 , @MonHocID          = a.MonHocID
            FROM
                   dbo.tblEL_Submissions          s
                   JOIN dbo.tblEL_AssignToStudent ats ON s.AssignToStudentID = ats.AssignToStudentID
                   JOIN dbo.tblEL_Assignments     a ON ats.ResourceID        = a.AssignmentID
                                                   AND ats.ResourceType      = 'ASSIGNMENT'
                   JOIN dbo.tblMonHocLop          mhl ON ats.MonHocLopID     = mhl.MonHocLopID
            WHERE
                   s.SubmissionID = @SubmissionID_Out;

            DECLARE @Questions TABLE
            (
                QuestionID_InJSON VARCHAR(50) NOT NULL CHECK (LEN(LTRIM(RTRIM(QuestionID_InJSON))) > 0)
              , QuestionType      VARCHAR(50) NOT NULL CHECK (LEN(LTRIM(RTRIM(QuestionType))) > 0)
              , MaxScore          DECIMAL(5, 2) NOT NULL
      , Skills            NVARCHAR(MAX)
            );
            INSERT INTO @Questions
            (
                QuestionID_InJSON
              , QuestionType
              , MaxScore
      , Skills
            )
            SELECT JSON_VALUE(q.Value, '$.id')
                 , JSON_VALUE(q.Value, '$.type')
                 , COALESCE(TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE(q.Value, '$.points')), 1.00)
         , JSON_QUERY(q.Value, '$.skills')
            FROM
                   OPENJSON(@AssignmentConfig, '$.groups')           AS groups
                   CROSS APPLY OPENJSON(groups.Value, '$.questions') AS q
            UNION ALL
            -- Giữ tương thích với assignment JSON cũ có questions ở root.
            SELECT JSON_VALUE(q.Value, '$.id')
                 , JSON_VALUE(q.Value, '$.type')
                 , COALESCE(TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE(q.Value, '$.points')), 1.00)
         , JSON_QUERY(q.Value, '$.skills')
            FROM OPENJSON(@AssignmentConfig, '$.questions') AS q;
            -- Chèn dữ liệu mới vào bảng Analytics
            INSERT INTO dbo.tblEL_Analytics_QuestionResults
            (
                SubmissionID
              , AssignmentID
              , AssignToStudentID
              , HocSinhID
              , LopID
              , NienKhoa
              , MonHocLopID
              , MonHocID
              , QuestionID_InJSON
              , QuestionType
              , Score
              , MaxScore
              , IsCorrect
              , SubmissionTime
              , Skills
            )
            SELECT @SubmissionID_Out
                 , @AssignmentID
                 , @AssignToStudentID
                 , @HocSinhID
                 , @LopID
                 , @NienKhoa
                 , @MonHocLopID
                 , @MonHocID
                     , q_info.QuestionID_InJSON
                     , q_info.QuestionType
                 -- manualScore là điểm giáo viên chốt; autoScore chỉ là fallback khi
                 -- câu chưa có điểm thủ công. Không cộng hai field vì flow auto-grade
                 -- hiện lưu cùng một điểm vào cả hai field.
                 , COALESCE(
                       TRY_CAST(JSON_VALUE(answers.Value, '$.grading.manualScore') AS DECIMAL(5, 2)),
                       TRY_CAST(JSON_VALUE(answers.Value, '$.grading.autoScore') AS DECIMAL(5, 2)),
                       0
                   ) AS QuestionScore
                 , q_info.MaxScore
                 -- =================================================================
                 -- == LOGIC TÍNH IsCorrect ĐÃ ĐƯỢC VIẾT LẠI HOÀN TOÀN            ==
                 -- =================================================================
                 , CASE
                        -- Trường hợp 1: Có trường isCorrect và nó là 'true'
                        WHEN JSON_VALUE(answers.Value, '$.grading.isCorrect') = 'true' THEN 1

                        -- Trường hợp 2: Điểm đạt được bằng điểm tối đa (và > 0)
                        WHEN q_info.MaxScore > 0
                         AND COALESCE(
                               TRY_CAST(JSON_VALUE(answers.Value, '$.grading.manualScore') AS DECIMAL(5, 2)),
                               TRY_CAST(JSON_VALUE(answers.Value, '$.grading.autoScore') AS DECIMAL(5, 2)),
                               0
                             ) = q_info.MaxScore THEN 1

                        -- Trường hợp 3: Có trường isCorrect và nó là 'false'
                        WHEN JSON_VALUE(answers.Value, '$.grading.isCorrect') = 'false' THEN 0

                        -- Trường hợp 4: Điểm số là 0
                        WHEN COALESCE(
                               TRY_CAST(JSON_VALUE(answers.Value, '$.grading.manualScore') AS DECIMAL(5, 2)),
                               TRY_CAST(JSON_VALUE(answers.Value, '$.grading.autoScore') AS DECIMAL(5, 2)),
                               0
                             ) = 0 THEN 0

                        -- Các trường hợp còn lại (ví dụ: đúng một phần)
                        ELSE NULL
                   END                                                                                                                                                                       AS IsCorrect
                 , @SubmissionTime
                 , q_info.Skills
                -- Lấy danh sách câu từ snapshot làm nguồn chuẩn để mỗi câu luôn có một dòng
                -- analytics; đáp án cũ có question-id ngoài snapshot sẽ không tạo dòng rác.
                FROM
                       @Questions AS q_info
                       LEFT JOIN OPENJSON(@SubmissionContent, '$.answers') AS answers
                         ON answers.[Key] COLLATE DATABASE_DEFAULT = q_info.QuestionID_InJSON COLLATE DATABASE_DEFAULT;
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;
    -- Lấy lại dữ liệu để load lại UI 
    EXEC spAPI_EL_Student_GetAssignmentDetail_AssignToStudent @AssignToStudentID = @AssignToStudentID
                                                            , @LanNop = @EffectiveLanNop
                                                            , @HocSinhID = @HocSinhID
                                                            , @sys_UserID = @HocSinhID;

    --Gắn thêm thông báo
       IF (@SubmissionStatus >= 2)
    BEGIN
        EXEC [dbo].[spAPI_ThongBao_Ins] @ResourceID = @SubmissionID_Out
                                      , @ResourceType = 'SUBMISSION'
                                      , @ThongBao_TemplateID = 7
                                      , @NguoiNhan = @HocSinhID
                                      , @SYS_USERID = @HocSinhID;
    END;
END;
