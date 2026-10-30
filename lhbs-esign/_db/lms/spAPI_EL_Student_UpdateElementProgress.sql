-- POST lms/EL_Student_UpdateElementProgress
-- Mỗi request ghi một khoảng thời gian nhỏ cho element đang hiển thị.
CREATE PROCEDURE [dbo].[spAPI_EL_Student_UpdateElementProgress]
    @AssignToClassID int,
    @LessonID int,
    @ElementID bigint,
    @TimeSpentSeconds int,
    @ClientEventID uniqueidentifier,
    @sys_UserID varchar(9),
    @HocSinhID int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Ưu tiên HocSinhID truyền lên (từ client khi phụ huynh học cùng con), nếu không có mới fallback về sys_UserID
    IF @HocSinhID IS NULL OR @HocSinhID <= 0
        SET @HocSinhID = TRY_CONVERT(int, RIGHT(@sys_UserID, 8));

    IF @HocSinhID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.tblHocSinh WHERE HocSinhID = @HocSinhID)
    BEGIN
        RAISERROR(N'Không xác định được học sinh từ phiên đăng nhập.', 16, 1);
        RETURN;
    END;

    IF @LessonID <= 0 OR @ElementID <= 0 OR @ClientEventID IS NULL
       OR ISNULL(@TimeSpentSeconds, 0) <= 0
    BEGIN
        RAISERROR(N'Dữ liệu tiến độ element không hợp lệ.', 16, 1);
        RETURN;
    END;
    IF @TimeSpentSeconds > 15 SET @TimeSpentSeconds = 15;

    DECLARE @AssignedLessonID int;
    DECLARE @AssignmentConfig nvarchar(max);
    DECLARE @ExpectedContentLessonID int;

    SELECT @AssignedLessonID = assigned.ResourceID,
           @AssignmentConfig = assigned.AssignmentConfig
    FROM dbo.tblEL_AssignToClass assigned
    INNER JOIN dbo.tblMonHocLop subjectClass ON subjectClass.MonHocLopID = assigned.MonHocLopID
    INNER JOIN dbo.tblHocSinhLop studentClass
        ON studentClass.LopID = subjectClass.LopNhomID
       AND studentClass.HocSinhID = @HocSinhID
       AND ISNULL(studentClass.Enable, 1) = 1
    WHERE assigned.AssignToClassID = @AssignToClassID
      AND assigned.ResourceType = 'LESSON'
      AND assigned.IsDeleted = 0;

    IF @AssignedLessonID IS NULL OR @AssignedLessonID <> @LessonID
    BEGIN
        RAISERROR(N'Học sinh chưa được giao bài học này.', 16, 1);
        RETURN;
    END;

    SET @ExpectedContentLessonID = COALESCE(
        TRY_CONVERT(int, JSON_VALUE(
            CASE WHEN ISJSON(@AssignmentConfig) = 1 THEN @AssignmentConfig ELSE N'{}' END,
            '$.lessonOverrideId'
        )),
        @LessonID
    );
    IF NOT EXISTS (
        SELECT 1 FROM dbo.tblEL_Lessons
        WHERE LessonID = @ExpectedContentLessonID
          AND IsDeleted = 0
          AND IsCopy = 1
          AND CopyFromLessonID = @LessonID
    )
        SET @ExpectedContentLessonID = @LessonID;

    DECLARE @ContentLessonID int;
    DECLARE @MappedLessonID int;
    DECLARE @CompletionPolicy varchar(30);
    DECLARE @IsRequired bit;
    DECLARE @RequiredDurationSeconds int;
    DECLARE @RequireSequential bit;
    DECLARE @ElementSortOrder int;

    SELECT
        @ContentLessonID = element.LessonID,
        @MappedLessonID = CASE WHEN contentLesson.IsCopy = 1
                               THEN contentLesson.CopyFromLessonID
                               ELSE contentLesson.LessonID END,
        @CompletionPolicy = contentLesson.CompletionPolicy,
        @IsRequired = element.IsRequired,
        @RequiredDurationSeconds = element.RequiredDurationSeconds,
        @RequireSequential = contentLesson.RequireSequential,
        @ElementSortOrder = element.SortOrder
    FROM dbo.tblEL_Elements element
    INNER JOIN dbo.tblEL_Lessons contentLesson ON contentLesson.LessonID = element.LessonID
    WHERE element.ElementID = @ElementID
      AND element.IsDeleted = 0
      AND contentLesson.IsDeleted = 0;

    IF @ContentLessonID IS NULL
       OR @MappedLessonID <> @LessonID
       OR @ContentLessonID <> @ExpectedContentLessonID
    BEGIN
        RAISERROR(N'Element không thuộc bài học được ghi nhận tiến độ.', 16, 1);
        RETURN;
    END;

    IF ISNULL(@CompletionPolicy, 'LEGACY_DURATION') <> 'ALL_REQUIRED'
    BEGIN
        RAISERROR(N'Bài học này đang dùng chế độ thời gian tổng.', 16, 1);
        RETURN;
    END;

    IF @IsRequired = 1 AND ISNULL(@RequiredDurationSeconds, 0) <= 0
    BEGIN
        RAISERROR(N'Element bắt buộc chưa được cấu hình thời gian hoàn thành.', 16, 1);
        RETURN;
    END;

    IF ISNULL(@RequireSequential, 0) = 1 AND EXISTS (
        SELECT 1
        FROM dbo.tblEL_Elements previousElement
        WHERE previousElement.LessonID = @ContentLessonID
          AND previousElement.IsDeleted = 0
          AND previousElement.IsRequired = 1
          AND (previousElement.SortOrder < @ElementSortOrder
               OR (previousElement.SortOrder = @ElementSortOrder AND previousElement.ElementID < @ElementID))
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.tblEL_Element_Progress previousProgress
              WHERE previousProgress.ElementID = previousElement.ElementID
                AND previousProgress.HocSinhID = @HocSinhID
                AND previousProgress.Status = 'COMPLETED'
          )
    )
    BEGIN
        RAISERROR(N'Hãy hoàn thành các khối bắt buộc phía trước theo thứ tự.', 16, 1);
        RETURN;
    END;

    DECLARE @Now datetime = GETDATE();
    DECLARE @ExistingSeconds int = 0;
    DECLARE @LastAccessed datetime;
    DECLARE @LastEventID uniqueidentifier;
    DECLARE @LastEventSeconds int = 0;
    DECLARE @AcceptedSeconds int = @TimeSpentSeconds;
    DECLARE @ElementStatus varchar(20);
    DECLARE @ElementSeconds int;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            @ExistingSeconds = progress.TimeSpentSeconds,
            @LastAccessed = progress.LastAccessed,
            @LastEventID = progress.LastEventID,
            @LastEventSeconds = progress.LastEventSeconds
        FROM dbo.tblEL_Element_Progress progress WITH (UPDLOCK, HOLDLOCK)
        WHERE progress.HocSinhID = @HocSinhID
          AND progress.ElementID = @ElementID;

        IF @LastEventID = @ClientEventID
        BEGIN
            SET @AcceptedSeconds = @LastEventSeconds;
        END
        ELSE
        BEGIN
            -- Giới hạn time báo lên theo thời gian server giữa hai heartbeat để giảm gửi nhanh/cộng khống.
            IF @LastAccessed IS NOT NULL
            BEGIN
                DECLARE @ServerElapsedSeconds int = DATEDIFF(SECOND, @LastAccessed, @Now) + 2;
                IF @ServerElapsedSeconds < 1 SET @ServerElapsedSeconds = 1;
                IF @AcceptedSeconds > @ServerElapsedSeconds SET @AcceptedSeconds = @ServerElapsedSeconds;
            END;

            SET @ElementSeconds = @ExistingSeconds + @AcceptedSeconds;
            SET @ElementStatus = CASE
                WHEN @IsRequired = 1 AND @ElementSeconds >= @RequiredDurationSeconds THEN 'COMPLETED'
                ELSE 'IN_PROGRESS'
            END;

            IF EXISTS (
                SELECT 1 FROM dbo.tblEL_Element_Progress
                WHERE HocSinhID = @HocSinhID AND ElementID = @ElementID
            )
            BEGIN
                UPDATE dbo.tblEL_Element_Progress
                SET Status = CASE WHEN Status = 'COMPLETED' THEN Status ELSE @ElementStatus END,
                    StartedTime = ISNULL(StartedTime, @Now),
                    CompletedTime = CASE
                        WHEN (Status = 'COMPLETED' OR @ElementStatus = 'COMPLETED')
                            THEN ISNULL(CompletedTime, @Now)
                        ELSE CompletedTime
                    END,
                    LastAccessed = @Now,
                    TimeSpentSeconds = @ElementSeconds,
                    ProgressPercent = CASE WHEN @IsRequired = 1
                        THEN CONVERT(decimal(5,2), CASE WHEN @ElementSeconds >= @RequiredDurationSeconds THEN 100
                            ELSE (@ElementSeconds * 100.0) / @RequiredDurationSeconds END)
                        ELSE NULL END,
                    CompletionSource = CASE WHEN @ElementStatus = 'COMPLETED' THEN 'ELEMENT_TIME' ELSE CompletionSource END,
                    LastEventID = @ClientEventID,
                    LastEventSeconds = @AcceptedSeconds,
                    UpdateUser = @sys_UserID,
                    UpdateTime = @Now
                WHERE HocSinhID = @HocSinhID AND ElementID = @ElementID;
            END
            ELSE
            BEGIN
                INSERT INTO dbo.tblEL_Element_Progress (
                    HocSinhID, ElementID, Status, StartedTime, CompletedTime, LastAccessed,
                    TimeSpentSeconds, ProgressPercent, CompletionSource, LastEventID, LastEventSeconds, CreateUser
                )
                VALUES (
                    @HocSinhID, @ElementID, @ElementStatus, @Now,
                    CASE WHEN @ElementStatus = 'COMPLETED' THEN @Now ELSE NULL END,
                    @Now, @ElementSeconds,
                    CASE WHEN @IsRequired = 1
                        THEN CONVERT(decimal(5,2), CASE WHEN @ElementSeconds >= @RequiredDurationSeconds THEN 100
                            ELSE (@ElementSeconds * 100.0) / @RequiredDurationSeconds END)
                        ELSE NULL END,
                    CASE WHEN @ElementStatus = 'COMPLETED' THEN 'ELEMENT_TIME' ELSE NULL END,
                    @ClientEventID, @AcceptedSeconds, @sys_UserID
                );
            END;
        END;

        DECLARE @RequiredCount int;
        DECLARE @CompletedRequiredCount int;
        DECLARE @LessonIsCompleted bit;
        DECLARE @LessonTimeSpentSeconds int;

        SELECT @RequiredCount = COUNT(*)
        FROM dbo.tblEL_Elements
        WHERE LessonID = @ContentLessonID AND IsDeleted = 0 AND IsRequired = 1;

        SELECT @CompletedRequiredCount = COUNT(*)
        FROM dbo.tblEL_Elements element
        INNER JOIN dbo.tblEL_Element_Progress progress
            ON progress.ElementID = element.ElementID
           AND progress.HocSinhID = @HocSinhID
           AND progress.Status = 'COMPLETED'
        WHERE element.LessonID = @ContentLessonID
          AND element.IsDeleted = 0
          AND element.IsRequired = 1
          AND ISNULL(element.RequiredDurationSeconds, 0) > 0;

        SET @LessonIsCompleted = CASE WHEN @RequiredCount > 0 AND @CompletedRequiredCount = @RequiredCount THEN 1 ELSE 0 END;

        DECLARE @ElementProgressTotalSeconds int;
        SELECT @ElementProgressTotalSeconds = ISNULL(SUM(progress.TimeSpentSeconds), 0)
        FROM dbo.tblEL_Elements element
        INNER JOIN dbo.tblEL_Element_Progress progress
            ON progress.ElementID = element.ElementID AND progress.HocSinhID = @HocSinhID
        INNER JOIN dbo.tblEL_Lessons contentLesson ON contentLesson.LessonID = element.LessonID
        WHERE element.IsDeleted = 0
          AND CASE WHEN contentLesson.IsCopy = 1 THEN contentLesson.CopyFromLessonID ELSE contentLesson.LessonID END = @LessonID;

        DECLARE @LearningProgressID bigint;
        DECLARE @WasCompleted bit = 0;
        DECLARE @PreviousLessonTimeSpentSeconds int = 0;

        SELECT @LearningProgressID = ProgressID,
               @WasCompleted = IsCompleted,
               @PreviousLessonTimeSpentSeconds = ISNULL(TimeSpentSeconds, 0)
        FROM dbo.tblEL_Learning_Progress WITH (UPDLOCK, HOLDLOCK)
        WHERE HocSinhID = @HocSinhID AND LessonID = @LessonID AND ISNULL(IsDeleted, 0) = 0;

        -- Keep historical lesson-level time when a lesson is upgraded from total-time tracking.
        SET @LessonTimeSpentSeconds = CASE
            WHEN @PreviousLessonTimeSpentSeconds > @ElementProgressTotalSeconds THEN @PreviousLessonTimeSpentSeconds
            ELSE @ElementProgressTotalSeconds
        END;

        IF @LearningProgressID IS NULL
        BEGIN
            INSERT INTO dbo.tblEL_Learning_Progress (
                HocSinhID, LessonID, TimeSpentSeconds, IsCompleted, CompletedDate,
                CompletedByUserID, CompletionSource, LastAccessed
            )
            VALUES (
                @HocSinhID, @LessonID, @LessonTimeSpentSeconds, @LessonIsCompleted,
                CASE WHEN @LessonIsCompleted = 1 THEN @Now ELSE NULL END,
                CASE WHEN @LessonIsCompleted = 1 THEN @sys_UserID ELSE NULL END,
                CASE WHEN @LessonIsCompleted = 1 THEN 'ELEMENT_TIME' ELSE NULL END,
                @Now
            );
            SET @LearningProgressID = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.tblEL_Learning_Progress
            SET TimeSpentSeconds = @LessonTimeSpentSeconds,
                IsCompleted = CASE WHEN IsCompleted = 1 OR @LessonIsCompleted = 1 THEN 1 ELSE 0 END,
                CompletedDate = CASE WHEN IsCompleted = 1 OR @LessonIsCompleted = 1
                    THEN ISNULL(CompletedDate, @Now) ELSE NULL END,
                CompletedByUserID = CASE WHEN IsCompleted = 1 OR @LessonIsCompleted = 1
                    THEN ISNULL(CompletedByUserID, @sys_UserID) ELSE NULL END,
                CompletionSource = CASE WHEN IsCompleted = 1 OR @LessonIsCompleted = 1
                    THEN ISNULL(CompletionSource, 'ELEMENT_TIME') ELSE NULL END,
                LastAccessed = @Now
            WHERE ProgressID = @LearningProgressID;
        END;

        IF @LessonIsCompleted = 1 AND @WasCompleted = 0
           AND NOT EXISTS (SELECT 1 FROM dbo.tblEL_ThongBao WHERE ResourceID = @LearningProgressID)
        BEGIN
            INSERT INTO dbo.tblEL_ThongBao (
                ResourceType, ResourceID, ThongBao_TemplateID, NguoiNhan,
                ThoiGianNhan, NguoiGiao, ThoiGianGiao
            )
            VALUES ('LP', @LearningProgressID, 13, @HocSinhID, @Now, @HocSinhID, @Now);
        END;

        COMMIT TRANSACTION;

        SELECT progress.ElementID, progress.Status, progress.TimeSpentSeconds,
               progress.ProgressPercent, progress.CompletedTime,
               @AcceptedSeconds AS AcceptedSeconds,
               @LessonIsCompleted AS LessonIsCompleted,
               @LessonTimeSpentSeconds AS LessonTimeSpentSeconds
        FROM dbo.tblEL_Element_Progress progress
        WHERE progress.HocSinhID = @HocSinhID AND progress.ElementID = @ElementID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
