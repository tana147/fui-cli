-- FILE: spAPI_AUTH_EL_Student_GetLessonContent.sql
-- =================================================================================
-- Description:    Lấy nội dung chi tiết bài giảng cho học sinh.
--                 API PUBLIC, không kiểm tra quyền, ai cũng xem được nếu có link.
-- API Endpoint:   GET lms/auth/el_student_getlessoncontent/{LessonID}
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetLessonContent_OLD]
    @LessonID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_Lessons WHERE LessonID = @LessonID AND IsDeleted = 0 AND Status = 2)
    BEGIN
        RAISERROR(N'Bài giảng không tồn tại hoặc chưa được xuất bản.', 16, 1);
        RETURN;
    END

    SELECT * FROM dbo.tblEL_Lessons WHERE LessonID = @LessonID;
    SELECT * FROM dbo.tblEL_Elements WHERE LessonID = @LessonID AND IsDeleted = 0 ORDER BY SortOrder;
END
