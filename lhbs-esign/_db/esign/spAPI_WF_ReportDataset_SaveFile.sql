CREATE PROCEDURE [dbo].[spAPI_WF_ReportDataset_SaveFile]
    @sys_UserID VARCHAR(50),
    @sys_UserFullName NVARCHAR(200) = NULL,
    @sys_RawData NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DatasetName NVARCHAR(200) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DatasetName'), N'')));
    DECLARE @Description NVARCHAR(500) = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.Description'), N''))), N'');
    DECLARE @SourceFileID UNIQUEIDENTIFIER = TRY_CAST(JSON_VALUE(@sys_RawData, '$.SourceFileID') AS UNIQUEIDENTIFIER);
    DECLARE @SourceFileName NVARCHAR(260) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SourceFileName'), N'')));
    DECLARE @SourceContentType VARCHAR(150) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SourceContentType'), '')));
    DECLARE @SourceKind VARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SourceKind'), 'CSV'))));
    DECLARE @SourceMetaJson NVARCHAR(MAX) = JSON_QUERY(@sys_RawData, '$.SourceMeta');
    DECLARE @DatasetCode VARCHAR(50) = 'file_' + REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '');
    DECLARE @SchemaStatus VARCHAR(30) = 'PENDING_SCHEMA';
    DECLARE @ReportDatasetID INT = 0;
    DECLARE @SortOrder INT = 900;

    DECLARE @Columns TABLE
    (
        RowNo INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        FieldKey VARCHAR(50) NOT NULL,
        FieldLabel NVARCHAR(200) NOT NULL,
        DataType VARCHAR(20) NOT NULL
    );

    IF @DatasetName = N''
    BEGIN
        RAISERROR(N'Tên dataset không được để trống.', 16, 1);
        RETURN;
    END

    IF @SourceFileID IS NULL
    BEGIN
        RAISERROR(N'Chưa nhận được FileID sau khi upload file.', 16, 1);
        RETURN;
    END

    IF @SourceKind NOT IN ('CSV', 'XLS', 'XLSX')
    BEGIN
        SET @SourceKind = 'CSV';
    END

    INSERT INTO @Columns (FieldKey, FieldLabel, DataType)
    SELECT
        FieldKey = LEFT(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.FieldKey'), ''))), 50),
        FieldLabel = LEFT(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.FieldLabel'), N''))), 200),
        DataType = CASE
            WHEN LOWER(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.DataType'), '')))) IN ('number', 'date', 'datetime', 'boolean')
                THEN LOWER(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.DataType'), ''))))
            ELSE 'string'
        END
    FROM OPENJSON(@sys_RawData, '$.Columns')
    WHERE LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.FieldKey'), ''))) <> ''
      AND LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.FieldLabel'), N''))) <> N'';

    IF EXISTS (SELECT 1 FROM @Columns)
    BEGIN
        SET @SchemaStatus = 'READY';
    END

    SELECT @SortOrder = ISNULL(MAX(SortOrder), 800) + 10
    FROM dbo.tblWF_ReportDataset
    WHERE [Enable] = 0;

    INSERT INTO dbo.tblWF_ReportDataset
    (
        DatasetCode, DatasetName, Description, Icon, ThemeColor, DatasetType, SourceKind,
        SourceFileID, SourceFileName, SourceContentType, SchemaStatus,
        OwnerUserID, OwnerUserName, SourceMetaJson,
        SortOrder, IsActive, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
    )
    VALUES
    (
        @DatasetCode, @DatasetName, @Description, 'mdi-file-upload-outline', '#7b5e10', 'FILE', @SourceKind,
        @SourceFileID, @SourceFileName, @SourceContentType, @SchemaStatus,
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
        C.FieldKey,
        C.FieldLabel,
        'DIMENSION',
        C.DataType,
        1,
        1,
        0,
        C.RowNo * 10,
        1,
        @sys_UserID,
        GETDATE(),
        @sys_UserID,
        GETDATE(),
        0
    FROM @Columns AS C
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.tblWF_ReportDatasetField AS F
        WHERE F.ReportDatasetID = @ReportDatasetID
          AND F.FieldKey = C.FieldKey
    );

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
        Message = CASE
            WHEN @SchemaStatus = 'READY' AND @SourceKind = 'CSV' THEN N'Đã tạo dataset file và nhận diện schema CSV.'
            WHEN @SchemaStatus = 'READY' AND @SourceKind IN ('XLS', 'XLSX') THEN N'Đã tạo dataset Excel và nhận diện sheet/header sơ bộ.'
            ELSE N'Đã tạo dataset file và lưu metadata nguồn, chờ map schema ở bước tiếp theo.'
        END,
        ReportDatasetID = @ReportDatasetID,
        DatasetCode = @DatasetCode,
        DatasetName = @DatasetName,
        DatasetType = 'FILE',
        SourceKind = @SourceKind,
        SchemaStatus = @SchemaStatus,
        SourceFileID = @SourceFileID,
        SourceFileName = @SourceFileName;

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
