
CREATE PROCEDURE [dbo].[spAPI_WF_RequestDraft_Submit]
    @DraftID BIGINT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DefinitionID BIGINT;
    DECLARE @RawData NVARCHAR(MAX);
    DECLARE @FieldJSON NVARCHAR(MAX);
    DECLARE @SignerJSON NVARCHAR(MAX);
    DECLARE @BoxJSON NVARCHAR(MAX);
    DECLARE @InstanceID BIGINT;
    DECLARE @Result TABLE
    (
        Message NVARCHAR(4000),
        InstanceID BIGINT,
        InstanceName NVARCHAR(200),
        Status VARCHAR(20),
        CurrentStepOrder INT,
        CreateMode VARCHAR(20)
    );

    IF NOT EXISTS (SELECT 1 FROM dbo.tblWF_RequestDraft WHERE DraftID = @DraftID AND [Enable] = 0)
    BEGIN
        RAISERROR(N'Không tìm thấy draft để trình ký.', 16, 1);
        RETURN;
    END

    SELECT @FieldJSON =
    (
        SELECT
            FieldName,
            FieldLabel,
            FieldValue AS [Value]
        FROM dbo.tblWF_RequestDraftField
        WHERE DraftID = @DraftID
          AND [Enable] = 0
        FOR JSON PATH
    );

    SELECT @SignerJSON =
    (
        SELECT
            SignerOrder AS SignOrder,
            StepOrder,
            StepName,
            SignerType,
            SignerValue,
            PersonName,
            SignMethod,
            DepartmentName
        FROM dbo.tblWF_RequestDraftSigner
        WHERE DraftID = @DraftID
          AND [Enable] = 0
        ORDER BY SignerOrder, DraftSignerID
        FOR JSON PATH
    );

    SELECT @BoxJSON =
    (
        SELECT
            BoxOrder,
            PageNo,
            PosX,
            PosY,
            BoxWidth,
            BoxHeight,
            StepOrder,
            SignerOrder,
            SignerType,
            SignerValue,
            PersonName,
            DepartmentName,
            SignMethod,
            ExecutionEngine,
            ContractProvider,
            LabelText
        FROM dbo.tblWF_RequestDraftBox
        WHERE DraftID = @DraftID
          AND [Enable] = 0
        ORDER BY BoxOrder, DraftBoxID
        FOR JSON PATH
    );

    SELECT
        @DefinitionID = ISNULL(DefinitionID, 0),
        @RawData =
        (
            SELECT
                CreateMode,
                DefinitionID,
                CategoryID,
                DraftName AS InstanceName,
                ReferenceCode,
                Description,
                ExecutionEngine,
                ContractProvider,
                FileMethod,
                SourceFileID AS FileID,
                SourceFileName AS UploadFileName,
                TemplateID,
                DueDate,
                Priority,
                Sequential,
                NotifyEmail,
                RequireOtpConfirm,
                JSON_QUERY(ISNULL(@FieldJSON, '[]')) AS FieldValues,
                JSON_QUERY(ISNULL(@SignerJSON, '[]')) AS Signers,
                JSON_QUERY(ISNULL(@BoxJSON, '[]')) AS SignBoxes
            FROM dbo.tblWF_RequestDraft
            WHERE DraftID = @DraftID
              AND [Enable] = 0
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM dbo.tblWF_RequestDraft
    WHERE DraftID = @DraftID
      AND [Enable] = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO @Result
        EXEC dbo.spAPI_WF_Request_Create
            @DefinitionID = @DefinitionID,
            @sys_UserID = @sys_UserID,
            @sys_RawData = @RawData;

        SELECT TOP (1) @InstanceID = InstanceID FROM @Result;

        UPDATE dbo.tblWF_RequestDraft
        SET SubmittedInstanceID = @InstanceID,
            Status = 'SUBMITTED',
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE DraftID = @DraftID
          AND [Enable] = 0;

        COMMIT TRANSACTION;

        SELECT * FROM @Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END
