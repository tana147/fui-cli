
CREATE PROCEDURE [dbo].[spAPI_WF_Request_SyncEContract]
    @InstanceID BIGINT,
    @HopDongID BIGINT = 0,
    @ContractStatusCode VARCHAR(50) = NULL,
    @ContractStatusText NVARCHAR(200) = NULL,
    @SignStatusCode VARCHAR(50) = NULL,
    @SignStatusText NVARCHAR(200) = NULL,
    @DownloadFileID VARCHAR(50) = NULL,
    @DownloadFileName NVARCHAR(255) = NULL,
    @ExternalDocumentUrl NVARCHAR(1000) = NULL,
    @ExternalDocumentName NVARCHAR(255) = NULL,
    @ProviderPayload NVARCHAR(MAX) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExecutionEngine VARCHAR(20) = '';
    DECLARE @ContractProvider VARCHAR(50) = '';
    DECLARE @CurrentStepOrder INT = 0;
    DECLARE @CurrentExecutionID BIGINT = 0;
    DECLARE @DocumentFileUrl NVARCHAR(500) = NULL;
    DECLARE @ActionDetail NVARCHAR(MAX) = N'';
    DECLARE @SelectedFileJson NVARCHAR(MAX) = NULL;
    DECLARE @SourceFileID UNIQUEIDENTIFIER = NULL;
    DECLARE @CurrentDocumentFileID UNIQUEIDENTIFIER = NULL;
    DECLARE @RequiresSignedFile BIT = 0;
    DECLARE @ResolvedExternalDocumentUrl NVARCHAR(1000) = NULL;
    DECLARE @ResolvedExternalDocumentName NVARCHAR(255) = NULL;
    DECLARE @HasProviderSigner BIT = 0;
    DECLARE @HasRejected BIT = 0;
    DECLARE @RejectedSignerOrder INT = 0;
    DECLARE @HasSignedSigner BIT = 0;
    DECLARE @NextWaitingUserID VARCHAR(9) = NULL;
    DECLARE @NextExecutionID BIGINT = 0;
    DECLARE @NextStepOrder INT = 0;

    SELECT
        @ExecutionEngine = UPPER(ISNULL(ExecutionEngine, '')),
        @ContractProvider = UPPER(ISNULL(ContractProvider, '')),
        @CurrentStepOrder = ISNULL(CurrentStepOrder, 0),
        @SourceFileID = SourceFileID
    FROM dbo.tblWF_Instance
    WHERE InstanceID = @InstanceID
      AND [Enable] = 0;

    IF ISNULL(@ExecutionEngine, '') = ''
    BEGIN
        SELECT TOP (1)
            @ExecutionEngine = UPPER(ISNULL(B.ExecutionEngine, '')),
            @ContractProvider = COALESCE(NULLIF(@ContractProvider, ''), UPPER(ISNULL(B.ContractProvider, '')))
        FROM dbo.tblWF_InstanceSignBox AS B
        WHERE B.InstanceID = @InstanceID
          AND B.[Enable] = 0
          AND (ISNULL(B.ExecutionEngine, '') <> '' OR ISNULL(B.ContractProvider, '') <> '')
        ORDER BY B.BoxOrder, B.InstanceSignBoxID;
    END

    IF ISNULL(@ExecutionEngine, '') = ''
    BEGIN
        SELECT TOP (1)
            @ExecutionEngine =
                CASE
                    WHEN LOWER(ISNULL(SE.SignMethod, '')) IN ('econtract', 'otp_email', 'otp_sms', 'image') THEN 'ECONTRACT'
                    ELSE ''
                END
        FROM dbo.tblWF_StepExecution AS EX
        INNER JOIN dbo.tblWF_StepSignerExec AS SE
            ON SE.ExecutionID = EX.ExecutionID
           AND SE.[Enable] = 0
        WHERE EX.InstanceID = @InstanceID
          AND EX.[Enable] = 0
        ORDER BY EX.StepOrder, SE.SignerOrder;
    END

    IF ISNULL(@ExecutionEngine, '') <> 'ECONTRACT'
    BEGIN
        RAISERROR(N'Instance không thuộc engine eContract.', 16, 1);
        RETURN;
    END

    UPDATE dbo.tblWF_Instance
    SET ExecutionEngine = 'ECONTRACT',
        ContractProvider = CASE WHEN ISNULL(@ContractProvider, '') <> '' THEN @ContractProvider ELSE ContractProvider END,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE InstanceID = @InstanceID
      AND [Enable] = 0
      AND
      (
          ISNULL(ExecutionEngine, '') <> 'ECONTRACT'
          OR (ISNULL(ContractProvider, '') = '' AND ISNULL(@ContractProvider, '') <> '')
      );

    SELECT TOP (1)
        @CurrentExecutionID = ExecutionID
    FROM dbo.tblWF_StepExecution
    WHERE InstanceID = @InstanceID
      AND StepOrder = @CurrentStepOrder
      AND [Enable] = 0
    ORDER BY ExecutionID DESC;

    SELECT
        @CurrentDocumentFileID = DocumentFileID
    FROM dbo.tblWF_StepExecution
    WHERE ExecutionID = @CurrentExecutionID
      AND [Enable] = 0;

    SET @RequiresSignedFile =
        CASE
            WHEN TRY_CAST(NULLIF(LTRIM(RTRIM(ISNULL(@ContractStatusCode, ''))), '') AS INT) IN (9, 10) THEN 1
            WHEN TRY_CAST(NULLIF(LTRIM(RTRIM(ISNULL(@SignStatusCode, ''))), '') AS INT) = 8 THEN 1
            WHEN @ContractStatusText LIKE N'%Hoàn thành%' OR @ContractStatusText LIKE N'%Có hiệu lực%' THEN 1
            WHEN @SignStatusText LIKE N'%Hoàn thành%' THEN 1
            ELSE 0
        END;

    IF @RequiresSignedFile = 1
       AND ISNULL(NULLIF(LTRIM(RTRIM(ISNULL(@DownloadFileID, ''))), ''), '') = ''
    BEGIN
        RAISERROR(N'Hợp đồng eContract đã hoàn thành nhưng LHBS chưa nhận được file signed mới.', 16, 1);
        RETURN;
    END

    IF @RequiresSignedFile = 1
       AND ISNULL(NULLIF(LTRIM(RTRIM(ISNULL(@DownloadFileID, ''))), ''), '') <> ''
       AND
       (
           TRY_CAST(NULLIF(LTRIM(RTRIM(@DownloadFileID)), '') AS UNIQUEIDENTIFIER) = @SourceFileID
           OR TRY_CAST(NULLIF(LTRIM(RTRIM(@DownloadFileID)), '') AS UNIQUEIDENTIFIER) = @CurrentDocumentFileID
       )
    BEGIN
        RAISERROR(N'File eContract đồng bộ về vẫn trùng file gốc/runtime hiện tại. Chưa thể hoàn tất workflow.', 16, 1);
        RETURN;
    END

    DECLARE @ProviderSigner TABLE
    (
        SignerOrder INT NOT NULL,
        ProviderStatusCode INT NULL,
        ProviderStatusText NVARCHAR(200) NULL,
        SignedDate DATETIME NULL
    );

    ;WITH ProviderFiles AS
    (
        SELECT
            FileJson = F.[value],
            FlagMain = TRY_CAST(JSON_VALUE(F.[value], '$.FLAG_HD_CHINH') AS INT),
            StatusId = TRY_CAST(JSON_VALUE(F.[value], '$.TRANGTHAI_ID') AS INT)
        FROM OPENJSON(@ProviderPayload, '$.object') AS O
        CROSS APPLY OPENJSON(O.[value], '$.CHITIET_FILE') AS F
    )
    SELECT TOP (1) @SelectedFileJson = FileJson
    FROM ProviderFiles
    ORDER BY ISNULL(FlagMain, 0) DESC, ISNULL(StatusId, 0) DESC;

    IF ISNULL(@SelectedFileJson, N'') <> N''
    BEGIN
        SET @ResolvedExternalDocumentUrl = NULLIF(LTRIM(RTRIM(ISNULL(@ExternalDocumentUrl, N''))), N'');
        SET @ResolvedExternalDocumentName = NULLIF(LTRIM(RTRIM(ISNULL(@ExternalDocumentName, N''))), N'');

        IF @ResolvedExternalDocumentUrl IS NULL
        BEGIN
            SET @ResolvedExternalDocumentUrl = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@SelectedFileJson, '$.HD_FILE_URL'), N''))), N'');
            IF @ResolvedExternalDocumentUrl IS NOT NULL
               AND LEFT(@ResolvedExternalDocumentUrl, 4) <> 'http'
            BEGIN
                SET @ResolvedExternalDocumentUrl =
                    CASE
                        WHEN LEFT(@ResolvedExternalDocumentUrl, 1) = '/'
                            THEN N'https://econtract-v2-poc.vnpt.vn' + @ResolvedExternalDocumentUrl
                        ELSE N'https://econtract-v2-poc.vnpt.vn/' + @ResolvedExternalDocumentUrl
                    END;
            END
        END

        IF @ResolvedExternalDocumentName IS NULL
        BEGIN
            SET @ResolvedExternalDocumentName = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@SelectedFileJson, '$.HD_FILE_TEN'), N''))), N'');
        END
    END

    IF ISNULL(@SelectedFileJson, N'') <> N''
    BEGIN
        INSERT INTO @ProviderSigner
        (
            SignerOrder, ProviderStatusCode, ProviderStatusText, SignedDate
        )
        SELECT
            ISNULL(TRY_CAST(JSON_VALUE(NK.[value], '$.THUTU_KY') AS INT), 0),
            TRY_CAST(JSON_VALUE(NK.[value], '$.TRANGTHAI_KY') AS INT),
            LTRIM(RTRIM(ISNULL(JSON_VALUE(NK.[value], '$.TRANGTHAI_KY_FE'), N''))),
            COALESCE(
                TRY_CAST(JSON_VALUE(CK.[value], '$.NGAY_KY') AS DATETIME),
                TRY_CAST(JSON_VALUE(NK.[value], '$.THOIGIAN_XULY_NGAY') AS DATETIME),
                TRY_CAST(JSON_VALUE(NK.[value], '$.NGAY_GUI') AS DATETIME)
            )
        FROM OPENJSON(@SelectedFileJson, '$.CHITIET_NGUOIKY') AS NK
        OUTER APPLY
        (
            SELECT TOP (1) [value]
            FROM OPENJSON(NK.[value], '$.CHUKY')
        ) AS CK
        WHERE ISNULL(TRY_CAST(JSON_VALUE(NK.[value], '$.THUTU_KY') AS INT), 0) > 0;
    END

    IF EXISTS (SELECT 1 FROM @ProviderSigner)
    BEGIN
        SET @HasProviderSigner = 1;

        ;WITH SignerMap AS
        (
            SELECT
                SE.SignerExecID,
                SE.SignerOrder,
                IsRejected =
                    CASE
                        WHEN PS.ProviderStatusText LIKE N'%Từ chối%' THEN 1
                        WHEN PS.ProviderStatusCode IN (5, 6) THEN 1
                        ELSE 0
                    END,
                IsSigned =
                    CASE
                        WHEN PS.SignedDate IS NOT NULL THEN 1
                        WHEN PS.ProviderStatusText LIKE N'%Đã ký%' THEN 1
                        WHEN PS.ProviderStatusText LIKE N'%Hoàn thành%' THEN 1
                        WHEN PS.ProviderStatusCode IN (2, 8) THEN 1
                        ELSE 0
                    END,
                SignedDate = PS.SignedDate
            FROM dbo.tblWF_StepSignerExec AS SE
            LEFT JOIN @ProviderSigner AS PS
                ON PS.SignerOrder = SE.SignerOrder
            WHERE SE.ExecutionID = @CurrentExecutionID
              AND SE.[Enable] = 0
        )
        UPDATE SE
        SET Status =
                CASE
                    WHEN SM.IsRejected = 1 THEN 'REJECTED'
                    WHEN SM.IsSigned = 1 THEN 'SIGNED'
                    ELSE SE.Status
                END,
            SignedDate =
                CASE
                    WHEN SM.IsSigned = 1 THEN ISNULL(SM.SignedDate, ISNULL(SE.SignedDate, GETDATE()))
                    ELSE SE.SignedDate
                END,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        FROM dbo.tblWF_StepSignerExec AS SE
        INNER JOIN SignerMap AS SM
            ON SM.SignerExecID = SE.SignerExecID;

        SELECT TOP (1)
            @RejectedSignerOrder = SignerOrder
        FROM @ProviderSigner
        WHERE
            ProviderStatusText LIKE N'%Từ chối%'
            OR ProviderStatusCode IN (5, 6)
        ORDER BY SignerOrder;

        SET @HasRejected = CASE WHEN ISNULL(@RejectedSignerOrder, 0) > 0 THEN 1 ELSE 0 END;

        IF @HasRejected = 1
        BEGIN
            UPDATE dbo.tblWF_StepSignerExec
            SET Status =
                    CASE
                        WHEN SignerOrder = @RejectedSignerOrder THEN 'REJECTED'
                        WHEN SignerOrder > @RejectedSignerOrder AND Status IN ('WAITING', 'PENDING') THEN 'CANCELLED'
                        ELSE Status
                    END,
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            WHERE ExecutionID = @CurrentExecutionID
              AND [Enable] = 0;

            UPDATE dbo.tblWF_InstanceSignBox
            SET Status =
                    CASE
                        WHEN SignerOrder = @RejectedSignerOrder THEN 'REJECTED'
                        WHEN SignerOrder > @RejectedSignerOrder AND Status IN ('ACTIVE', 'PENDING') THEN 'CANCELLED'
                        WHEN SignerOrder < @RejectedSignerOrder THEN 'SIGNED'
                        ELSE Status
                    END,
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            WHERE InstanceID = @InstanceID
              AND ISNULL(StepOrder, @CurrentStepOrder) = @CurrentStepOrder
              AND [Enable] = 0;

            UPDATE dbo.tblWF_StepExecution
            SET Status = 'REJECTED',
                RejectedBy = @sys_UserID,
                RejectedReason = ISNULL(NULLIF(@SignStatusText, N''), N'Từ chối trên VNPT eContract'),
                RejectedDate = GETDATE(),
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            WHERE ExecutionID = @CurrentExecutionID
              AND [Enable] = 0;

            UPDATE dbo.tblWF_Instance
            SET Status = 'REJECTED',
                CurrentStepOrder = @CurrentStepOrder,
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            WHERE InstanceID = @InstanceID
              AND [Enable] = 0;
        END
        ELSE
        BEGIN
            SET @HasSignedSigner =
                CASE
                    WHEN EXISTS (
                        SELECT 1
                        FROM dbo.tblWF_StepSignerExec
                        WHERE ExecutionID = @CurrentExecutionID
                          AND [Enable] = 0
                          AND Status = 'SIGNED'
                    ) THEN 1
                    ELSE 0
                END;

            ;WITH PendingSigner AS
            (
                SELECT
                    SE.SignerExecID,
                    RN = ROW_NUMBER() OVER (ORDER BY SE.SignerOrder)
                FROM dbo.tblWF_StepSignerExec AS SE
                WHERE SE.ExecutionID = @CurrentExecutionID
                  AND SE.[Enable] = 0
                  AND SE.Status NOT IN ('SIGNED', 'REJECTED', 'CANCELLED')
            )
            UPDATE SE
            SET Status = CASE WHEN P.RN = 1 THEN 'WAITING' ELSE 'PENDING' END,
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            FROM dbo.tblWF_StepSignerExec AS SE
            INNER JOIN PendingSigner AS P
                ON P.SignerExecID = SE.SignerExecID;

            UPDATE B
            SET Status =
                    CASE
                        WHEN SE.Status = 'SIGNED' THEN 'SIGNED'
                        WHEN SE.Status = 'WAITING' THEN 'ACTIVE'
                        WHEN SE.Status = 'PENDING' THEN 'PENDING'
                        WHEN SE.Status = 'CANCELLED' THEN 'CANCELLED'
                        WHEN SE.Status = 'REJECTED' THEN 'REJECTED'
                        ELSE B.Status
                    END,
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            FROM dbo.tblWF_InstanceSignBox AS B
            INNER JOIN dbo.tblWF_StepSignerExec AS SE
                ON SE.SignerExecID = B.SignerExecID
               AND SE.[Enable] = 0
            WHERE B.InstanceID = @InstanceID
              AND B.[Enable] = 0
              AND SE.ExecutionID = @CurrentExecutionID;

            IF EXISTS (
                SELECT 1
                FROM dbo.tblWF_StepSignerExec
                WHERE ExecutionID = @CurrentExecutionID
                  AND [Enable] = 0
                  AND Status IN ('WAITING', 'PENDING')
            )
            BEGIN
                UPDATE dbo.tblWF_StepExecution
                SET Status = CASE WHEN @HasSignedSigner = 1 THEN 'SIGNING' ELSE 'ACTIVE' END,
                    UpdateUser = @sys_UserID,
                    UpdateTime = GETDATE()
                WHERE ExecutionID = @CurrentExecutionID
                  AND [Enable] = 0;

                SELECT TOP (1) @NextWaitingUserID = ResolvedPersonID
                FROM dbo.tblWF_StepSignerExec
                WHERE ExecutionID = @CurrentExecutionID
                  AND [Enable] = 0
                  AND Status = 'WAITING'
                ORDER BY SignerOrder;

                UPDATE dbo.tblWF_Instance
                SET Status = CASE WHEN @NextWaitingUserID = @sys_UserID THEN 'WAITING_ME' ELSE 'RUNNING' END,
                    CurrentStepOrder = @CurrentStepOrder,
                    UpdateUser = @sys_UserID,
                    UpdateTime = GETDATE()
                WHERE InstanceID = @InstanceID
                  AND [Enable] = 0;
            END
            ELSE
            BEGIN
                UPDATE dbo.tblWF_StepExecution
                SET Status = 'COMPLETED',
                    CompletedDate = ISNULL(CompletedDate, GETDATE()),
                    UpdateUser = @sys_UserID,
                    UpdateTime = GETDATE()
                WHERE ExecutionID = @CurrentExecutionID
                  AND [Enable] = 0;

                SELECT TOP (1)
                    @NextExecutionID = EX.ExecutionID,
                    @NextStepOrder = EX.StepOrder
                FROM dbo.tblWF_StepExecution AS EX
                WHERE EX.InstanceID = @InstanceID
                  AND EX.[Enable] = 0
                  AND EX.Status = 'PENDING'
                ORDER BY EX.StepOrder, EX.ExecutionID;

                IF ISNULL(@NextExecutionID, 0) > 0
                BEGIN
                    UPDATE dbo.tblWF_StepExecution
                    SET Status = 'ACTIVE',
                        StartedDate = ISNULL(StartedDate, GETDATE()),
                        UpdateUser = @sys_UserID,
                        UpdateTime = GETDATE()
                    WHERE ExecutionID = @NextExecutionID
                      AND [Enable] = 0;

                    UPDATE dbo.tblWF_StepSignerExec
                    SET Status = 'WAITING',
                        UpdateUser = @sys_UserID,
                        UpdateTime = GETDATE()
                    WHERE SignerExecID =
                    (
                        SELECT TOP (1) SignerExecID
                        FROM dbo.tblWF_StepSignerExec
                        WHERE ExecutionID = @NextExecutionID
                          AND [Enable] = 0
                        ORDER BY SignerOrder
                    );

                    SELECT TOP (1) @NextWaitingUserID = ResolvedPersonID
                    FROM dbo.tblWF_StepSignerExec
                    WHERE ExecutionID = @NextExecutionID
                      AND [Enable] = 0
                      AND Status = 'WAITING'
                    ORDER BY SignerOrder;

                    UPDATE dbo.tblWF_Instance
                    SET CurrentStepOrder = @NextStepOrder,
                        Status = CASE WHEN @NextWaitingUserID = @sys_UserID THEN 'WAITING_ME' ELSE 'RUNNING' END,
                        UpdateUser = @sys_UserID,
                        UpdateTime = GETDATE()
                    WHERE InstanceID = @InstanceID
                      AND [Enable] = 0;
                END
                ELSE
                BEGIN
                    UPDATE dbo.tblWF_Instance
                    SET Status = 'COMPLETED',
                        CurrentStepOrder = @CurrentStepOrder,
                        UpdateUser = @sys_UserID,
                        UpdateTime = GETDATE()
                    WHERE InstanceID = @InstanceID
                      AND [Enable] = 0;
                END
            END
        END
    END

    IF ISNULL(NULLIF(LTRIM(RTRIM(@DownloadFileID)), ''), '') <> ''
    BEGIN
        SET @DocumentFileUrl = N'https://file.zentea.vn/iotdev/FileData/' + LTRIM(RTRIM(@DownloadFileID));

        UPDATE dbo.tblWF_StepExecution
        SET DocumentFileID = TRY_CAST(LTRIM(RTRIM(@DownloadFileID)) AS UNIQUEIDENTIFIER),
            DocumentFileName = ISNULL(NULLIF(@DownloadFileName, N''), DocumentFileName),
            DocumentFileUrl = @DocumentFileUrl,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE ExecutionID = @CurrentExecutionID
          AND [Enable] = 0;
    END

    UPDATE dbo.tblWF_Instance
    SET ExternalContractID = CASE WHEN ISNULL(@HopDongID, 0) > 0 THEN @HopDongID ELSE ExternalContractID END,
        ExternalContractStatusCode = NULLIF(LTRIM(RTRIM(ISNULL(@ContractStatusCode, ''))), ''),
        ExternalContractStatusText = NULLIF(LTRIM(RTRIM(ISNULL(@ContractStatusText, N''))), N''),
        ExternalSignStatusCode = NULLIF(LTRIM(RTRIM(ISNULL(@SignStatusCode, ''))), ''),
        ExternalSignStatusText = NULLIF(LTRIM(RTRIM(ISNULL(@SignStatusText, N''))), N''),
        ExternalDocumentUrl = COALESCE(@ResolvedExternalDocumentUrl, ExternalDocumentUrl),
        ExternalDocumentName = COALESCE(@ResolvedExternalDocumentName, ExternalDocumentName),
        ExternalLastSyncTime = GETDATE(),
        ExternalProviderPayload = CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(@ProviderPayload, N''))), N'') IS NOT NULL THEN @ProviderPayload ELSE ExternalProviderPayload END,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE InstanceID = @InstanceID
      AND [Enable] = 0;

    SET @ActionDetail = N'HoSo=' + ISNULL(CAST(NULLIF(@HopDongID, 0) AS NVARCHAR(30)), N'-')
        + N' | TrangThaiHD=' + ISNULL(NULLIF(@ContractStatusText, N''), ISNULL(NULLIF(@ContractStatusCode, ''), N'-'))
        + N' | TrangThaiKy=' + ISNULL(NULLIF(@SignStatusText, N''), ISNULL(NULLIF(@SignStatusCode, ''), N'-'))
        + CASE WHEN ISNULL(NULLIF(LTRIM(RTRIM(@DownloadFileID)), ''), '') <> '' THEN N' | FileID=' + LTRIM(RTRIM(@DownloadFileID)) ELSE N'' END
        + CASE WHEN ISNULL(@ResolvedExternalDocumentName, N'') <> N'' THEN N' | ExternalFile=' + @ResolvedExternalDocumentName ELSE N'' END;

    INSERT INTO dbo.tblWF_AuditLog
    (
        InstanceID, StepOrder, ActionCode, ActionDetail, UserID,
        CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
    )
    VALUES
    (
        @InstanceID, NULLIF(@CurrentStepOrder, 0), 'ECONTRACT_SYNC', @ActionDetail, @sys_UserID,
        @sys_UserID, GETDATE(), NULL, NULL, 0
    );

    SELECT
        Message = N'Đã đồng bộ trạng thái eContract.',
        InstanceID = @InstanceID,
        HopDongID = CASE WHEN ISNULL(@HopDongID, 0) > 0 THEN @HopDongID ELSE NULL END,
        ContractStatusCode = NULLIF(LTRIM(RTRIM(ISNULL(@ContractStatusCode, ''))), ''),
        ContractStatusText = NULLIF(LTRIM(RTRIM(ISNULL(@ContractStatusText, N''))), N''),
        SignStatusCode = NULLIF(LTRIM(RTRIM(ISNULL(@SignStatusCode, ''))), ''),
        SignStatusText = NULLIF(LTRIM(RTRIM(ISNULL(@SignStatusText, N''))), N''),
        DownloadFileID = NULLIF(LTRIM(RTRIM(ISNULL(@DownloadFileID, ''))), ''),
        SyncTime = GETDATE();
END
