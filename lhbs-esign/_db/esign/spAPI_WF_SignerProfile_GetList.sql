CREATE PROCEDURE [dbo].[spAPI_WF_SignerProfile_GetList]
    @sys_UserID VARCHAR(50),
    @Keyword NVARCHAR(200) = NULL,
    @OnlyActive BIT = 0
AS

BEGIN
    SET NOCOUNT ON;
    DECLARE @q NVARCHAR(200) = LTRIM(RTRIM(ISNULL(@Keyword, N'')));

    SELECT
        UserID,
        LegacyUserID,
        FullName,
        Email,
        EmployeeCode,
        IsInternalUser,
        JobTitle,
        DepartmentName,
        CertSerial,
        CertIssuer,
        CertValidFrom,
        CertValidTo,
        CertIsActive,
        SignatureDisplayName,
        SignatureFileID,
        IsActive,
        CreateTime,
        UpdateTime
    FROM dbo.tblWF_User
    WHERE [Enable] = 1
      AND (@OnlyActive = 0 OR IsActive = 1)
      AND (
            @q = N''
            OR FullName LIKE N'%' + @q + N'%'
            OR ISNULL(Email, '') LIKE '%' + CAST(@q AS VARCHAR(200)) + '%'
            OR ISNULL(EmployeeCode, '') LIKE '%' + CAST(@q AS VARCHAR(200)) + '%'
            OR ISNULL(CertSerial, '') LIKE '%' + CAST(@q AS VARCHAR(200)) + '%'
          )
    ORDER BY IsActive DESC, FullName ASC, UserID DESC;
END

