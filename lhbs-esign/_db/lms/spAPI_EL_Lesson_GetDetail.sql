-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Create date:    [Ngày hiện tại]
-- Description:    Lấy thông tin chi tiết của một bài giảng, bao gồm cả
--                 danh sách các thành phần (elements) bên trong.
-- API Endpoint:   GET /el/lesson_getdetail/{LessonID}
-- Ví dụ gọi:      /el/lesson_getdetail/1
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Lesson_GetDetail]
    -- Tham số từ URL
    @LessonID INT,
    
    -- Tham số hệ thống
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Chuẩn hóa tài khoản proxy giống các API LMS khác trước khi kiểm tra quyền.
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    -- Giáo viên được xem bài do mình tạo hoặc bài thuộc môn đã được cấp quyền SUBJECT.
    -- SUBJECT chỉ là quyền xem; quyền sửa vẫn được xác định riêng bởi CreateUser.
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.tblEL_Lessons l
        WHERE l.LessonID = @LessonID
          AND l.IsDeleted = 0
          AND (
              @sys_UserID = 'NA0000022'
              OR l.CreateUser = @sys_UserID
              OR EXISTS (
                  SELECT 1
                  FROM dbo.tblEL_Resoucre_TeacherPermissions tp
                  WHERE tp.Enable = 1
                    AND tp.GiaoVienID = @sys_UserID
                    AND tp.PermissionScope = 'SUBJECT'
                    AND tp.MonHocID = l.MonHocID
                    AND (tp.NienKhoa IS NULL OR tp.NienKhoa = l.NienKhoa)
              )
          )
    )
    BEGIN
        RAISERROR(N'Không tìm thấy bài giảng hoặc bạn không có quyền truy cập.', 16, 1);
        RETURN;
    END

    -- Trả thêm CanEdit để UI phân biệt chủ bài (được sửa) với người xem theo môn.
    SELECT l.*,
           CAST(CASE WHEN @sys_UserID = 'NA0000022' OR l.CreateUser = @sys_UserID
                     THEN 1 ELSE 0 END AS bit) AS CanEdit
    FROM dbo.tblEL_Lessons l
    WHERE l.LessonID = @LessonID
      AND l.IsDeleted = 0;

    -- Trả về danh sách tất cả các thành phần của bài giảng đó (bảng 2)
    -- Metadata hoàn thành phải được trả lại cùng element để trình soạn bài khôi phục đúng cấu hình sau reload.
    SELECT 
        ElementID,
        LessonID,
        ElementType,
        ElementData,
        SortOrder,
        IsRequired,
        CompletionMode,
        ExpectedDurationSeconds,
        RequiredDurationSeconds
    FROM dbo.tblEL_Elements
    WHERE 
        LessonID = @LessonID
        AND IsDeleted = 0
    ORDER BY
        SortOrder ASC;
END
