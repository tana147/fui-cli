CREATE PROCEDURE [dbo].[spAPI_WF_ReportSource_ContractVolume_PreviewSource]
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

    ;WITH BaseData AS
    (
        SELECT
            I.InstanceID,
            I.CreateTime,
            NormalizedStatus =
                CASE
                    WHEN I.Status = 'COMPLETED' THEN N'Hoàn tất'
                    WHEN I.Status = 'REJECTED' THEN N'Từ chối'
                    WHEN I.Status IN ('RUNNING', 'WAITING_ME') THEN N'Chờ ký'
                    ELSE N'Khác'
                END,
            DepartmentLabel = ISNULL(NULLIF(C.Name, N''), N'Chưa phân loại'),
            MonthLabel = N'Tháng ' + RIGHT('0' + CAST(MONTH(I.CreateTime) AS VARCHAR(2)), 2) + N'/' + CAST(YEAR(I.CreateTime) AS NVARCHAR(4)),
            MonthSort = YEAR(I.CreateTime) * 100 + MONTH(I.CreateTime),
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
            ) / 3600.0 AS DECIMAL(18,2))
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
              )
    ),
    Aggregated AS
    (
        SELECT
            SortKey =
                CASE
                    WHEN @DimensionKey = 'status' THEN
                        CASE NormalizedStatus
                            WHEN N'Hoàn tất' THEN 10
                            WHEN N'Chờ ký' THEN 20
                            WHEN N'Từ chối' THEN 30
                            ELSE 90
                        END
                    WHEN @DimensionKey = 'department' THEN 0
                    ELSE MonthSort
                END,
            Label =
                CASE
                    WHEN @DimensionKey = 'status' THEN NormalizedStatus
                    WHEN @DimensionKey = 'department' THEN DepartmentLabel
                    ELSE MonthLabel
                END,
            RequestCount = CAST(COUNT(1) AS DECIMAL(18,2)),
            CompletedRate = CAST(CASE WHEN COUNT(1) = 0 THEN 0 ELSE (SUM(CASE WHEN NormalizedStatus = N'Hoàn tất' THEN 1 ELSE 0 END) * 100.0 / COUNT(1)) END AS DECIMAL(18,2)),
            SlaHours = CAST(ISNULL(AVG(DurationHours), 0) AS DECIMAL(18,2))
        FROM BaseData
        GROUP BY
            CASE
                WHEN @DimensionKey = 'status' THEN
                    CASE NormalizedStatus
                        WHEN N'Hoàn tất' THEN 10
                        WHEN N'Chờ ký' THEN 20
                        WHEN N'Từ chối' THEN 30
                        ELSE 90
                    END
                WHEN @DimensionKey = 'department' THEN 0
                ELSE MonthSort
            END,
            CASE
                WHEN @DimensionKey = 'status' THEN NormalizedStatus
                WHEN @DimensionKey = 'department' THEN DepartmentLabel
                ELSE MonthLabel
            END
    )
    SELECT
        SortKey = CASE WHEN @DimensionKey = 'department' THEN ROW_NUMBER() OVER (ORDER BY RequestCount DESC, Label ASC) ELSE SortKey END,
        Label,
        RequestCount,
        CompletedRate,
        SlaHours
    FROM Aggregated;
END
