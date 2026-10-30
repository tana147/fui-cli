CREATE PROCEDURE [dbo].[spAPI_WF_StepSignerExec_GetList]
    @sys_UserID  VARCHAR(9),
    @ExecutionID BIGINT = NULL,
    @InstanceID  BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Bắt buộc phải truyền ít nhất một trong hai tham số
    IF @ExecutionID IS NULL AND @InstanceID IS NULL
    BEGIN
        RAISERROR(N'Phải truyền ExecutionID hoặc InstanceID.', 16, 1);
        RETURN;
    END;

    SELECT
        SE.SignerExecID,
        SE.ExecutionID,
        -- Thông tin bước (join ngược lên StepExecution để tiện render Gantt)
        EX.InstanceID,
        EX.StepOrder,
        EX.StepName,
        EX.StepCode,
        -- Thông tin người ký
        SE.SignerOrder,
        SE.SignerType,
        SE.SignerValue,
        SE.ResolvedPersonID,
        SE.ResolvedPersonName,
        SE.DepartmentName,
        SE.SignMethod,
        SE.Status,
        SE.SignedDate,
        SE.SignCertInfo
    FROM dbo.tblWF_StepSignerExec AS SE
    INNER JOIN dbo.tblWF_StepExecution AS EX
        ON EX.ExecutionID = SE.ExecutionID
       AND EX.[Enable] = 1
    WHERE SE.[Enable] = 1
      AND (@ExecutionID IS NULL OR SE.ExecutionID = @ExecutionID)
      AND (@InstanceID  IS NULL OR EX.InstanceID  = @InstanceID)
    ORDER BY
        EX.StepOrder,
        SE.SignerOrder,
        SE.SignerExecID;
END
