-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Create date:    [Ngày hiện tại]
-- Description:    Tạo mới hoặc cập nhật một thành phần (element) trong một bài giảng.
--                 - Nếu @ElementID = 0, thực hiện INSERT.
--                 - Nếu @ElementID > 0, thực hiện UPDATE.
-- API Endpoint:   POST lms/EL_Element_Save
-- Ví dụ Body:
-- {
--   "ElementID": 0, "LessonID": 1, "ElementType": "TEXT",
--   "ElementData": "{\"content\":\"Nội dung mới\"}", "SortOrder": 10
-- }
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Element_Save]
    @ElementID BIGINT = 0,
    @LessonID INT,
    @ElementType VARCHAR(50),
    @ElementData NVARCHAR(MAX),
    @SortOrder INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
	 set @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID)

    -- === VALIDATION ===
    IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_Lessons WHERE LessonID = @LessonID AND CreateUser = @sys_UserID AND IsDeleted = 0)
    BEGIN
        RAISERROR(N'Bài giảng không tồn tại hoặc bạn không có quyền chỉnh sửa.', 16, 1);
        RETURN;
    END

    IF ISJSON(@ElementData) = 0
    BEGIN
        RAISERROR(N'Dữ liệu ElementData không phải là một chuỗi JSON hợp lệ.', 16, 1);
        RETURN;
    END

    -- === LOGIC ===
    IF @ElementID > 0
    BEGIN
        -- --- UPDATE ---
        UPDATE dbo.tblEL_Elements
        SET
            ElementType = @ElementType,
            ElementData = @ElementData,
            SortOrder = @SortOrder,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE ElementID = @ElementID AND LessonID = @LessonID;

        SELECT * FROM dbo.tblEL_Elements WHERE ElementID = @ElementID;
    END
    ELSE
    BEGIN
        -- --- INSERT ---
        INSERT INTO dbo.tblEL_Elements (LessonID, ElementType, ElementData, SortOrder, CreateUser)
        VALUES (@LessonID, @ElementType, @ElementData, @SortOrder, @sys_UserID);
        
        DECLARE @NewElementID BIGINT = SCOPE_IDENTITY();
        SELECT * FROM dbo.tblEL_Elements WHERE ElementID = @NewElementID;
    END
END
