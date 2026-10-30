CREATE PROCEDURE [dbo].[spAPI_WF_ReportDefinition_GetDetail]
    @ReportDefinitionID BIGINT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@ReportDefinitionID, 0) <= 0
    BEGIN
        RAISERROR(N'Không tìm thấy báo cáo cần xem.', 16, 1);
        RETURN;
    END

    SELECT TOP (1)
        R.ReportDefinitionID,
        R.ReportCode,
        R.ReportName,
        R.Description,
        R.DatasetCode,
        DatasetName = D.DatasetName,
        DatasetDescription = D.Description,
        R.ChartType,
        R.DimensionKey,
        R.MetricKey,
        R.TimeRangeKey,
        R.StatusFilter,
        R.SelectedFieldsJson,
        R.ConfigJson,
        R.IsShared,
        R.IsPinnedDashboard,
        R.IsActive,
        R.OwnerUserID,
        R.OwnerUserName,
        R.CreateTime,
        R.UpdateTime
    FROM dbo.tblWF_ReportDefinition AS R
    LEFT JOIN dbo.tblWF_ReportDataset AS D
        ON D.DatasetCode = R.DatasetCode
       AND D.[Enable] = 0
    WHERE R.ReportDefinitionID = @ReportDefinitionID
      AND R.[Enable] = 0
      AND (R.OwnerUserID = @sys_UserID OR R.IsShared = 1);

    SELECT TOP (1)
        D.ReportDatasetID,
        D.DatasetCode,
        D.DatasetName,
        D.Description,
        D.Icon,
        D.ThemeColor,
        D.SortOrder,
        D.IsActive
    FROM dbo.tblWF_ReportDefinition AS R
    INNER JOIN dbo.tblWF_ReportDataset AS D
        ON D.DatasetCode = R.DatasetCode
       AND D.[Enable] = 0
    WHERE R.ReportDefinitionID = @ReportDefinitionID
      AND R.[Enable] = 0;

    SELECT
        F.ReportDatasetFieldID,
        D.DatasetCode,
        F.FieldKey,
        F.FieldLabel,
        F.FieldRole,
        F.DataType,
        F.IsFilterable,
        F.IsGroupable,
        F.IsAggregatable,
        F.SortOrder
    FROM dbo.tblWF_ReportDefinition AS R
    INNER JOIN dbo.tblWF_ReportDataset AS D
        ON D.DatasetCode = R.DatasetCode
       AND D.[Enable] = 0
    INNER JOIN dbo.tblWF_ReportDatasetField AS F
        ON F.ReportDatasetID = D.ReportDatasetID
       AND F.[Enable] = 0
       AND F.IsActive = 1
    WHERE R.ReportDefinitionID = @ReportDefinitionID
      AND R.[Enable] = 0
    ORDER BY F.SortOrder, F.FieldKey;
END
