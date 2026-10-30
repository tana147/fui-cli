
-- ==========================================================
-- SP CẬP NHẬT THỨ TỰ / CẤU TRÚC CÂY (SAU KHI KÉO-THẢ)
-- ==========================================================
CREATE PROCEDURE [dbo].[spAPI_FP_NoiDung_UpdateTreeStructure]
    @JsonData NVARCHAR(MAX), -- '[{"id": 1, "order": 0, "parent": null}, {"id": 2, "order": 0, "parent": 1}]'
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    -- Cập nhật thứ tự và cha của các node dựa trên JSON đầu vào
    UPDATE T
    SET 
        T.ThuTu = J.sortOrder,
        T.ParentID = J.parentId,
        T.UpdateUser = @sys_UserID,
        T.UpdateTime = GETDATE()
    FROM 
        dbo.tblNoiDungHocLieu_FP AS T
    INNER JOIN 
        OPENJSON(@JsonData) WITH (
            id INT '$.id',
            sortOrder INT '$.order',
            parentId INT '$.parent'
        ) AS J ON T.NoiDungID = J.id;

    SELECT Success = 1, Message = N'Đã cập nhật cấu trúc cây.';
END
