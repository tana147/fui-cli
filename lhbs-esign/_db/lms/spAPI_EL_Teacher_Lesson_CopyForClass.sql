CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_Lesson_CopyForClass]
    @AssignToClassID BIGINT,
    @sys_UserID VARCHAR(9),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT @sys_UserID = SYS_USERID,
           @sys_SystemRight = SYS_SystemRight
    FROM dbo.Table_GetUser_LMS(@sys_UserID, @sys_SystemRight);

    IF NULLIF(LTRIM(RTRIM(@sys_UserID)), '') IS NULL
    BEGIN
        RAISERROR(N'[Unauthorized] Không xác định được giáo viên đang đăng nhập.', 16, 1);
        RETURN;
    END;

    DECLARE @LessonID INT;
    DECLARE @LessonOverrideID INT;
    DECLARE @AssignToClassOwner VARCHAR(9);
    DECLARE @AssignmentConfig NVARCHAR(MAX);
    DECLARE @LessonOwner VARCHAR(9);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Lock the class assignment so concurrent clicks cannot create two lesson copies for one class.
        SELECT @LessonID = atc.ResourceID,
               @AssignToClassOwner = atc.CreateUser,
               @AssignmentConfig = atc.AssignmentConfig
        FROM dbo.tblEL_AssignToClass atc WITH (UPDLOCK, HOLDLOCK)
        WHERE atc.AssignToClassID = @AssignToClassID
          AND atc.ResourceType = 'LESSON'
          AND atc.IsDeleted = 0;

        IF @LessonID IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy lớp được giao bài học.', 16, 1);
        END;

        SELECT @LessonOwner = lesson.CreateUser
        FROM dbo.tblEL_Lessons lesson WITH (UPDLOCK, HOLDLOCK)
        WHERE lesson.LessonID = @LessonID
          AND lesson.IsDeleted = 0;

        IF @LessonOwner IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy bài học gốc.', 16, 1);
        END;

        -- Chỉ người giao bài, quản trị viên hoặc giáo viên có quyền sửa assignment/môn học được tạo bản riêng.
        IF @AssignToClassOwner <> @sys_UserID
           AND @LessonOwner <> @sys_UserID
           AND ISNULL(@sys_SystemRight, -1) NOT IN (3, 5, 9)
           AND NOT EXISTS (
                   SELECT 1
                   FROM dbo.tblEL_Resoucre_TeacherPermissions permission
                   WHERE permission.AssignToClassID = @AssignToClassID
                     AND permission.GiaoVienID = @sys_UserID
                     AND permission.Enable = 1
                     AND permission.IsEdit = 1
               )
           AND NOT EXISTS (
                   SELECT 1
                   FROM dbo.tblEL_Resoucre_TeacherPermissions permission
                   WHERE permission.GiaoVienID = @sys_UserID
                     AND permission.Enable = 1
                     AND permission.PermissionScope = 'SUBJECT'
                     AND permission.IsEdit = 1
                     AND permission.MonHocID = (
                             SELECT source.MonHocID
                             FROM dbo.tblEL_Lessons source
                             WHERE source.LessonID = @LessonID
                         )
                     AND (permission.NienKhoa IS NULL OR permission.NienKhoa = (
                             SELECT source.NienKhoa
                             FROM dbo.tblEL_Lessons source
                             WHERE source.LessonID = @LessonID
                         ))
               )
        BEGIN
            RAISERROR(N'[Unauthorized] Bạn không có quyền sửa nội dung bài học của lớp này.', 16, 1);
        END;

        SET @AssignmentConfig = COALESCE(NULLIF(LTRIM(RTRIM(@AssignmentConfig)), N''), N'{}');
        IF ISJSON(@AssignmentConfig) <> 1 OR LEFT(LTRIM(@AssignmentConfig), 1) <> N'{'
        BEGIN
            RAISERROR(N'Không thể lưu bản bài học riêng vì cấu hình của lần giao bài không phải JSON object hợp lệ.', 16, 1);
        END;

        SET @LessonOverrideID = TRY_CONVERT(INT, JSON_VALUE(@AssignmentConfig, '$.lessonOverrideId'));

        IF @LessonOverrideID > 0
           AND EXISTS (
                   SELECT 1
                   FROM dbo.tblEL_Lessons
                   WHERE LessonID = @LessonOverrideID
                     AND IsDeleted = 0
                     AND IsCopy = 1
                     AND CopyFromLessonID = @LessonID
               )
        BEGIN
            COMMIT TRANSACTION;
            SELECT @LessonOverrideID AS LessonID;
            RETURN;
        END;

        INSERT INTO dbo.tblEL_Lessons
        (
            Title, Description, NienKhoa, HocKi, EstimatedDuration, ThumbnailURL,
            Status, IsDev, IsDeleted, CreateTime, CreateUser, UpdateTime, UpdateUser,
            Tuan, TuanHocID, Chuong, KhoiID, MonHocID, IsPublic, IsCopy,
            CopyFromLessonID, CopyFromUserID, CopyTime
        )
        SELECT source.Title, source.Description, source.NienKhoa, source.HocKi,
               source.EstimatedDuration, source.ThumbnailURL, source.Status, source.IsDev,
               0, GETDATE(), @sys_UserID, NULL, NULL, source.Tuan, source.TuanHocID,
               source.Chuong, source.KhoiID, source.MonHocID, 0, 1,
               source.LessonID, source.CreateUser, GETDATE()
        FROM dbo.tblEL_Lessons source
        WHERE source.LessonID = @LessonID
          AND source.IsDeleted = 0;

        SET @LessonOverrideID = CONVERT(INT, SCOPE_IDENTITY());
        IF @LessonOverrideID IS NULL
        BEGIN
            RAISERROR(N'Không thể tạo bản bài học riêng cho lớp.', 16, 1);
        END;

        INSERT INTO dbo.tblEL_Elements
        (
            LessonID, ElementType, ElementData, SortOrder, IsDeleted,
            CreateTime, CreateUser, UpdateTime, UpdateUser
        )
        SELECT @LessonOverrideID, element.ElementType, element.ElementData,
               element.SortOrder, element.IsDeleted, GETDATE(), @sys_UserID, NULL, NULL
        FROM dbo.tblEL_Elements element
        WHERE element.LessonID = @LessonID;

        UPDATE dbo.tblEL_AssignToClass
        SET AssignmentConfig = JSON_MODIFY(@AssignmentConfig, '$.lessonOverrideId', @LessonOverrideID),
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE AssignToClassID = @AssignToClassID;

        COMMIT TRANSACTION;
        SELECT @LessonOverrideID AS LessonID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(N'%s', 16, 1, @ErrorMessage);
        RETURN;
    END CATCH;
END;
