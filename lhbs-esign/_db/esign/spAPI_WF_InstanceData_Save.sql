CREATE PROCEDURE [dbo].[spAPI_WF_InstanceData_Save]
    @sys_UserID   VARCHAR(9),
    @InstanceID   BIGINT,
    @DataJSON  NVARCHAR(MAX) -- { "UpdatedAtStep": N, "Fields": [{"FieldName":"...","FieldValue":"..."},...] }
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UpdatedAtStep INT = TRY_CAST(JSON_VALUE(@DataJSON, '$.UpdatedAtStep') AS INT);
    DECLARE @Now DATETIME = GETDATE();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Trích xuất các trường từ JSON
        DECLARE @Fields TABLE (
            FieldName VARCHAR(100),
            FieldValue NVARCHAR(MAX)
        );

        INSERT INTO @Fields (FieldName, FieldValue)
        SELECT FieldName, FieldValue
        FROM OPENJSON(@DataJSON, '$.Fields')
        WITH (
            FieldName  VARCHAR(100)      '$.FieldName',
            FieldValue NVARCHAR(MAX)     '$.FieldValue'
        );

        -- 2. Cập nhật các trường đã tồn tại
        UPDATE D
        SET    D.FieldValue    = F.FieldValue,
               D.UpdatedAtStep = @UpdatedAtStep,
               D.UpdateUser    = @sys_UserID,
               D.UpdateTime    = @Now
        FROM   dbo.tblWF_InstanceData AS D
        INNER JOIN @Fields AS F ON F.FieldName = D.FieldName
        WHERE  D.InstanceID = @InstanceID
          AND  D.[Enable]   = 1;

        -- 3. Chèn thêm các trường chưa tồn tại
        INSERT INTO dbo.tblWF_InstanceData (
            InstanceID, FieldName, FieldValue, UpdatedAtStep,
            CreateUser, CreateTime, [Enable]
        )
        SELECT 
            @InstanceID, F.FieldName, F.FieldValue, @UpdatedAtStep,
            @sys_UserID, @Now, 1
        FROM @Fields AS F
        WHERE NOT EXISTS (
            SELECT 1 
            FROM dbo.tblWF_InstanceData AS D 
            WHERE D.InstanceID = @InstanceID 
              AND D.FieldName = F.FieldName
              AND D.[Enable] = 1
        );

        -- 4. Đồng bộ tblWF_StepSignerExec khi trường signature được cập nhật
        --    (Fix race condition: MoveStep tạo signer rỗng trước khi user nhập data)
        IF EXISTS (
            SELECT 1 FROM @Fields AS F
            INNER JOIN dbo.tblWF_FieldMapping AS FM
                ON FM.FieldName = F.FieldName AND FM.FieldType = 'signature' AND FM.[Enable] = 1
            INNER JOIN dbo.tblWF_Instance AS I
                ON I.InstanceID = @InstanceID AND FM.DefinitionID = I.DefinitionID
        )
        BEGIN
            -- Tính lại SignerOrder dựa trên FieldMapping (giống logic trong MoveStep)
            DECLARE @SigFieldMap TABLE (
                SignerOrder INT,
                FieldName VARCHAR(100),
                FieldValue NVARCHAR(MAX)
            );

            INSERT INTO @SigFieldMap (SignerOrder, FieldName, FieldValue)
            SELECT
                ROW_NUMBER() OVER(ORDER BY FM.MappingID),
                FM.FieldName,
                ISNULL(ID.FieldValue, '')
            FROM dbo.tblWF_FieldMapping AS FM
            JOIN dbo.tblWF_Instance AS I ON I.InstanceID = @InstanceID
            LEFT JOIN dbo.tblWF_InstanceData AS ID
                ON ID.InstanceID = @InstanceID AND ID.FieldName = FM.FieldName AND ID.[Enable] = 1
            WHERE FM.DefinitionID = I.DefinitionID
              AND FM.FieldType = 'signature'
              AND FM.[Enable] = 1;

            -- Lấy ExecutionID đang active của bước SIGN
            DECLARE @ActiveSignExecID BIGINT;
            SELECT TOP 1 @ActiveSignExecID = ExecutionID
            FROM dbo.tblWF_StepExecution
            WHERE InstanceID = @InstanceID
              AND StepType IN ('SIGN', 'ECONTRACT')
              AND Status = 'ACTIVE'
              AND [Enable] = 1;

            IF @ActiveSignExecID IS NOT NULL
            BEGIN
                UPDATE SE
                SET SE.SignerValue = SFM.FieldValue,
                    SE.ResolvedPersonID = CASE
                        WHEN LEN(ISNULL(PF.ProfileUserID, '')) BETWEEN 1 AND 9 THEN PF.ProfileUserID
                        WHEN LEN(ISNULL(SFM.FieldValue, ''))   BETWEEN 1 AND 9 THEN SFM.FieldValue
                        ELSE SE.ResolvedPersonID
                    END,
                    SE.ResolvedPersonName = ISNULL(PF.ProfileName, SE.ResolvedPersonName),
                    SE.UpdateUser = @sys_UserID,
                    SE.UpdateTime = @Now
                FROM dbo.tblWF_StepSignerExec AS SE
                INNER JOIN @SigFieldMap AS SFM ON SFM.SignerOrder = SE.SignerOrder
                OUTER APPLY (
                    SELECT TOP 1
                        ProfileUserID = NULLIF(LTRIM(RTRIM(ISNULL(P.EmployeeCode, ''))), ''),
                        ProfileName   = NULLIF(LTRIM(RTRIM(ISNULL(P.FullName, N''))), N'')
                    FROM dbo.tblWF_User AS P
                    WHERE P.[Enable] = 1
                      AND ISNULL(P.IsActive, 1) = 1
                      AND (
                          UPPER(ISNULL(P.EmployeeCode, '')) = UPPER(ISNULL(SFM.FieldValue, ''))
                          OR UPPER(ISNULL(P.Email, ''))     = UPPER(ISNULL(SFM.FieldValue, ''))
                      )
                    ORDER BY
                        CASE WHEN UPPER(ISNULL(P.EmployeeCode,'')) = UPPER(ISNULL(SFM.FieldValue,'')) THEN 0 ELSE 1 END,
                        P.UserID DESC
                ) AS PF
                WHERE SE.ExecutionID = @ActiveSignExecID
                  AND SE.[Enable] = 1;

                -- Đồng bộ SignBox tương ứng
                UPDATE B
                SET B.SignerValue = SE.SignerValue,
                    B.PersonName = SE.ResolvedPersonName,
                    B.UpdateUser = @sys_UserID,
                    B.UpdateTime = @Now
                FROM dbo.tblWF_InstanceSignBox AS B
                INNER JOIN dbo.tblWF_StepSignerExec AS SE
                    ON SE.ExecutionID = @ActiveSignExecID
                   AND SE.SignerOrder = B.SignerOrder
                   AND SE.[Enable] = 1
                WHERE B.InstanceID = @InstanceID
                  AND B.[Enable] = 1;
            END
        END

        COMMIT TRANSACTION;

        -- ── Kích hoạt tự động hóa ──────────────────────────────────────────────
        EXEC dbo.spAPI_WF_Automation_Execute 
            @sys_UserID = @sys_UserID, 
            @InstanceID = @InstanceID, 
            @Event = 'STAGE_CHANGED',
            @InternalCall = 1;

        SELECT 1 AS Success, N'Lưu dữ liệu thành công' AS Message;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
    END CATCH;
END

