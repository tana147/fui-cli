
-- 4. Tạo/Cập nhật Procedure thêm thông báo mới
CREATE   PROCEDURE [dbo].[spAPI_Alert_Insert]
    @TypeAlert      VARCHAR(100),
    @ContentAlert   NVARCHAR(100),
    @DateAlert      DATETIME,
    @CapID          INT,
    @NienKhoa       INT,
    @SYS_USERID     VARCHAR(20),
    @UserRight      VARCHAR(50) = 'ALL'
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO tblAlert (TypeAlert, ContentAlert, DateAlert, CapID, NienKhoa, Enable, CreateUser, CreateTime, UpdateUser, UpdateTime, UserRight)
    VALUES (@TypeAlert, @ContentAlert, @DateAlert, @CapID, @NienKhoa, 1, @SYS_USERID, GETDATE(), @SYS_USERID, GETDATE(), @UserRight);
    
    SELECT SCOPE_IDENTITY() AS AlertID;
END
