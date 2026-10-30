
-- 5. Tạo/Cập nhật Procedure sửa thông báo
CREATE   PROCEDURE [dbo].[spAPI_Alert_Update]
    @AlertID        INT,
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

    UPDATE tblAlert
    SET TypeAlert = @TypeAlert,
        ContentAlert = @ContentAlert,
        DateAlert = @DateAlert,
        CapID = @CapID,
        NienKhoa = @NienKhoa,
        UpdateUser = @SYS_USERID,
        UpdateTime = GETDATE(),
        UserRight = @UserRight
    WHERE AlertID = @AlertID;
END
