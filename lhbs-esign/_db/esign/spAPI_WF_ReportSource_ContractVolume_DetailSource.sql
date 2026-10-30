CREATE PROCEDURE [dbo].[spAPI_WF_ReportSource_ContractVolume_DetailSource]
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
        SET @DimensionKey = 'month';

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

    DECLARE @ContractDetail TABLE
    (
        GroupLabel NVARCHAR(200),
        InstanceID BIGINT,
        InstanceName NVARCHAR(500),
        StatusLabel NVARCHAR(200),
        CategoryName NVARCHAR(200),
        CreateUser VARCHAR(50),
        CreateTime DATETIME,
        UpdateTime DATETIME,
        DurationHours DECIMAL(18,2),
        ExecutionEngine VARCHAR(50),
        ContractProvider VARCHAR(100),
        CurrentStepOrder INT
    );

    INSERT INTO @ContractDetail
    (
        GroupLabel, InstanceID, InstanceName, StatusLabel, CategoryName,
        CreateUser, CreateTime, UpdateTime, DurationHours, ExecutionEngine, ContractProvider, CurrentStepOrder
    )
    SELECT
        GroupLabel =
            CASE
                WHEN @DimensionKey = 'status' THEN
                    CASE
                        WHEN I.Status = 'COMPLETED' THEN N'Hoàn tất'
                        WHEN I.Status = 'REJECTED' THEN N'Từ chối'
                        WHEN I.Status IN ('RUNNING', 'WAITING_ME') THEN N'Chờ ký'
                        ELSE N'Khác'
                    END
                WHEN @DimensionKey = 'department' THEN ISNULL(NULLIF(C.Name, N''), N'Chưa phân loại')
                ELSE N'Tháng ' + RIGHT('0' + CAST(MONTH(I.CreateTime) AS VARCHAR(2)), 2) + N'/' + CAST(YEAR(I.CreateTime) AS NVARCHAR(4))
            END,
        I.InstanceID,
        I.InstanceName,
        StatusLabel =
            CASE
                WHEN I.Status = 'COMPLETED' THEN N'Hoàn tất'
                WHEN I.Status = 'REJECTED' THEN N'Từ chối'
                WHEN I.Status IN ('RUNNING', 'WAITING_ME') THEN N'Chờ ký'
                ELSE ISNULL(I.Status, '')
            END,
        CategoryName = ISNULL(NULLIF(C.Name, N''), N'Chưa phân loại'),
        I.CreateUser,
        I.CreateTime,
        I.UpdateTime,
        DurationHours = CAST(DATEDIFF(SECOND, I.CreateTime,
            CASE
                WHEN I.Status IN ('COMPLETED', 'REJECTED') THEN
                    CASE
                        WHEN ISNULL(I.UpdateTime, I.CreateTime) < I.CreateTime THEN I.CreateTime
                        ELSE ISNULL(I.UpdateTime, I.CreateTime)
                    END
                ELSE
                    CASE
                        WHEN ISNULL(I.UpdateTime, @Now) < I.CreateTime THEN @Now
                        ELSE ISNULL(I.UpdateTime, @Now)
                    END
            END
        ) / 3600.0 AS DECIMAL(18,2)),
        I.ExecutionEngine,
        I.ContractProvider,
        I.CurrentStepOrder
    FROM dbo.tblWF_Instance AS I
    LEFT JOIN dbo.tblWF_Category AS C
        ON C.CategoryID = I.CategoryID
       AND C.[Enable] = 0
    WHERE I.[Enable] = 0
      AND I.CreateTime >= @RangeStart
      AND (
            @StatusFilter = N'Tất cả'
            OR (@StatusFilter = N'Chỉ hoàn tất' AND I.Status = 'COMPLETED')
            OR (@StatusFilter = N'Đang hoạt động' AND I.Status IN ('RUNNING', 'WAITING_ME'))
            OR (@StatusFilter = N'Cần xử lý' AND I.Status IN ('RUNNING', 'WAITING_ME', 'REJECTED'))
          );

    SELECT
        DimensionKey = @DimensionKey,
        MetricKey = ISNULL(@MetricKey, 'requestCount'),
        TimeRangeKey = @TimeRangeKey,
        StatusFilter = @StatusFilter,
        GroupLabel = ISNULL(@GroupLabel, N'Tất cả'),
        DetailRowCount = COUNT(1)
    FROM @ContractDetail
    WHERE @GroupLabel IS NULL OR GroupLabel = @GroupLabel;

    SELECT
        GroupLabel,
        InstanceID,
        InstanceName,
        StatusLabel,
        CategoryName,
        CreateUser,
        CreateTime,
        UpdateTime,
        DurationHours,
        ExecutionEngine,
        ContractProvider,
        CurrentStepOrder
    FROM @ContractDetail
    WHERE @GroupLabel IS NULL OR GroupLabel = @GroupLabel
    ORDER BY CreateTime DESC, InstanceID DESC;
END
