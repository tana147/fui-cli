CREATE PROCEDURE [dbo].[spAPI_WF_ReportDefinition_Save]
    @ReportDefinitionID BIGINT = 0,
    @sys_UserID VARCHAR(50),
    @sys_UserFullName NVARCHAR(200) = NULL,
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ReportName NVARCHAR(200) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.ReportName'), N'')));
    DECLARE @Description NVARCHAR(500) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.Description'), N''))), N'');
    DECLARE @DatasetCode VARCHAR(50) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DatasetCode'), ''))), '');
    DECLARE @ChartType VARCHAR(20) = LOWER(NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.ChartType'), ''))), ''));
    DECLARE @DimensionKey VARCHAR(50) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DimensionKey'), ''))), '');
    DECLARE @MetricKey VARCHAR(50) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.MetricKey'), ''))), '');
    DECLARE @TimeRangeKey VARCHAR(50) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.TimeRangeKey'), ''))), '');
    DECLARE @StatusFilter NVARCHAR(100) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.StatusFilter'), N''))), N'');
    DECLARE @SelectedFieldsJson NVARCHAR(MAX) = JSON_QUERY(@sys_RawData, '$.SelectedFields');
    DECLARE @ConfigJson NVARCHAR(MAX) = JSON_QUERY(@sys_RawData, '$.Config');
    DECLARE @IsShared BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.IsShared') AS BIT), 0);
    DECLARE @IsPinnedDashboard BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.IsPinnedDashboard') AS BIT), 0);
    DECLARE @IsActive BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.IsActive') AS BIT), 1);
    DECLARE @DatasetExists BIT = 0;

    IF @ReportName = N''
    BEGIN
        RAISERROR(N'Tên báo cáo không được để trống.', 16, 1);
        RETURN;
    END

    IF @DatasetCode IS NULL
    BEGIN
        RAISERROR(N'Bạn chưa chọn dataset cho báo cáo.', 16, 1);
        RETURN;
    END

    IF @ChartType IS NULL OR @ChartType NOT IN ('bar', 'bar_horizontal', 'line', 'area', 'pie', 'donut', 'kpi', 'progress_list', 'table', 'matrix')
    BEGIN
        SET @ChartType = 'bar';
    END

    SELECT @DatasetExists = CASE WHEN EXISTS
    (
        SELECT 1
        FROM dbo.tblWF_ReportDataset
        WHERE DatasetCode = @DatasetCode
          AND [Enable] = 0
          AND IsActive = 1
    ) THEN 1 ELSE 0 END;

    IF @DatasetExists = 0
    BEGIN
        RAISERROR(N'Dataset không tồn tại hoặc đã ngừng hoạt động.', 16, 1);
        RETURN;
    END

    IF ISNULL(@SelectedFieldsJson, '') = ''
    BEGIN
        SET @SelectedFieldsJson = N'[]';
    END

    IF ISNULL(@ConfigJson, '') = ''
    BEGIN
        SET @ConfigJson = (
            SELECT
                DatasetCode = @DatasetCode,
                ChartType = @ChartType,
                DimensionKey = @DimensionKey,
                MetricKey = @MetricKey,
                TimeRangeKey = @TimeRangeKey,
                StatusFilter = @StatusFilter,
                SelectedFields = JSON_QUERY(@SelectedFieldsJson)
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END

    IF ISNULL(@ReportDefinitionID, 0) <= 0
    BEGIN
        INSERT INTO dbo.tblWF_ReportDefinition
        (
            ReportCode, ReportName, Description, DatasetCode, ChartType, DimensionKey, MetricKey,
            TimeRangeKey, StatusFilter, SelectedFieldsJson, ConfigJson, IsShared, IsPinnedDashboard,
            IsActive, OwnerUserID, OwnerUserName, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            NULL, @ReportName, @Description, @DatasetCode, @ChartType, @DimensionKey, @MetricKey,
            @TimeRangeKey, @StatusFilter, @SelectedFieldsJson, @ConfigJson, @IsShared, @IsPinnedDashboard,
            @IsActive, @sys_UserID, ISNULL(@sys_UserFullName, @sys_UserID), @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 0
        );

        SET @ReportDefinitionID = SCOPE_IDENTITY();

        UPDATE dbo.tblWF_ReportDefinition
        SET ReportCode = 'RPT-' + RIGHT('000000' + CAST(@ReportDefinitionID AS VARCHAR(20)), 6)
        WHERE ReportDefinitionID = @ReportDefinitionID
          AND [Enable] = 0;
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_ReportDefinition
        SET ReportName = @ReportName,
            Description = @Description,
            DatasetCode = @DatasetCode,
            ChartType = @ChartType,
            DimensionKey = @DimensionKey,
            MetricKey = @MetricKey,
            TimeRangeKey = @TimeRangeKey,
            StatusFilter = @StatusFilter,
            SelectedFieldsJson = @SelectedFieldsJson,
            ConfigJson = @ConfigJson,
            IsShared = @IsShared,
            IsPinnedDashboard = @IsPinnedDashboard,
            IsActive = @IsActive,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE ReportDefinitionID = @ReportDefinitionID
          AND [Enable] = 0
          AND OwnerUserID = @sys_UserID;

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR(N'Không tìm thấy báo cáo để cập nhật hoặc bạn không có quyền sửa.', 16, 1);
            RETURN;
        END
    END

    SELECT
        Message = N'Lưu cấu hình báo cáo thành công.',
        ReportDefinitionID = @ReportDefinitionID,
        ReportCode = ReportCode
    FROM dbo.tblWF_ReportDefinition
    WHERE ReportDefinitionID = @ReportDefinitionID
      AND [Enable] = 0;
END
