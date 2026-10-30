

-- 3G. spAPI_WF_SignerProfile_GetMyActiveCert

CREATE PROCEDURE [dbo].[spAPI_WF_SignerProfile_GetMyActiveCert]

    @sys_UserID VARCHAR(50)

AS

BEGIN
    SET NOCOUNT ON;

    ;WITH XMLNAMESPACES ('http://www.w3.org/2001/XMLSchema' AS xs)
    SELECT TOP (1)
        P.UserID,
        P.LegacyUserID,
        P.FullName,
        P.Email,
        P.EmployeeCode,
        P.CertSerial,
        P.CertSubject,
        P.CertIssuer,
        P.CertValidFrom,
        P.CertValidTo,
        P.CertIsActive,
        P.SmartCAOptionSign,
        P.SignatureDisplayName,
        P.SignatureFileID,
        ImgSign = CASE
            WHEN FA.BinaryData IS NULL THEN ''
            ELSE CAST(N'' AS XML).value('xs:base64Binary(sql:column("FA.BinaryData"))', 'VARCHAR(MAX)')
        END,
        TextSign = ISNULL(NULLIF(LTRIM(RTRIM(P.FullName)), ''), 'SmartCA')
    FROM dbo.tblWF_User AS P

    LEFT JOIN eSignature_File.dbo.tblFileData AS FD
        ON FD.FileID = P.SignatureFileID
    OUTER APPLY
    (
        SELECT BinaryData = CAST(FD.BinaryContent AS VARBINARY(MAX))
    ) AS FA

    WHERE P.[Enable] = 1
      AND P.IsActive = 1
      AND P.CertIsActive = 1
      AND ISNULL(P.CertSerial, '') <> ''
      AND (P.CertValidFrom IS NULL OR P.CertValidFrom <= GETDATE())
      AND (P.CertValidTo IS NULL OR P.CertValidTo >= GETDATE())
      AND
      (
            P.EmployeeCode = @sys_UserID
            OR P.Email = @sys_UserID
            OR CAST(P.LegacyUserID AS VARCHAR(50)) = @sys_UserID
      )
    ORDER BY
        CASE WHEN P.EmployeeCode = @sys_UserID THEN 0
             WHEN P.Email = @sys_UserID THEN 1
             WHEN CAST(P.LegacyUserID AS VARCHAR(50)) = @sys_UserID THEN 2
             ELSE 9 END,
        P.UserID DESC;

END




