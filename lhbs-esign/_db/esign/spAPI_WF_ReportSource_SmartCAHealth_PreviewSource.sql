CREATE PROCEDURE [dbo].[spAPI_WF_ReportSource_SmartCAHealth_PreviewSource]
    @sys_UserID VARCHAR(50),
    @DimensionKey VARCHAR(50) = NULL,
    @MetricKey VARCHAR(50) = NULL,
    @TimeRangeKey NVARCHAR(100) = NULL,
    @StatusFilter NVARCHAR(100) = NULL
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

    ;WITH BaseData AS
    (
        SELECT
            ResultLabel =
                CASE
                    WHEN SE.Status = 'SIGNED' THEN N'Thành công'
                    WHEN SE.Status = 'REJECTED' THEN N'Từ chối'
                    WHEN SE.Status = 'WAITING' THEN N'Đang chờ'
                    WHEN SE.Status = 'PENDING' THEN N'Chờ lượt'
                    ELSE N'Khác'
                END,
            ResultSort =
                CASE
                    WHEN SE.Status = 'SIGNED' THEN 10
                    WHEN SE.Status = 'WAITING' THEN 20
                    WHEN SE.Status = 'PENDING' THEN 30
                    WHEN SE.Status = 'REJECTED' THEN 40
                    ELSE 90
                END,
            GatewayLabel =
                CASE
                    WHEN UPPER(ISNULL(I.ExecutionEngine, '')) = 'ECONTRACT' AND UPPER(ISNULL(I.ContractProvider, '')) = 'VNPT_ECONTRACT' THEN N'VNPT eContract'
                    WHEN UPPER(ISNULL(I.ExecutionEngine, '')) = 'ECONTRACT' AND UPPER(ISNULL(I.ContractProvider, '')) = 'AMIS_WESIGN' THEN N'AMIS WeSign'
                    WHEN UPPER(ISNULL(I.ExecutionEngine, '')) = 'ECONTRACT' THEN N'eContract khác'
                    ELSE N'SmartCA Core'
                END,
            HourBand =
                CASE
                    WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 8 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 10 THEN N'08h - 10h'
                    WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 10 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 12 THEN N'10h - 12h'
                    WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 13 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 15 THEN N'13h - 15h'
                    WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 15 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 17 THEN N'15h - 17h'
                    ELSE N'Sau giờ hành chính'
                END,
            HourSort =
                CASE
                    WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 8 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 10 THEN 10
                    WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 10 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 12 THEN 20
                    WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 13 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 15 THEN 30
                    WHEN DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) >= 15 AND DATEPART(HOUR, ISNULL(SE.CreateTime, I.CreateTime)) < 17 THEN 40
                    ELSE 90
                END,
            SuccessFlag = CASE WHEN SE.Status = 'SIGNED' THEN 1 ELSE 0 END,
            ResponseSeconds = CAST(DATEDIFF(SECOND, ISNULL(SE.CreateTime, I.CreateTime),
                CASE
                    WHEN SE.Status = 'SIGNED' AND SE.SignedDate IS NOT NULL AND SE.SignedDate >= ISNULL(SE.CreateTime, I.CreateTime) THEN SE.SignedDate
                    WHEN SE.Status IN ('WAITING', 'PENDING') THEN @Now
                    WHEN ISNULL(SE.UpdateTime, @Now) < ISNULL(SE.CreateTime, I.CreateTime) THEN ISNULL(SE.CreateTime, I.CreateTime)
                    ELSE ISNULL(SE.UpdateTime, @Now)
                END
            ) AS DECIMAL(18,2))
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
              )
    ),
    Aggregated AS
    (
        SELECT
            SortKey =
                CASE
                    WHEN @DimensionKey = 'result' THEN ResultSort
                    WHEN @DimensionKey = 'hourBand' THEN HourSort
                    WHEN @DimensionKey = 'gateway' THEN 0
                    ELSE ResultSort
                END,
            Label =
                CASE
                    WHEN @DimensionKey = 'result' THEN ResultLabel
                    WHEN @DimensionKey = 'hourBand' THEN HourBand
                    WHEN @DimensionKey = 'gateway' THEN GatewayLabel
                    ELSE ResultLabel
                END,
            RequestCount = CAST(COUNT(1) AS DECIMAL(18,2)),
            CompletedRate = CAST(CASE WHEN COUNT(1) = 0 THEN 0 ELSE (SUM(SuccessFlag) * 100.0 / COUNT(1)) END AS DECIMAL(18,2)),
            SlaHours = CAST(ISNULL(AVG(ResponseSeconds), 0) AS DECIMAL(18,2))
        FROM BaseData
        GROUP BY
            CASE
                WHEN @DimensionKey = 'result' THEN ResultSort
                WHEN @DimensionKey = 'hourBand' THEN HourSort
                WHEN @DimensionKey = 'gateway' THEN 0
                ELSE ResultSort
            END,
            CASE
                WHEN @DimensionKey = 'result' THEN ResultLabel
                WHEN @DimensionKey = 'hourBand' THEN HourBand
                WHEN @DimensionKey = 'gateway' THEN GatewayLabel
                ELSE ResultLabel
            END
    )
    SELECT
        SortKey = CASE WHEN @DimensionKey = 'gateway' THEN ROW_NUMBER() OVER (ORDER BY RequestCount DESC, Label ASC) ELSE SortKey END,
        Label,
        RequestCount,
        CompletedRate,
        SlaHours
    FROM Aggregated;
END
