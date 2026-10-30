CREATE PROCEDURE [dbo].[spAPI_WF_Audit_Backlog_Save]
    @BacklogID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @WorkDate DATE = TRY_CAST(JSON_VALUE(@sys_RawData, '$.WorkDate') AS DATE);
    DECLARE @WorkType VARCHAR(30) = ISNULL(JSON_VALUE(@sys_RawData, '$.WorkType'), 'REQUEST');
    DECLARE @Title NVARCHAR(300) = JSON_VALUE(@sys_RawData, '$.Title');
    DECLARE @Detail NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.Detail');
    DECLARE @Status VARCHAR(30) = ISNULL(JSON_VALUE(@sys_RawData, '$.Status'), 'TODO');
    DECLARE @PICType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.PICType');
    DECLARE @PICCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.PICCode');
    DECLARE @PICName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.PICName');
    DECLARE @HandlerType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.HandlerType');
    DECLARE @HandlerCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.HandlerCode');
    DECLARE @HandlerName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.HandlerName');
    DECLARE @SourceFile NVARCHAR(300) = JSON_VALUE(@sys_RawData, '$.SourceFile');

    IF ISNULL(@Title, '') = ''
    BEGIN
        RAISERROR(N'Tiêu đề backlog không được để trống.', 16, 1);
        RETURN;
    END

    IF @WorkDate IS NULL SET @WorkDate = CAST(GETDATE() AS DATE);

    IF @BacklogID = 0
    BEGIN
        INSERT INTO dbo.tblWF_AuditBacklog (WorkDate, WorkType, Title, Detail, Status, PICType, PICCode, PICName, HandlerType, HandlerCode, HandlerName, SourceFile, CreateUser, CreateTime, [Enable])
        VALUES (@WorkDate, @WorkType, @Title, @Detail, @Status, @PICType, @PICCode, @PICName, @HandlerType, @HandlerCode, @HandlerName, @SourceFile, @sys_UserID, GETDATE(), 0);
        SET @BacklogID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_AuditBacklog
        SET WorkDate = @WorkDate, WorkType = @WorkType, Title = @Title, Detail = @Detail, Status = @Status,
            PICType = @PICType, PICCode = @PICCode, PICName = @PICName,
            HandlerType = @HandlerType, HandlerCode = @HandlerCode, HandlerName = @HandlerName,
            SourceFile = @SourceFile, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE BacklogID = @BacklogID AND [Enable] = 0;
    END

    SELECT Message = N'Lưu backlog thành công.', BacklogID = @BacklogID;
END
