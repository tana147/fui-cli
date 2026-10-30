
-- =================================================================================
-- Description:    Cập nhật tiến độ học của học sinh.
--                 API PUBLIC, cần truyền HocSinhID.
-- API Endpoint:   POST lms/auth/el_student_updateprogress
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Student_UpdateProgress]
    --@HocSinhID INT,
    @LessonID         INT
  , @TimeSpentSeconds INT
  , @IsCompleted      BIT
  , @HocSinhID        INT
  , @SYS_USERID       VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Legacy clients may still post total time; they cannot complete a lesson configured for element tracking.
    IF EXISTS (
        SELECT 1 FROM dbo.tblEL_Lessons
        WHERE LessonID = @LessonID AND IsDeleted = 0 AND CompletionPolicy = 'ALL_REQUIRED'
    )
    BEGIN
        RAISERROR(N'Bài học này theo dõi thời gian từng element; vui lòng mở bằng viewer hỗ trợ V2.', 16, 1);
        RETURN;
    END;

    -- EstimatedDuration được lưu theo phút; backend là nơi quyết định trạng thái hoàn thành.
    DECLARE @CompletionDurationSeconds INT;
    SELECT @CompletionDurationSeconds = CASE
        WHEN ISNULL(EstimatedDuration, 0) >= 1 THEN EstimatedDuration * 60
        ELSE 3 * 60
    END
    FROM dbo.tblEL_Lessons
    WHERE LessonID = @LessonID
      AND IsDeleted = 0;

    IF ISNULL(@CompletionDurationSeconds, 0) <= 0
        SET @CompletionDurationSeconds = 3 * 60;

    MERGE dbo.tblEL_Learning_Progress AS target
    USING
    (
        SELECT @LessonID  AS LessonID
             , @HocSinhID AS HocSinhID
    ) AS source
    ON (
           target.LessonID = source.LessonID
     AND   target.HocSinhID = source.HocSinhID
       )
    WHEN MATCHED THEN UPDATE SET TimeSpentSeconds = ISNULL(target.TimeSpentSeconds, 0) + ISNULL(@TimeSpentSeconds, 0)
                               , IsCompleted = CASE
                                                   WHEN target.IsCompleted = 1
                                                     OR ISNULL(target.TimeSpentSeconds, 0) + ISNULL(@TimeSpentSeconds, 0) >= @CompletionDurationSeconds
                                                       THEN 1
                                                   ELSE 0
                                                 END
                               , CompletedDate = CASE
                                                      WHEN (target.IsCompleted = 1
                                                        OR ISNULL(target.TimeSpentSeconds, 0) + ISNULL(@TimeSpentSeconds, 0) >= @CompletionDurationSeconds)
                                                       AND target.CompletedDate IS NULL THEN GETDATE()
                                                      ELSE target.CompletedDate
                                                 END
                               , CompletedByUserID = CASE
                                                         WHEN ISNULL(target.IsCompleted, 0) = 0
                                                          AND ISNULL(target.TimeSpentSeconds, 0) + ISNULL(@TimeSpentSeconds, 0) >= @CompletionDurationSeconds
                                                             THEN @SYS_USERID
                                                         ELSE target.CompletedByUserID
                                                     END
                               , CompletionSource = CASE
                                                       WHEN ISNULL(target.IsCompleted, 0) = 0
                                                        AND ISNULL(target.TimeSpentSeconds, 0) + ISNULL(@TimeSpentSeconds, 0) >= @CompletionDurationSeconds
                                                           THEN 'AUTO_TIME'
                                                       ELSE target.CompletionSource
                                                   END
                               , LastAccessed = GETDATE()
    WHEN NOT MATCHED THEN INSERT
                          (
                              HocSinhID
                            , LessonID
                            , TimeSpentSeconds
                            , IsCompleted
                            , CompletedDate
                            , CompletedByUserID
                            , CompletionSource
                            , LastAccessed
                          )
                          VALUES
                          (
                              @HocSinhID
                            , @LessonID
                            , ISNULL(@TimeSpentSeconds, 0)
                            , CASE WHEN ISNULL(@TimeSpentSeconds, 0) >= @CompletionDurationSeconds THEN 1 ELSE 0 END
                            , CASE WHEN ISNULL(@TimeSpentSeconds, 0) >= @CompletionDurationSeconds THEN GETDATE() ELSE NULL END
                            , CASE WHEN ISNULL(@TimeSpentSeconds, 0) >= @CompletionDurationSeconds THEN @SYS_USERID ELSE NULL END
                            , CASE WHEN ISNULL(@TimeSpentSeconds, 0) >= @CompletionDurationSeconds THEN 'AUTO_TIME' ELSE NULL END
                            , GETDATE()
                          );


    DECLARE @ProgressID INT = 0;

    SELECT @ProgressID = ProgressID
    FROM
           dbo.tblEL_Learning_Progress
    WHERE
           LessonID   = @LessonID
      AND  HocSinhID   = @HocSinhID
      AND  IsDeleted   = 0
      AND  IsCompleted = 1;

    IF @ProgressID > 0
    BEGIN
        IF NOT EXISTS
        (
            SELECT *
            FROM
                   dbo.tblEL_ThongBao
            WHERE
                   ResourceID = @ProgressID
        )
        BEGIN
            INSERT INTO dbo.tblEL_ThongBao
            (
                ResourceType
              , ResourceID
              , ThongBao_TemplateID
              , NguoiNhan
              , ThoiGianNhan
              , NguoiGiao
              , ThoiGianGiao
            )
            VALUES
            (
                'LP'
              , @ProgressID
              , 13
              , @HocSinhID
              , GETDATE()
              , @HocSinhID
              , GETDATE()
            );
        END;
    END;
END;
