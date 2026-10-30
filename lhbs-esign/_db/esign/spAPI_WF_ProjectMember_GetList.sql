CREATE   PROCEDURE [dbo].[spAPI_WF_ProjectMember_GetList]
    @sys_UserID VARCHAR(9),
    @ProjectID  BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        M.MemberID, M.ProjectID, M.EmployeeCode, M.FullName, M.Role, M.CreateTime,
        IsCurrentUser = CASE WHEN M.EmployeeCode = @sys_UserID THEN 1 ELSE 0 END
    FROM dbo.tblWF_ProjectMember AS M
    WHERE M.ProjectID = @ProjectID AND M.[Enable] = 1
    ORDER BY CASE M.Role WHEN 'LEAD' THEN 0 WHEN 'MEMBER' THEN 1 ELSE 2 END, M.FullName;
END