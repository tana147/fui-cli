CREATE PROCEDURE [dbo].[spAPI_WF_Instance_AssignPIC]
    @sys_UserID  VARCHAR(9),
    @InstanceID  BIGINT,
    @AssignTo    NVARCHAR(100),
    @StepDefID   BIGINT       = NULL,  -- tuỳ chọn: chỉ gán trong execution của bước này
    @SignerExecID BIGINT      = NULL   -- tuỳ chọn: gán chính xác một signer exec cụ thể
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        -- Kiểm tra instance tồn tại
        IF NOT EXISTS(SELECT 1 FROM dbo.tblWF_Instance WHERE InstanceID = @InstanceID AND [Enable] = 1)
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy hồ sơ' AS Message
            RETURN
        END

        -- Resolve FullName và UserID từ profile (nếu có)
        DECLARE @ResolvedUserID BIGINT = NULL;
        DECLARE @ResolvedName NVARCHAR(200) = NULL;
        SELECT TOP 1 
            @ResolvedUserID = UserID,
            @ResolvedName = ISNULL(NULLIF(LTRIM(RTRIM(FullName)), N''), NULL)
        FROM dbo.tblWF_User
        WHERE [Enable] = 1
          AND ISNULL(IsActive, 1) = 1
          AND (
              UPPER(ISNULL(EmployeeCode, '')) = UPPER(ISNULL(@AssignTo, ''))
              OR UPPER(ISNULL(Email, ''))     = UPPER(ISNULL(@AssignTo, ''))
          )
        ORDER BY
            CASE WHEN UPPER(ISNULL(EmployeeCode,'')) = UPPER(ISNULL(@AssignTo,'')) THEN 0 ELSE 1 END,
            UserID DESC;

        -- Cập nhật AssigneeCode cho Instance
        UPDATE dbo.tblWF_Instance
        SET AssigneeCode = @AssignTo,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID AND [Enable] = 1;

        -- 🟢 [MỚI] Cập nhật đồng bộ cho bảng thực thi gán quyền mới tblWF_StepAssigneeExec
        UPDATE ae
        SET ae.EmployeeID   = ISNULL(@ResolvedUserID, ae.EmployeeID),
            ae.EmployeeCode = @AssignTo,
            ae.FullName     = ISNULL(@ResolvedName, ae.FullName),
            ae.UpdateTime   = GETDATE(),
            ae.UpdateUser   = @sys_UserID
        FROM dbo.tblWF_StepAssigneeExec ae
        INNER JOIN dbo.tblWF_StepExecution ex ON ex.ExecutionID = ae.ExecutionID
        WHERE ex.InstanceID = @InstanceID
          AND ex.Status     = 'ACTIVE'
          AND ex.[Enable]   = 1
          AND ae.[Enable]   = 1
          AND (@StepDefID IS NULL OR ex.StepDefID = @StepDefID);

        IF @SignerExecID IS NOT NULL
        BEGIN
            -- Chế độ chính xác: gán đúng SignerExecID được chỉ định (bất kể status)
            -- Hoặc vô hiệu hoá nếu AssignTo rỗng
            UPDATE se
            SET se.ResolvedPersonID   = CASE WHEN ISNULL(@AssignTo, '') = '' THEN NULL ELSE @AssignTo END,
                se.ResolvedPersonName = CASE WHEN ISNULL(@AssignTo, '') = '' THEN NULL ELSE ISNULL(@ResolvedName, se.ResolvedPersonName) END,
                se.[Status]           = CASE WHEN ISNULL(@AssignTo, '') = '' THEN 'DISABLED' ELSE se.[Status] END,
                se.[Enable]           = CASE WHEN ISNULL(@AssignTo, '') = '' THEN 0 ELSE se.[Enable] END,
                se.UpdateTime         = GETDATE(),
                se.UpdateUser         = @sys_UserID
            FROM dbo.tblWF_StepSignerExec se
            WHERE se.SignerExecID = @SignerExecID;

            -- 🟢 Đồng bộ hoặc vô hiệu hóa tương ứng trên tblWF_InstanceSignBox
            IF ISNULL(@AssignTo, '') = ''
            BEGIN
                UPDATE dbo.tblWF_InstanceSignBox
                SET [Enable] = 0,
                    UpdateTime = GETDATE(),
                    UpdateUser = @sys_UserID
                WHERE InstanceID = @InstanceID
                  AND SignerExecID = @SignerExecID;
            END
            ELSE
            BEGIN
                UPDATE dbo.tblWF_InstanceSignBox
                SET SignerValue = @AssignTo,
                    PersonName = ISNULL(@ResolvedName, PersonName),
                    UpdateTime = GETDATE(),
                    UpdateUser = @sys_UserID
                WHERE InstanceID = @InstanceID
                  AND SignerExecID = @SignerExecID;
            END
        END
        ELSE
        BEGIN
            -- Chế độ fallback: gán tất cả WAITING signers trong execution ACTIVE (hoặc của StepDefID chỉ định)
            UPDATE se
            SET se.ResolvedPersonID   = @AssignTo,
                se.ResolvedPersonName = ISNULL(@ResolvedName, se.ResolvedPersonName),
                se.UpdateTime         = GETDATE(),
                se.UpdateUser         = @sys_UserID
            FROM dbo.tblWF_StepSignerExec se
            INNER JOIN dbo.tblWF_StepExecution ex ON ex.ExecutionID = se.ExecutionID
            WHERE ex.InstanceID = @InstanceID
              AND ex.[Enable]   = 1
              AND ex.Status     = 'ACTIVE'
              AND se.[Enable]   = 1
              AND se.Status     = 'WAITING'
              AND (@StepDefID IS NULL OR ex.StepDefID = @StepDefID);

            -- 🟢 Đồng bộ sang tblWF_InstanceSignBox cho chế độ fallback
            UPDATE B
            SET B.SignerValue = @AssignTo,
                B.PersonName = ISNULL(@ResolvedName, B.PersonName),
                B.UpdateTime = GETDATE(),
                B.UpdateUser = @sys_UserID
            FROM dbo.tblWF_InstanceSignBox AS B
            INNER JOIN dbo.tblWF_StepSignerExec AS SE ON SE.SignerExecID = B.SignerExecID
            INNER JOIN dbo.tblWF_StepExecution AS EX ON EX.ExecutionID = SE.ExecutionID
            WHERE B.InstanceID = @InstanceID
              AND B.[Enable] = 1
              AND EX.[Enable] = 1
              AND EX.Status = 'ACTIVE'
              AND SE.[Enable] = 1
              AND SE.Status = 'WAITING'
              AND (@StepDefID IS NULL OR EX.StepDefID = @StepDefID);
        END

        SELECT CAST(1 AS BIT) AS Success,
               N'Đã gán người phụ trách: ' + @AssignTo AS Message
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message
    END CATCH
END
