-- FILE: spAPI_EL_Student_GetAssignedLessonContent.sql
-- =================================================================================
-- Description:    Lấy nội dung chi tiết của một bài giảng ĐÃ ĐƯỢC GIAO.
--                 API này kiểm tra quyền truy cập của học sinh, đảm bảo
--                 học sinh thuộc lớp được giao bài.
-- API Endpoint:   POST lms/el_student_getassignedlessoncontent
-- Ví dụ Body:     { "AssignToClassID": 456 }
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetAssignedLessonContent] -- 97,'25100119'
    @AssignToClassID int,
	@HocSinhID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LessonID INT;
    DECLARE @LessonContentID INT;
    DECLARE @AssignmentConfig NVARCHAR(MAX);
    DECLARE @LopID_HocSinh VARCHAR(100);
    DECLARE @LopID_GiaoBai VARCHAR(100);
	DECLARE @NienKhoa INT;

    -- === Bước 1: Lấy thông tin Lớp và LessonID từ lần giao bài ===
    SELECT 
        @LessonID		= atc.ResourceID,
        @AssignmentConfig = atc.AssignmentConfig,
        @LopID_GiaoBai	= mhl.LopNhomID,
		@NienKhoa		= atc.NienKhoa
    FROM dbo.tblEL_AssignToClass atc
		JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE atc.AssignToClassID = @AssignToClassID
      AND atc.ResourceType = 'LESSON'
      AND atc.IsDeleted = 0;

    IF @LessonID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin giao bài giảng.', 16, 1);
        RETURN;
    END

    -- AssignmentConfig giữ ID bản sao riêng của lớp; nếu bản sao không còn dùng được thì fallback về bài gốc.
    SET @LessonContentID = COALESCE(
        TRY_CONVERT(INT, JSON_VALUE(
            CASE WHEN ISJSON(@AssignmentConfig) = 1 THEN @AssignmentConfig ELSE N'{}' END,
            '$.lessonOverrideId'
        )),
        @LessonID
    );

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.tblEL_Lessons
        WHERE LessonID = @LessonContentID AND IsDeleted = 0
          AND IsCopy = 1 AND CopyFromLessonID = @LessonID
    )
    BEGIN
        SET @LessonContentID = @LessonID;
    END;
	 
    -- === Bước 3: Nếu có quyền, trả về nội dung bài giảng ===
    -- Bảng 1: Nội dung dùng bản riêng theo lớp, còn ProgressLessonID giữ khóa tiến độ hiện có.
    SELECT lesson.*, @LessonID AS ProgressLessonID
    FROM dbo.tblEL_Lessons lesson
    WHERE lesson.LessonID = @LessonContentID AND lesson.IsDeleted = 0;

    -- Bảng 2: Danh sách các thành phần của bài giảng
    SELECT 
        ElementID, LessonID, ElementType, ElementData, SortOrder
    FROM dbo.tblEL_Elements
    WHERE LessonID = @LessonContentID AND IsDeleted = 0
    ORDER BY SortOrder ASC;
	
	-- BẢNG 3 : Trả về thông tin tiến độ của học sinh với bài này
	 SELECT 
        IsCompleted,
        TimeSpentSeconds,
        LastAccessed
    FROM dbo.tblEL_Learning_Progress
    WHERE HocSinhID = @HocSinhID AND LessonID = @LessonID;

END
