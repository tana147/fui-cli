
CREATE PROCEDURE [dbo].[spAPI_WF_RequestDraft_GetList]
    @Filter VARCHAR(20) = 'ALL',
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UseFilter VARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@Filter, 'ALL'))));

    SELECT
        D.DraftID,
        D.CreateMode,
        D.DefinitionID,
        D.CategoryID,
        D.DraftName,
        D.ReferenceCode,
        D.Description,
        D.ExecutionEngine,
        D.ContractProvider,
        D.FileMethod,
        D.SourceFileID,
        D.SourceFileName,
        D.TemplateID,
        D.Priority,
        D.Sequential,
        D.NotifyEmail,
        D.RequireOtpConfirm,
        D.SubmittedInstanceID,
        D.Status,
        D.CreateUser,
        D.CreateTime,
        D.UpdateUser,
        D.UpdateTime,
        DefinitionName = ISNULL(WD.Name, CASE WHEN D.CreateMode = 'FREE_SIGN' THEN N'Ký tự do' ELSE N'-' END),
        CategoryName = ISNULL(WC.Name, N'-')
    FROM dbo.tblWF_RequestDraft D
    LEFT JOIN dbo.tblWF_Definition WD ON WD.DefinitionID = D.DefinitionID AND WD.Enable = 0
    LEFT JOIN dbo.tblWF_Category WC ON WC.CategoryID = D.CategoryID AND WC.Enable = 0
    WHERE D.Enable = 0
      AND (D.CreateUser = @sys_UserID OR ISNULL(D.UpdateUser, '') = @sys_UserID)
      AND (
            @UseFilter = 'ALL'
            OR (@UseFilter = 'DRAFT' AND ISNULL(D.Status, 'DRAFT') = 'DRAFT')
            OR (@UseFilter = 'SUBMITTED' AND ISNULL(D.Status, '') = 'SUBMITTED')
          )
    ORDER BY ISNULL(D.UpdateTime, D.CreateTime) DESC, D.DraftID DESC;
END
