CREATE PROCEDURE [dbo].[spAPI_WF_Report_RunDetail]
    @ReportDefinitionID BIGINT = 0,
    @sys_UserID VARCHAR(50),
    @sys_RawData NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DatasetCode VARCHAR(50) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DatasetCode'), ''))), '');
    DECLARE @DimensionKey VARCHAR(50) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DimensionKey'), ''))), '');
    DECLARE @MetricKey VARCHAR(50) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.MetricKey'), ''))), '');
    DECLARE @TimeRangeKey NVARCHAR(100) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.TimeRangeKey'), N''))), N'');
    DECLARE @StatusFilter NVARCHAR(100) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.StatusFilter'), N''))), N'');
    DECLARE @GroupLabel NVARCHAR(200) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.GroupLabel'), N''))), N'');
    DECLARE @SourceKind VARCHAR(20) = 'DATABASE';
    DECLARE @SourceProcedureName VARCHAR(150) = NULL;
    DECLARE @DetailSourceProcedureName VARCHAR(150) = NULL;
    DECLARE @ProcSchema SYSNAME;
    DECLARE @ProcName SYSNAME;
    DECLARE @ExecSql NVARCHAR(MAX);

    IF ISNULL(@ReportDefinitionID, 0) > 0
    BEGIN
        SELECT TOP (1)
            @DatasetCode = ISNULL(NULLIF(@DatasetCode, ''), R.DatasetCode),
            @DimensionKey = ISNULL(NULLIF(@DimensionKey, ''), R.DimensionKey),
            @MetricKey = ISNULL(NULLIF(@MetricKey, ''), R.MetricKey),
            @TimeRangeKey = ISNULL(@TimeRangeKey, R.TimeRangeKey),
            @StatusFilter = ISNULL(@StatusFilter, R.StatusFilter)
        FROM dbo.tblWF_ReportDefinition AS R
        WHERE R.ReportDefinitionID = @ReportDefinitionID
          AND R.[Enable] = 0
          AND (R.OwnerUserID = @sys_UserID OR R.IsShared = 1);
    END

    IF @DatasetCode IS NULL
        SET @DatasetCode = 'contract_volume';

    SELECT TOP (1)
        @SourceKind = ISNULL(NULLIF(D.SourceKind, ''), 'DATABASE'),
        @SourceProcedureName = NULLIF(LTRIM(RTRIM(ISNULL(D.SourceProcedureName, ''))), ''),
        @DetailSourceProcedureName = NULLIF(LTRIM(RTRIM(ISNULL(D.DetailSourceProcedureName, ''))), '')
    FROM dbo.tblWF_ReportDataset AS D
    WHERE D.DatasetCode = @DatasetCode
      AND D.[Enable] = 0
      AND D.IsActive = 1
      AND (D.OwnerUserID IS NULL OR D.OwnerUserID = @sys_UserID);

    IF @MetricKey IS NULL
    BEGIN
        SELECT TOP (1) @MetricKey = F.FieldKey
        FROM dbo.tblWF_ReportDatasetField AS F
        INNER JOIN dbo.tblWF_ReportDataset AS D
            ON D.ReportDatasetID = F.ReportDatasetID
           AND D.[Enable] = 0
        WHERE D.DatasetCode = @DatasetCode
          AND F.[Enable] = 0
          AND F.IsActive = 1
          AND F.FieldRole = 'METRIC'
        ORDER BY F.SortOrder, F.FieldKey;
    END

    IF @DimensionKey IS NULL
    BEGIN
        SELECT TOP (1) @DimensionKey = F.FieldKey
        FROM dbo.tblWF_ReportDatasetField AS F
        INNER JOIN dbo.tblWF_ReportDataset AS D
            ON D.ReportDatasetID = F.ReportDatasetID
           AND D.[Enable] = 0
        WHERE D.DatasetCode = @DatasetCode
          AND F.[Enable] = 0
          AND F.IsActive = 1
          AND F.FieldRole = 'DIMENSION'
        ORDER BY F.SortOrder, F.FieldKey;
    END

    IF @MetricKey IS NULL
        SET @MetricKey = 'requestCount';

    IF @DimensionKey IS NULL
        SET @DimensionKey = 'month';

    IF @TimeRangeKey IS NULL
        SET @TimeRangeKey = N'30 ngày gần nhất';

    IF @StatusFilter IS NULL
        SET @StatusFilter = N'Tất cả';

    IF @SourceKind = 'API' AND @DetailSourceProcedureName IS NOT NULL
    BEGIN
        SET @ProcSchema = ISNULL(PARSENAME(@DetailSourceProcedureName, 2), 'dbo');
        SET @ProcName = PARSENAME(@DetailSourceProcedureName, 1);

        IF @ProcName IS NOT NULL AND OBJECT_ID(QUOTENAME(@ProcSchema) + '.' + QUOTENAME(@ProcName), N'P') IS NOT NULL
        BEGIN
            SET @ExecSql = N'EXEC ' + QUOTENAME(@ProcSchema) + N'.' + QUOTENAME(@ProcName) + N'
                @sys_UserID = @p_sys_UserID,
                @DimensionKey = @p_DimensionKey,
                @MetricKey = @p_MetricKey,
                @TimeRangeKey = @p_TimeRangeKey,
                @StatusFilter = @p_StatusFilter,
                @GroupLabel = @p_GroupLabel;';

            EXEC sp_executesql
                @ExecSql,
                N'@p_sys_UserID VARCHAR(50), @p_DimensionKey VARCHAR(50), @p_MetricKey VARCHAR(50), @p_TimeRangeKey NVARCHAR(100), @p_StatusFilter NVARCHAR(100), @p_GroupLabel NVARCHAR(200)',
                @p_sys_UserID = @sys_UserID,
                @p_DimensionKey = @DimensionKey,
                @p_MetricKey = @MetricKey,
                @p_TimeRangeKey = @TimeRangeKey,
                @p_StatusFilter = @StatusFilter,
                @p_GroupLabel = @GroupLabel;
            RETURN;
        END
    END

    IF @SourceKind = 'API' AND @SourceProcedureName IS NOT NULL
    BEGIN
        CREATE TABLE #PreviewSourceRows
        (
            SortKey INT NOT NULL,
            Label NVARCHAR(200) NOT NULL,
            RequestCount DECIMAL(18,2) NOT NULL,
            CompletedRate DECIMAL(18,2) NOT NULL,
            SlaHours DECIMAL(18,2) NOT NULL
        );

        SET @ProcSchema = ISNULL(PARSENAME(@SourceProcedureName, 2), 'dbo');
        SET @ProcName = PARSENAME(@SourceProcedureName, 1);

        IF @ProcName IS NOT NULL AND OBJECT_ID(QUOTENAME(@ProcSchema) + '.' + QUOTENAME(@ProcName), N'P') IS NOT NULL
        BEGIN
            SET @ExecSql = N'INSERT INTO #PreviewSourceRows (SortKey, Label, RequestCount, CompletedRate, SlaHours)
                EXEC ' + QUOTENAME(@ProcSchema) + N'.' + QUOTENAME(@ProcName) + N'
                    @sys_UserID = @p_sys_UserID,
                    @DimensionKey = @p_DimensionKey,
                    @MetricKey = @p_MetricKey,
                    @TimeRangeKey = @p_TimeRangeKey,
                    @StatusFilter = @p_StatusFilter;';

            EXEC sp_executesql
                @ExecSql,
                N'@p_sys_UserID VARCHAR(50), @p_DimensionKey VARCHAR(50), @p_MetricKey VARCHAR(50), @p_TimeRangeKey NVARCHAR(100), @p_StatusFilter NVARCHAR(100)',
                @p_sys_UserID = @sys_UserID,
                @p_DimensionKey = @DimensionKey,
                @p_MetricKey = @MetricKey,
                @p_TimeRangeKey = @TimeRangeKey,
                @p_StatusFilter = @StatusFilter;
        END

        SELECT
            DatasetCode = @DatasetCode,
            DimensionKey = @DimensionKey,
            MetricKey = @MetricKey,
            TimeRangeKey = @TimeRangeKey,
            StatusFilter = @StatusFilter,
            GroupLabel = ISNULL(@GroupLabel, N'Tất cả'),
            DetailRowCount = COUNT(1)
        FROM #PreviewSourceRows
        WHERE @GroupLabel IS NULL OR Label = @GroupLabel;

        SELECT
            GroupLabel = Label,
            MetricValue =
                CASE
                    WHEN @MetricKey = 'completedRate' THEN CompletedRate
                    WHEN @MetricKey = 'slaHours' THEN SlaHours
                    ELSE RequestCount
                END,
            RequestCount,
            CompletedRate,
            SlaHours
        FROM #PreviewSourceRows
        WHERE @GroupLabel IS NULL OR Label = @GroupLabel
        ORDER BY SortKey, Label;

        RETURN;
    END

    SELECT
        DatasetCode = @DatasetCode,
        DimensionKey = @DimensionKey,
        MetricKey = @MetricKey,
        TimeRangeKey = @TimeRangeKey,
        StatusFilter = @StatusFilter,
        GroupLabel = ISNULL(@GroupLabel, N'Tất cả'),
        DetailRowCount = 0;

    SELECT
        GroupLabel = CAST(N'' AS NVARCHAR(200)),
        MetricValue = CAST(0 AS DECIMAL(18,2)),
        RequestCount = CAST(0 AS DECIMAL(18,2)),
        CompletedRate = CAST(0 AS DECIMAL(18,2)),
        SlaHours = CAST(0 AS DECIMAL(18,2))
    WHERE 1 = 0;
END
