CREATE PROCEDURE [dbo].[spAPI_WF_Audit_SpecChange_Save]
    @SpecChangeID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ChangeDate DATE = TRY_CAST(JSON_VALUE(@sys_RawData, '$.ChangeDate') AS DATE);
    DECLARE @ChangeType VARCHAR(30) = ISNULL(JSON_VALUE(@sys_RawData, '$.ChangeType'), 'REQUEST');
    DECLARE @Title NVARCHAR(300) = JSON_VALUE(@sys_RawData, '$.Title');
    DECLARE @PreviousSpec NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.PreviousSpec');
    DECLARE @NewSpec NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.NewSpec');
    DECLARE @ImpactModules NVARCHAR(500) = JSON_VALUE(@sys_RawData, '$.ImpactModules');
    DECLARE @Status VARCHAR(30) = ISNULL(JSON_VALUE(@sys_RawData, '$.Status'), 'APPLIED');
    DECLARE @PICType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.PICType');
    DECLARE @PICCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.PICCode');
    DECLARE @PICName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.PICName');
    DECLARE @HandlerType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.HandlerType');
    DECLARE @HandlerCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.HandlerCode');
    DECLARE @HandlerName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.HandlerName');
    DECLARE @Note NVARCHAR(1000) = JSON_VALUE(@sys_RawData, '$.Note');

    IF ISNULL(@Title, '') = ''
    BEGIN
        RAISERROR(N'Tiêu đề changed spec không được để trống.', 16, 1);
        RETURN;
    END

    IF @ChangeDate IS NULL SET @ChangeDate = CAST(GETDATE() AS DATE);

    IF @SpecChangeID = 0
    BEGIN
        INSERT INTO dbo.tblWF_AuditSpecChange
        (
            ChangeDate, ChangeType, Title, PreviousSpec, NewSpec, ImpactModules, Status,
            PICType, PICCode, PICName, HandlerType, HandlerCode, HandlerName, Note,
            CreateUser, CreateTime, [Enable]
        )
        VALUES
        (
            @ChangeDate, @ChangeType, @Title, @PreviousSpec, @NewSpec, @ImpactModules, @Status,
            @PICType, @PICCode, @PICName, @HandlerType, @HandlerCode, @HandlerName, @Note,
            @sys_UserID, GETDATE(), 0
        );
        SET @SpecChangeID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_AuditSpecChange
        SET ChangeDate = @ChangeDate,
            ChangeType = @ChangeType,
            Title = @Title,
            PreviousSpec = @PreviousSpec,
            NewSpec = @NewSpec,
            ImpactModules = @ImpactModules,
            Status = @Status,
            PICType = @PICType,
            PICCode = @PICCode,
            PICName = @PICName,
            HandlerType = @HandlerType,
            HandlerCode = @HandlerCode,
            HandlerName = @HandlerName,
            Note = @Note,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE SpecChangeID = @SpecChangeID
          AND [Enable] = 0;
    END

    SELECT Message = N'Lưu changed spec thành công.', SpecChangeID = @SpecChangeID;
END
