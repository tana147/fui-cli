CREATE PROCEDURE [dbo].[spAPI_WF_StepExecution_GetList]
    @sys_UserID VARCHAR(9),
    @InstanceID BIGINT = NULL,
    @FromDate   DATETIME = NULL,
    @ToDate     DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        EX.ExecutionID,
        EX.InstanceID,
        EX.StepOrder,
        EX.StepCode,
        EX.StepName,
        EX.StepType,
        EX.Status,
        EX.StartedDate,
        EX.CompletedDate,
        EX.RejectedBy,
        EX.RejectedReason,
        EX.RejectedDate,
        -- Thông tin hồ sơ (để dùng khi query toàn hệ thống)
        I.InstanceName,
        I.CreateUser   AS InstanceOwner,
        I.CreateTime   AS InstanceCreateTime,
        -- Tổng số người ký của bước này
        SignerTotal    = ISNULL(SC.SignerTotal, 0),
        SignerDone     = ISNULL(SC.SignerDone,  0)
    FROM dbo.tblWF_StepExecution AS EX
    INNER JOIN dbo.tblWF_Instance AS I
        ON I.InstanceID = EX.InstanceID
       AND I.[Enable] = 1
    -- Đếm người ký để tiện hiển thị progress trong từng bước
    OUTER APPLY
    (
        SELECT
            COUNT(1)                                        AS SignerTotal,
            SUM(CASE WHEN SE.Status = 'SIGNED' THEN 1 ELSE 0 END) AS SignerDone
        FROM dbo.tblWF_StepSignerExec AS SE
        WHERE SE.ExecutionID = EX.ExecutionID
          AND SE.[Enable] = 1
    ) AS SC
    WHERE EX.[Enable] = 1
      -- Lọc theo hồ sơ cụ thể
      AND (@InstanceID IS NULL OR EX.InstanceID = @InstanceID)
      -- Lọc theo khoảng thời gian (dùng khi query toàn hệ thống)
      AND (@FromDate IS NULL OR EX.StartedDate >= @FromDate)
      AND (@ToDate   IS NULL OR EX.StartedDate <  DATEADD(DAY, 1, @ToDate))
    ORDER BY
        EX.InstanceID,
        EX.StepOrder,
        EX.ExecutionID;
END
