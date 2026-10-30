CREATE PROCEDURE [dbo].[spAPI_WF_Definition_Save]
    @DefinitionID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Code VARCHAR(50) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.Code'), '')));
    DECLARE @Name NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.Name');
    DECLARE @Description NVARCHAR(500) = JSON_VALUE(@sys_RawData, '$.Description');
    DECLARE @CategoryID INT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.CategoryID') AS INT);
    DECLARE @OnRejectAction VARCHAR(20) = ISNULL(JSON_VALUE(@sys_RawData, '$.OnRejectAction'), 'ADMIN_CHOOSE');
    DECLARE @NotifyEmail BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.NotifyEmail') AS BIT), 1);
    DECLARE @NotifyOnComplete BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.NotifyOnComplete') AS BIT), 1);
    DECLARE @IsActive BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.IsActive') AS BIT), 0);
    DECLARE @Version INT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.Version') AS INT), 1);
    DECLARE @AssignerID VARCHAR(9) = JSON_VALUE(@sys_RawData, '$.AssignerID');
    DECLARE @ProjectID BIGINT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.ProjectID') AS BIGINT); -- NULL = không đổi (khi sửa) / không thuộc project (khi tạo)

    -- Validate
    IF ISNULL(@Name, '') = '' BEGIN RAISERROR(N'Tên workflow không được để trống.', 16, 1); RETURN; END
    IF ISNULL(@Code, '') = '' BEGIN RAISERROR(N'Mã workflow không được để trống.', 16, 1); RETURN; END

    -- Kiểm tra trùng mã (chỉ với bản ghi đang hoạt động Enable=1)
    IF EXISTS (SELECT 1 FROM dbo.tblWF_Definition WHERE [Enable] = 1 AND Code = @Code AND DefinitionID <> @DefinitionID)
    BEGIN RAISERROR(N'Mã workflow đã tồn tại, vui lòng dùng mã khác.', 16, 1); RETURN; END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- CREATE hoặc UPDATE Definition
        IF @DefinitionID = 0
        BEGIN
            INSERT INTO dbo.tblWF_Definition (Code, Name, Description, CategoryID, ProjectID, Version, IsActive, OnRejectAction, NotifyEmail, NotifyOnComplete, AssignerID, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable])
            VALUES (@Code, @Name, @Description, @CategoryID, @ProjectID, @Version, @IsActive, @OnRejectAction, @NotifyEmail, @NotifyOnComplete, @AssignerID, @sys_UserID, GETDATE(), NULL, NULL, 1); -- Enable=1 ✅
            SET @DefinitionID = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.tblWF_Definition
            SET Code = @Code, Name = @Name, Description = @Description, CategoryID = @CategoryID,
                ProjectID = ISNULL(@ProjectID, ProjectID), -- không truyền → giữ nguyên project hiện tại
                Version = @Version, IsActive = @IsActive, OnRejectAction = @OnRejectAction,
                NotifyEmail = @NotifyEmail, NotifyOnComplete = @NotifyOnComplete,
                AssignerID = @AssignerID, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
            WHERE DefinitionID = @DefinitionID AND [Enable] = 1; -- Enable=1 ✅
        END

        -- XÓA HẲN Task cũ (theo yêu cầu)
        DELETE TK
        FROM dbo.tblWF_Task TK
        INNER JOIN dbo.tblWF_StepDefinition S ON TK.StepDefID = S.StepDefID
        WHERE S.DefinitionID = @DefinitionID;

        -- Soft-delete Steps, Signers, Fields cũ (Enable=0 = đã xóa) ✅
        UPDATE dbo.tblWF_StepSignerDef SET [Enable] = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE StepDefID IN (SELECT StepDefID FROM dbo.tblWF_StepDefinition WHERE DefinitionID = @DefinitionID AND [Enable] = 1);

        UPDATE dbo.tblWF_StepDefinition SET [Enable] = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE DefinitionID = @DefinitionID AND [Enable] = 1;

        UPDATE dbo.tblWF_StepAssignee SET [Enable] = 0
        WHERE StepDefID IN (SELECT StepDefID FROM dbo.tblWF_StepDefinition WHERE DefinitionID = @DefinitionID);

        UPDATE dbo.tblWF_FieldMapping SET [Enable] = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE DefinitionID = @DefinitionID AND [Enable] = 1;

        -- Đọc danh sách Steps từ JSON
        DECLARE @StepSeed TABLE (
            RowNo INT IDENTITY(1,1) PRIMARY KEY,
            StepOrder INT, StepCode VARCHAR(50), StepName NVARCHAR(200), StepType VARCHAR(20),
            SignSystem VARCHAR(20), TemplateID BIGINT, AutoTrigger BIT, IsRequired BIT,
            OnRejectGoToStep INT, ConditionJSON NVARCHAR(MAX),
            AssigneeID VARCHAR(9), DueHours NVARCHAR(50), DueType VARCHAR(20),
            Description NVARCHAR(500),
            SignersJSON NVARCHAR(MAX), TasksJSON NVARCHAR(MAX),
            AssigneesJSON NVARCHAR(MAX),
            TemplatesJSON NVARCHAR(MAX)  -- [MULTI-TEMPLATE] array of template slots
        );

        INSERT INTO @StepSeed (StepOrder, StepCode, StepName, StepType, SignSystem, TemplateID, AutoTrigger, IsRequired, OnRejectGoToStep, ConditionJSON, AssigneeID, DueHours, DueType, Description, SignersJSON, TasksJSON, AssigneesJSON, TemplatesJSON)
        SELECT StepOrder, StepCode, StepName, StepType, SignSystem, TemplateID, AutoTrigger, IsRequired, OnRejectGoToStep, ConditionJSON, AssigneeID, DueHours, DueType, Description, SignersJSON, TasksJSON, AssigneesJSON, TemplatesJSON
        FROM OPENJSON(@sys_RawData, '$.Steps')
        WITH (
            StepOrder INT '$.StepOrder', StepCode VARCHAR(50) '$.StepCode', StepName NVARCHAR(200) '$.StepName',
            StepType VARCHAR(20) '$.StepType', SignSystem VARCHAR(20) '$.SignSystem', TemplateID BIGINT '$.TemplateID',
            AutoTrigger BIT '$.AutoTrigger', IsRequired BIT '$.IsRequired', OnRejectGoToStep INT '$.OnRejectGoToStep',
            ConditionJSON NVARCHAR(MAX) '$.ConditionJSON',
            AssigneeID VARCHAR(9) '$.AssigneeID',
            DueHours NVARCHAR(50) '$.DueHours',
            DueType VARCHAR(20) '$.DueType',
            Description NVARCHAR(500) '$.Description',
            SignersJSON NVARCHAR(MAX) '$.Signers' AS JSON,
            TasksJSON NVARCHAR(MAX) '$.Tasks' AS JSON,
            AssigneesJSON NVARCHAR(MAX) '$.Assignees' AS JSON,
            TemplatesJSON NVARCHAR(MAX) '$.TemplatesJSON' AS JSON  -- [MULTI-TEMPLATE]
        );

        DECLARE @StepRow INT = 1, @StepMax INT = (SELECT COUNT(1) FROM @StepSeed), @NewStepDefID BIGINT;
        -- Biến tạm để đọc từng dòng @StepSeed
        DECLARE @CurStepOrder INT, @CurStepCode VARCHAR(50), @CurStepName NVARCHAR(200),
                @CurStepType VARCHAR(20), @CurSignSystem VARCHAR(20), @CurTemplateID BIGINT,
                @CurAutoTrigger BIT, @CurIsRequired BIT, @CurOnRejectGoToStep INT,
                @CurConditionJSON NVARCHAR(MAX), @CurDueHours NVARCHAR(50), @CurDueType VARCHAR(20),
                @CurDescription NVARCHAR(500),
                @CurTemplatesJSON NVARCHAR(MAX);  -- [MULTI-TEMPLATE]

        WHILE @StepRow <= @StepMax
        BEGIN
            SELECT @CurStepOrder = StepOrder, @CurStepCode = StepCode, @CurStepName = StepName,
                   @CurStepType = StepType, @CurSignSystem = SignSystem, @CurTemplateID = TemplateID,
                   @CurAutoTrigger = ISNULL(AutoTrigger, 1), @CurIsRequired = ISNULL(IsRequired, 1),
                   @CurOnRejectGoToStep = OnRejectGoToStep, @CurConditionJSON = ConditionJSON,
                   @CurDueHours = ISNULL(DueHours, N'0'), @CurDueType = ISNULL(DueType, 'HOURS'),
                   @CurDescription = Description,
                   @CurTemplatesJSON = TemplatesJSON  -- [MULTI-TEMPLATE]
            FROM @StepSeed WHERE RowNo = @StepRow;

            -- Ưu tiên UPDATE step cũ cùng StepOrder (giữ nguyên StepDefID → instance hiện có không bị mất)
            SET @NewStepDefID = NULL;
            SELECT TOP (1) @NewStepDefID = StepDefID
            FROM dbo.tblWF_StepDefinition
            WHERE DefinitionID = @DefinitionID AND StepOrder = @CurStepOrder AND [Enable] = 0
            ORDER BY StepDefID DESC;

            IF @NewStepDefID IS NOT NULL
            BEGIN
                UPDATE dbo.tblWF_StepDefinition
                SET StepCode = @CurStepCode, StepName = @CurStepName, StepType = @CurStepType,
                    SignSystem = @CurSignSystem, TemplateID = @CurTemplateID,
                    TemplatesJSON = @CurTemplatesJSON,  -- [MULTI-TEMPLATE]
                    AutoTrigger = @CurAutoTrigger, IsRequired = @CurIsRequired,
                    OnRejectGoToStep = @CurOnRejectGoToStep, ConditionJSON = @CurConditionJSON,
                    DueHours = @CurDueHours, DueType = @CurDueType, Description = @CurDescription, [Enable] = 1,
                    UpdateUser = @sys_UserID, UpdateTime = GETDATE()
                WHERE StepDefID = @NewStepDefID;
            END
            ELSE
            BEGIN
                -- Bước mới hoàn toàn (StepOrder chưa từng tồn tại) → INSERT
                INSERT INTO dbo.tblWF_StepDefinition (DefinitionID, StepOrder, StepCode, StepName, StepType, SignSystem, TemplateID, TemplatesJSON, AutoTrigger, IsRequired, OnRejectGoToStep, ConditionJSON, DueHours, DueType, Description, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable])
                VALUES (@DefinitionID, @CurStepOrder, @CurStepCode, @CurStepName, @CurStepType,
                        @CurSignSystem, @CurTemplateID, @CurTemplatesJSON,  -- [MULTI-TEMPLATE]
                        @CurAutoTrigger, @CurIsRequired,
                        @CurOnRejectGoToStep, @CurConditionJSON, @CurDueHours, @CurDueType, @CurDescription,
                        @sys_UserID, GETDATE(), NULL, NULL, 1);
                SET @NewStepDefID = SCOPE_IDENTITY();
            END

            -- [MULTI-TEMPLATE] INSERT Signers:
            -- Nếu TemplatesJSON có giá trị → insert signers per-slot với TemplateSlotIdx
            -- Ngược lại → legacy path (step-level signers, TemplateSlotIdx = NULL)
            IF @CurTemplatesJSON IS NOT NULL AND LEN(@CurTemplatesJSON) > 2
            BEGIN
                INSERT INTO dbo.tblWF_StepSignerDef (StepDefID, TemplateSlotIdx, SignerOrder, SignerType, SignerValue, SignMethod, IsSequential, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable])
                SELECT
                    @NewStepDefID,
                    Slot.SlotIdx,
                    ISNULL(S.SignerOrder, 1),
                    S.SignerType,
                    S.SignerValue,
                    S.SignMethod,
                    ISNULL(S.IsSequential, 1),
                    @sys_UserID, GETDATE(), NULL, NULL, 1
                FROM OPENJSON(@CurTemplatesJSON)
                WITH (
                    SlotIdx      INT            '$.SlotIdx',
                    SignersJSON  NVARCHAR(MAX)  '$.Signers' AS JSON
                ) AS Slot
                CROSS APPLY OPENJSON(Slot.SignersJSON)
                WITH (
                    SignerOrder  INT            '$.SignerOrder',
                    SignerType   VARCHAR(20)    '$.SignerType',
                    SignerValue  NVARCHAR(200)  '$.SignerValue',
                    SignMethod   VARCHAR(20)    '$.SignMethod',
                    IsSequential BIT            '$.IsSequential'
                ) AS S
                WHERE Slot.SignersJSON IS NOT NULL AND LEN(Slot.SignersJSON) > 2;
            END
            ELSE
            BEGIN
                -- Legacy: step-level signers (TemplateSlotIdx = NULL)
                INSERT INTO dbo.tblWF_StepSignerDef (StepDefID, SignerOrder, SignerType, SignerValue, SignMethod, IsSequential, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable])
                SELECT @NewStepDefID, ISNULL(SignerOrder, 1), SignerType, SignerValue, SignMethod, ISNULL(IsSequential, 1), @sys_UserID, GETDATE(), NULL, NULL, 1
                FROM OPENJSON((SELECT SignersJSON FROM @StepSeed WHERE RowNo = @StepRow))
                WITH (SignerOrder INT '$.SignerOrder', SignerType VARCHAR(20) '$.SignerType', SignerValue NVARCHAR(200) '$.SignerValue', SignMethod VARCHAR(20) '$.SignMethod', IsSequential BIT '$.IsSequential');
            END

            -- INSERT Multi-Assignees mới
            INSERT INTO dbo.tblWF_StepAssignee (StepDefID, EmployeeID, RoleCode, RightCode, CreateUser, CreateTime, [Enable])
            SELECT
                @NewStepDefID,
                P.UserID, -- Lưu ID số (bigint)
                J.RoleCode,
                ISNULL(J.RightCode, 'MANAGER'),
                @sys_UserID,
                GETDATE(),
                1
            FROM OPENJSON((SELECT AssigneesJSON FROM @StepSeed WHERE RowNo = @StepRow))
            WITH (
                EmployeeCode VARCHAR(50) '$.EmployeeCode',
                RoleCode VARCHAR(50) '$.RoleCode',
                RightCode VARCHAR(50) '$.RightCode'
            ) AS J
            LEFT JOIN (
                SELECT EmployeeCode, UserID = MAX(UserID)
                FROM dbo.tblWF_User
                WHERE [Enable] = 1 AND IsActive = 1
                GROUP BY EmployeeCode
            ) P ON J.EmployeeCode = P.EmployeeCode;

            -- INSERT Tasks mới
            INSERT INTO dbo.tblWF_Task (StepDefID, TaskName, Description, DueHours, IsCompleted, IsRequired, IsLocked, IsDeleted, FileIDList, ImageIDList, SortOrder, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable])
            SELECT @NewStepDefID, TaskName, Description, ISNULL(DueHours, N'24'), ISNULL(IsCompleted, 0), ISNULL(IsRequired, 0), ISNULL(IsLocked, 0), ISNULL(IsDeleted, 0), NULL, NULL, ISNULL(SortOrder, 0), @sys_UserID, GETDATE(), NULL, NULL, 1 -- Enable=1 ✅
            FROM OPENJSON((SELECT TasksJSON FROM @StepSeed WHERE RowNo = @StepRow))
            WITH (TaskName NVARCHAR(1000) '$.TaskName', Description NVARCHAR(500) '$.Description', DueHours NVARCHAR(50) '$.DueHours', IsCompleted BIT '$.IsCompleted', IsRequired BIT '$.IsRequired', IsLocked BIT '$.IsLocked', IsDeleted BIT '$.IsDeleted', SortOrder INT '$.SortOrder');

            SET @StepRow = @StepRow + 1;
        END

        -- INSERT Fields mới
        INSERT INTO dbo.tblWF_FieldMapping (DefinitionID, FieldName, FieldLabel, FieldType, FieldOptions, InputAtStep, IsRequired, DefaultValue, SortOrder, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable])
        SELECT @DefinitionID, FieldName, FieldLabel, ISNULL(FieldType, 'text'), FieldOptions, ISNULL(NULLIF(InputAtStep, ''), '1'), ISNULL(IsRequired, 0), DefaultValue, SortOrder, @sys_UserID, GETDATE(), NULL, NULL, 1 -- Enable=1 ✅
        FROM OPENJSON(@sys_RawData, '$.Fields')
        WITH (FieldName VARCHAR(50) '$.FieldName', FieldLabel NVARCHAR(200) '$.FieldLabel', FieldType VARCHAR(20) '$.FieldType', FieldOptions NVARCHAR(MAX) '$.FieldOptions', InputAtStep NVARCHAR(255) '$.InputAtStep', IsRequired BIT '$.IsRequired', DefaultValue NVARCHAR(500) '$.DefaultValue', SortOrder INT '$.SortOrder');

        -- Tự động đồng bộ các trường dữ liệu kiểu file/image thành các checklist định nghĩa (tblWF_StepChecklistDef)
        -- Bước 1: Vô hiệu hóa (Enable = 0) các checklist định nghĩa cũ của các bước thuộc Definition này
        UPDATE dbo.tblWF_StepChecklistDef
        SET [Enable] = 0,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE StepDefID IN (
            SELECT StepDefID
            FROM dbo.tblWF_StepDefinition
            WHERE DefinitionID = @DefinitionID
        );

        -- Bước 2: Đồng bộ các trường kiểu file/image
        MERGE dbo.tblWF_StepChecklistDef AS target
        USING (
            SELECT
                s.StepDefID,
                f.FieldName AS ItemCode,
                f.FieldLabel AS ItemName,
                N'Tự động đồng bộ từ trường dữ liệu ' + f.FieldName AS [Description],
                f.IsRequired,
                ISNULL(NULLIF(f.FieldOptions, ''), 'ONLINE') AS AllowedMethods,
                1 AS AllowDefer
            FROM dbo.tblWF_FieldMapping f
            CROSS APPLY STRING_SPLIT(f.InputAtStep, ',') split
            INNER JOIN dbo.tblWF_StepDefinition s
                ON s.DefinitionID = f.DefinitionID
                AND s.StepOrder = TRY_CAST(LTRIM(RTRIM(split.value)) AS INT)
            WHERE f.DefinitionID = @DefinitionID
              AND f.[Enable] = 1
              AND s.[Enable] = 1
              AND (f.FieldType = 'file' OR f.FieldType = 'image')
        ) AS source
        ON (target.StepDefID = source.StepDefID AND target.ItemCode = source.ItemCode)
        WHEN MATCHED THEN
            UPDATE SET
                ItemName = source.ItemName,
                [Description] = source.[Description],
                IsRequired = source.IsRequired,
                AllowedMethods = source.AllowedMethods,
                AllowDefer = source.AllowDefer,
                [Enable] = 1,
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (StepDefID, ItemCode, ItemName, [Description], IsRequired, AllowedMethods, AllowDefer, CreateUser, CreateTime, [Enable])
            VALUES (source.StepDefID, source.ItemCode, source.ItemName, source.[Description], source.IsRequired, source.AllowedMethods, source.AllowDefer, @sys_UserID, GETDATE(), 1);

        COMMIT TRANSACTION;
        SELECT Message = N'Lưu workflow thành công.', DefinitionID = @DefinitionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ISNULL(ERROR_SEVERITY(), 16);
        DECLARE @ErrorState INT = ISNULL(ERROR_STATE(), 1);
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END

