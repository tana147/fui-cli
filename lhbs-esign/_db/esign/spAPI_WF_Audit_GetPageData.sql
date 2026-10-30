CREATE PROCEDURE [dbo].[spAPI_WF_Audit_GetPageData]
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CheckListOpenCount = (SELECT COUNT(1) FROM dbo.tblWF_AuditChecklist WHERE [Enable] = 0 AND Status IN ('TODO', 'IN_PROGRESS', 'BLOCKED')),
        TestCaseOpenCount = (SELECT COUNT(1) FROM dbo.tblWF_AuditTestCase WHERE [Enable] = 0 AND Status IN ('DRAFT', 'READY', 'FAILED', 'BLOCKED')),
        BacklogOpenCount = (SELECT COUNT(1) FROM dbo.tblWF_AuditBacklog WHERE [Enable] = 0 AND Status IN ('TODO', 'IN_PROGRESS', 'BLOCKED')),
        SpecChangeCount = (SELECT COUNT(1) FROM dbo.tblWF_AuditSpecChange WHERE [Enable] = 0),
        AgentOwnedCount =
            (SELECT COUNT(1) FROM dbo.tblWF_AuditChecklist WHERE [Enable] = 0 AND (PICType = 'AGENT' OR HandlerType = 'AGENT'))
            + (SELECT COUNT(1) FROM dbo.tblWF_AuditTestCase WHERE [Enable] = 0 AND (PICType = 'AGENT' OR HandlerType = 'AGENT'))
            + (SELECT COUNT(1) FROM dbo.tblWF_AuditBacklog WHERE [Enable] = 0 AND (PICType = 'AGENT' OR HandlerType = 'AGENT'))
            + (SELECT COUNT(1) FROM dbo.tblWF_AuditSpecChange WHERE [Enable] = 0 AND (PICType = 'AGENT' OR HandlerType = 'AGENT'));

    SELECT ChecklistID, ModuleKey, ItemGroup, ItemTitle, Status, Priority, PICType, PICCode, PICName, HandlerType, HandlerCode, HandlerName, DueDate, Note, CreateUser, CreateTime, UpdateUser, UpdateTime
    FROM dbo.tblWF_AuditChecklist
    WHERE [Enable] = 0
    ORDER BY UpdateTime DESC, CreateTime DESC, ChecklistID DESC;

    SELECT AuditTestCaseID, TestCaseCode, TestType, ModuleKey, ScreenKey, Title, Preconditions, TestSteps, ExpectedResult, ActualResult, EvidenceUrl, ReportUrl, TesterType, TesterCode, TesterName, LastTestTime, Status, Priority, PICType, PICCode, PICName, HandlerType, HandlerCode, HandlerName, Note, CreateUser, CreateTime, UpdateUser, UpdateTime
    FROM dbo.tblWF_AuditTestCase
    WHERE [Enable] = 0
    ORDER BY UpdateTime DESC, CreateTime DESC, AuditTestCaseID DESC;

    SELECT BacklogID, WorkDate, WorkType, Title, Detail, Status, PICType, PICCode, PICName, HandlerType, HandlerCode, HandlerName, SourceFile, CreateUser, CreateTime, UpdateUser, UpdateTime
    FROM dbo.tblWF_AuditBacklog
    WHERE [Enable] = 0
    ORDER BY WorkDate DESC, UpdateTime DESC, CreateTime DESC, BacklogID DESC;

    SELECT SpecChangeID, ChangeDate, ChangeType, Title, PreviousSpec, NewSpec, ImpactModules, Status, PICType, PICCode, PICName, HandlerType, HandlerCode, HandlerName, Note, CreateUser, CreateTime, UpdateUser, UpdateTime
    FROM dbo.tblWF_AuditSpecChange
    WHERE [Enable] = 0
    ORDER BY ChangeDate DESC, UpdateTime DESC, CreateTime DESC, SpecChangeID DESC;
END
