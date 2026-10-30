CREATE PROCEDURE [dbo].[spAPI_WF_ReportDataset_GetList]
    @sys_UserID VARCHAR(50),
    @Keyword NVARCHAR(200) = NULL,
    @OnlyActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @q NVARCHAR(200) = LTRIM(RTRIM(ISNULL(@Keyword, N'')));

    SELECT
        D.ReportDatasetID,
        D.DatasetCode,
        D.DatasetName,
        D.Description,
        D.Icon,
        D.ThemeColor,
        D.DatasetType,
        D.SourceKind,
        D.SourceFileID,
        D.SourceFileName,
        D.SourceContentType,
        D.SourceApiCode,
        D.SourceProcedureName,
        D.DetailSourceProcedureName,
        D.SourceConfigJson,
        D.SchemaStatus,
        D.OwnerUserID,
        D.OwnerUserName,
        D.SortOrder,
        D.IsActive,
        CanPreview = CASE
            WHEN D.DatasetType = 'FILE' AND ISNULL(D.SourceKind, '') = 'CSV' AND D.SourceFileID IS NOT NULL THEN 1
            WHEN ISNULL(D.SourceKind, 'DATABASE') = 'API' AND ISNULL(D.SourceProcedureName, '') <> '' AND D.SchemaStatus = 'READY' THEN 1
            WHEN D.DatasetType = 'DB' AND ISNULL(D.SourceKind, 'DATABASE') = 'DATABASE' AND D.SchemaStatus = 'READY' THEN 1
            ELSE 0
        END,
        DimensionCount = SUM(CASE WHEN F.FieldRole = 'DIMENSION' AND F.[Enable] = 0 THEN 1 ELSE 0 END),
        MetricCount = SUM(CASE WHEN F.FieldRole = 'METRIC' AND F.[Enable] = 0 THEN 1 ELSE 0 END)
    FROM dbo.tblWF_ReportDataset AS D
    LEFT JOIN dbo.tblWF_ReportDatasetField AS F
        ON F.ReportDatasetID = D.ReportDatasetID
       AND F.[Enable] = 0
       AND F.IsActive = 1
    WHERE D.[Enable] = 0
      AND (@OnlyActive = 0 OR D.IsActive = 1)
      AND (D.OwnerUserID IS NULL OR D.OwnerUserID = @sys_UserID)
      AND (
            @q = N''
            OR D.DatasetName LIKE N'%' + @q + N'%'
            OR D.DatasetCode LIKE '%' + CAST(@q AS VARCHAR(200)) + '%'
            OR D.SourceFileName LIKE N'%' + @q + N'%'
            OR D.SourceApiCode LIKE '%' + CAST(@q AS VARCHAR(200)) + '%'
            OR D.SourceProcedureName LIKE '%' + CAST(@q AS VARCHAR(200)) + '%'
            OR D.DetailSourceProcedureName LIKE '%' + CAST(@q AS VARCHAR(200)) + '%'
          )
    GROUP BY
        D.ReportDatasetID, D.DatasetCode, D.DatasetName, D.Description, D.Icon, D.ThemeColor,
        D.DatasetType, D.SourceKind, D.SourceFileID, D.SourceFileName, D.SourceContentType,
        D.SourceApiCode, D.SourceProcedureName, D.DetailSourceProcedureName, D.SourceConfigJson,
        D.SchemaStatus, D.OwnerUserID, D.OwnerUserName, D.SortOrder, D.IsActive
    ORDER BY D.SortOrder, D.DatasetName;

    SELECT
        F.ReportDatasetFieldID,
        F.ReportDatasetID,
        D.DatasetCode,
        D.DatasetType,
        D.SourceKind,
        D.SchemaStatus,
        F.FieldKey,
        F.FieldLabel,
        F.FieldRole,
        F.DataType,
        F.IsFilterable,
        F.IsGroupable,
        F.IsAggregatable,
        F.SortOrder,
        F.IsActive
    FROM dbo.tblWF_ReportDatasetField AS F
    INNER JOIN dbo.tblWF_ReportDataset AS D
        ON D.ReportDatasetID = F.ReportDatasetID
       AND D.[Enable] = 0
    WHERE F.[Enable] = 0
      AND F.IsActive = 1
      AND (@OnlyActive = 0 OR D.IsActive = 1)
      AND (D.OwnerUserID IS NULL OR D.OwnerUserID = @sys_UserID)
    ORDER BY D.SortOrder, F.SortOrder, F.FieldKey;
END
