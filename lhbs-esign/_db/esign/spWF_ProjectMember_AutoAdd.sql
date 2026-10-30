
-- 6.2 Đảm bảo 1 người là member của project (auto-add, không hạ cấp role sẵn có)
CREATE   PROCEDURE [dbo].[spWF_ProjectMember_AutoAdd]
    @ProjectID    BIGINT,
    @EmployeeCode VARCHAR(9),
    @Role         VARCHAR(20) = 'MEMBER',
    @sys_UserID   VARCHAR(9)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @ProjectID IS NULL OR @EmployeeCode IS NULL OR LTRIM(RTRIM(@EmployeeCode)) = '' RETURN;

    -- Đã là member còn hiệu lực → giữ nguyên (không ghi đè role)
    IF EXISTS (SELECT 1 FROM dbo.tblWF_ProjectMember
               WHERE ProjectID = @ProjectID AND EmployeeCode = @EmployeeCode AND [Enable] = 1)
        RETURN;

    DECLARE @FullName NVARCHAR(200);
    SELECT TOP 1 @FullName = FullName FROM dbo.tblWF_User
    WHERE EmployeeCode = @EmployeeCode AND [Enable] = 1;

    -- Có bản ghi cũ bị soft-delete → bật lại
    IF EXISTS (SELECT 1 FROM dbo.tblWF_ProjectMember
               WHERE ProjectID = @ProjectID AND EmployeeCode = @EmployeeCode AND [Enable] = 0)
        UPDATE dbo.tblWF_ProjectMember
        SET [Enable] = 1, Role = @Role, FullName = ISNULL(@FullName, FullName),
            UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE ProjectID = @ProjectID AND EmployeeCode = @EmployeeCode;
    ELSE
        INSERT INTO dbo.tblWF_ProjectMember (ProjectID, EmployeeCode, FullName, Role, [Enable], CreateUser, CreateTime)
        VALUES (@ProjectID, @EmployeeCode, ISNULL(@FullName, @EmployeeCode), @Role, 1, @sys_UserID, GETDATE());
END