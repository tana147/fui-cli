
-- 7.1 Project_GetList — chỉ trả project mà user là member hoặc có quyền admin/manage
CREATE   PROCEDURE [dbo].[spAPI_WF_Project_GetList]
    @sys_UserID VARCHAR(9),
    @Status     VARCHAR(20)   = 'ACTIVE',  -- ACTIVE | ARCHIVED | ALL
    @Keyword    NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @KeywordNorm NVARCHAR(200) = LTRIM(RTRIM(ISNULL(@Keyword, N'')));
    DECLARE @IsAdmin INT = dbo.fnWF_CheckPermission(@sys_UserID, 'admin-all,project-manage');

    SELECT
        P.ProjectID,
        P.Code,
        P.Name,
        P.Description,
        P.Icon,
        P.Color,
        P.OwnerCode,
        OwnerName  = ISNULL(U.FullName, P.OwnerCode),
        P.Status,
        MyRole     = M.Role,
        MemberCount = (SELECT COUNT(1) FROM dbo.tblWF_ProjectMember PM WHERE PM.ProjectID = P.ProjectID AND PM.[Enable] = 1),
        DefinitionCount = (SELECT COUNT(1) FROM dbo.tblWF_Definition D WHERE D.ProjectID = P.ProjectID AND D.[Enable] = 1),
        IssueCount = (SELECT COUNT(1) FROM dbo.tblWF_Instance I
                       INNER JOIN dbo.tblWF_Definition D2 ON D2.DefinitionID = I.DefinitionID
                       WHERE D2.ProjectID = P.ProjectID AND I.[Enable] = 1),
        P.CreateTime,
        P.UpdateTime
    FROM dbo.tblWF_Project AS P
    OUTER APPLY (
        SELECT TOP 1 PM.Role FROM dbo.tblWF_ProjectMember PM
        WHERE PM.ProjectID = P.ProjectID AND PM.EmployeeCode = @sys_UserID AND PM.[Enable] = 1
    ) AS M
    LEFT JOIN dbo.tblWF_User AS U ON U.EmployeeCode = P.OwnerCode AND U.[Enable] = 1 AND U.IsActive = 1
    WHERE P.[Enable] = 1
      AND (@Status = 'ALL' OR P.Status = @Status)
      AND (@KeywordNorm = N'' OR P.Name LIKE N'%' + @KeywordNorm + N'%' OR P.Code LIKE N'%' + @KeywordNorm + N'%')
      AND (@IsAdmin = 1 OR M.Role IS NOT NULL)   -- enforce: chỉ thấy project mình là member, trừ admin
    ORDER BY P.UpdateTime DESC, P.ProjectID DESC;
END