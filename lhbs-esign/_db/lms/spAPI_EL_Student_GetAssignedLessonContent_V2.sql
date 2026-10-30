-- POST lms/EL_Student_GetAssignedLessonContent_V2
-- V2 giữ cấu trúc ba result set; metadata và progress element nằm cùng result set thứ hai.
CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetAssignedLessonContent_V2]
    @AssignToClassID int,
    @HocSinhID int,
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Ưu tiên HocSinhID truyền lên (từ URL phụ huynh/học sinh/giáo viên), nếu không có mới fallback về sys_UserID
    IF @HocSinhID IS NULL OR @HocSinhID <= 0
    BEGIN
        SET @HocSinhID = TRY_CONVERT(int, RIGHT(@sys_UserID, 8));
    END;

    IF @HocSinhID IS NULL OR @HocSinhID <= 0
    BEGIN
        RAISERROR(N'Không xác định được học sinh được yêu cầu.', 16, 1);
        RETURN;
    END;

    DECLARE @LessonID int;
    DECLARE @LessonContentID int;
    DECLARE @AssignmentConfig nvarchar(max);

    SELECT
        @LessonID = assigned.ResourceID,
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

    IF @LessonID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin giao bài giảng.', 16, 1);
        RETURN;
    END;

    SET @LessonContentID = COALESCE(
        TRY_CONVERT(int, JSON_VALUE(
            CASE WHEN ISJSON(@AssignmentConfig) = 1 THEN @AssignmentConfig ELSE N'{}' END,
            '$.lessonOverrideId'
        )),
        @LessonID
    );

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.tblEL_Lessons
        WHERE LessonID = @LessonContentID
          AND IsDeleted = 0
          AND IsCopy = 1
          AND CopyFromLessonID = @LessonID
    )
        SET @LessonContentID = @LessonID;

    -- Result set 1: content lesson plus original lesson ID for the progress summary.
    SELECT lesson.*, @LessonID AS ProgressLessonID
    FROM dbo.tblEL_Lessons lesson
    WHERE lesson.LessonID = @LessonContentID AND lesson.IsDeleted = 0;

    -- Result set 2: each element carries its configuration and saved progress.
    SELECT
        element.ElementID,
        element.LessonID,
        element.ElementType,
        element.ElementData,
        element.SortOrder,
        element.IsRequired,
        element.CompletionMode,
        element.ExpectedDurationSeconds,
        element.RequiredDurationSeconds,
        ISNULL(progress.Status, 'NOT_STARTED') AS ElementProgressStatus,
        ISNULL(progress.TimeSpentSeconds, 0) AS ElementTimeSpentSeconds,
        progress.ProgressPercent AS ElementProgressPercent,
        progress.CompletedTime AS ElementCompletedTime
    FROM dbo.tblEL_Elements element
    LEFT JOIN dbo.tblEL_Element_Progress progress
        ON progress.ElementID = element.ElementID
       AND progress.HocSinhID = @HocSinhID
    WHERE element.LessonID = @LessonContentID AND element.IsDeleted = 0
    ORDER BY element.SortOrder ASC;

    -- Result set 3: lesson-level summary remains keyed to the original assigned lesson.
    SELECT IsCompleted, TimeSpentSeconds, LastAccessed
    FROM dbo.tblEL_Learning_Progress
    WHERE HocSinhID = @HocSinhID
      AND LessonID = @LessonID
      AND ISNULL(IsDeleted, 0) = 0;
END;
