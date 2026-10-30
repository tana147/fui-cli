-- POST lms/EL_Element_Save_V2
-- V2 lưu metadata hoàn thành ở cột riêng, giữ EL_Element_Save cho client cũ.
CREATE PROCEDURE [dbo].[spAPI_EL_Element_Save_V2]
    @ElementID bigint,
    @LessonID int,
    @ElementType varchar(50),
    @ElementData nvarchar(max),
    @SortOrder int,
    @IsRequired bit,
    @CompletionMode varchar(40),
    @ExpectedDurationSeconds int,
    @RequiredDurationSeconds int,
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    IF NOT EXISTS (
        SELECT 1 FROM dbo.tblEL_Lessons
        WHERE LessonID = @LessonID AND CreateUser = @sys_UserID AND IsDeleted = 0
    )
    BEGIN
        RAISERROR(N'Bài giảng không tồn tại hoặc bạn không có quyền chỉnh sửa.', 16, 1);
        RETURN;
    END;

    IF ISJSON(@ElementData) <> 1
    BEGIN
        RAISERROR(N'Dữ liệu ElementData không phải JSON hợp lệ.', 16, 1);
        RETURN;
    END;

    IF @CompletionMode <> 'TIME_REQUIRED'
       OR (@ExpectedDurationSeconds IS NOT NULL AND @ExpectedDurationSeconds < 0)
       OR (@RequiredDurationSeconds IS NOT NULL AND @RequiredDurationSeconds < 1)
    BEGIN
        RAISERROR(N'Cấu hình hoàn thành element không hợp lệ.', 16, 1);
        RETURN;
    END;

    IF @ElementID > 0
    BEGIN
        UPDATE dbo.tblEL_Elements
        SET ElementType = @ElementType,
            ElementData = @ElementData,
            SortOrder = @SortOrder,
            IsRequired = @IsRequired,
            CompletionMode = @CompletionMode,
            ExpectedDurationSeconds = @ExpectedDurationSeconds,
            RequiredDurationSeconds = @RequiredDurationSeconds,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE ElementID = @ElementID AND LessonID = @LessonID AND IsDeleted = 0;

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR(N'Không tìm thấy element trong bài học này.', 16, 1);
            RETURN;
        END;

        SELECT * FROM dbo.tblEL_Elements WHERE ElementID = @ElementID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tblEL_Elements (
            LessonID, ElementType, ElementData, SortOrder, IsRequired,
            CompletionMode, ExpectedDurationSeconds, RequiredDurationSeconds, CreateUser
        )
        VALUES (
            @LessonID, @ElementType, @ElementData, @SortOrder, @IsRequired,
            @CompletionMode, @ExpectedDurationSeconds, @RequiredDurationSeconds, @sys_UserID
        );

        DECLARE @NewElementID bigint = SCOPE_IDENTITY();
        SELECT * FROM dbo.tblEL_Elements WHERE ElementID = @NewElementID;
    END;
END;
