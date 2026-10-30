CREATE PROCEDURE [dbo].[spAPI_WF_ReportDataset_SaveApi]
    @sys_UserID VARCHAR(50),
    @sys_UserFullName NVARCHAR(200) = NULL,
    @sys_RawData NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DatasetName NVARCHAR(200) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DatasetName'), N'')));
    DECLARE @Description NVARCHAR(500) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.Description'), N''))), N'');
    DECLARE @SourceApiCode VARCHAR(150) = LEFT(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SourceApiCode'), ''))), 150);
    DECLARE @SourceProcedureName VARCHAR(150) = LEFT(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SourceProcedureName'), ''))), 150);
    DECLARE @DetailSourceProcedureName VARCHAR(150) = LEFT(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DetailSourceProcedureName'), ''))), 150);
    DECLARE @SourceMetaJson NVARCHAR(MAX) = JSON_QUERY(@sys_RawData, '$.SourceMeta');
    DECLARE @DatasetCode VARCHAR(50) = 'api_' + REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '');
    DECLARE @ReportDatasetID INT = 0;
    DECLARE @SortOrder INT = 900;

    DECLARE @Fields TABLE
    (
        RowNo INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        FieldKey VARCHAR(50) NOT NULL,
        FieldLabel NVARCHAR(200) NOT NULL,
        FieldRole VARCHAR(20) NOT NULL,
        DataType VARCHAR(20) NOT NULL
    );

    IF @DatasetName = N''
    BEGIN
        RAISERROR(N'Tên dataset không được để trống.', 16, 1);
        RETURN;
    END

    IF @SourceApiCode = ''
    BEGIN
        RAISERROR(N'Bạn cần nhập API endpoint code cho dataset API/store.', 16, 1);
        RETURN;
    END

    INSERT INTO @Fields (FieldKey, FieldLabel, FieldRole, DataType)
    SELECT
        FieldKey = LEFT(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.FieldKey'), ''))), 50),
        FieldLabel = LEFT(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.FieldLabel'), N''))), 200),
        FieldRole = CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.FieldRole'), 'DIMENSION')))) = 'METRIC' THEN 'METRIC' ELSE 'DIMENSION' END,
        DataType = CASE
            WHEN LOWER(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.DataType'), '')))) IN ('number', 'date', 'datetime', 'boolean')
                THEN LOWER(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.DataType'), ''))))
            ELSE 'string'
        END
    FROM OPENJSON(@sys_RawData, '$.Fields')
    WHERE LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.FieldKey'), ''))) <> ''
      AND LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.FieldLabel'), N''))) <> N'';

    IF NOT EXISTS (SELECT 1 FROM @Fields)
    BEGIN
        RAISERROR(N'Bạn cần khai báo ít nhất một field metadata cho dataset API/store.', 16, 1);
        RETURN;
    END

    SELECT @SortOrder = ISNULL(MAX(SortOrder), 800) + 10
    FROM dbo.tblWF_ReportDataset
    WHERE [Enable] = 0;

    INSERT INTO dbo.tblWF_ReportDataset
    (
        DatasetCode, DatasetName, Description, Icon, ThemeColor, DatasetType, SourceKind,
        SourceApiCode, SourceProcedureName, DetailSourceProcedureName, SourceConfigJson, SchemaStatus,
        OwnerUserID, OwnerUserName, SourceMetaJson,
        SortOrder, IsActive, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
    )
    VALUES
    (
        @DatasetCode, @DatasetName, @Description, 'mdi-api', '#335c9b', 'DB', 'API',
        @SourceApiCode, NULLIF(@SourceProcedureName, ''), NULLIF(@DetailSourceProcedureName, ''), @sys_RawData, 'READY',
        @sys_UserID, NULLIF(LTRIM(RTRIM(ISNULL(@sys_UserFullName, N''))), N''), @SourceMetaJson,
        @SortOrder, 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 0
    );

    SET @ReportDatasetID = SCOPE_IDENTITY();

    INSERT INTO dbo.tblWF_ReportDatasetField
    (
        ReportDatasetID, FieldKey, FieldLabel, FieldRole, DataType,
        IsFilterable, IsGroupable, IsAggregatable, SortOrder, IsActive,
        CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
    )
    SELECT
        @ReportDatasetID,
        F.FieldKey,
        F.FieldLabel,
        F.FieldRole,
        F.DataType,
        CASE WHEN F.FieldRole = 'DIMENSION' THEN 1 ELSE 0 END,
        CASE WHEN F.FieldRole = 'DIMENSION' THEN 1 ELSE 0 END,
        CASE WHEN F.FieldRole = 'METRIC' THEN 1 ELSE 0 END,
        F.RowNo * 10,
        1,
        @sys_UserID,
        GETDATE(),
        @sys_UserID,
        GETDATE(),
        0
    FROM @Fields AS F;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.tblWF_ReportDatasetField
        WHERE ReportDatasetID = @ReportDatasetID
          AND FieldKey = 'rowCount'
          AND [Enable] = 0
    )
    BEGIN
        INSERT INTO dbo.tblWF_ReportDatasetField
        (
            ReportDatasetID, FieldKey, FieldLabel, FieldRole, DataType,
            IsFilterable, IsGroupable, IsAggregatable, SortOrder, IsActive,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            @ReportDatasetID, 'rowCount', N'Số dòng', 'METRIC', 'number',
            0, 0, 1, 9990, 1,
            @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 0
        );
    END

    SELECT
        Message = N'Đã tạo dataset API/store và lưu metadata field cho builder/detail.',
        ReportDatasetID = @ReportDatasetID,
        DatasetCode = @DatasetCode,
        DatasetName = @DatasetName,
        DatasetType = 'DB',
        SourceKind = 'API',
        SourceApiCode = @SourceApiCode,
        SourceProcedureName = @SourceProcedureName,
        DetailSourceProcedureName = @DetailSourceProcedureName,
        SchemaStatus = 'READY';

    SELECT
        ReportDatasetFieldID,
        ReportDatasetID,
        FieldKey,
        FieldLabel,
        FieldRole,
        DataType,
        SortOrder
    FROM dbo.tblWF_ReportDatasetField
    WHERE ReportDatasetID = @ReportDatasetID
      AND [Enable] = 0
    ORDER BY SortOrder, FieldKey;
END
