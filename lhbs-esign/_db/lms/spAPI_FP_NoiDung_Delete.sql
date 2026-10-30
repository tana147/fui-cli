
-- ==========================================================
-- SP XÓA MỘT MỤC TRONG CÂY NỘI DUNG (XÓA CẢ CÁC CON)
-- ==========================================================
CREATE PROCEDURE [dbo].[spAPI_FP_NoiDung_Delete]
    @NoiDungID INT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    -- Dùng CTE đệ quy để tìm tất cả các node con cần xóa
    WITH NodesToDelete AS (
        SELECT NoiDungID FROM dbo.tblNoiDungHocLieu_FP WHERE NoiDungID = @NoiDungID
        UNION ALL
        SELECT n.NoiDungID FROM dbo.tblNoiDungHocLieu_FP n
        INNER JOIN NodesToDelete d ON n.ParentID = d.NoiDungID
    )
    -- Đánh dấu xóa (soft delete)
    UPDATE dbo.tblNoiDungHocLieu_FP
    SET Is_Xoa = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE NoiDungID IN (SELECT NoiDungID FROM NodesToDelete);

    SELECT Success = 1, Message = N'Đã xóa thành công.';
END
