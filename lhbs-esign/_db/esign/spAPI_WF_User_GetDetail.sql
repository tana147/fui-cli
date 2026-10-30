CREATE PROCEDURE [dbo].[spAPI_WF_User_GetDetail]
    @UserID INT = 0,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@UserID, 0) <= 0
    BEGIN
        SELECT
            UserID              = 0,
            LegacyUserID        = NULL,
            FullName            = N'',
            Email               = '',
            EmployeeCode        = '',
            IsInternalUser      = CAST(1 AS BIT),
            JobTitle            = N'',
            DepartmentName      = N'',
            CertSerial          = '',
            CertSubject         = N'',
            CertIssuer          = N'',
            CertValidFrom       = NULL,
            CertValidTo         = NULL,
            CertIsActive        = CAST(1 AS BIT),
            SignatureDisplayName = N'',
            SignatureFileID      = NULL,        -- was ''
            SignatureNote       = N'',
            IsActive            = CAST(1 AS BIT);
        RETURN;
    END

    SELECT TOP 1
        UserID, LegacyUserID, FullName, Email, EmployeeCode,
        IsInternalUser, JobTitle, DepartmentName,
        CertSerial, CertSubject, CertIssuer, CertValidFrom, CertValidTo, CertIsActive,
        SignatureDisplayName, SignatureFileID, SignatureNote, IsActive,
        CreateUser, CreateTime, UpdateUser, UpdateTime
    FROM dbo.tblWF_User
    WHERE UserID = @UserID
      AND [Enable] = 1;
END
