
    CREATE   PROCEDURE [dbo].[spAPI_WF_Instance_GetChildren]
        @sys_UserID VARCHAR(9),
        @sys_RawData NVARCHAR(MAX)
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @ParentInstanceID BIGINT = TRY_CAST(JSON_VALUE(@sys_RawData, '$.ParentInstanceID') AS BIGINT);

        IF @ParentInstanceID IS NULL OR @ParentInstanceID <= 0
        BEGIN
            RAISERROR(N'ParentInstanceID không hợp lệ.', 16, 1);
            RETURN;
        END

        SELECT 
            ChildInstanceID = I.InstanceID,
            ChildInstanceName = I.InstanceName,
            Status = I.Status,
            CurrentStepName = ISNULL(CS.StepName, N'-')
        FROM dbo.tblWF_Instance AS I
        OUTER APPLY
        (
            SELECT TOP (1) EX.StepName
            FROM dbo.tblWF_StepExecution AS EX
            WHERE EX.InstanceID = I.InstanceID
              AND EX.StepOrder = I.CurrentStepOrder
              AND EX.[Enable] = 1
            ORDER BY EX.ExecutionID DESC
        ) AS CS
        WHERE I.ParentInstanceID = @ParentInstanceID
          AND I.[Enable] = 1
        ORDER BY I.InstanceID ASC;
    END
    