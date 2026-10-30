CREATE PROCEDURE [dbo].[spAPI_WF_Request_Create]
    @DefinitionID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CreateMode VARCHAR(20) = UPPER(ISNULL(JSON_VALUE(@sys_RawData, '$.CreateMode'), 'TEMPLATE_FLOW'));
    DECLARE @InstanceName NVARCHAR(200) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.InstanceName'), '')));
    DECLARE @ReferenceCode VARCHAR(50) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.ReferenceCode'), '')));
    DECLARE @Description NVARCHAR(500) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.Description'), '')));
    DECLARE @CategoryID INT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.CategoryID') AS INT);
    DECLARE @FileMethod VARCHAR(20) = UPPER(ISNULL(JSON_VALUE(@sys_RawData, '$.FileMethod'), 'TEMPLATE'));
    DECLARE @TemplateID BIGINT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.TemplateID') AS BIGINT);
    DECLARE @FileID UNIQUEIDENTIFIER = TRY_CAST(JSON_VALUE(@sys_RawData, '$.FileID') AS UNIQUEIDENTIFIER);
    DECLARE @UploadFileName NVARCHAR(255) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.UploadFileName'), '')));
    DECLARE @Priority VARCHAR(20) = UPPER(ISNULL(JSON_VALUE(@sys_RawData, '$.Priority'), 'NORMAL'));
    DECLARE @DueDate DATETIME = TRY_CAST(JSON_VALUE(@sys_RawData, '$.DueDate') AS DATETIME);
    DECLARE @Sequential BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.Sequential') AS BIT), 1);
    DECLARE @NotifyEmail BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.NotifyEmail') AS BIT), 1);
    DECLARE @RequireOtpConfirm BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.RequireOtpConfirm') AS BIT), 0);
    DECLARE @ExecutionEngine VARCHAR(20) = UPPER(ISNULL(JSON_VALUE(@sys_RawData, '$.ExecutionEngine'), 'SMARTCA'));
    DECLARE @ContractProvider VARCHAR(50) = ISNULL(JSON_VALUE(@sys_RawData, '$.ContractProvider'), '');
    DECLARE @DefinitionVersion INT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.DefinitionVersion') AS INT);
    DECLARE @AssigneeCode NVARCHAR(9) = NULLIF(LTRIM(RTRIM(JSON_VALUE(@sys_RawData, '$.AssigneeCode'))), '');
    DECLARE @StartStepDefID BIGINT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.StartStepDefID') AS BIGINT);
    DECLARE @Now DATETIME = GETDATE();
    DECLARE @InstanceID BIGINT = 0;
    DECLARE @CurrentStepOrder INT = 1;
    DECLARE @InstanceStatus VARCHAR(20) = 'RUNNING';
    DECLARE @DefinitionName NVARCHAR(200) = N'';
    DECLARE @DefinitionActive BIT = 0;
    DECLARE @InitialStepOrder INT = 1;
    DECLARE @InitialStepType VARCHAR(20) = 'SIGN';
    DECLARE @ActionStepOrder INT = 1;
    DECLARE @FallbackSignerStepOrder INT = 1;
    DECLARE @ActiveExecutionID BIGINT = NULL;
    DECLARE @WaitingForMe BIT = 0;
    DECLARE @DefaultSignSystem VARCHAR(20) = NULL;
    DECLARE @SourceFileName NVARCHAR(255) = NULL;
    DECLARE @DefaultAssignerID VARCHAR(9) = NULL;
    DECLARE @CreatorEmployeeCode VARCHAR(9) = NULL;

    -- Lấy EmployeeCode cho người tạo (vì @sys_UserID là UserID dạng VARCHAR)
    SELECT TOP 1 @CreatorEmployeeCode = EmployeeCode
    FROM dbo.tblWF_User
    WHERE UserID = TRY_CAST(@sys_UserID AS BIGINT)
      AND [Enable] = 1;

    IF @CreatorEmployeeCode IS NULL
    BEGIN
        SELECT TOP 1 @CreatorEmployeeCode = EmployeeCode
        FROM dbo.tblWF_User
        WHERE EmployeeCode = @sys_UserID
          AND [Enable] = 1;
    END

    SET @CreatorEmployeeCode = ISNULL(@CreatorEmployeeCode, @sys_UserID);

    IF @CreateMode NOT IN ('TEMPLATE_FLOW', 'FREE_SIGN')
        SET @CreateMode = 'TEMPLATE_FLOW';

    SET @ExecutionEngine = UPPER(LTRIM(RTRIM(ISNULL(@ExecutionEngine, 'SMARTCA'))));
    IF @ExecutionEngine <> 'ECONTRACT'
        SET @ExecutionEngine = 'SMARTCA';

    SET @ContractProvider = UPPER(LTRIM(RTRIM(ISNULL(@ContractProvider, ''))));
    IF @ContractProvider = 'VNPT'
        SET @ContractProvider = 'VNPT_ECONTRACT';
    IF @ContractProvider IN ('AMIS', 'WESIGN')
        SET @ContractProvider = 'AMIS_WESIGN';

    IF @CreateMode = 'FREE_SIGN'
        SET @FileMethod = 'UPLOAD';

    IF @CreateMode = 'TEMPLATE_FLOW' AND (ISNULL(@DefinitionID, 0) <= 0)
    BEGIN
        RAISERROR(N'Workflow không hợp lệ.', 16, 1);
        RETURN;
    END

    IF @CreateMode = 'FREE_SIGN' AND @InstanceName = N''
    BEGIN
        RAISERROR(N'Tên văn bản ký tự do không được để trống.', 16, 1);
        RETURN;
    END

    IF @FileMethod = 'UPLOAD' AND @FileID IS NULL
    BEGIN
        RAISERROR(N'Bạn cần upload file trước khi gửi yêu cầu ký.', 16, 1);
        RETURN;
    END

    -- [MULTI-TEMPLATE] Chỉ validate TemplateID đơn khi definition KHÔNG có step nào dùng TemplatesJSON
    IF @CreateMode = 'TEMPLATE_FLOW' AND @FileMethod = 'TEMPLATE' AND ISNULL(@TemplateID, 0) <= 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.tblWF_StepDefinition
            WHERE DefinitionID = @DefinitionID AND TemplatesJSON IS NOT NULL AND [Enable] = 1
        )
        BEGIN
            RAISERROR(N'Luồng theo template yêu cầu chọn template hợp lệ.', 16, 1);
            RETURN;
        END
    END

    -- [MULTI-TEMPLATE] Tương tự: bỏ qua kiểm tra template tồn tại khi dùng multi-template
    IF @CreateMode = 'TEMPLATE_FLOW' AND @FileMethod = 'TEMPLATE' AND ISNULL(@TemplateID, 0) > 0
       AND NOT EXISTS (
            SELECT 1
            FROM dbo.tblWF_Template AS T
            WHERE T.TemplateID = @TemplateID
              AND T.[Enable] = 1
              AND ISNULL(T.IsActive, 1) = 1
       )
    BEGIN
        RAISERROR(N'Template đã chọn không tồn tại hoặc đang tạm dừng.', 16, 1);
        RETURN;
    END

    IF @CreateMode = 'TEMPLATE_FLOW'
    BEGIN
        SELECT
            @DefinitionName = D.Name,
            @DefinitionActive = D.IsActive,
            @CategoryID = ISNULL(@CategoryID, D.CategoryID),
            @DefaultAssignerID = NULLIF(LTRIM(RTRIM(D.AssignerID)), '')
        FROM dbo.tblWF_Definition AS D
        WHERE D.DefinitionID = @DefinitionID
          AND D.[Enable] = 1;

        IF ISNULL(@DefinitionName, N'') = N''
        BEGIN
            RAISERROR(N'Không tìm thấy workflow cần tạo yêu cầu ký.', 16, 1);
            RETURN;
        END

        IF ISNULL(@DefinitionActive, 0) = 0
        BEGIN
            RAISERROR(N'Workflow đang tạm dừng, không thể tạo yêu cầu ký.', 16, 1);
            RETURN;
        END

        IF @InstanceName = N''
            SET @InstanceName = @DefinitionName;
    END
    ELSE
    BEGIN
        SET @DefinitionID = NULL;
        SET @DefinitionName = N'Ký tự do';
        SET @DefinitionVersion = NULL;
    END

    SET @SourceFileName =
        CASE
            WHEN ISNULL(@UploadFileName, N'') <> N'' THEN @UploadFileName
            WHEN @CreateMode = 'FREE_SIGN' THEN @InstanceName + N'.pdf'
            ELSE NULL
        END;

    DECLARE @PayloadFields TABLE
    (
        FieldName VARCHAR(50) NOT NULL,
        FieldLabel NVARCHAR(200) NULL,
        FieldValue NVARCHAR(MAX) NULL
    );

    INSERT INTO @PayloadFields (FieldName, FieldLabel, FieldValue)
    SELECT
        JSON_VALUE(J.[value], '$.FieldName'),
        JSON_VALUE(J.[value], '$.FieldLabel'),
        JSON_VALUE(J.[value], '$.Value')
    FROM OPENJSON(@sys_RawData, '$.FieldValues') AS J
    WHERE ISNULL(JSON_VALUE(J.[value], '$.FieldName'), '') <> '';

    DECLARE @PayloadSigners TABLE
    (
        RowNo INT IDENTITY(1,1) PRIMARY KEY,
        SignOrder INT NOT NULL,
        StepOrder INT NULL,
        StepName NVARCHAR(200) NULL,
        SignerType VARCHAR(20) NULL,
        SignerValue VARCHAR(50) NULL,
        PersonName NVARCHAR(200) NULL,
        SignMethod VARCHAR(100) NULL,
        DepartmentName NVARCHAR(200) NULL,
        TemplateSlotIdx INT NULL  -- [MULTI-TEMPLATE] slot index trong TemplatesJSON của step
    );

    INSERT INTO @PayloadSigners
    (
        SignOrder, StepOrder, StepName, SignerType, SignerValue, PersonName, SignMethod, DepartmentName,
        TemplateSlotIdx  -- [MULTI-TEMPLATE]
    )
    SELECT
        ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.SignOrder') AS INT), 1),
        TRY_CAST(JSON_VALUE(J.[value], '$.StepOrder') AS INT),
        JSON_VALUE(J.[value], '$.StepName'),
        ISNULL(JSON_VALUE(J.[value], '$.SignerType'), 'ROLE'),
        JSON_VALUE(J.[value], '$.SignerValue'),
        JSON_VALUE(J.[value], '$.PersonName'),
        JSON_VALUE(J.[value], '$.SignMethod'),
        JSON_VALUE(J.[value], '$.DepartmentName'),
        TRY_CAST(JSON_VALUE(J.[value], '$.TemplateSlotIdx') AS INT)  -- [MULTI-TEMPLATE]
    FROM OPENJSON(@sys_RawData, '$.Signers') AS J;

    IF @CreateMode = 'TEMPLATE_FLOW'
       AND EXISTS (
            SELECT 1
            FROM @PayloadSigners
            WHERE ISNULL(LTRIM(RTRIM(SignerValue)), '') = ''
               OR ISNULL(LTRIM(RTRIM(SignMethod)), '') = ''
       )
    BEGIN
        RAISERROR(N'Danh sách người ký theo template có dòng chưa chọn người ký hoặc phương thức ký.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM @PayloadSigners
        WHERE
            LOWER(ISNULL(SignMethod, '')) LIKE '%econtract%'
            OR LOWER(ISNULL(SignMethod, '')) LIKE '%otp%'
            OR LOWER(ISNULL(SignMethod, '')) LIKE '%image%'
            OR LOWER(ISNULL(SignMethod, '')) LIKE N'%ký ảnh%'
    )
        SET @ExecutionEngine = 'ECONTRACT';

    DECLARE @PayloadSignBoxes TABLE
    (
        RowNo INT IDENTITY(1,1) PRIMARY KEY,
        BoxOrder INT NOT NULL,
        PageNo INT NOT NULL,
        PosX FLOAT NOT NULL,
        PosY FLOAT NOT NULL,
        BoxWidth FLOAT NOT NULL,
        BoxHeight FLOAT NOT NULL,
        StepOrder INT NULL,
        SignerOrder INT NULL,
        SignerType VARCHAR(20) NULL,
        SignerValue VARCHAR(50) NULL,
        PersonName NVARCHAR(200) NULL,
        DepartmentName NVARCHAR(200) NULL,
        SignMethod VARCHAR(100) NULL,
        ExecutionEngine VARCHAR(20) NULL,
        ContractProvider VARCHAR(50) NULL,
        LabelText NVARCHAR(200) NULL
    );

    DECLARE @SignerSeed TABLE
    (
        RowNo INT IDENTITY(1,1) PRIMARY KEY,
        SignOrder INT NOT NULL,
        SignerType VARCHAR(20) NULL,
        SignerValue VARCHAR(50) NULL,
        PersonName NVARCHAR(200) NULL,
        DepartmentName NVARCHAR(200) NULL,
        SignMethodRaw VARCHAR(100) NULL,
        TemplateSlotIdx INT NULL  -- [MULTI-TEMPLATE]
    );

    DECLARE @FieldMappingSigners TABLE (
        FieldName VARCHAR(255),
        SignerOrder INT
    );

    IF @DefinitionID IS NOT NULL
    BEGIN
        INSERT INTO @FieldMappingSigners (FieldName, SignerOrder)
        SELECT FieldName, ROW_NUMBER() OVER(ORDER BY MappingID)
        FROM dbo.tblWF_FieldMapping
        WHERE DefinitionID = @DefinitionID AND FieldType = 'signature' AND [Enable] = 1;
    END

    INSERT INTO @PayloadSignBoxes
    (
        BoxOrder, PageNo, PosX, PosY, BoxWidth, BoxHeight, StepOrder, SignerOrder,
        SignerType, SignerValue, PersonName, DepartmentName, SignMethod, ExecutionEngine,
        ContractProvider, LabelText
    )
    SELECT
        ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.BoxOrder') AS INT), ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
        ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.PageNo') AS INT), 1),
        ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.PosX') AS FLOAT), 0),
        ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.PosY') AS FLOAT), 0),
        ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.BoxWidth') AS FLOAT), 180),
        ISNULL(TRY_CAST(JSON_VALUE(J.[value], '$.BoxHeight') AS FLOAT), 64),
        TRY_CAST(JSON_VALUE(J.[value], '$.StepOrder') AS INT),
        ISNULL((SELECT TOP 1 SignerOrder FROM @FieldMappingSigners WHERE FieldName = JSON_VALUE(J.[value], '$.LabelText')), TRY_CAST(JSON_VALUE(J.[value], '$.SignerOrder') AS INT)),
        ISNULL(JSON_VALUE(J.[value], '$.SignerType'), 'ROLE'),
        JSON_VALUE(J.[value], '$.SignerValue'),
        JSON_VALUE(J.[value], '$.PersonName'),
        JSON_VALUE(J.[value], '$.DepartmentName'),
        JSON_VALUE(J.[value], '$.SignMethod'),
        UPPER(ISNULL(JSON_VALUE(J.[value], '$.ExecutionEngine'), @ExecutionEngine)),
        ISNULL(JSON_VALUE(J.[value], '$.ContractProvider'), @ContractProvider),
        JSON_VALUE(J.[value], '$.LabelText')
    FROM OPENJSON(@sys_RawData, '$.SignBoxes') AS J;

    IF NOT EXISTS (SELECT 1 FROM @PayloadSignBoxes) AND @TemplateID IS NOT NULL
    BEGIN
        DECLARE @PlaceholderJSON NVARCHAR(MAX);
        SELECT @PlaceholderJSON = PlaceholderJSON
        FROM dbo.tblWF_Template
        WHERE TemplateID = @TemplateID AND [Enable] = 1;

        IF @PlaceholderJSON IS NOT NULL
        BEGIN
            DECLARE @ParsedTokens TABLE (
                RowNo INT IDENTITY(1,1) PRIMARY KEY,
                Token NVARCHAR(200),
                SignerOrder INT
            );

            INSERT INTO @ParsedTokens (Token, SignerOrder)
            SELECT
                J.[value] AS Token,
                CASE
                    WHEN J.[value] LIKE '%[0-9]%' THEN
                        TRY_CAST(SUBSTRING(J.[value], PATINDEX('%[0-9]%', J.[value]), 1) AS INT)
                    ELSE 1
                END AS SignerOrder
            FROM OPENJSON(@PlaceholderJSON) AS J
            WHERE J.[value] LIKE 'sig%' OR J.[value] LIKE 'ky%'
            ORDER BY
                CASE
                    WHEN J.[value] LIKE '%[0-9]%' THEN
                        TRY_CAST(SUBSTRING(J.[value], PATINDEX('%[0-9]%', J.[value]), 1) AS INT)
                    ELSE 1
                END,
                J.[value];

            DECLARE @WorkflowSigners TABLE (
                RowNo INT IDENTITY(1,1) PRIMARY KEY,
                StepOrder INT,
                SignerOrder INT,
                SignMethod VARCHAR(100)
            );

            INSERT INTO @WorkflowSigners (StepOrder, SignerOrder, SignMethod)
            SELECT S.StepOrder, ROW_NUMBER() OVER(ORDER BY FM.MappingID),
                CASE WHEN ISJSON(FM.FieldOptions) = 1 THEN ISNULL(JSON_VALUE(FM.FieldOptions, '$.provider'), 'smartca') ELSE 'smartca' END
            FROM dbo.tblWF_FieldMapping AS FM
            CROSS JOIN (SELECT TOP 1 StepOrder FROM dbo.tblWF_StepDefinition WHERE DefinitionID = @DefinitionID AND StepType IN ('SIGN', 'ECONTRACT') AND [Enable]=1 ORDER BY StepOrder) AS S
            WHERE FM.DefinitionID = @DefinitionID
              AND FM.[Enable] = 1
              AND FM.FieldType = 'signature'
            ORDER BY S.StepOrder, FM.MappingID;

            INSERT INTO @PayloadSignBoxes
            (
                BoxOrder, PageNo, PosX, PosY, BoxWidth, BoxHeight, StepOrder, SignerOrder,
                SignerType, SignerValue, PersonName, DepartmentName, SignMethod, ExecutionEngine,
                ContractProvider, LabelText
            )
            SELECT
                PT.RowNo AS BoxOrder,
                1 AS PageNo,
                14 + ((PT.SignerOrder - 1) % 2) * 41 AS PosX,
                68 + ((PT.SignerOrder - 1) / 2) * 11 AS PosY,
                32 AS BoxWidth,
                9 AS BoxHeight,
                ISNULL(WS.StepOrder, ISNULL((SELECT MAX(S.StepOrder) FROM dbo.tblWF_StepSignerDef AS SD INNER JOIN dbo.tblWF_StepDefinition AS S ON S.StepDefID = SD.StepDefID WHERE S.DefinitionID = @DefinitionID AND S.[Enable] = 1 AND SD.[Enable] = 1 AND ISNULL(SD.SignMethod, 'none') <> 'none'), 1)) AS StepOrder,
                ISNULL(WS.SignerOrder, PT.SignerOrder) AS SignerOrder,
                'ROLE' AS SignerType,
                NULL AS SignerValue,
                NULL AS PersonName,
                NULL AS DepartmentName,
                NULL AS SignMethod,
                @ExecutionEngine,
                @ContractProvider,
                PT.Token AS LabelText
            FROM @ParsedTokens AS PT
            LEFT JOIN @WorkflowSigners AS WS ON WS.RowNo = PT.RowNo;
        END
    END

    IF @CreateMode = 'FREE_SIGN' AND NOT EXISTS (SELECT 1 FROM @PayloadSigners)
    BEGIN
        RAISERROR(N'Ký tự do yêu cầu tối thiểu một người ký.', 16, 1);
        RETURN;
    END

    IF @ExecutionEngine = 'ECONTRACT' AND ISNULL(@ContractProvider, '') = ''
    BEGIN
        RAISERROR(N'Yêu cầu eContract cần chọn nhà cung cấp (VNPT eContract hoặc AMIS WeSign).', 16, 1);
        RETURN;
    END

    IF ISNULL(@ContractProvider, '') <> '' AND @ContractProvider NOT IN ('VNPT_ECONTRACT', 'AMIS_WESIGN')
    BEGIN
        RAISERROR(N'Nhà cung cấp eContract không hợp lệ. Chỉ hỗ trợ VNPT_ECONTRACT hoặc AMIS_WESIGN.', 16, 1);
        RETURN;
    END

    IF @ExecutionEngine <> 'ECONTRACT'
        SET @ContractProvider = '';

    IF @CreateMode = 'FREE_SIGN' AND EXISTS (SELECT 1 FROM @PayloadSignBoxes) AND NOT EXISTS (SELECT 1 FROM @PayloadSigners)
    BEGIN
        RAISERROR(N'Ký tự do yêu cầu tối thiểu một người ký để gán vào box ký.', 16, 1);
        RETURN;
    END

    DECLARE @StepSeed TABLE
    (
        RowNo INT IDENTITY(1,1) PRIMARY KEY,
        StepDefID BIGINT NULL,
        StepOrder INT NOT NULL,
        StepCode VARCHAR(50) NULL,
        StepName NVARCHAR(200) NOT NULL,
        StepType VARCHAR(20) NOT NULL,
        SignSystem VARCHAR(20) NULL,
        TemplateID BIGINT NULL,
        TemplatesJSON NVARCHAR(MAX) NULL,  -- [MULTI-TEMPLATE]
        DocumentFileUrl NVARCHAR(500) NULL,
        DocumentFileID UNIQUEIDENTIFIER NULL,
        DocumentFileName NVARCHAR(255) NULL,
        IsRequired BIT NOT NULL
    );

    IF @CreateMode = 'TEMPLATE_FLOW'
    BEGIN
        INSERT INTO @StepSeed
        (
            StepDefID, StepOrder, StepCode, StepName, StepType, SignSystem, TemplateID, TemplatesJSON,
            DocumentFileUrl, DocumentFileID, DocumentFileName, IsRequired
        )
        SELECT
            S.StepDefID,
            S.StepOrder,
            S.StepCode,
            S.StepName,
            S.StepType,
            S.SignSystem,
            S.TemplateID,
            S.TemplatesJSON,  -- [MULTI-TEMPLATE]
            -- DocumentFileUrl: multi-template steps không dùng 1 FileUrl duy nhất
            CASE
                WHEN S.TemplatesJSON IS NOT NULL THEN NULL
                WHEN @FileMethod = 'UPLOAD' THEN NULL
                ELSE T.FileUrl
            END,
            CASE WHEN @FileMethod = 'UPLOAD' THEN @FileID ELSE NULL END,
            CASE
                WHEN S.TemplatesJSON IS NOT NULL THEN NULL
                WHEN @FileMethod = 'UPLOAD' THEN @SourceFileName
                ELSE T.FileName
            END,
            S.IsRequired
        FROM dbo.tblWF_StepDefinition AS S
        LEFT JOIN dbo.tblWF_Template AS T
            ON T.TemplateID = S.TemplateID
           AND T.[Enable] = 1
        WHERE S.DefinitionID = @DefinitionID
          AND S.[Enable] = 1
        ORDER BY S.StepOrder;

        IF NOT EXISTS (SELECT 1 FROM @StepSeed)
        BEGIN
            RAISERROR(N'Workflow chưa có bước xử lý nào.', 16, 1);
            RETURN;
        END

        SELECT @InitialStepOrder = MIN(StepOrder) FROM @StepSeed;
        SELECT @InitialStepType = StepType FROM @StepSeed WHERE StepOrder = @InitialStepOrder;

        DECLARE @IsStep1Filled BIT = 0;

        IF @InitialStepType = 'INPUT_ONLY' AND @IsStep1Filled = 1
            SELECT @ActionStepOrder = MIN(StepOrder) FROM @StepSeed WHERE StepOrder > @InitialStepOrder;
        ELSE
            SET @ActionStepOrder = @InitialStepOrder;

        IF @ActionStepOrder IS NULL
            SET @ActionStepOrder = @InitialStepOrder;
    END
    ELSE
    BEGIN
        SELECT TOP (1) @DefaultSignSystem =
            CASE
                WHEN LOWER(ISNULL(SignMethod, 'smartca')) LIKE '%otp email%' THEN 'otp_email'
                WHEN LOWER(ISNULL(SignMethod, 'smartca')) LIKE '%otp sms%' THEN 'otp_sms'
                WHEN LOWER(ISNULL(SignMethod, 'smartca')) LIKE '%econtract%' THEN 'econtract'
                WHEN LOWER(ISNULL(SignMethod, 'smartca')) LIKE '%smartca%' THEN 'smartca'
                ELSE 'smartca'
            END
        FROM @PayloadSigners
        ORDER BY SignOrder;

        INSERT INTO @StepSeed
        (
            StepDefID, StepOrder, StepCode, StepName, StepType, SignSystem, TemplateID, TemplatesJSON,
            DocumentFileUrl, DocumentFileID, DocumentFileName, IsRequired
        )
        VALUES
        (
            NULL, 1, 'FREE_SIGN', N'Ký tự do', 'SIGN', @DefaultSignSystem, NULL, NULL,
            NULL, @FileID, @SourceFileName, 1
        );

        UPDATE @PayloadSigners
        SET StepOrder = 1,
            StepName = ISNULL(NULLIF(StepName, N''), N'Ký tự do')
        WHERE ISNULL(StepOrder, 0) = 0;

        SET @InitialStepOrder = 1;
        SET @InitialStepType = 'SIGN';
        SET @ActionStepOrder = 1;
    END

    SET @CurrentStepOrder = @ActionStepOrder;
    SELECT @FallbackSignerStepOrder = MAX(StepOrder) FROM @StepSeed WHERE StepType IN ('SIGN', 'REVIEW', 'ECONTRACT');
    IF @FallbackSignerStepOrder IS NULL SET @FallbackSignerStepOrder = @ActionStepOrder;

    UPDATE @PayloadSigners
    SET StepOrder = @FallbackSignerStepOrder
    WHERE ISNULL(StepOrder, 0) = 0;

    DECLARE @ExecutionMap TABLE
    (
        RowNo INT IDENTITY(1,1) PRIMARY KEY,
        ExecutionID BIGINT NOT NULL,
        StepDefID BIGINT NULL,
        StepOrder INT NOT NULL,
        StepType VARCHAR(20) NULL,
        StepStatus VARCHAR(20) NOT NULL
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.tblWF_Instance
        (
            DefinitionID, CategoryID, InstanceName, ReferenceCode, Description, CreateMode,
            SourceFileID, SourceFileName, CurrentStepOrder, Status,Priority,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            @DefinitionID, @CategoryID, @InstanceName, @ReferenceCode, @Description, @CreateMode,
            CASE WHEN @FileMethod = 'UPLOAD' THEN @FileID ELSE NULL END,
            CASE WHEN @FileMethod = 'UPLOAD' THEN @SourceFileName ELSE NULL END,
            @CurrentStepOrder, 'RUNNING', NULLIF(@Priority, 'NORMAL'),
            @sys_UserID, @Now, NULL, NULL, 1
        );

        SET @InstanceID = SCOPE_IDENTITY();

        IF @CreateMode = 'TEMPLATE_FLOW'
        BEGIN
            INSERT INTO dbo.tblWF_InstanceData
            (
                InstanceID, FieldName, FieldValue, UpdatedAtStep,
                CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
            )
            SELECT
                @InstanceID,
                F.FieldName,
                ISNULL(P.FieldValue, F.DefaultValue),
                @InitialStepOrder,
                @sys_UserID,
                @Now,
                NULL,
                NULL,
                1
            FROM dbo.tblWF_FieldMapping AS F
            LEFT JOIN @PayloadFields AS P
                ON P.FieldName = F.FieldName
            WHERE F.DefinitionID = @DefinitionID
              AND F.[Enable] = 1
            ORDER BY F.SortOrder, F.MappingID;
        END

        -- [MULTI-TEMPLATE] Thêm TemplatesJSON vào INSERT tblWF_StepExecution
        INSERT INTO dbo.tblWF_StepExecution
        (
            InstanceID, StepDefID, StepOrder, StepCode, StepName, StepType, SignSystem, TemplateID, TemplatesJSON,
            Status, DocumentFileUrl, DocumentFileID, DocumentFileName, SignTransactionID,
            StartedDate, CompletedDate, RejectedBy, RejectedReason, RejectedDate,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        OUTPUT
            INSERTED.ExecutionID,
            INSERTED.StepDefID,
            INSERTED.StepOrder,
            INSERTED.StepType,
            INSERTED.Status
        INTO @ExecutionMap (ExecutionID, StepDefID, StepOrder, StepType, StepStatus)
        SELECT
            @InstanceID,
            S.StepDefID,
            S.StepOrder,
            S.StepCode,
            S.StepName,
            S.StepType,
            S.SignSystem,
            S.TemplateID,
            S.TemplatesJSON,  -- [MULTI-TEMPLATE]
            CASE
                WHEN @InitialStepType = 'INPUT_ONLY' AND @IsStep1Filled = 1 AND S.StepOrder = @InitialStepOrder THEN 'COMPLETED'
                WHEN @ActionStepOrder = S.StepOrder THEN 'ACTIVE'
                ELSE 'PENDING'
            END,
            S.DocumentFileUrl,
            S.DocumentFileID,
            S.DocumentFileName,
            NULL,
            CASE
                WHEN (@InitialStepType = 'INPUT_ONLY' AND @IsStep1Filled = 1 AND S.StepOrder = @InitialStepOrder) OR S.StepOrder = @ActionStepOrder THEN @Now
                ELSE NULL
            END,
            CASE
                WHEN @InitialStepType = 'INPUT_ONLY' AND @IsStep1Filled = 1 AND S.StepOrder = @InitialStepOrder THEN @Now
                ELSE NULL
            END,
            NULL,
            NULL,
            NULL,
            @sys_UserID,
            @Now,
            NULL,
            NULL,
            1
        FROM @StepSeed AS S
        ORDER BY S.StepOrder;

        DECLARE @LoopRow INT = 1;
        DECLARE @LoopMax INT;
        DECLARE @LoopExecutionID BIGINT;
        DECLARE @LoopStepDefID BIGINT;
        DECLARE @LoopStepOrder INT;
        DECLARE @LoopStepType VARCHAR(20);
        DECLARE @LoopStepStatus VARCHAR(20);

        SELECT @LoopMax = COUNT(1) FROM @ExecutionMap;

        WHILE @LoopRow <= @LoopMax
        BEGIN
            SELECT
                @LoopExecutionID = ExecutionID,
                @LoopStepDefID = StepDefID,
                @LoopStepOrder = StepOrder,
                @LoopStepType = StepType,
                @LoopStepStatus = StepStatus
            FROM @ExecutionMap
            WHERE RowNo = @LoopRow;

            DELETE FROM @SignerSeed;

            IF EXISTS (SELECT 1 FROM @PayloadSigners WHERE StepOrder = @LoopStepOrder)
            BEGIN
                INSERT INTO @SignerSeed (SignOrder, SignerType, SignerValue, PersonName, DepartmentName, SignMethodRaw, TemplateSlotIdx)
                SELECT
                    P.SignOrder,
                    P.SignerType,
                    P.SignerValue,
                    P.PersonName,
                    P.DepartmentName,
                    P.SignMethod,
                    P.TemplateSlotIdx  -- [MULTI-TEMPLATE]
                FROM @PayloadSigners AS P
                WHERE P.StepOrder = @LoopStepOrder
                ORDER BY P.SignOrder, P.RowNo;
            END
            ELSE IF @CreateMode = 'TEMPLATE_FLOW' AND @LoopStepType IN ('SIGN', 'ECONTRACT')
            BEGIN
                INSERT INTO @SignerSeed (SignOrder, SignerType, SignerValue, PersonName, DepartmentName, SignMethodRaw, TemplateSlotIdx)
                SELECT
                    ROW_NUMBER() OVER(ORDER BY FM.MappingID),
                    'USER',
                    NULL,
                    NULL,
                    NULL,
                    'smartca',
                    NULL  -- [MULTI-TEMPLATE] legacy = NULL
                FROM dbo.tblWF_FieldMapping AS FM
                WHERE FM.DefinitionID = @DefinitionID
                  AND FM.[Enable] = 1
                  AND FM.FieldType = 'signature'
                ORDER BY FM.MappingID;
            END

            -- Bổ sung các người ký từ các ô ký (SignBoxes) của template nếu bước đó chưa có người ký ứng với SignerOrder đó
            IF @CreateMode = 'TEMPLATE_FLOW' AND EXISTS (SELECT 1 FROM @PayloadSignBoxes WHERE StepOrder = @LoopStepOrder)
            BEGIN
                INSERT INTO @SignerSeed (SignOrder, SignerType, SignerValue, PersonName, DepartmentName, SignMethodRaw, TemplateSlotIdx)
                SELECT DISTINCT
                    B.SignerOrder,
                    'ROLE' AS SignerType,
                    NULL AS SignerValue,
                    NULL AS PersonName,
                    NULL AS DepartmentName,
                    NULL AS SignMethodRaw,
                    NULL AS TemplateSlotIdx  -- [MULTI-TEMPLATE] sign box không có slot
                FROM @PayloadSignBoxes AS B
                WHERE B.StepOrder = @LoopStepOrder
                  AND B.SignerOrder NOT IN (SELECT SignOrder FROM @SignerSeed);
            END


            -- [MULTI-TEMPLATE] Thêm TemplateSlotIdx vào INSERT tblWF_StepSignerExec
            INSERT INTO dbo.tblWF_StepSignerExec
            (
                ExecutionID, SignerOrder, SignerType, SignerValue, DepartmentName,
                ResolvedPersonID, ResolvedPersonName, SignMethod, Status, SignedDate, SignCertInfo,
                TemplateSlotIdx,
                CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
            )
            SELECT
                @LoopExecutionID,
                SS.SignOrder,
                LEFT(UPPER(ISNULL(SS.SignerType, 'ROLE')), 20),
                LEFT(ISNULL(SS.SignerValue, ''), 50),
                LEFT(ISNULL(COALESCE(SS.DepartmentName, PF.ProfileDept), N''), 200),
                CASE
                    WHEN UPPER(ISNULL(SS.SignerType, 'ROLE')) = 'ROLE'
                        THEN LEFT(ISNULL(R.DefaultPersonID, ''), 9)
                    ELSE
                        CASE
                            WHEN LEN(ISNULL(PF.ProfileUserID, '')) BETWEEN 1 AND 9 THEN PF.ProfileUserID
                            WHEN LEN(ISNULL(SS.SignerValue, '')) BETWEEN 1 AND 9 THEN SS.SignerValue
                            ELSE NULL
                        END
                END,
                CASE
                    WHEN UPPER(ISNULL(SS.SignerType, 'ROLE')) = 'ROLE'
                        THEN ISNULL(R.DefaultPersonName, SS.PersonName)
                    ELSE ISNULL(PF.ProfileName, SS.PersonName)
                END,
                CASE
                    WHEN LOWER(ISNULL(SS.SignMethodRaw, 'smartca')) LIKE '%otp email%' THEN 'otp_email'
                    WHEN LOWER(ISNULL(SS.SignMethodRaw, 'smartca')) LIKE '%otp sms%' THEN 'otp_sms'
                    WHEN LOWER(ISNULL(SS.SignMethodRaw, 'smartca')) LIKE '%econtract%' THEN 'econtract'
                    WHEN LOWER(ISNULL(SS.SignMethodRaw, 'smartca')) LIKE '%ký ảnh%' THEN 'image'
                    WHEN LOWER(ISNULL(SS.SignMethodRaw, 'smartca')) LIKE '%smartca%' THEN 'smartca'
                    ELSE LOWER(ISNULL(SS.SignMethodRaw, 'smartca'))
                END,
                CASE
                    WHEN @LoopStepStatus = 'ACTIVE' AND @Sequential = 1 AND SS.SignOrder = 1 THEN 'WAITING'
                    WHEN @LoopStepStatus = 'ACTIVE' AND @Sequential = 0 THEN 'WAITING'
                    ELSE 'PENDING'
                END,
                NULL,
                NULL,
                SS.TemplateSlotIdx,  -- [MULTI-TEMPLATE]
                @sys_UserID,
                @Now,
                NULL,
                NULL,
                1
            FROM @SignerSeed AS SS
            OUTER APPLY
            (
                SELECT TOP (1) R2.DefaultPersonID, R2.DefaultPersonName
                FROM dbo.tblWF_RoleMapping AS R2
                WHERE R2.RoleCode = SS.SignerValue
                  AND R2.[Enable] = 1
                ORDER BY
                  CASE WHEN ISNULL(R2.DefaultPersonID, '') <> '' THEN 0 ELSE 1 END,
                  CASE WHEN ISNULL(R2.DepartmentName, '') = ISNULL(SS.DepartmentName, '') THEN 0 ELSE 1 END,
                  R2.RoleMappingID DESC
            ) AS R
            OUTER APPLY
            (
                SELECT TOP (1)
                    ProfileUserID = NULLIF(LTRIM(RTRIM(ISNULL(P.EmployeeCode, ''))), ''),
                    ProfileName = NULLIF(LTRIM(RTRIM(ISNULL(P.FullName, N''))), N''),
                    ProfileDept = NULLIF(LTRIM(RTRIM(ISNULL(P.DepartmentName, N''))), N'')
                FROM dbo.tblWF_User AS P
                WHERE P.[Enable] = 1
                  AND ISNULL(P.IsActive, 1) = 1
                  AND
                  (
                      UPPER(ISNULL(P.EmployeeCode, '')) = UPPER(ISNULL(SS.SignerValue, ''))
                      OR UPPER(ISNULL(P.Email, '')) = UPPER(ISNULL(SS.SignerValue, ''))
                  )
                ORDER BY
                    CASE WHEN UPPER(ISNULL(P.EmployeeCode, '')) = UPPER(ISNULL(SS.SignerValue, '')) THEN 0 ELSE 1 END,
                    P.UserID DESC
            ) AS PF;

            -- Tự động tạo bản ghi thực thi gán quyền bước (tblWF_StepAssigneeExec) cho execution hiện tại
            INSERT INTO dbo.tblWF_StepAssigneeExec
            (
                ExecutionID, StepAssigneeID, EmployeeID, EmployeeCode, FullName,
                RoleCode, RightCode, Status, CreateUser, CreateTime, [Enable]
            )
            SELECT
                @LoopExecutionID,
                SA.StepAssigneeID,
                SA.EmployeeID,
                P.EmployeeCode,
                P.FullName,
                SA.RoleCode,
                SA.RightCode,
                CASE WHEN @LoopStepStatus = 'ACTIVE' THEN 'ACTIVE' ELSE 'PENDING' END,
                @sys_UserID, @Now, 1
            FROM dbo.tblWF_StepAssignee AS SA
            LEFT JOIN dbo.tblWF_User AS P ON SA.EmployeeID = P.UserID AND P.[Enable] = 1
            WHERE SA.StepDefID = @LoopStepDefID
              AND SA.[Enable] = 1;

            SET @LoopRow = @LoopRow + 1;
        END

        INSERT INTO dbo.tblWF_InstanceTask
            (ExecutionID, InstanceID, StepDefID, TaskName, Description, DueHours, Status, [Enable], CreateTime, CreateUser, SortOrder)
        SELECT
            EX.ExecutionID,
            @InstanceID,
            EX.StepDefID,
            T.TaskName,
            T.Description,
            ISNULL(T.DueHours, N'24'),
            'TODO',
            1,
            @Now,
            @sys_UserID,
            T.SortOrder
        FROM @ExecutionMap AS EX
        INNER JOIN dbo.tblWF_Task AS T
            ON T.StepDefID = EX.StepDefID
           AND T.[Enable] = 1
        WHERE EX.StepStatus = 'ACTIVE';

        IF EXISTS (SELECT 1 FROM @PayloadSignBoxes)
        BEGIN
            INSERT INTO dbo.tblWF_InstanceSignBox
            (
                InstanceID, ExecutionID, SignerExecID, BoxOrder, PageNo, PosX, PosY, BoxWidth, BoxHeight,
                StepOrder, SignerOrder, SignerType, SignerValue, PersonName, DepartmentName,
                SignMethod, ExecutionEngine, ContractProvider, LabelText, Status,
                CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
            )
            SELECT
                @InstanceID,
                EX.ExecutionID,
                SE.SignerExecID,
                B.BoxOrder,
                B.PageNo,
                B.PosX,
                B.PosY,
                B.BoxWidth,
                B.BoxHeight,
                ISNULL(B.StepOrder, EX.StepOrder),
                B.SignerOrder,
                UPPER(ISNULL(B.SignerType, 'ROLE')),
                B.SignerValue,
                B.PersonName,
                B.DepartmentName,
                ISNULL(B.SignMethod, SE.SignMethod),
                @ExecutionEngine,
                NULLIF(@ContractProvider, ''),
                B.LabelText,
                CASE
                    WHEN EX.StepStatus = 'ACTIVE' AND SE.Status = 'WAITING' THEN 'ACTIVE'
                    ELSE 'PENDING'
                END,
                @sys_UserID,
                @Now,
                NULL,
                NULL,
                1
            FROM @PayloadSignBoxes AS B
            LEFT JOIN @ExecutionMap AS EX
                ON EX.StepOrder = ISNULL(B.StepOrder, 1)
            LEFT JOIN dbo.tblWF_StepSignerExec AS SE
                ON SE.ExecutionID = EX.ExecutionID
               AND SE.SignerOrder = ISNULL(B.SignerOrder, 1)
               AND SE.[Enable] = 1;
        END

        -- Cập nhật ResolvedPersonID cho signer từ giá trị signature fields trong InstanceData
        UPDATE SE
        SET SE.ResolvedPersonID = LTRIM(RTRIM(ID.FieldValue)),
            SE.ResolvedPersonName = ISNULL(
                (SELECT TOP 1 P.FullName
                 FROM dbo.tblWF_User P
                 WHERE (P.EmployeeCode = LTRIM(RTRIM(ID.FieldValue)) OR P.Email = LTRIM(RTRIM(ID.FieldValue)))
                   AND P.IsActive = 1 AND P.[Enable] = 1
                 ORDER BY CASE WHEN P.EmployeeCode = LTRIM(RTRIM(ID.FieldValue)) THEN 0 ELSE 1 END, P.UserID DESC),
                SE.ResolvedPersonName
            ),
            SE.UpdateTime = @Now,
            SE.UpdateUser = @sys_UserID
        FROM dbo.tblWF_StepSignerExec SE
        INNER JOIN dbo.tblWF_InstanceSignBox B
            ON B.SignerExecID = SE.SignerExecID AND B.[Enable] = 1 AND B.InstanceID = @InstanceID
        INNER JOIN dbo.tblWF_InstanceData ID
            ON ID.InstanceID = @InstanceID AND ID.FieldName = B.LabelText AND ID.[Enable] = 1
        WHERE SE.[Enable] = 1
          AND ISNULL(SE.ResolvedPersonID, '') = ''
          AND ISNULL(ID.FieldValue, '') <> ''
          AND LEN(LTRIM(RTRIM(ID.FieldValue))) BETWEEN 1 AND 20;

        SELECT TOP (1)
            @ActiveExecutionID = ExecutionID,
            @CurrentStepOrder = StepOrder
        FROM @ExecutionMap
        WHERE StepStatus = 'ACTIVE'
        ORDER BY StepOrder;

        IF @ActiveExecutionID IS NULL
        BEGIN
            SET @InstanceStatus = 'COMPLETED';
        END
        ELSE
        BEGIN
            IF EXISTS
            (
                SELECT 1
                FROM dbo.tblWF_StepSignerExec AS SE
                WHERE SE.ExecutionID = @ActiveExecutionID
                  AND SE.Status = 'WAITING'
                  AND ISNULL(SE.ResolvedPersonID, '') = @sys_UserID
                  AND SE.[Enable] = 1
            )
                SET @WaitingForMe = 1;

            SET @InstanceStatus = CASE WHEN @WaitingForMe = 1 THEN 'WAITING_ME' ELSE 'RUNNING' END;
        END

        -- Nếu @AssigneeCode trống, KHÔNG tự động gán — để trống cho quản lý tự phân công sau
        -- (Logic fallback cũ đã bị xóa: trước đây tự gán người ký đầu tiên hoặc người tạo)

        UPDATE dbo.tblWF_Instance
        SET CurrentStepOrder = @CurrentStepOrder,
            Status = @InstanceStatus,
            AssigneeCode = @AssigneeCode,
            UpdateUser = @sys_UserID,
            UpdateTime = @Now
        WHERE InstanceID = @InstanceID;

        INSERT INTO dbo.tblWF_AuditLog
        (
            InstanceID, StepOrder, ActionCode, ActionDetail, UserID,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            @InstanceID,
            @CurrentStepOrder,
            'INSTANCE_CREATED',
            N'{"CreateMode":"' + ISNULL(@CreateMode, '')
            + N'","ReferenceCode":"' + REPLACE(ISNULL(@ReferenceCode, ''), '"', '\"')
            + N'","Description":"' + REPLACE(ISNULL(@Description, N''), '"', '\"')
            + N'","FileMethod":"' + ISNULL(@FileMethod, '')
            + N'","FileID":"' + ISNULL(CAST(@FileID AS VARCHAR(50)), N'')
            + N'","TemplateID":"' + ISNULL(CAST(@TemplateID AS NVARCHAR(20)), N'')
            + N'","ExecutionEngine":"' + ISNULL(@ExecutionEngine, '')
            + N'","ContractProvider":"' + ISNULL(@ContractProvider, '')
            + N'","Priority":"' + ISNULL(@Priority, '')
            + N'","NotifyEmail":"' + CAST(@NotifyEmail AS NVARCHAR(5))
            + N'","RequireOtpConfirm":"' + CAST(@RequireOtpConfirm AS NVARCHAR(5))
            + N'","DefinitionVersion":"' + ISNULL(CAST(@DefinitionVersion AS NVARCHAR(20)), N'')
            + N'","SignBoxCount":"' + CAST((SELECT COUNT(1) FROM @PayloadSignBoxes) AS NVARCHAR(20))
            + N'"}',
            @sys_UserID,
            @sys_UserID,
            @Now,
            NULL,
            NULL,
            0
        );

        COMMIT TRANSACTION;

        -- ── Kích hoạt tự động hóa ──────────────────────────────────────────────
        EXEC dbo.spAPI_WF_Automation_Execute
            @sys_UserID = @sys_UserID,
            @InstanceID = @InstanceID,
            @Event = 'TASK_CREATED',
            @InternalCall = 1;

        SELECT
            Message = N'Tạo yêu cầu ký thành công.',
            InstanceID = @InstanceID,
            InstanceName = @InstanceName,
            Status = @InstanceStatus,
            CurrentStepOrder = @CurrentStepOrder,
            CreateMode = @CreateMode;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END


