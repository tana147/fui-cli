

-- =================================================================================
-- 3. CẬP NHẬT CÁC STORED PROCEDURES HIỆN TẠI
-- =================================================================================

-- Cập nhật spAPI_EL_Lesson_Save để hỗ trợ lưu liên kết chương trình học
CREATE PROCEDURE [dbo].[spAPI_EL_Lesson_Save]
    @LessonID INT = 0,
    @TuanHocID INT,
    @Chuong NVARCHAR(2000),
    @Title NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @KhoiID INT, 
    @MonHocID INT, 
    @NienKhoa INT,
    @HocKi INT,
    @EstimatedDuration INT = NULL,
    @ThumbnailURL NVARCHAR(1000) = NULL,
    @Status INT,
    @sys_UserID VARCHAR(9),
    @IsPublic BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    IF LTRIM(RTRIM(@Title)) = '' BEGIN RAISERROR(N'Tiêu đề bài giảng không được để trống.', 16, 1); RETURN; END;
   
    IF @LessonID > 0
    BEGIN
        -- --- UPDATE ---
        IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_Lessons WHERE LessonID = @LessonID AND CreateUser = @sys_UserID)
        BEGIN
            RAISERROR(N'Bạn không có quyền chỉnh sửa bài giảng này.', 16, 1);
            RETURN; 
        END;

        UPDATE dbo.tblEL_Lessons
        SET
            Title = @Title,
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
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID,
            IsPublic = @IsPublic
        WHERE LessonID = @LessonID;SELECT LessonID FROM dbo.tblEL_Lessons WHERE LessonID = @LessonID;
    END;
    ELSE
    BEGIN
        -- --- INSERT ---
        DECLARE @NewLessonID INT;

        INSERT INTO dbo.tblEL_Lessons (Title, Description, KhoiID, MonHocID, NienKhoa, HocKi, EstimatedDuration, ThumbnailURL, Status, CreateUser, TuanHocID, Chuong, IsPublic)
        VALUES (@Title, @Description, @KhoiID, @MonHocID, @NienKhoa, @HocKi, @EstimatedDuration, @ThumbnailURL, @Status, @sys_UserID, @TuanHocID, @Chuong, @IsPublic);
        
        SET @NewLessonID = SCOPE_IDENTITY();SELECT LessonID FROM dbo.tblEL_Lessons WHERE LessonID = @NewLessonID;
    END;
END;

