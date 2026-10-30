-- POST lms/EL_Lesson_Save_V2
-- V2 bổ sung completion policy; SP cũ được giữ nguyên cho các client hiện hữu.
CREATE PROCEDURE [dbo].[spAPI_EL_Lesson_Save_V2]
    @LessonID int,
    @TuanHocID int,
    @Chuong nvarchar(2000),
    @Title nvarchar(255),
    @Description nvarchar(max),
    @KhoiID int,
    @MonHocID int,
    @NienKhoa int,
    @HocKi int,
    @EstimatedDuration int,
    @ThumbnailURL nvarchar(1000),
    @Status int,
    @IsPublic bit,
    @CompletionPolicy varchar(30),
    @RequireSequential bit,
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    IF LTRIM(RTRIM(ISNULL(@Title, N''))) = N''
    BEGIN
        RAISERROR(N'Tiêu đề bài giảng không được để trống.', 16, 1);
        RETURN;
    END;

    IF ISNULL(@CompletionPolicy, '') NOT IN ('LEGACY_DURATION', 'ALL_REQUIRED')
    BEGIN
        RAISERROR(N'Chế độ hoàn thành bài học không hợp lệ.', 16, 1);
        RETURN;
    END;

    IF @LessonID > 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.tblEL_Lessons
            WHERE LessonID = @LessonID AND CreateUser = @sys_UserID AND IsDeleted = 0
        )
        BEGIN
            RAISERROR(N'Bạn không có quyền chỉnh sửa bài giảng này.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.tblEL_Lessons
        SET Title = @Title,
            TuanHocID = @TuanHocID,
            Chuong = @Chuong,
            KhoiID = @KhoiID,
            MonHocID = @MonHocID,
            Description = @Description,
            NienKhoa = @NienKhoa,
            HocKi = @HocKi,
            EstimatedDuration = @EstimatedDuration,
            ThumbnailURL = @ThumbnailURL,
            Status = @Status,
            IsPublic = @IsPublic,
            CompletionPolicy = @CompletionPolicy,
            RequireSequential = @RequireSequential,
            CompletionVersion = 2,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE LessonID = @LessonID;

        SELECT LessonID FROM dbo.tblEL_Lessons WHERE LessonID = @LessonID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tblEL_Lessons (
            Title, Description, KhoiID, MonHocID, NienKhoa, HocKi, EstimatedDuration,
            ThumbnailURL, Status, CreateUser, TuanHocID, Chuong, IsPublic,
            CompletionPolicy, RequireSequential, CompletionVersion
        )
        VALUES (
            @Title, @Description, @KhoiID, @MonHocID, @NienKhoa, @HocKi, @EstimatedDuration,
            @ThumbnailURL, @Status, @sys_UserID, @TuanHocID, @Chuong, @IsPublic,
            @CompletionPolicy, @RequireSequential, 2
        );

        SELECT CONVERT(int, SCOPE_IDENTITY()) AS LessonID;
    END;
END;
