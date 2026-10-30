CREATE PROCEDURE [dbo].[spAPI_WF_ReportSource_SmartCAHealth_DetailSource]
    @sys_UserID VARCHAR(50),
    @DimensionKey VARCHAR(50) = NULL,
    @MetricKey VARCHAR(50) = NULL,
    @TimeRangeKey NVARCHAR(100) = NULL,
    @StatusFilter NVARCHAR(100) = NULL,
    @GroupLabel NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME = GETDATE();
    DECLARE @RangeStart DATETIME;

    IF @DimensionKey IS NULL
        SET @DimensionKey = 'gateway';

    IF @TimeRangeKey IS NULL
        SET @TimeRangeKey = N'30 ngày gần nhất';

    IF @StatusFilter IS NULL
        SET @StatusFilter = N'Tất cả';

    SET @RangeStart =
        CASE
            WHEN @TimeRangeKey = N'7 ngày gần nhất' THEN DATEADD(DAY, -7, @Now)
            WHEN @TimeRangeKey = N'Quý này' THEN DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Now), 0)
            WHEN @TimeRangeKey = N'Năm nay' THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, @Now), 0)
            ELSE DATEADD(DAY, -30, @Now)
        END;

    DECLARE @SmartcaDetail TABLE
    (
        GroupLabel NVARCHAR(200),
        InstanceID BIGINT,
        ExecutionID BIGINT,
        SignerExecID BIGINT,
        ResolvedPersonID VARCHAR(50),
        ResolvedPersonName NVARCHAR(250),
        SignMethod VARCHAR(100),
        SignerStatus VARCHAR(50),
        ResultLabel NVARCHAR(200),
        GatewayLabel NVARCHAR(200),
        EventTime DATETIME,
        SignedDate DATETIME,
        ResponseSeconds DECIMAL(18,2),
        ExecutionEngine VARCHAR(50),
        ContractProvider VARCHAR(100),
        InstanceStatus VARCHAR(50)
    );

    INSERT INTO @SmartcaDetail
    (
        GroupLabel, InstanceID, ExecutionID, SignerExecID, ResolvedPersonID, ResolvedPersonName,
        SignMethod, SignerStatus, ResultLabel, GatewayLabel, EventTime, SignedDate, ResponseSeconds,
        ExecutionEngine, ContractProvider, InstanceStatus
    )
    SELECT
        GroupLabel =
            CASE
                WHEN @DimensionKey = 'result' THEN
                    CASE
                        WHEN SE.Status = 'SIGNED' THEN N'Thành công'
                        WHEN SE.Status = 'REJECTED' THEN N'Từ chối'
                        WHEN SE.Status = 'WAITING' THEN N'Đang chờ'
                        WHEN SE.Status = 'PENDING' THEN N'Chờ lượt'
                        ELSE N'Khác'
                    END
                WHEN @DimensionKey = 'hourBand' THEN
                    CASE
                        WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 8 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 10 THEN N'08h - 10h'
                        WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 10 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 12 THEN N'10h - 12h'
                        WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 13 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 15 THEN N'13h - 15h'
                        WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 15 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 17 THEN N'15h - 17h'
                        ELSE N'Sau giờ hành chính'
                    END
                ELSE
                    CASE
                        WHEN UPPER(ISNULL(I.ExecutionEngine, '')) = 'ECONTRACT' AND UPPER(ISNULL(I.ContractProvider, '')) = 'VNPT_ECONTRACT' THEN N'VNPT eContract'
                        WHEN UPPER(ISNULL(I.ExecutionEngine, '')) = 'ECONTRACT' AND UPPER(ISNULL(I.ContractProvider, '')) = 'AMIS_WESIGN' THEN N'AMIS WeSign'
                        WHEN UPPER(ISNULL(I.ExecutionEngine, '')) = 'ECONTRACT' THEN N'eContract khác'
                        ELSE N'SmartCA Core'
                    END
            END,
        I.InstanceID,
        EX.ExecutionID,
        SE.SignerExecID,
        SE.ResolvedPersonID,
        SE.ResolvedPersonName,
        SE.SignMethod,
        SignerStatus = SE.Status,
        ResultLabel =
            CASE
                WHEN SE.Status = 'SIGNED' THEN N'Thành công'
                WHEN SE.Status = 'REJECTED' THEN N'Từ chối'
                WHEN SE.Status = 'WAITING' THEN N'Đang chờ'
                WHEN SE.Status = 'PENDING' THEN N'Chờ lượt'
                ELSE N'Khác'
            END,
        GatewayLabel =
            CASE
                WHEN UPPER(ISNULL(I.ExecutionEngine, '')) = 'ECONTRACT' AND UPPER(ISNULL(I.ContractProvider, '')) = 'VNPT_ECONTRACT' THEN N'VNPT eContract'
                WHEN UPPER(ISNULL(I.ExecutionEngine, '')) = 'ECONTRACT' AND UPPER(ISNULL(I.ContractProvider, '')) = 'AMIS_WESIGN' THEN N'AMIS WeSign'
                WHEN UPPER(ISNULL(I.ExecutionEngine, '')) = 'ECONTRACT' THEN N'eContract khác'
                ELSE N'SmartCA Core'
            END,
        EventTime = ISNULL(SE.CreateTime, I.CreateTime),
        SE.SignedDate,
        ResponseSeconds = CAST(DATEDIFF(SECOND, ISNULL(SE.CreateTime, I.CreateTime),
            CASE
                WHEN SE.Status = 'SIGNED' AND SE.SignedDate IS NOT NULL AND SE.SignedDate >= ISNULL(SE.CreateTime, I.CreateTime) THEN SE.SignedDate
                WHEN SE.Status IN ('WAITING', 'PENDING') THEN @Now
                WHEN ISNULL(SE.UpdateTime, @Now) < ISNULL(SE.CreateTime, I.CreateTime) THEN ISNULL(SE.CreateTime, I.CreateTime)
                ELSE ISNULL(SE.UpdateTime, @Now)
            END
        ) AS DECIMAL(18,2)),
        I.ExecutionEngine,
        I.ContractProvider,
        I.Status AS InstanceStatus
    FROM dbo.tblWF_StepSignerExec AS SE
    INNER JOIN dbo.tblWF_StepExecution AS EX
        ON EX.ExecutionID = SE.ExecutionID
       AND EX.[Enable] = 0
    INNER JOIN dbo.tblWF_Instance AS I
        ON I.InstanceID = EX.InstanceID
       AND I.[Enable] = 0
    WHERE SE.[Enable] = 0
      AND LOWER(ISNULL(SE.SignMethod, '')) LIKE '%smartca%'
      AND ISNULL(SE.CreateTime, I.CreateTime) >= @RangeStart
      AND (
            @StatusFilter = N'Tất cả'
            OR (@StatusFilter = N'Chỉ hoàn tất' AND SE.Status = 'SIGNED')
            OR (@StatusFilter = N'Đang hoạt động' AND SE.Status IN ('WAITING', 'PENDING'))
            OR (@StatusFilter = N'Cần xử lý' AND SE.Status IN ('WAITING', 'PENDING', 'REJECTED'))
          );

    SELECT
        DimensionKey = @DimensionKey,
        MetricKey = ISNULL(@MetricKey, 'requestCount'),
        TimeRangeKey = @TimeRangeKey,
        StatusFilter = @StatusFilter,
        GroupLabel = ISNULL(@GroupLabel, N'Tất cả'),
        DetailRowCount = COUNT(1)
    FROM @SmartcaDetail
    WHERE @GroupLabel IS NULL OR GroupLabel = @GroupLabel;

    SELECT
        GroupLabel,
        InstanceID,
        ExecutionID,
        SignerExecID,
        ResolvedPersonID,
        ResolvedPersonName,
        SignMethod,
        SignerStatus,
        ResultLabel,
        GatewayLabel,
        EventTime,
        SignedDate,
        ResponseSeconds,
        ExecutionEngine,
        ContractProvider,
        InstanceStatus
    FROM @SmartcaDetail
    WHERE @GroupLabel IS NULL OR GroupLabel = @GroupLabel
    ORDER BY EventTime DESC, SignerExecID DESC;
END
