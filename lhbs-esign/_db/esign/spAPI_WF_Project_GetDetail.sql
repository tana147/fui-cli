

-- 7.2 Project_GetDetail — thông tin project + danh sách member + counts
CREATE   PROCEDURE [dbo].[spAPI_WF_Project_GetDetail]
    @sys_UserID VARCHAR(9),
    @ProjectID  BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsAdmin INT = dbo.fnWF_CheckPermission(@sys_UserID, 'admin-all,project-manage');
    DECLARE @MyRole VARCHAR(20);
    SELECT @MyRole = Role FROM dbo.tblWF_ProjectMember
    WHERE ProjectID = @ProjectID AND EmployeeCode = @sys_UserID AND [Enable] = 1;

    IF @IsAdmin = 0 AND @MyRole IS NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Bạn không có quyền xem project này.' AS Message;
        RETURN;
    END

    -- Thông tin project
    SELECT
        P.ProjectID, P.Code, P.Name, P.Description, P.Icon, P.Color,
        P.OwnerCode, OwnerName = ISNULL(U.FullName, P.OwnerCode),
        P.Status, MyRole = ISNULL(@MyRole, CASE WHEN @IsAdmin = 1 THEN 'ADMIN' ELSE NULL END),
        P.CreateTime, P.UpdateTime
    FROM dbo.tblWF_Project AS P
    LEFT JOIN dbo.tblWF_User AS U ON U.EmployeeCode = P.OwnerCode AND U.[Enable] = 1
    WHERE P.ProjectID = @ProjectID AND P.[Enable] = 1;

    -- Danh sách workflow (Definition) trong project
    SELECT D.DefinitionID, D.Code, D.Name, D.IsActive,
           StepCount = (SELECT COUNT(1) FROM dbo.tblWF_StepDefinition S WHERE S.DefinitionID = D.DefinitionID AND S.[Enable] = 1)
    FROM dbo.tblWF_Definition AS D
    WHERE D.ProjectID = @ProjectID AND D.[Enable] = 1
    ORDER BY D.Name;

    -- Danh sách thành viên
    SELECT M.MemberID, M.EmployeeCode, M.FullName, M.Role, M.CreateTime
    FROM dbo.tblWF_ProjectMember AS M
    WHERE M.ProjectID = @ProjectID AND M.[Enable] = 1
    ORDER BY CASE M.Role WHEN 'LEAD' THEN 0 WHEN 'MEMBER' THEN 1 ELSE 2 END, M.FullName;
END
