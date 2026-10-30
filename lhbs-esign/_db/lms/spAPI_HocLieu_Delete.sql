CREATE PROCEDURE [dbo].[spAPI_HocLieu_Delete]
    @HocLieuID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem có mục con nào không
    IF EXISTS (SELECT 1 FROM dbo.tblHocLieu WHERE ParentID = @HocLieuID)
    BEGIN
        -- Nếu có con, báo lỗi và không cho xóa
        RAISERROR(N'Không thể xóa mục này vì nó chứa các mục con. Vui lòng xóa các mục con trước.', 16, 1);
        RETURN;
    END

    -- Nếu không có con, tiến hành xóa
    DELETE FROM dbo.tblHocLieu
    WHERE HocLieuID = @HocLieuID;

    -- Trả về thông báo thành công
    SELECT Success = 1, Message = N'Đã xóa thành công.';
END
