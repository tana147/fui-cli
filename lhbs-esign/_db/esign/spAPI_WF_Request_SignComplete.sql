CREATE PROCEDURE [dbo].[spAPI_WF_Request_SignComplete]
    @InstanceID BIGINT,
    @SignerExecID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SignCertInfo   NVARCHAR(MAX) = JSON_VALUE(@sys_RawData, '$.SignCertInfo');
    DECLARE @ActionDetail   NVARCHAR(MAX) = ISNULL(JSON_VALUE(@sys_RawData, '$.ActionDetail'), N'Đã ký hoàn tất yêu cầu.');
    DECLARE @OtpCode        VARCHAR(32)   = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.OtpCode'), '')));
    DECLARE @SignedFileID   VARCHAR(100)  = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SignedFileID'), '')));
    DECLARE @SignedFileName NVARCHAR(255) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SignedFileName'), '')));
    DECLARE @ResolvedSignerExecID BIGINT = 0;
    DECLARE @ExecutionID BIGINT = 0;
    DECLARE @CurrentStepOrder INT = 0;
    DECLARE @CurrentSignerMethodRaw VARCHAR(100) = '';
    DECLARE @CurrentSignerMethod VARCHAR(100) = '';
    DECLARE @ApprovedSignCertInfo NVARCHAR(MAX) = N'';
    DECLARE @FallbackProfileCertSerial VARCHAR(128) = '';
    DECLARE @MaskedOtpSuffix VARCHAR(8) = '';
    DECLARE @NextExecutionID BIGINT = 0;
    DECLARE @NextStepOrder INT = 0;
    DECLARE @NextWaitingUserID VARCHAR(9) = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tblWF_Instance
            WHERE InstanceID = @InstanceID
              AND [Enable] = 1
        )
        BEGIN
            RAISERROR(N'Không tìm thấy yêu cầu ký.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF ISNULL(@SignerExecID, 0) > 0
        BEGIN
            SELECT TOP (1)
                @ResolvedSignerExecID = SE.SignerExecID,
                @ExecutionID = SE.ExecutionID
            FROM dbo.tblWF_StepSignerExec AS SE
            INNER JOIN dbo.tblWF_StepExecution AS EX
                ON EX.ExecutionID = SE.ExecutionID
               AND EX.[Enable] = 1
            OUTER APPLY
            (
                -- Fallback: lấy mã NV từ sig field nếu DB chưa được cập nhật đúng
                SELECT TOP 1
                    NULLIF(LTRIM(RTRIM(ID.FieldValue)), '') AS FieldEmpCode
                FROM dbo.tblWF_InstanceSignBox AS SB
                INNER JOIN dbo.tblWF_InstanceData AS ID
                    ON  ID.InstanceID = @InstanceID
                    AND ID.[Enable]   = 1
                    AND ID.FieldName  =
                        CASE
                            WHEN SB.LabelText LIKE '{{%}}'   THEN SUBSTRING(SB.LabelText, 3, LEN(SB.LabelText) - 4)
                            WHEN SB.LabelText LIKE '###%###' THEN SUBSTRING(SB.LabelText, 4, LEN(SB.LabelText) - 6)
                            ELSE SB.LabelText
                        END
                WHERE SB.InstanceID  = @InstanceID
                  AND SB.StepOrder   = EX.StepOrder
                  AND SB.SignerOrder  = SE.SignerOrder
                  AND SB.[Enable]     = 1
                  AND NULLIF(LTRIM(RTRIM(ID.FieldValue)), '') IS NOT NULL
            ) AS SFD
            WHERE SE.SignerExecID = @SignerExecID
              AND EX.InstanceID = @InstanceID
              AND EX.Status IN ('ACTIVE', 'SIGNING')
              AND SE.Status IN ('WAITING', 'SIGNED')
              AND SE.[Enable] = 1
              AND (
                  UPPER(ISNULL(SE.ResolvedPersonID, '')) = UPPER(@sys_UserID)
                  OR UPPER(ISNULL(SFD.FieldEmpCode, '')) = UPPER(@sys_UserID)
              );

            IF ISNULL(@ResolvedSignerExecID, 0) = 0
            BEGIN
                RAISERROR(N'SignerExecID không hợp lệ hoặc không thuộc lượt ký hiện tại của bạn.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        IF ISNULL(@SignerExecID, 0) <= 0
           AND ISNULL(@ResolvedSignerExecID, 0) = 0
        BEGIN
            SELECT TOP (1)
                @ResolvedSignerExecID = SE.SignerExecID,
                @ExecutionID = SE.ExecutionID
            FROM dbo.tblWF_StepSignerExec AS SE
            INNER JOIN dbo.tblWF_StepExecution AS EX
                ON EX.ExecutionID = SE.ExecutionID
               AND EX.[Enable] = 1
            OUTER APPLY
            (
                SELECT TOP 1
                    NULLIF(LTRIM(RTRIM(ID.FieldValue)), '') AS FieldEmpCode
                FROM dbo.tblWF_InstanceSignBox AS SB
                INNER JOIN dbo.tblWF_InstanceData AS ID
                    ON  ID.InstanceID = @InstanceID
                    AND ID.[Enable]   = 1
                    AND ID.FieldName  =
                        CASE
                            WHEN SB.LabelText LIKE '{{%}}'   THEN SUBSTRING(SB.LabelText, 3, LEN(SB.LabelText) - 4)
                            WHEN SB.LabelText LIKE '###%###' THEN SUBSTRING(SB.LabelText, 4, LEN(SB.LabelText) - 6)
                            ELSE SB.LabelText
                        END
                WHERE SB.InstanceID  = @InstanceID
                  AND SB.StepOrder   = EX.StepOrder
                  AND SB.SignerOrder  = SE.SignerOrder
                  AND SB.[Enable]     = 1
                  AND NULLIF(LTRIM(RTRIM(ID.FieldValue)), '') IS NOT NULL
            ) AS SFD
            WHERE EX.InstanceID = @InstanceID
              AND EX.Status IN ('ACTIVE', 'SIGNING')
              AND SE.Status IN ('WAITING', 'SIGNED')
              AND SE.[Enable] = 1
              AND (
                  UPPER(ISNULL(SE.ResolvedPersonID, '')) = UPPER(@sys_UserID)
                  OR UPPER(ISNULL(SFD.FieldEmpCode, '')) = UPPER(@sys_UserID)
              )
            ORDER BY EX.StepOrder, SE.SignerOrder;
        END

        IF ISNULL(@ResolvedSignerExecID, 0) = 0
        BEGIN
            RAISERROR(N'Không tìm thấy lượt ký hiện tại của người dùng.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @CurrentStepOrder = EX.StepOrder
        FROM dbo.tblWF_StepExecution AS EX
        WHERE EX.ExecutionID = @ExecutionID
          AND EX.[Enable] = 1;

        SELECT TOP (1)
            @CurrentSignerMethodRaw = ISNULL(SE.SignMethod, ''),
            @ApprovedSignCertInfo = ISNULL(SE.SignCertInfo, N'')
        FROM dbo.tblWF_StepSignerExec AS SE
        WHERE SE.SignerExecID = @ResolvedSignerExecID
          AND SE.[Enable] = 1;

        SET @CurrentSignerMethod = LOWER(@CurrentSignerMethodRaw);
        SET @SignCertInfo = LTRIM(RTRIM(ISNULL(@SignCertInfo, N'')));
        SET @ApprovedSignCertInfo = LTRIM(RTRIM(ISNULL(@ApprovedSignCertInfo, N'')));

        IF @CurrentSignerMethod = 'smartca'
        BEGIN
            IF @ApprovedSignCertInfo = N''
            BEGIN
                SELECT TOP (1)
                    @FallbackProfileCertSerial = ISNULL(P.CertSerial, '')
                FROM dbo.tblWF_User AS P
                WHERE P.[Enable] = 1
                  AND P.IsActive = 1
                  AND P.CertIsActive = 1
                  AND ISNULL(P.CertSerial, '') <> ''
                  AND (P.CertValidFrom IS NULL OR P.CertValidFrom <= GETDATE())
                  AND (P.CertValidTo IS NULL OR P.CertValidTo >= GETDATE())
                  AND
                  (
                        P.EmployeeCode = @sys_UserID
                        OR P.Email = @sys_UserID
                        OR CAST(P.LegacyUserID AS VARCHAR(50)) = @sys_UserID
                  )
                ORDER BY
                    CASE WHEN P.EmployeeCode = @sys_UserID THEN 0
                         WHEN P.Email = @sys_UserID THEN 1
                         WHEN CAST(P.LegacyUserID AS VARCHAR(50)) = @sys_UserID THEN 2
                         ELSE 9 END,
                    P.UserID DESC;

                SET @FallbackProfileCertSerial = LTRIM(RTRIM(ISNULL(@FallbackProfileCertSerial, '')));
                IF @FallbackProfileCertSerial <> ''
                    SET @ApprovedSignCertInfo = @FallbackProfileCertSerial;
            END

            IF @ApprovedSignCertInfo = N''
            BEGIN
                RAISERROR(N'Chưa có metadata chứng thư đã duyệt cho bước SmartCA hiện tại.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            IF LEN(@ApprovedSignCertInfo) < 6 OR LEN(@ApprovedSignCertInfo) > 64
               OR @ApprovedSignCertInfo LIKE '%[^0-9A-Za-z]%'
            BEGIN
                RAISERROR(N'Metadata chứng thư đã duyệt không hợp lệ. Yêu cầu chuỗi 6-64 ký tự chữ/số.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            IF @SignCertInfo <> N'' AND @SignCertInfo <> @ApprovedSignCertInfo
            BEGIN
                RAISERROR(N'Chỉ được dùng metadata chứng thư đã duyệt cho bước SmartCA hiện tại.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            SET @SignCertInfo = @ApprovedSignCertInfo;
        END

        IF @CurrentSignerMethod IN ('otp_email', 'otp_sms')
        BEGIN
            IF @OtpCode = ''
            BEGIN
                RAISERROR(N'Bước OTP yêu cầu nhập mã xác thực trước khi hoàn tất.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            IF @OtpCode LIKE '%[^0-9A-Za-z]%' OR LEN(@OtpCode) < 4 OR LEN(@OtpCode) > 12
            BEGIN
                RAISERROR(N'Mã OTP không hợp lệ. Vui lòng nhập 4-12 ký tự chữ/số.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            SET @MaskedOtpSuffix = CASE WHEN LEN(@OtpCode) >= 2 THEN RIGHT(@OtpCode, 2) ELSE @OtpCode END;
            SET @SignCertInfo = N'OTP:****' + @MaskedOtpSuffix;
            SET @ActionDetail = N'Đã xác nhận OTP cho bước ký. OtpRef=****' + @MaskedOtpSuffix;
        END

        UPDATE dbo.tblWF_StepSignerExec
        SET Status = 'SIGNED',
            SignedDate = GETDATE(),
            SignCertInfo = @SignCertInfo,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE SignerExecID = @ResolvedSignerExecID
          AND [Enable] = 1;

        -- [XÓA BỎ/COMMENT]: Không update lại file từ Frontend để tránh ghi đè file của Gateway
        -- Lưu file PDF đã ký vào execution (nếu frontend truyền SignedFileID)
        -- IF ISNULL(@SignedFileID, '') <> ''
        -- BEGIN
        --     UPDATE dbo.tblWF_StepExecution
        --     SET DocumentFileID   = @SignedFileID,
        --         DocumentFileName = ISNULL(NULLIF(@SignedFileName, ''), DocumentFileName),
        --         DocumentFileUrl  = N'https://file.zentea.vn/iotdev/FileData/' + @SignedFileID,
        --         UpdateUser       = @sys_UserID,
        --         UpdateTime       = GETDATE()
        --     WHERE InstanceID = @InstanceID
        --       AND StepOrder >= @CurrentStepOrder
        --       AND [Enable]    = 1;
        -- END

        -- Cập nhật trạng thái ô ký này sang SIGNED
        UPDATE dbo.tblWF_InstanceSignBox
        SET Status = 'SIGNED',
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE SignerExecID = @ResolvedSignerExecID
          AND [Enable] = 1;

        INSERT INTO dbo.tblWF_AuditLog
        (
            InstanceID, StepOrder, ActionCode, ActionDetail, UserID,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            @InstanceID, @CurrentStepOrder, 'SIGNED', @ActionDetail, @sys_UserID,
            @sys_UserID, GETDATE(), NULL, NULL, 1
        );

        IF EXISTS (
            SELECT 1
            FROM dbo.tblWF_StepSignerExec
            WHERE ExecutionID = @ExecutionID
              AND [Enable] = 1
              AND Status = 'PENDING'
        )
        BEGIN
            DECLARE @NextSignerExecID BIGINT;
            SELECT TOP (1) @NextSignerExecID = SignerExecID
            FROM dbo.tblWF_StepSignerExec
            WHERE ExecutionID = @ExecutionID
              AND [Enable] = 1
              AND Status = 'PENDING'
            ORDER BY SignerOrder;

            UPDATE dbo.tblWF_StepSignerExec
            SET Status = 'WAITING',
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            WHERE SignerExecID = @NextSignerExecID;

            -- Cập nhật trạng thái ô ký tiếp theo sang ACTIVE
            UPDATE dbo.tblWF_InstanceSignBox
            SET Status = 'ACTIVE'
            WHERE SignerExecID = @NextSignerExecID
              AND [Enable] = 1;


            UPDATE dbo.tblWF_StepExecution
            SET Status = 'SIGNING',
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            WHERE ExecutionID = @ExecutionID
              AND [Enable] = 1;

            SELECT TOP (1) @NextWaitingUserID = ResolvedPersonID
            FROM dbo.tblWF_StepSignerExec
            WHERE ExecutionID = @ExecutionID
              AND [Enable] = 1
              AND Status = 'WAITING'
            ORDER BY SignerOrder;

            UPDATE dbo.tblWF_Instance
            SET Status = CASE WHEN @NextWaitingUserID = @sys_UserID THEN 'WAITING_ME' ELSE 'RUNNING' END,
                CurrentStepOrder = @CurrentStepOrder,
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            WHERE InstanceID = @InstanceID
              AND [Enable] = 1;
        END
        ELSE
        BEGIN
            UPDATE dbo.tblWF_StepExecution
            SET Status = 'COMPLETED',
                CompletedDate = ISNULL(CompletedDate, GETDATE()),
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            WHERE ExecutionID = @ExecutionID
              AND [Enable] = 1;

            SELECT TOP (1)
                @NextExecutionID = EX.ExecutionID,
                @NextStepOrder = EX.StepOrder
            FROM dbo.tblWF_StepExecution AS EX
            WHERE EX.InstanceID = @InstanceID
              AND EX.[Enable] = 1
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
                  AND [Enable] = 1;

                -- Kế thừa DocumentFileID từ lượt ký trước để người tiếp theo thấy file đã ký
                UPDATE dbo.tblWF_StepExecution
                SET DocumentFileID   = ISNULL((SELECT DocumentFileID FROM dbo.tblWF_StepExecution WHERE ExecutionID = @ExecutionID), DocumentFileID),
                    DocumentFileName = ISNULL((SELECT DocumentFileName FROM dbo.tblWF_StepExecution WHERE ExecutionID = @ExecutionID), DocumentFileName),
                    DocumentFileUrl  = ISNULL((SELECT DocumentFileUrl FROM dbo.tblWF_StepExecution WHERE ExecutionID = @ExecutionID), DocumentFileUrl)
                WHERE InstanceID = @InstanceID
                  AND StepOrder >= @NextStepOrder
                  AND [Enable] = 1;

                UPDATE dbo.tblWF_StepSignerExec
                SET Status = 'WAITING',
                    UpdateUser = @sys_UserID,
                    UpdateTime = GETDATE()
                WHERE SignerExecID =
                (
                    SELECT TOP (1) SignerExecID
                    FROM dbo.tblWF_StepSignerExec
                    WHERE ExecutionID = @NextExecutionID
                      AND [Enable] = 1
                    ORDER BY SignerOrder
                );

                -- Cập nhật trạng thái ô ký sang ACTIVE cho signer đang WAITING
                UPDATE dbo.tblWF_InstanceSignBox
                SET Status = 'ACTIVE'
                WHERE ExecutionID = @NextExecutionID
                  AND [Enable] = 1
                  AND SignerExecID IN (
                      SELECT SignerExecID
                      FROM dbo.tblWF_StepSignerExec
                      WHERE ExecutionID = @NextExecutionID
                        AND Status = 'WAITING'
                        AND [Enable] = 1
                  );

                -- Cập nhật ResolvedPersonID từ signature fields trong InstanceData
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
                    SE.UpdateTime = GETDATE(),
                    SE.UpdateUser = @sys_UserID
                FROM dbo.tblWF_StepSignerExec SE
                INNER JOIN dbo.tblWF_InstanceSignBox B
                    ON B.SignerExecID = SE.SignerExecID AND B.[Enable] = 1 AND B.InstanceID = @InstanceID
                INNER JOIN dbo.tblWF_InstanceData ID
                    ON ID.InstanceID = @InstanceID AND ID.FieldName = B.LabelText AND ID.[Enable] = 1
                WHERE SE.ExecutionID = @NextExecutionID
                  AND SE.[Enable] = 1
                  AND ISNULL(SE.ResolvedPersonID, '') = ''
                  AND ISNULL(ID.FieldValue, '') <> ''
                  AND LEN(LTRIM(RTRIM(ID.FieldValue))) BETWEEN 1 AND 20;

                SELECT TOP (1) @NextWaitingUserID = ResolvedPersonID
                FROM dbo.tblWF_StepSignerExec
                WHERE ExecutionID = @NextExecutionID
                  AND [Enable] = 1
                  AND Status = 'WAITING'
                ORDER BY SignerOrder;

                UPDATE dbo.tblWF_Instance
                SET CurrentStepOrder = @NextStepOrder,
                    Status = CASE WHEN @NextWaitingUserID = @sys_UserID THEN 'WAITING_ME' ELSE 'RUNNING' END,
                    UpdateUser = @sys_UserID,
                    UpdateTime = GETDATE()
                WHERE InstanceID = @InstanceID
                  AND [Enable] = 1;
            END
            ELSE
            BEGIN
                UPDATE dbo.tblWF_Instance
                SET Status = 'COMPLETED',
                    CurrentStepOrder = @CurrentStepOrder,
                    UpdateUser = @sys_UserID,
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
                    @InstanceID, @CurrentStepOrder, 'INSTANCE_COMPLETED', N'Yêu cầu ký đã hoàn tất.', @sys_UserID,
                    @sys_UserID, GETDATE(), NULL, NULL, 1
                );
            END
        END

        -- ── Đồng bộ DocumentFileUrl khớp với DocumentFileID ─────────────────
        -- (Gateway _LuotKy chỉ update DocumentFileID mà KHÔNG update DocumentFileUrl)
        UPDATE dbo.tblWF_StepExecution
        SET DocumentFileUrl  = CAST(DocumentFileID AS VARCHAR(50)),
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID
          AND [Enable] = 1
          AND StepOrder >= @CurrentStepOrder
          AND DocumentFileID IS NOT NULL
          AND (
              DocumentFileUrl IS NULL
              OR DocumentFileUrl NOT LIKE N'%' + CAST(DocumentFileID AS VARCHAR(50)) + N'%'
          );

        -- ── Đảm bảo DocumentFileName là .pdf sau khi ký ─────────────────────
        -- (phòng trường hợp Gateway _LuotKy ghi đè tên .docx vào DB)
        UPDATE dbo.tblWF_StepExecution
        SET DocumentFileName = REPLACE(DocumentFileName, '.docx', '.pdf'),
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID
          AND [Enable] = 1
          AND StepOrder >= @CurrentStepOrder
          AND DocumentFileName LIKE '%.docx';

        UPDATE dbo.tblWF_StepExecution
        SET DocumentFileName = STUFF(DocumentFileName, LEN(DocumentFileName) - 3, 4, '.pdf'),
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID
          AND [Enable] = 1
          AND StepOrder >= @CurrentStepOrder
          AND DocumentFileName LIKE '%.doc'
          AND DocumentFileName NOT LIKE '%.docx'
          AND DocumentFileName NOT LIKE '%.pdf';

        -- Sửa SourceFileName ở Instance nếu cần
        UPDATE dbo.tblWF_Instance
        SET SourceFileName = REPLACE(SourceFileName, '.docx', '.pdf'),
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID
          AND [Enable] = 1
          AND SourceFileName LIKE '%.docx';

        COMMIT TRANSACTION;

        -- ── Kích hoạt tự động hóa ──────────────────────────────────────────────
        EXEC dbo.spAPI_WF_Automation_Execute
            @sys_UserID = @sys_UserID,
            @InstanceID = @InstanceID,
            @Event = 'STAGE_CHANGED',
            @InternalCall = 1;

        EXEC dbo.spAPI_WF_Request_GetDetail @InstanceID = @InstanceID, @sys_UserID = @sys_UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
