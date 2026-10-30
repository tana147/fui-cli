CREATE PROCEDURE [dbo].[spAPI_WF_Audit_TestCase_UpdateExecution]
    @AuditTestCaseID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET @AuditTestCaseID = ISNULL(@AuditTestCaseID, 0);

    DECLARE @TestCaseCode VARCHAR(50) = JSON_VALUE(@sys_RawData, '$.TestCaseCode');
    DECLARE @TestType VARCHAR(20) = ISNULL(JSON_VALUE(@sys_RawData, '$.TestType'), 'UI');
    DECLARE @ModuleKey VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.ModuleKey');
    DECLARE @ScreenKey VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.ScreenKey');
    DECLARE @Title NVARCHAR(300) = ISNULL(JSON_VALUE(@sys_RawData, '$.Title'), JSON_VALUE(@sys_RawData, '$.TestCaseCode'));
    DECLARE @Status VARCHAR(30) = ISNULL(JSON_VALUE(@sys_RawData, '$.Status'), 'READY');
    DECLARE @ActualResult NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.ActualResult');
    DECLARE @EvidenceUrl NVARCHAR(1000) = JSON_VALUE(@sys_RawData, '$.EvidenceUrl');
    DECLARE @ReportUrl NVARCHAR(1000) = JSON_VALUE(@sys_RawData, '$.ReportUrl');
    DECLARE @TesterType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.TesterType');
    DECLARE @TesterCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.TesterCode');
    DECLARE @TesterName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.TesterName');

    IF @AuditTestCaseID = 0 AND ISNULL(@TestCaseCode, '') <> ''
    BEGIN
        SELECT TOP 1 @AuditTestCaseID = AuditTestCaseID
        FROM dbo.tblWF_AuditTestCase
        WHERE TestCaseCode = @TestCaseCode AND [Enable] = 0
        ORDER BY AuditTestCaseID DESC;
    END

    IF @AuditTestCaseID = 0
    BEGIN
        INSERT INTO dbo.tblWF_AuditTestCase
        (
            TestCaseCode, TestType, ModuleKey, ScreenKey, Title,
            ActualResult, EvidenceUrl, ReportUrl,
            TesterType, TesterCode, TesterName, LastTestTime,
            Status, HandlerType, HandlerCode, HandlerName,
            CreateUser, CreateTime, [Enable]
        )
        VALUES
        (
            @TestCaseCode, @TestType, @ModuleKey, @ScreenKey, @Title,
            @ActualResult, @EvidenceUrl, @ReportUrl,
            @TesterType, @TesterCode, @TesterName, GETDATE(),
            @Status, 'AGENT', 'CODEX', N'Codex',
            @sys_UserID, GETDATE(), 0
        );
        SET @AuditTestCaseID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_AuditTestCase
        SET TestType = ISNULL(@TestType, TestType),
            ModuleKey = ISNULL(@ModuleKey, ModuleKey),
            ScreenKey = ISNULL(@ScreenKey, ScreenKey),
            Title = ISNULL(@Title, Title),
            ActualResult = ISNULL(@ActualResult, ActualResult),
            EvidenceUrl = ISNULL(@EvidenceUrl, EvidenceUrl),
            ReportUrl = ISNULL(@ReportUrl, ReportUrl),
            TesterType = ISNULL(@TesterType, TesterType),
            TesterCode = ISNULL(@TesterCode, TesterCode),
            TesterName = ISNULL(@TesterName, TesterName),
            LastTestTime = GETDATE(),
            Status = ISNULL(@Status, Status),
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE AuditTestCaseID = @AuditTestCaseID AND [Enable] = 0;
    END

    SELECT Message = N'Cập nhật kết quả testcase thành công.', AuditTestCaseID = @AuditTestCaseID;
END
