
-- 3D. spAPI_WF_SignerProfile_Delete
CREATE PROCEDURE [dbo].[spAPI_WF_SignerProfile_Delete]
    @UserID INT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblWF_User
    SET [Enable] = 0,
        IsActive = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE UserID = @UserID
      AND [Enable] = 1;

    SELECT
        Message = N'Đã xóa hồ sơ người ký.',
        UserID = @UserID;
END
