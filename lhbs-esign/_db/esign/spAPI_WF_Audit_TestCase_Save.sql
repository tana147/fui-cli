CREATE PROCEDURE [dbo].[spAPI_WF_Audit_TestCase_Save]
    @AuditTestCaseID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TestCaseCode VARCHAR(50) = JSON_VALUE(@sys_RawData, '$.TestCaseCode');
    DECLARE @TestType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.TestType');
    DECLARE @ModuleKey VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.ModuleKey');
    DECLARE @ScreenKey VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.ScreenKey');
    DECLARE @Title NVARCHAR(300) = JSON_VALUE(@sys_RawData, '$.Title');
    DECLARE @Preconditions NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.Preconditions');
    DECLARE @TestSteps NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.TestSteps');
    DECLARE @ExpectedResult NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.ExpectedResult');
    DECLARE @ActualResult NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.ActualResult');
    DECLARE @EvidenceUrl NVARCHAR(1000) = JSON_VALUE(@sys_RawData, '$.EvidenceUrl');
    DECLARE @ReportUrl NVARCHAR(1000) = JSON_VALUE(@sys_RawData, '$.ReportUrl');
    DECLARE @TesterType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.TesterType');
    DECLARE @TesterCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.TesterCode');
    DECLARE @TesterName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.TesterName');
    DECLARE @LastTestTime DATETIME = TRY_CONVERT(DATETIME, JSON_VALUE(@sys_RawData, '$.LastTestTime'));
    DECLARE @Status VARCHAR(30) = ISNULL(JSON_VALUE(@sys_RawData, '$.Status'), 'DRAFT');
    DECLARE @Priority VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.Priority');
    DECLARE @PICType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.PICType');
    DECLARE @PICCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.PICCode');
    DECLARE @PICName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.PICName');
    DECLARE @HandlerType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.HandlerType');
    DECLARE @HandlerCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.HandlerCode');
    DECLARE @HandlerName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.HandlerName');
    DECLARE @Note NVARCHAR(1000) = JSON_VALUE(@sys_RawData, '$.Note');

    IF ISNULL(@Title, '') = ''
    BEGIN
        RAISERROR(N'Mục tiêu testcase không được để trống.', 16, 1);
        RETURN;
    END

    IF @AuditTestCaseID = 0
    BEGIN
        INSERT INTO dbo.tblWF_AuditTestCase (TestCaseCode, TestType, ModuleKey, ScreenKey, Title, Preconditions, TestSteps, ExpectedResult, ActualResult, EvidenceUrl, ReportUrl, TesterType, TesterCode, TesterName, LastTestTime, Status, Priority, PICType, PICCode, PICName, HandlerType, HandlerCode, HandlerName, Note, CreateUser, CreateTime, [Enable])
        VALUES (@TestCaseCode, @TestType, @ModuleKey, @ScreenKey, @Title, @Preconditions, @TestSteps, @ExpectedResult, @ActualResult, @EvidenceUrl, @ReportUrl, @TesterType, @TesterCode, @TesterName, @LastTestTime, @Status, @Priority, @PICType, @PICCode, @PICName, @HandlerType, @HandlerCode, @HandlerName, @Note, @sys_UserID, GETDATE(), 0);
        SET @AuditTestCaseID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_AuditTestCase
        SET TestCaseCode = @TestCaseCode, TestType = @TestType, ModuleKey = @ModuleKey, ScreenKey = @ScreenKey, Title = @Title,
            Preconditions = @Preconditions, TestSteps = @TestSteps, ExpectedResult = @ExpectedResult, ActualResult = @ActualResult,
            EvidenceUrl = @EvidenceUrl, ReportUrl = @ReportUrl, TesterType = @TesterType, TesterCode = @TesterCode, TesterName = @TesterName, LastTestTime = @LastTestTime,
            Status = @Status, Priority = @Priority, PICType = @PICType, PICCode = @PICCode, PICName = @PICName,
            HandlerType = @HandlerType, HandlerCode = @HandlerCode, HandlerName = @HandlerName, Note = @Note,
            UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE AuditTestCaseID = @AuditTestCaseID AND [Enable] = 0;
    END

    SELECT Message = N'Lưu testcase thành công.', AuditTestCaseID = @AuditTestCaseID;
END
