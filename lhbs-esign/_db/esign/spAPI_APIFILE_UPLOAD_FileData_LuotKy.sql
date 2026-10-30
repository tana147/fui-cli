CREATE PROCEDURE [dbo].[spAPI_APIFILE_UPLOAD_FileData_LuotKy]
    @ChiTietID BIGINT,
    @AccessCode VARCHAR(32),
    @CTS VARCHAR(32),
    @JSON_ChungThuSo_SauKhiKy NVARCHAR(MAX) = NULL,
    @FileBase64 NVARCHAR(MAX),
    @FileName NVARCHAR(200),
    @FileContentType VARCHAR(100),
    @sys_UserID VARCHAR(9),
    @sys_GroupID INT,
    @sys_SystemRight INT,
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @FileBase64Clean NVARCHAR(MAX) = LTRIM(RTRIM(ISNULL(@FileBase64, '')));
        DECLARE @FileBinary VARBINARY(MAX) = NULL;
        DECLARE @FileID VARCHAR(36) = REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '');
        DECLARE @FileSize INT = 0;
        DECLARE @UseUserID VARCHAR(9) = LTRIM(RTRIM(ISNULL(@sys_UserID, '')));
        DECLARE @InstanceID BIGINT = 0;
        DECLARE @ExecutionID BIGINT = 0;
        DECLARE @CurrentStepOrder INT = 0;
        DECLARE @SignerExecID BIGINT = ISNULL(@ChiTietID, 0);

        IF @FileBase64Clean = ''
            THROW 50001, N'FileBase64 is required.', 1;

        IF ISNULL(LTRIM(RTRIM(@FileName)), N'') = N''
            THROW 50002, N'FileName is required.', 1;

        IF CHARINDEX('base64,', LOWER(@FileBase64Clean)) > 0
            SET @FileBase64Clean = RIGHT(@FileBase64Clean, LEN(@FileBase64Clean) - CHARINDEX('base64,', LOWER(@FileBase64Clean)) - 6);

        SET @FileBase64Clean = REPLACE(REPLACE(REPLACE(@FileBase64Clean, CHAR(13), ''), CHAR(10), ''), ' ', '');

        SELECT @FileBinary = TRY_CAST('' AS XML).value('xs:base64Binary(sql:variable("@FileBase64Clean"))', 'VARBINARY(MAX)');
        IF @FileBinary IS NULL OR DATALENGTH(@FileBinary) = 0
            THROW 50003, N'Failed to decode FileBase64. The string might be empty or invalid.', 1;

        SET @FileSize = DATALENGTH(@FileBinary);
        IF ISNULL(@FileContentType, '') = ''
            SET @FileContentType = 'application/pdf';

        INSERT INTO [eSignature_File].[dbo].[tblFileData]
        (
            FileID,
            FileName,
            BinaryContent,
            ContentType,
            FileSize
        )
        VALUES
        (
            @FileID,
            @FileName,
            @FileBinary,
            @FileContentType,
            @FileSize
        );

        IF @UseUserID = '' AND ISNULL(@CTS, '') <> ''
        BEGIN
            SELECT TOP (1) @UseUserID = EmployeeCode
            FROM dbo.tblWF_User
            WHERE [Enable] = 1        
              AND IsActive = 1
              AND CertIsActive = 1
              AND CertSerial = @CTS
            ORDER BY UserID DESC;
        END

        IF @SignerExecID > 0
        BEGIN
            SELECT
                @ExecutionID = SE.ExecutionID,
                @InstanceID = EX.InstanceID,
                @CurrentStepOrder = EX.StepOrder
            FROM dbo.tblWF_StepSignerExec AS SE
            INNER JOIN dbo.tblWF_StepExecution AS EX
                ON EX.ExecutionID = SE.ExecutionID
               AND EX.[Enable] = 1    
            WHERE SE.SignerExecID = @SignerExecID
              AND SE.[Enable] = 1;    
        END

        IF @InstanceID > 0 AND @CurrentStepOrder > 0
        BEGIN
            -- Cập nhật file đã ký cho bước hiện tại và các bước kế tiếp chưa hoàn tất
            UPDATE EX
            SET EX.DocumentFileID   = @FileID,
                EX.DocumentFileName = @FileName,
                EX.DocumentFileUrl  = @FileID,
                EX.UpdateUser = NULLIF(@UseUserID, ''),
                EX.UpdateTime = GETDATE()
            FROM dbo.tblWF_StepExecution AS EX
            WHERE EX.InstanceID = @InstanceID
              AND EX.[Enable] = 1
              AND EX.StepOrder >= @CurrentStepOrder
              AND EX.Status IN ('PENDING', 'ACTIVE', 'SIGNING');

            -- Đánh dấu signer này đã ký xong
            -- (đảm bảo trạng thái đúng kể cả khi mobile user thoát app trước khi FE gọi SignComplete)
            UPDATE dbo.tblWF_StepSignerExec
            SET Status     = 'SIGNED',
                SignedDate = GETDATE(),
                UpdateUser = NULLIF(@UseUserID, ''),
                UpdateTime = GETDATE()
            WHERE SignerExecID = @SignerExecID
              AND [Enable]     = 1
              AND Status       = 'WAITING';

            UPDATE dbo.tblWF_Instance
            SET SourceFileID = @FileID,
                SourceFileName = @FileName,
                UpdateUser = NULLIF(@UseUserID, ''),
                UpdateTime = GETDATE()
            WHERE InstanceID = @InstanceID
              AND [Enable] = 1;      

            INSERT INTO dbo.tblWF_AuditLog
            (
                InstanceID, StepOrder, ActionCode, ActionDetail, UserID,
                CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
            )
            VALUES
            (
                @InstanceID,
                @CurrentStepOrder,
                'SIGNED_FILE_UPLOADED',
                N'Đã lưu file PDF sau khi ký. FileID=' + @FileID + N'; SignerExecID=' + CONVERT(NVARCHAR(30), @SignerExecID),
                NULLIF(@UseUserID, ''),
                NULLIF(@UseUserID, ''),
                GETDATE(),
                NULL,
                NULL,
                1                      
            );
        END

        SELECT
            FileID = @FileID,
            FileName = @FileName,
            FileContentType = @FileContentType,
            FileSize = @FileSize,
            FileUrl = '/FileData/' + @FileID,
            InstanceID = @InstanceID,
            ExecutionID = @ExecutionID,
            SignerExecID = @SignerExecID,
            Message = N'Lưu file ký thành công.';
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrNum INT = ERROR_NUMBER();
        RAISERROR(N'[spAPI_APIFILE_UPLOAD_FileData_LuotKy] failed. %s (Error %d)', 16, 1, @ErrMsg, @ErrNum);
    END CATCH
END
