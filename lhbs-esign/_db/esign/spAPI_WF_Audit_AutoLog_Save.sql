CREATE PROCEDURE [dbo].[spAPI_WF_Audit_AutoLog_Save]
    @AutoLogID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LogDate DATETIME = TRY_CAST(JSON_VALUE(@sys_RawData, '$.LogDate') AS DATETIME);
    DECLARE @ChangeArea VARCHAR(30) = ISNULL(JSON_VALUE(@sys_RawData, '$.ChangeArea'), 'PROCESS');
    DECLARE @ActionType VARCHAR(30) = ISNULL(JSON_VALUE(@sys_RawData, '$.ActionType'), 'UPDATE');
    DECLARE @ModuleKey VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.ModuleKey');
    DECLARE @ScreenKey VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.ScreenKey');
    DECLARE @Title NVARCHAR(300) = JSON_VALUE(@sys_RawData, '$.Title');
    DECLARE @Detail NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.Detail');
    DECLARE @ChangedFilesJSON NVARCHAR(MAX) = JSON_QUERY(@sys_RawData, '$.ChangedFiles');
    DECLARE @ResultStatus VARCHAR(30) = ISNULL(JSON_VALUE(@sys_RawData, '$.ResultStatus'), 'DONE');
    DECLARE @PICType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.PICType');
    DECLARE @PICCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.PICCode');
    DECLARE @PICName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.PICName');
    DECLARE @HandlerType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.HandlerType');
    DECLARE @HandlerCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.HandlerCode');
    DECLARE @HandlerName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.HandlerName');

    IF ISNULL(@Title, '') = ''
    BEGIN
        RAISERROR(N'Tiêu đề auto log không được để trống.', 16, 1);
        RETURN;
    END

    IF @LogDate IS NULL SET @LogDate = GETDATE();

    IF @AutoLogID = 0
    BEGIN
        INSERT INTO dbo.tblWF_AuditAutoLog
        (
            LogDate, ChangeArea, ActionType, ModuleKey, ScreenKey, Title, Detail, ChangedFilesJSON, ResultStatus,
            PICType, PICCode, PICName, HandlerType, HandlerCode, HandlerName, CreateUser, CreateTime, [Enable]
        )
        VALUES
        (
            @LogDate, @ChangeArea, @ActionType, @ModuleKey, @ScreenKey, @Title, @Detail, @ChangedFilesJSON, @ResultStatus,
            @PICType, @PICCode, @PICName, @HandlerType, @HandlerCode, @HandlerName, @sys_UserID, GETDATE(), 0
        );
        SET @AutoLogID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_AuditAutoLog
        SET LogDate = @LogDate,
            ChangeArea = @ChangeArea,
            ActionType = @ActionType,
            ModuleKey = @ModuleKey,
            ScreenKey = @ScreenKey,
            Title = @Title,
            Detail = @Detail,
            ChangedFilesJSON = @ChangedFilesJSON,
            ResultStatus = @ResultStatus,
            PICType = @PICType,
            PICCode = @PICCode,
            PICName = @PICName,
            HandlerType = @HandlerType,
            HandlerCode = @HandlerCode,
            HandlerName = @HandlerName,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE AutoLogID = @AutoLogID
          AND [Enable] = 0;
    END

    SELECT Message = N'Lưu auto log thành công.', AutoLogID = @AutoLogID;
END
