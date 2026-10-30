
CREATE PROCEDURE [dbo].[spAPI_WF_WorkItem_GetList]
    @sys_UserID     VARCHAR(9),
    @ProjectID      BIGINT       = NULL,
    @Status         VARCHAR(20)  = NULL,     -- NULL = tất cả; hoặc BACKLOG/TODO/IN_PROGRESS/DONE/BLOCKED
    @AssigneeCode   VARCHAR(9)   = NULL,
    @Priority       VARCHAR(20)  = NULL,
    @Keyword        NVARCHAR(200)= NULL
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        W.WorkItemID,
        W.ProjectID,
        W.ItemType,
        W.Title,
        W.Description,
        W.Status,
        W.Priority,
        W.AssigneeCode,
        AssigneeName   = ISNULL(U.FullName, W.AssigneeCode),
        W.DueDate,
        W.SortOrder,
        W.ParentWorkItemID,
        W.IssueKey,
        W.CreateUser,
        CreateUserName = ISNULL(UC.FullName, W.CreateUser),
        W.CreateTime,
        W.UpdateUser,
        W.UpdateTime
    FROM dbo.tblWF_WorkItem AS W
    OUTER APPLY
    (
        SELECT TOP (1) FullName
        FROM dbo.tblWF_User
        WHERE EmployeeCode = W.AssigneeCode AND [Enable] = 1 AND IsActive = 1
        ORDER BY UserID DESC
    ) AS U
    OUTER APPLY
    (
        SELECT TOP (1) FullName
        FROM dbo.tblWF_User
        WHERE EmployeeCode = W.CreateUser AND [Enable] = 1 AND IsActive = 1
        ORDER BY UserID DESC
    ) AS UC
    WHERE W.[Enable] = 1
      AND (@ProjectID   IS NULL OR W.ProjectID   = @ProjectID)
      AND (@Status       IS NULL OR W.Status      = @Status)
      AND (@AssigneeCode IS NULL OR W.AssigneeCode = @AssigneeCode)
      AND (@Priority     IS NULL OR W.Priority    = @Priority)
      AND (@Keyword      IS NULL OR W.Title LIKE '%' + @Keyword + '%')
    ORDER BY W.SortOrder ASC, W.CreateTime DESC, W.WorkItemID DESC
END
