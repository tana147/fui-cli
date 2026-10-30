-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Create date:    [Ngày hiện tại]
-- Description:    Cập nhật lại thứ tự (SortOrder) của nhiều element cùng lúc.
--                 Dùng sau khi người dùng kéo-thả sắp xếp lại các element.
-- API Endpoint:   POST lms/EL_Element_UpdateOrder
-- Ví dụ Body:     { "LessonID": 1, "OrderData": "[{\"id\": 1, \"order\": 10}, {\"id\": 3, \"order\": 20}]" }
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Element_UpdateOrder]
    @LessonID INT,
    @OrderData NVARCHAR(MAX), -- JSON array of objects: [{id: 1, order: 10}, ...]
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền sở hữu bài giảng
    IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_Lessons WHERE LessonID = @LessonID AND CreateUser = @sys_UserID AND IsDeleted = 0)
    BEGIN
        RAISERROR(N'Bạn không có quyền thay đổi thứ tự trong bài giảng này.', 16, 1);
        RETURN;
    END

    -- Dùng MERGE hoặc UPDATE với JOIN để cập nhật hàng loạt
    -- Cách này hiệu quả hơn là dùng con trỏ (cursor) lặp qua từng item
    UPDATE el
    SET 
        el.SortOrder = jsonData.sortOrder,
        el.UpdateUser = @sys_UserID,
        el.UpdateTime = GETDATE()
    FROM 
        dbo.tblEL_Elements AS el
    INNER JOIN 
        OPENJSON(@OrderData) WITH (
            id BIGINT '$.id',
            sortOrder INT '$.order'
        ) AS jsonData ON el.ElementID = jsonData.id
    WHERE
        el.LessonID = @LessonID; -- Đảm bảo chỉ cập nhật trong phạm vi bài giảng này

    SELECT Success = 1, Message = N'Đã cập nhật thành công thứ tự các thành phần.';
END
