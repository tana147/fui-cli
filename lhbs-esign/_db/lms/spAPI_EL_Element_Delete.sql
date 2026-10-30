-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Create date:    [Ngày hiện tại]
-- Description:    Xóa mềm (soft delete) một thành phần khỏi bài giảng.
-- API Endpoint:   POST lms/EL_Element_Delete
-- Ví dụ Body:     { "ElementID": 123 }
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Element_Delete]
    @ElementID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
	set @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID)

    -- Lấy LessonID từ ElementID để kiểm tra quyền
    DECLARE @LessonID_Check INT;
    SELECT @LessonID_Check = LessonID FROM dbo.tblEL_Elements WHERE ElementID = @ElementID;

    IF @LessonID_Check IS NULL
    BEGIN
        RAISERROR(N'Thành phần không tồn tại.', 16, 1);
        RETURN;
    END

    -- Kiểm tra quyền sở hữu bài giảng chứa element này
    IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_Lessons WHERE LessonID = @LessonID_Check AND CreateUser = @sys_UserID AND IsDeleted = 0)
    BEGIN
        RAISERROR(N'Bạn không có quyền xóa thành phần trong bài giảng này.', 16, 1);
        RETURN;
    END

    -- Thực hiện xóa mềm
    UPDATE dbo.tblEL_Elements
    SET
        IsDeleted = 1,
        UpdateTime = GETDATE(),
        UpdateUser = @sys_UserID
    WHERE
        ElementID = @ElementID;

    -- Trả về thông báo thành công
    SELECT Success = 1, Message = N'Đã xóa thành phần thành công.', DeletedElementID = @ElementID;
END
