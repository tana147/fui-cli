CREATE PROCEDURE [dbo].[spAPI_WF_Definition_GetList]
    @sys_UserID VARCHAR(9),
    @Status VARCHAR(20) = 'ALL',
    @Keyword NVARCHAR(200) = NULL,
    @ProjectID BIGINT = NULL   -- NULL = không lọc theo project (flow cũ)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @KeywordNorm NVARCHAR(200) = LTRIM(RTRIM(ISNULL(@Keyword, N'')));

    SELECT
        D.DefinitionID,
        D.Code,
        D.Name,
        D.Description,
        D.CategoryID,
        D.ProjectID,
        D.ProjectSortOrder,
        D.Version,
        D.IsActive,
        D.OnRejectAction,
        D.NotifyEmail,
        D.NotifyOnComplete,
        D.AssignerID,
        AssignerName = ISNULL(U.FullName, N''),
        C.Code AS CategoryCode,
        C.Name AS CategoryName,
        C.Color AS CategoryColor,
        C.Icon AS CategoryIcon,
        (
            SELECT COUNT(1)
            FROM dbo.tblWF_StepDefinition AS S
            WHERE S.DefinitionID = D.DefinitionID
              AND S.[Enable] = 1
        ) AS StepCount,
        (
            SELECT COUNT(1)
            FROM dbo.tblWF_FieldMapping AS F
            WHERE F.DefinitionID = D.DefinitionID
              AND F.[Enable] = 1
        ) AS FieldCount,
        (
            SELECT COUNT(1)
            FROM dbo.tblWF_Instance AS I
            WHERE I.DefinitionID = D.DefinitionID
              AND I.Status IN ('RUNNING', 'WAITING_ME')
              AND I.[Enable] = 1
        ) AS ActiveInstances,
        (
            SELECT MAX(I.UpdateTime)
            FROM dbo.tblWF_Instance AS I
            WHERE I.DefinitionID = D.DefinitionID
              AND I.[Enable] = 1
        ) AS LastInstanceUpdateTime,
        D.CreateUser,
        D.CreateTime,
        D.UpdateUser,
        D.UpdateTime
    FROM dbo.tblWF_Definition AS D
    LEFT JOIN dbo.tblWF_Category AS C
        ON C.CategoryID = D.CategoryID
       AND C.[Enable] = 1
    OUTER APPLY (
        SELECT TOP (1) U.FullName
        FROM dbo.tblWF_User AS U
        WHERE U.EmployeeCode = D.AssignerID AND U.[Enable] = 1 AND U.IsActive = 1
        ORDER BY U.UserID DESC
    ) AS U
    WHERE D.[Enable] = 1
      AND
      (
          @Status = 'ALL'
          OR (@Status = 'ACTIVE' AND D.IsActive = 1)
          OR (@Status = 'INACTIVE' AND D.IsActive = 0)
      )
      AND
      (
          @KeywordNorm = N''
          OR D.Name LIKE N'%' + @KeywordNorm + N'%'
          OR D.Code LIKE N'%' + @KeywordNorm + N'%'
          OR ISNULL(C.Name, N'') LIKE N'%' + @KeywordNorm + N'%'
      )
      AND (@ProjectID IS NULL OR D.ProjectID = @ProjectID)
    ORDER BY D.CreateTime DESC, D.DefinitionID DESC;
END
