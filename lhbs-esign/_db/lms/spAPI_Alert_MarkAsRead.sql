
-- 3. Tạo/Cập nhật Procedure đánh dấu đã xem thông báo
CREATE   PROCEDURE [dbo].[spAPI_Alert_MarkAsRead]
    @AlertID    INT,
    @UserID     VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra nếu chưa tồn tại vết thì ghi nhận vào bảng
    IF NOT EXISTS (SELECT 1 FROM tblAlertRead WHERE AlertID = @AlertID AND UserID = @UserID)
    BEGIN
        INSERT INTO tblAlertRead (AlertID, UserID, ReadTime)
        VALUES (@AlertID, @UserID, GETDATE());
    END
END
