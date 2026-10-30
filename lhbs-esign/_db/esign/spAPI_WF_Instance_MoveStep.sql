
    CREATE PROCEDURE [dbo].[spAPI_WF_Instance_MoveStep]
        @sys_UserID VARCHAR(9),
        @InstanceID BIGINT,
        @ToStepDefID BIGINT, -- ID của bước mới (cột mới) mà người dùng kéo tới
        @InternalCall INT = 0
    AS
    BEGIN

         IF @InternalCall IS NULL SET @InternalCall = 0

        SET NOCOUNT ON;
        BEGIN TRY
            -- 1. Lấy thông tin bước mới
            DECLARE @NewStepOrder  INT;
            DECLARE @NewStepName   NVARCHAR(200);
            DECLARE @NewStepType   VARCHAR(20);
            DECLARE @NewSignSystem VARCHAR(50);
            DECLARE @NewTemplateID BIGINT;
            DECLARE @NewStepCode   VARCHAR(50);
            DECLARE @NewRequireManualSendSign BIT;
            DECLARE @NewTemplatesJSON NVARCHAR(MAX);  -- [MULTI-TEMPLATE]
            DECLARE @NewDueHours   NVARCHAR(50);
            DECLARE @NewDueType    VARCHAR(20);

            SELECT
                @NewStepOrder  = SD.StepOrder,
                @NewStepName   = SD.StepName,
                @NewStepType   = SD.StepType,
                @NewSignSystem = SD.SignSystem,
                @NewTemplateID = SD.TemplateID,
                @NewStepCode   = SD.StepCode,
                @NewRequireManualSendSign = SD.RequireManualSendSign,
                @NewTemplatesJSON = SD.TemplatesJSON,  -- [MULTI-TEMPLATE]
                @NewDueHours   = SD.DueHours,
                @NewDueType    = SD.DueType
            FROM dbo.tblWF_StepDefinition AS SD
            WHERE SD.StepDefID = @ToStepDefID;

            -- Lấy step order hiện tại của Instance
            DECLARE @CurrentStepOrder INT;
            SELECT @CurrentStepOrder = CurrentStepOrder FROM dbo.tblWF_Instance WHERE InstanceID = @InstanceID;

            -- Kiểm tra nếu bước hiện tại của Instance là bước ký thủ công đang hoạt động và đã gửi đi ký (có DocumentFileID)
            IF @InternalCall = 0 AND EXISTS (
                SELECT 1
                FROM dbo.tblWF_StepExecution AS EX
                WHERE EX.InstanceID = @InstanceID
                  AND EX.Status = 'ACTIVE'
                  AND EX.[Enable] = 1
                  AND EX.StepType = 'SIGN'
                  AND EX.RequireManualSendSign = 1
                  -- AND EX.DocumentFileID IS NOT NULL
            )
            BEGIN
                RAISERROR(N'Bước hiện tại yêu cầu ký số thủ công. Bạn cần hoàn thành ký số để tự động chuyển bước.', 16, 1);
                RETURN 0;
            END

            -- Kiểm tra nếu chuyển ngược về bước Nhập dữ liệu (INPUT_ONLY) khi đã có chữ ký và là cuộc gọi thủ công từ UI
            IF @InternalCall = 0 AND @NewStepType = 'INPUT_ONLY' AND @NewStepOrder < @CurrentStepOrder AND EXISTS (
                SELECT 1
                FROM dbo.tblWF_StepSignerExec AS SE
                INNER JOIN dbo.tblWF_StepExecution AS EX ON EX.ExecutionID = SE.ExecutionID
                WHERE EX.InstanceID = @InstanceID
                  AND EX.[Enable] = 1
                  AND SE.[Enable] = 1
                  AND SE.Status = 'SIGNED'
            )
            BEGIN
                RAISERROR(N'Hồ sơ đã có chữ ký, không thể chuyển ngược về bước nhập dữ liệu.', 16, 1);
                RETURN 0;
            END

            BEGIN TRANSACTION;

            DECLARE @Now DATETIME = GETDATE();

            -- 2. Xác định trạng thái Instance dựa trên StepCode đích nghiệp vụ
            DECLARE @NewInstanceStatus VARCHAR(20) = 'RUNNING';

            IF @NewStepCode = 'STEP_SUCCESS'
                SET @NewInstanceStatus = 'COMPLETED';
            ELSE IF @NewStepCode = 'STEP_FAILURE'
                SET @NewInstanceStatus = 'REJECTED';
            ELSE
            BEGIN
                -- Luôn reset về RUNNING khi chuyển về bước xử lý thường
                -- Bao gồm cả trường hợp chuyển ngược từ bước SUCCESS/FAILURE (Status đang là COMPLETED/REJECTED)
                SET @NewInstanceStatus = 'RUNNING';
            END

            -- Tính toán hạn chót StepDueDate mới từ DueHours và DueType của bước đích
            DECLARE @HoursVal INT = TRY_CAST(@NewDueHours AS INT);
            DECLARE @CalculatedStepDueDate DATETIME = NULL;

            IF @HoursVal IS NOT NULL AND @HoursVal > 0
            BEGIN
                IF UPPER(ISNULL(@NewDueType, 'HOUR')) = 'DAY'
                    SET @CalculatedStepDueDate = DATEADD(DAY, @HoursVal, @Now);
                ELSE
                    SET @CalculatedStepDueDate = DATEADD(HOUR, @HoursVal, @Now);
            END

            -- 2b. Cập nhật Instance sang bước mới và trạng thái mới, bao gồm hạn chót mới (SLA)
            UPDATE dbo.tblWF_Instance
            SET CurrentStepOrder = @NewStepOrder,
                Status = @NewInstanceStatus,
                StepStartDate = @Now,
                StepDueDate = @CalculatedStepDueDate,
                UpdateTime = @Now,
                UpdateUser = @sys_UserID
            WHERE InstanceID = @InstanceID;

            -- 2b. [MỚI] Đóng gán quyền (tblWF_StepAssigneeExec) của các bước đang active sang COMPLETED
            UPDATE AE
            SET AE.Status     = 'COMPLETED',
                AE.UpdateTime = @Now,
                AE.UpdateUser = @sys_UserID
            FROM dbo.tblWF_StepAssigneeExec AS AE
            INNER JOIN dbo.tblWF_StepExecution AS EX ON EX.ExecutionID = AE.ExecutionID
            WHERE EX.InstanceID = @InstanceID
              AND EX.Status     = 'ACTIVE';

            -- 3. Vô hiệu hóa các execution cũ của bước đích và các bước sau nó (tránh trùng lặp khi chuyển ngược)
            UPDATE dbo.tblWF_StepExecution
            SET [Enable]      = 0,
                UpdateTime    = @Now,
                UpdateUser    = @sys_UserID
            WHERE InstanceID = @InstanceID
              AND StepOrder   >= @NewStepOrder;

            -- Vô hiệu hóa các signer tương ứng
            UPDATE SE
            SET SE.[Enable]   = 0,
                SE.UpdateTime = @Now,
                SE.UpdateUser = @sys_UserID
            FROM dbo.tblWF_StepSignerExec AS SE
            INNER JOIN dbo.tblWF_StepExecution AS EX ON EX.ExecutionID = SE.ExecutionID
            WHERE EX.InstanceID = @InstanceID
              AND EX.StepOrder   >= @NewStepOrder;

            -- 4. Đóng tất cả execution ACTIVE còn lại của instance (nếu có)
            UPDATE dbo.tblWF_StepExecution
            SET Status        = 'COMPLETED',
                CompletedDate = @Now,
                UpdateTime    = @Now,
                UpdateUser    = @sys_UserID
            WHERE InstanceID = @InstanceID
              AND Status      = 'ACTIVE';

            -- 5. Tạo execution MỚI (ACTIVE) cho bước đích
            -- [MULTI-TEMPLATE] Thêm TemplatesJSON vào INSERT
            INSERT INTO dbo.tblWF_StepExecution
            (
                InstanceID, StepDefID, StepOrder, StepName, StepType, SignSystem, TemplateID,
                TemplatesJSON,
                RequireManualSendSign,
                Status, StartedDate, [Enable], CreateTime, CreateUser
            )
            VALUES
            (
                @InstanceID, @ToStepDefID, @NewStepOrder, @NewStepName, @NewStepType, @NewSignSystem, @NewTemplateID,
                @NewTemplatesJSON,  -- [MULTI-TEMPLATE]
                ISNULL(@NewRequireManualSendSign, 0),
                'ACTIVE', @Now, 1, @Now, @sys_UserID
            );

            DECLARE @NewExecID BIGINT = SCOPE_IDENTITY();

            -- 6. Tạo StepSignerExec records cho execution mới (bước Ký)
            -- [MULTI-TEMPLATE] Nếu TemplatesJSON có giá trị → tạo signers từ từng slot
            --                  Ngược lại → legacy path: đọc từ tblWF_FieldMapping (FieldType='signature')
            IF @NewStepType IN ('SIGN', 'ECONTRACT')
            BEGIN
                IF @NewTemplatesJSON IS NOT NULL AND LEN(@NewTemplatesJSON) > 2
                BEGIN
                    -- [MULTI-TEMPLATE] Tạo signers từ TemplatesJSON
                    -- Resolve ROLE → tblWF_RoleMapping
                    -- Resolve FIELD_REF → tblWF_InstanceData (giá trị field đã nhập trước đó)
                    INSERT INTO dbo.tblWF_StepSignerExec
                    (
                        ExecutionID, SignerOrder, SignerType, SignerValue, DepartmentName,
                        ResolvedPersonID, ResolvedPersonName, SignMethod, Status,
                        TemplateSlotIdx,
                        SignedDate, SignCertInfo,
                        CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
                    )
                    SELECT
                        @NewExecID,
                        -- SignerOrder toàn cục: sắp xếp theo SlotIdx, rồi SignerOrder trong slot
                        ROW_NUMBER() OVER(ORDER BY Slot.SlotIdx, S.SignerOrder),
                        S.SignerType,
                        S.SignerValue,
                        N'',
                        -- ResolvedPersonID
                        CASE
                            WHEN UPPER(S.SignerType) = 'ROLE' THEN
                                LEFT(ISNULL(R.DefaultPersonID, ''), 9)
                            WHEN UPPER(S.SignerType) = 'FIELD_REF' THEN
                                CASE
                                    WHEN LEN(ISNULL(ID.FieldValue, '')) BETWEEN 1 AND 9 THEN LTRIM(RTRIM(ID.FieldValue))
                                    ELSE NULL
                                END
                            ELSE
                                CASE
                                    WHEN LEN(ISNULL(S.SignerValue, '')) BETWEEN 1 AND 9 THEN S.SignerValue
                                    ELSE NULL
                                END
                        END,
                        -- ResolvedPersonName
                        CASE
                            WHEN UPPER(S.SignerType) = 'ROLE' THEN ISNULL(R.DefaultPersonName, N'')
                            WHEN UPPER(S.SignerType) = 'FIELD_REF' THEN ISNULL(PF.ProfileName, N'')
                            ELSE N''
                        END,
                        S.SignMethod,
                        -- Status: slot đầu tiên, signer đầu tiên → WAITING (nếu không phải manual send)
                        CASE
                            WHEN ISNULL(@NewRequireManualSendSign, 0) = 1 THEN 'PENDING'
                            WHEN Slot.SlotIdx = MinSlot.MinSlotIdx AND S.SignerOrder = 1 THEN 'WAITING'
                            ELSE 'PENDING'
                        END,
                        Slot.SlotIdx,  -- TemplateSlotIdx
                        NULL, NULL,
                        @sys_UserID, @Now, NULL, NULL, 1
                    FROM (
                        -- Tìm SlotIdx nhỏ nhất để xác định signer WAITING đầu tiên
                        SELECT MIN(TRY_CAST(JSON_VALUE(X.[value], '$.SlotIdx') AS INT)) AS MinSlotIdx
                        FROM OPENJSON(@NewTemplatesJSON) AS X
                    ) AS MinSlot
                    CROSS JOIN OPENJSON(@NewTemplatesJSON)
                    WITH (
                        SlotIdx     INT           '$.SlotIdx',
                        SignSystem  VARCHAR(20)   '$.SignSystem',
                        SignersJSON NVARCHAR(MAX) '$.Signers' AS JSON
                    ) AS Slot
                    CROSS APPLY OPENJSON(Slot.SignersJSON)
                    WITH (
                        SignerOrder  INT           '$.SignerOrder',
                        SignerType   VARCHAR(20)   '$.SignerType',
                        SignerValue  NVARCHAR(200) '$.SignerValue',
                        SignMethod   VARCHAR(20)   '$.SignMethod',
                        IsSequential BIT           '$.IsSequential'
                    ) AS S
                    OUTER APPLY (
                        -- Resolve ROLE → RoleMapping
                        SELECT TOP 1 R2.DefaultPersonID, R2.DefaultPersonName
                        FROM dbo.tblWF_RoleMapping AS R2
                        WHERE R2.RoleCode = S.SignerValue
                          AND R2.[Enable] = 1
                        ORDER BY
                            CASE WHEN ISNULL(R2.DefaultPersonID, '') <> '' THEN 0 ELSE 1 END,
                            R2.RoleMappingID DESC
                    ) AS R
                    OUTER APPLY (
                        -- Resolve FIELD_REF → InstanceData (giá trị thực tế đã nhập)
                        SELECT TOP 1 LTRIM(RTRIM(ISNULL(ID2.FieldValue, ''))) AS FieldValue
                        FROM dbo.tblWF_InstanceData AS ID2
                        WHERE ID2.InstanceID = @InstanceID
                          AND ID2.FieldName  = S.SignerValue
                          AND ID2.[Enable]   = 1
                    ) AS ID
                    OUTER APPLY (
                        -- Lookup tên người từ FieldValue (email/mã NV)
                        SELECT TOP 1
                            ProfileName   = NULLIF(LTRIM(RTRIM(ISNULL(P.FullName, N''))), N''),
                            ProfileUserID = NULLIF(LTRIM(RTRIM(ISNULL(P.EmployeeCode, ''))), '')
                        FROM dbo.tblWF_User AS P
                        WHERE P.[Enable] = 1
                          AND ISNULL(P.IsActive, 1) = 1
                          AND (
                              UPPER(ISNULL(P.EmployeeCode, '')) = UPPER(ISNULL(ID.FieldValue, ''))
                              OR UPPER(ISNULL(P.Email, ''))     = UPPER(ISNULL(ID.FieldValue, ''))
                          )
                        ORDER BY
                            CASE WHEN UPPER(ISNULL(P.EmployeeCode, '')) = UPPER(ISNULL(ID.FieldValue, '')) THEN 0 ELSE 1 END,
                            P.UserID DESC
                    ) AS PF
                    WHERE Slot.SignersJSON IS NOT NULL AND LEN(Slot.SignersJSON) > 2;
                END
                ELSE
                BEGIN
                    -- Legacy path: tạo signers từ tblWF_FieldMapping (FieldType='signature')
                    INSERT INTO dbo.tblWF_StepSignerExec
                    (
                        ExecutionID, SignerOrder, SignerType, SignerValue, DepartmentName,
                        ResolvedPersonID, ResolvedPersonName, SignMethod, Status,
                        SignedDate, SignCertInfo,
                        CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
                    )
                    SELECT
                        @NewExecID,
                        ROW_NUMBER() OVER(ORDER BY FM.MappingID),
                        'USER',
                        ISNULL(ID.FieldValue, ''),
                        N'',
                        CASE
                            WHEN LEN(ISNULL(PF.ProfileUserID, '')) BETWEEN 1 AND 9 THEN PF.ProfileUserID
                            WHEN LEN(ISNULL(ID.FieldValue, ''))   BETWEEN 1 AND 9 THEN ID.FieldValue
                            ELSE NULL
                        END,
                        ISNULL(PF.ProfileName, N''),
                        CASE WHEN ISJSON(FM.FieldOptions) = 1 THEN ISNULL(JSON_VALUE(FM.FieldOptions, '$.provider'), 'smartca') ELSE 'smartca' END,
                        CASE
                            WHEN ISNULL(@NewRequireManualSendSign, 0) = 1 THEN 'PENDING'
                            WHEN ROW_NUMBER() OVER(ORDER BY FM.MappingID) = 1 THEN 'WAITING'
                            ELSE 'PENDING'
                        END,
                        NULL, NULL,
                        @sys_UserID, @Now, NULL, NULL, 1
                    FROM dbo.tblWF_FieldMapping AS FM
                    JOIN dbo.tblWF_Instance AS I ON I.InstanceID = @InstanceID
                    LEFT JOIN dbo.tblWF_InstanceData AS ID ON ID.InstanceID = @InstanceID AND ID.FieldName = FM.FieldName AND ID.[Enable] = 1
                    OUTER APPLY
                    (
                        SELECT TOP 1
                            ProfileUserID = NULLIF(LTRIM(RTRIM(ISNULL(P.EmployeeCode, ''))), ''),
                            ProfileName   = NULLIF(LTRIM(RTRIM(ISNULL(P.FullName, N''))), N'')
                        FROM dbo.tblWF_User AS P
                        WHERE P.[Enable] = 1
                          AND ISNULL(P.IsActive, 1) = 1
                          AND (
                              UPPER(ISNULL(P.EmployeeCode, '')) = UPPER(ISNULL(ID.FieldValue, ''))
                              OR UPPER(ISNULL(P.Email, ''))     = UPPER(ISNULL(ID.FieldValue, ''))
                          )
                        ORDER BY
                            CASE WHEN UPPER(ISNULL(P.EmployeeCode,'')) = UPPER(ISNULL(ID.FieldValue,'')) THEN 0 ELSE 1 END,
                            P.UserID DESC
                    ) AS PF
                    WHERE FM.DefinitionID = I.DefinitionID
                      AND FM.FieldType = 'signature'
                      AND FM.[Enable]  = 1;
                END
            END

            -- 6b. Cập nhật ExecutionID và SignerExecID mới cho các ô ký (tblWF_InstanceSignBox) tương ứng
            UPDATE B
            SET B.ExecutionID = SE.ExecutionID,
                B.SignerExecID = SE.SignerExecID,
                B.PersonName = SE.ResolvedPersonName,
                B.SignerValue = SE.SignerValue
            FROM dbo.tblWF_InstanceSignBox AS B
            INNER JOIN dbo.tblWF_StepSignerExec AS SE
                ON SE.ExecutionID = @NewExecID
               AND SE.SignerOrder = B.SignerOrder
               AND SE.[Enable] = 1
            WHERE B.InstanceID = @InstanceID
              AND B.StepOrder = @NewStepOrder
              AND B.[Enable] = 1;

            -- Dọn dẹp/Vô hiệu hóa các ô ký dư thừa của bước này mà không có người ký thực tế tương ứng (do thay đổi cấu hình)
            UPDATE B
            SET B.[Enable] = 0,
                B.UpdateTime = @Now,
                B.UpdateUser = @sys_UserID
            FROM dbo.tblWF_InstanceSignBox AS B
            LEFT JOIN dbo.tblWF_StepSignerExec AS SE
                ON SE.ExecutionID = @NewExecID
               AND SE.SignerOrder = B.SignerOrder
               AND SE.[Enable] = 1
            WHERE B.InstanceID = @InstanceID
              AND B.StepOrder = @NewStepOrder
              AND B.[Enable] = 1
              AND SE.SignerExecID IS NULL;

            -- 6c. [MỚI] Tự động tạo bản ghi thực thi gán quyền trong bảng tblWF_StepAssigneeExec từ tblWF_StepAssignee
            INSERT INTO dbo.tblWF_StepAssigneeExec
            (
                ExecutionID, StepAssigneeID, EmployeeID, EmployeeCode, FullName,
                RoleCode, RightCode, Status, CreateUser, CreateTime, [Enable]
            )
            SELECT
                @NewExecID,
                SA.StepAssigneeID,
                SA.EmployeeID,
                P.EmployeeCode,
                P.FullName,
                SA.RoleCode,
                SA.RightCode,
                'ACTIVE', -- Gán trạng thái ACTIVE cho bước mới hoạt động
                @sys_UserID, @Now, 1
            FROM dbo.tblWF_StepAssignee AS SA
            LEFT JOIN dbo.tblWF_User AS P ON SA.EmployeeID = P.UserID AND P.[Enable] = 1
            WHERE SA.StepDefID = @ToStepDefID
              AND SA.[Enable] = 1;

            -- 7. Clone tasks từ tblWF_Task vào tblWF_InstanceTask cho execution mới
            INSERT INTO dbo.tblWF_InstanceTask
                (ExecutionID, InstanceID, StepDefID, TaskName, Description, DueHours, Status, [Enable], CreateTime, CreateUser)
            SELECT
                @NewExecID, @InstanceID, @ToStepDefID,
                TaskName, Description, ISNULL(DueHours, N'0'),
                'TODO', 1, @Now, @sys_UserID
            FROM dbo.tblWF_Task
            WHERE StepDefID = @ToStepDefID AND [Enable] = 1;

            COMMIT TRANSACTION;

            -- ── Kích hoạt tự động hóa ──────────────────────────────────────────────
            EXEC dbo.spAPI_WF_Automation_Execute
                @sys_UserID   = @sys_UserID,
                @InstanceID   = @InstanceID,
                @Event        = 'STAGE_CHANGED',
                @InternalCall = 1;

            IF @InternalCall = 0
                SELECT 1 AS Success, N'Cập nhật bước thành công' AS Message;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
        END CATCH
    END
    