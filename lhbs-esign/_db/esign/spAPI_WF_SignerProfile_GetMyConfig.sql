

-- 3E. spAPI_WF_SignerProfile_GetMyConfig

CREATE PROCEDURE [dbo].[spAPI_WF_SignerProfile_GetMyConfig]

    @sys_UserID VARCHAR(50)

AS

BEGIN

    SET NOCOUNT ON;



    SELECT TOP (1)

        UserID,

        LegacyUserID,

        FullName,

        Email,

        EmployeeCode,

        IsInternalUser,

        JobTitle,

        DepartmentName,

        CertSerial,

        CertSubject,

        CertIssuer,

        CertValidFrom,

        CertValidTo,

        CertIsActive,

        SmartCAOptionSign,

        SignatureDisplayName,

        SignatureFileID,

        SignatureNote,

        IsActive,

        CreateUser,

        CreateTime,

        UpdateUser,

        UpdateTime

    FROM dbo.tblWF_User

    WHERE [Enable] = 1

      AND IsActive = 1

      AND

      (

            EmployeeCode = @sys_UserID

            OR Email = @sys_UserID

            OR CAST(LegacyUserID AS VARCHAR(50)) = @sys_UserID

      )

    ORDER BY

        CASE WHEN EmployeeCode = @sys_UserID THEN 0

             WHEN Email = @sys_UserID THEN 1

             WHEN CAST(LegacyUserID AS VARCHAR(50)) = @sys_UserID THEN 2

             ELSE 9 END,

        UserID DESC;

END


