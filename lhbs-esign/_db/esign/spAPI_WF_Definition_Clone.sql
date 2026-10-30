CREATE PROCEDURE [dbo].[spAPI_WF_Definition_Clone]
    @DefinitionID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewDefinitionID BIGINT;
    DECLARE @NowSuffix VARCHAR(20) = REPLACE(REPLACE(CONVERT(VARCHAR(19), GETDATE(), 120), '-', ''), ':', '');
    SET @NowSuffix = REPLACE(@NowSuffix, ' ', '');

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.tblWF_Definition
        (
            Code, Name, Description, CategoryID, Version, IsActive, OnRejectAction, NotifyEmail, NotifyOnComplete,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        SELECT
            LEFT(D.Code + '_COPY_' + RIGHT(@NowSuffix, 6), 50),
            D.Name + N' (Bản sao)',
            D.Description,
            D.CategoryID,
            D.Version,
            0,
            D.OnRejectAction,
            D.NotifyEmail,
            D.NotifyOnComplete,
            @sys_UserID,
            GETDATE(),
            NULL,
            NULL,
            1
        FROM dbo.tblWF_Definition AS D
        WHERE D.DefinitionID = @DefinitionID
          AND D.[Enable] = 1;

        SET @NewDefinitionID = SCOPE_IDENTITY();

        DECLARE @StepMap TABLE
        (
            SourceStepDefID BIGINT NOT NULL,
            NewStepDefID BIGINT NULL,
            StepOrder INT NOT NULL
        );

        INSERT INTO @StepMap (SourceStepDefID, StepOrder)
        SELECT S.StepDefID, S.StepOrder
        FROM dbo.tblWF_StepDefinition AS S
        WHERE S.DefinitionID = @DefinitionID
          AND S.[Enable] = 1
        ORDER BY S.StepOrder;

        DECLARE @SourceStepDefID BIGINT;
        DECLARE @StepOrder INT;
        DECLARE @NewStepDefID BIGINT;

        DECLARE step_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT SourceStepDefID, StepOrder
        FROM @StepMap
        ORDER BY StepOrder;

        OPEN step_cursor;
        FETCH NEXT FROM step_cursor INTO @SourceStepDefID, @StepOrder;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO dbo.tblWF_StepDefinition
            (
                DefinitionID, StepOrder, StepCode, StepName, StepType, SignSystem, TemplateID, AutoTrigger, IsRequired, OnRejectGoToStep, ConditionJSON,
                CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
            )
            SELECT
                @NewDefinitionID, S.StepOrder, S.StepCode, S.StepName, S.StepType, S.SignSystem, S.TemplateID, S.AutoTrigger, S.IsRequired, S.OnRejectGoToStep, S.ConditionJSON,
                @sys_UserID, GETDATE(), NULL, NULL, 1
            FROM dbo.tblWF_StepDefinition AS S
            WHERE S.StepDefID = @SourceStepDefID;

            SET @NewStepDefID = SCOPE_IDENTITY();

            UPDATE @StepMap
            SET NewStepDefID = @NewStepDefID
            WHERE SourceStepDefID = @SourceStepDefID;

            INSERT INTO dbo.tblWF_StepSignerDef
            (
                StepDefID, SignerOrder, SignerType, SignerValue, SignMethod, IsSequential,
                CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
            )
            SELECT
                @NewStepDefID, SD.SignerOrder, SD.SignerType, SD.SignerValue, SD.SignMethod, SD.IsSequential,
                @sys_UserID, GETDATE(), NULL, NULL, 1
            FROM dbo.tblWF_StepSignerDef AS SD
            WHERE SD.StepDefID = @SourceStepDefID
              AND SD.[Enable] = 1;

            -- Copy Step Assignees
            INSERT INTO dbo.tblWF_StepAssignee
            (
                StepDefID, EmployeeID, RoleCode, RightCode, CreateUser, CreateTime, [Enable]
            )
            SELECT
                @NewStepDefID, SA.EmployeeID, SA.RoleCode, SA.RightCode, @sys_UserID, GETDATE(), 1
            FROM dbo.tblWF_StepAssignee AS SA
            WHERE SA.StepDefID = @SourceStepDefID
              AND SA.[Enable] = 1;

            -- Copy Step Checklist Definitions
            INSERT INTO dbo.tblWF_StepChecklistDef
            (
                StepDefID, ItemCode, ItemName, Description, IsRequired, AllowedMethods, AllowDefer,
                CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
            )
            SELECT
                @NewStepDefID, SC.ItemCode, SC.ItemName, SC.Description, SC.IsRequired, SC.AllowedMethods, SC.AllowDefer,
                @sys_UserID, GETDATE(), NULL, NULL, 1
            FROM dbo.tblWF_StepChecklistDef AS SC
            WHERE SC.StepDefID = @SourceStepDefID
              AND SC.[Enable] = 1;

            FETCH NEXT FROM step_cursor INTO @SourceStepDefID, @StepOrder;
        END

        CLOSE step_cursor;
        DEALLOCATE step_cursor;

        INSERT INTO dbo.tblWF_FieldMapping
        (
            DefinitionID, FieldName, FieldLabel, FieldType, FieldOptions, InputAtStep, IsRequired, DefaultValue, SortOrder,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        SELECT
            @NewDefinitionID, F.FieldName, F.FieldLabel, F.FieldType, F.FieldOptions, F.InputAtStep, F.IsRequired, F.DefaultValue, F.SortOrder,
            @sys_UserID, GETDATE(), NULL, NULL, 1
        FROM dbo.tblWF_FieldMapping AS F
        WHERE F.DefinitionID = @DefinitionID
          AND F.[Enable] = 1;

        COMMIT TRANSACTION;

        SELECT
            Message = N'Đã clone workflow thành công.',
            DefinitionID = @NewDefinitionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ISNULL(ERROR_SEVERITY(), 16);
        DECLARE @ErrorState INT = ISNULL(ERROR_STATE(), 1);

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
