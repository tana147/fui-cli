
CREATE PROCEDURE [dbo].[spAPI_WF_RequestDraft_Save]
    @DraftID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CreateMode VARCHAR(20) = UPPER(ISNULL(JSON_VALUE(@sys_RawData, '$.CreateMode'), 'FREE_SIGN'));
    DECLARE @DefinitionID BIGINT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.DefinitionID') AS BIGINT);
    DECLARE @CategoryID INT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.CategoryID') AS INT);
    DECLARE @DraftName NVARCHAR(200) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.InstanceName'), '')));
    DECLARE @ReferenceCode VARCHAR(50) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.ReferenceCode'), '')));
    DECLARE @Description NVARCHAR(500) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.Description'), '')));
    DECLARE @ExecutionEngine VARCHAR(20) = UPPER(ISNULL(JSON_VALUE(@sys_RawData, '$.ExecutionEngine'), 'SMARTCA'));
    DECLARE @ContractProvider VARCHAR(50) = ISNULL(JSON_VALUE(@sys_RawData, '$.ContractProvider'), '');
    DECLARE @FileMethod VARCHAR(20) = UPPER(ISNULL(JSON_VALUE(@sys_RawData, '$.FileMethod'), 'UPLOAD'));
    DECLARE @SourceFileID UNIQUEIDENTIFIER = TRY_CAST(JSON_VALUE(@sys_RawData, '$.FileID') AS UNIQUEIDENTIFIER);
    DECLARE @SourceFileName NVARCHAR(255) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.UploadFileName'), '')));
    DECLARE @TemplateID BIGINT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.TemplateID') AS BIGINT);
    DECLARE @DueDate DATETIME = TRY_CAST(JSON_VALUE(@sys_RawData, '$.DueDate') AS DATETIME);
    DECLARE @Priority VARCHAR(20) = UPPER(ISNULL(JSON_VALUE(@sys_RawData, '$.Priority'), 'NORMAL'));
    DECLARE @Sequential BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.Sequential') AS BIT), 1);
    DECLARE @NotifyEmail BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.NotifyEmail') AS BIT), 1);
    DECLARE @RequireOtpConfirm BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.RequireOtpConfirm') AS BIT), 0);

    SET @ExecutionEngine = UPPER(LTRIM(RTRIM(ISNULL(@ExecutionEngine, 'SMARTCA'))));
    IF @ExecutionEngine <> 'ECONTRACT'
        SET @ExecutionEngine = 'SMARTCA';

    SET @ContractProvider = UPPER(LTRIM(RTRIM(ISNULL(@ContractProvider, ''))));
    IF @ContractProvider = 'VNPT'
        SET @ContractProvider = 'VNPT_ECONTRACT';
    IF @ContractProvider IN ('AMIS', 'WESIGN')
        SET @ContractProvider = 'AMIS_WESIGN';

    IF EXISTS (
        SELECT 1
        FROM OPENJSON(@sys_RawData, '$.Signers') AS J
        WHERE
            LOWER(ISNULL(JSON_VALUE(J.[value], '$.SignMethod'), '')) LIKE '%econtract%'
            OR LOWER(ISNULL(JSON_VALUE(J.[value], '$.SignMethod'), '')) LIKE '%otp%'
            OR LOWER(ISNULL(JSON_VALUE(J.[value], '$.SignMethod'), '')) LIKE '%image%'
            OR LOWER(ISNULL(JSON_VALUE(J.[value], '$.SignMethod'), '')) LIKE N'%ký ảnh%'
    )
        SET @ExecutionEngine = 'ECONTRACT';

    IF @DraftName = N''
    BEGIN
        RAISERROR(N'Tên draft không được để trống.', 16, 1);
        RETURN;
    END

    IF @ExecutionEngine = 'ECONTRACT' AND ISNULL(@ContractProvider, '') = ''
    BEGIN
        RAISERROR(N'Draft eContract cần chọn nhà cung cấp (VNPT eContract hoặc AMIS WeSign).', 16, 1);
        RETURN;
    END

    IF ISNULL(@ContractProvider, '') <> '' AND @ContractProvider NOT IN ('VNPT_ECONTRACT', 'AMIS_WESIGN')
    BEGIN
        RAISERROR(N'Nhà cung cấp eContract không hợp lệ. Chỉ hỗ trợ VNPT_ECONTRACT hoặc AMIS_WESIGN.', 16, 1);
        RETURN;
    END

    IF @ExecutionEngine <> 'ECONTRACT'
        SET @ContractProvider = '';

    BEGIN TRY
        BEGIN TRANSACTION;

        IF ISNULL(@DraftID, 0) <= 0
        BEGIN
            INSERT INTO dbo.tblWF_RequestDraft
            (
                CreateMode, DefinitionID, CategoryID, DraftName, ReferenceCode, Description,
                ExecutionEngine, ContractProvider, FileMethod, SourceFileID, SourceFileName,
                TemplateID, DueDate, Priority, Sequential, NotifyEmail, RequireOtpConfirm,
                SubmittedInstanceID, Status, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
            )
            VALUES
            (
                @CreateMode, @DefinitionID, @CategoryID, @DraftName, @ReferenceCode, @Description,
                @ExecutionEngine, NULLIF(@ContractProvider, ''), @FileMethod, @SourceFileID, @SourceFileName,
                @TemplateID, @DueDate, @Priority, @Sequential, @NotifyEmail, @RequireOtpConfirm,
                NULL, 'DRAFT', @sys_UserID, GETDATE(), NULL, NULL, 0
            );

            SET @DraftID = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.tblWF_RequestDraft
            SET CreateMode = @CreateMode,
                DefinitionID = @DefinitionID,
                CategoryID = @CategoryID,
                DraftName = @DraftName,
                ReferenceCode = @ReferenceCode,
                Description = @Description,
                ExecutionEngine = @ExecutionEngine,
                ContractProvider = NULLIF(@ContractProvider, ''),
                FileMethod = @FileMethod,
                SourceFileID = @SourceFileID,
                SourceFileName = @SourceFileName,
                TemplateID = @TemplateID,
                DueDate = @DueDate,
                Priority = @Priority,
                Sequential = @Sequential,
                NotifyEmail = @NotifyEmail,
                RequireOtpConfirm = @RequireOtpConfirm,
                Status = 'DRAFT',
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            WHERE DraftID = @DraftID
              AND [Enable] = 0;

            IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR(N'Không tìm thấy draft cần lưu.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            UPDATE dbo.tblWF_RequestDraftField SET [Enable] = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE() WHERE DraftID = @DraftID AND [Enable] = 0;
            UPDATE dbo.tblWF_RequestDraftSigner SET [Enable] = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE() WHERE DraftID = @DraftID AND [Enable] = 0;
            UPDATE dbo.tblWF_RequestDraftBox SET [Enable] = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE() WHERE DraftID = @DraftID AND [Enable] = 0;
        END

        INSERT INTO dbo.tblWF_RequestDraftField
        (
            DraftID, FieldName, FieldLabel, FieldValue, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        SELECT
            @DraftID,
            JSON_VALUE(J.[value], '$.FieldName'),
            JSON_VALUE(J.[value], '$.FieldLabel'),
            JSON_VALUE(J.[value], '$.Value'),
            @sys_UserID,
            GETDATE(),
            NULL,
            NULL,
            0
        FROM OPENJSON(@sys_RawData, '$.FieldValues') AS J
        WHERE ISNULL(JSON_VALUE(J.[value], '$.FieldName'), '') <> '';

        INSERT INTO dbo.tblWF_RequestDraftSigner
        (
            DraftID, SignerOrder, StepOrder, StepName, SignerType, SignerValue, PersonName,
            DepartmentName, SignMethod, ExecutionEngine, ContractProvider,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        SELECT
            @DraftID,
            ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.SignOrder') AS INT), 1),
            TRY_CAST(JSON_VALUE(J.[value], '$.StepOrder') AS INT),
            JSON_VALUE(J.[value], '$.StepName'),
            ISNULL(JSON_VALUE(J.[value], '$.SignerType'), 'ROLE'),
            JSON_VALUE(J.[value], '$.SignerValue'),
            JSON_VALUE(J.[value], '$.PersonName'),
            JSON_VALUE(J.[value], '$.DepartmentName'),
            JSON_VALUE(J.[value], '$.SignMethod'),
            @ExecutionEngine,
            NULLIF(@ContractProvider, ''),
            @sys_UserID, GETDATE(), NULL, NULL, 0
        FROM OPENJSON(@sys_RawData, '$.Signers') AS J;

        INSERT INTO dbo.tblWF_RequestDraftBox
        (
            DraftID, BoxOrder, PageNo, PosX, PosY, BoxWidth, BoxHeight, StepOrder, SignerOrder,
            SignerType, SignerValue, PersonName, DepartmentName, SignMethod,
            ExecutionEngine, ContractProvider, LabelText, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        SELECT
            @DraftID,
            ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.BoxOrder') AS INT), ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
            ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.PageNo') AS INT), 1),
            ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.PosX') AS FLOAT), 0),
            ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.PosY') AS FLOAT), 0),
            ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.BoxWidth') AS FLOAT), 180),
            ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.BoxHeight') AS FLOAT), 64),
            TRY_CAST(JSON_VALUE(J.[value], '$.StepOrder') AS INT),
            TRY_CAST(JSON_VALUE(J.[value], '$.SignerOrder') AS INT),
            ISNULL(JSON_VALUE(J.[value], '$.SignerType'), 'ROLE'),
            JSON_VALUE(J.[value], '$.SignerValue'),
            JSON_VALUE(J.[value], '$.PersonName'),
            JSON_VALUE(J.[value], '$.DepartmentName'),
            JSON_VALUE(J.[value], '$.SignMethod'),
            @ExecutionEngine,
            NULLIF(@ContractProvider, ''),
            JSON_VALUE(J.[value], '$.LabelText'),
            @sys_UserID, GETDATE(), NULL, NULL, 0
        FROM OPENJSON(@sys_RawData, '$.SignBoxes') AS J;

        COMMIT TRANSACTION;

        SELECT Message = N'Lưu draft yêu cầu ký thành công.', DraftID = @DraftID, Status = 'DRAFT';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END
