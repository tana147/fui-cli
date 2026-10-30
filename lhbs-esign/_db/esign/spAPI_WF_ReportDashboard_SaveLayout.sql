CREATE PROCEDURE [dbo].[spAPI_WF_ReportDashboard_SaveLayout]
    @ReportDashboardID BIGINT = 0,
    @sys_UserID VARCHAR(50),
    @sys_UserFullName NVARCHAR(200) = NULL,
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DashboardName NVARCHAR(200) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DashboardName'), N'Dashboard báo cáo của tôi')));
    DECLARE @LayoutJson NVARCHAR(MAX) = JSON_QUERY(@sys_RawData, '$.Layout');
    DECLARE @Widgets TABLE
    (
        ReportDefinitionID BIGINT NOT NULL,
        WidgetTitle NVARCHAR(200) NULL,
        ChartType VARCHAR(20) NULL,
        GridX INT NOT NULL,
        GridY INT NOT NULL,
        GridW INT NOT NULL,
        GridH INT NOT NULL,
        SortOrder INT NOT NULL
    );

    IF ISNULL(@DashboardName, N'') = N''
    BEGIN
        SET @DashboardName = N'Dashboard báo cáo của tôi';
    END

    INSERT INTO @Widgets (ReportDefinitionID, WidgetTitle, ChartType, GridX, GridY, GridW, GridH, SortOrder)
    SELECT
        ReportDefinitionID = TRY_CAST(JSON_VALUE([value], '$.ReportDefinitionID') AS BIGINT),
        WidgetTitle = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.WidgetTitle'), N''))), N''),
        ChartType = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE([value], '$.ChartType'), ''))), ''),
        GridX = ISNULL(TRY_CAST(JSON_VALUE([value], '$.GridX') AS INT), 0),
        GridY = ISNULL(TRY_CAST(JSON_VALUE([value], '$.GridY') AS INT), 0),
        GridW = ISNULL(TRY_CAST(JSON_VALUE([value], '$.GridW') AS INT), 6),
        GridH = ISNULL(TRY_CAST(JSON_VALUE([value], '$.GridH') AS INT), 4),
        SortOrder = ISNULL(TRY_CAST(JSON_VALUE([value], '$.SortOrder') AS INT), 0)
    FROM OPENJSON(@sys_RawData, '$.Widgets')
    WHERE TRY_CAST(JSON_VALUE([value], '$.ReportDefinitionID') AS BIGINT) IS NOT NULL;

    IF ISNULL(@ReportDashboardID, 0) <= 0
    BEGIN
        SELECT TOP (1)
            @ReportDashboardID = ReportDashboardID
        FROM dbo.tblWF_ReportDashboard
        WHERE OwnerUserID = @sys_UserID
          AND [Enable] = 0
          AND IsActive = 1
        ORDER BY IsDefault DESC, ReportDashboardID DESC;
    END

    IF ISNULL(@ReportDashboardID, 0) <= 0
    BEGIN
        INSERT INTO dbo.tblWF_ReportDashboard
        (
            DashboardCode, DashboardName, OwnerUserID, OwnerUserName, LayoutJson,
            IsDefault, IsActive, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            NULL, @DashboardName, @sys_UserID, ISNULL(@sys_UserFullName, @sys_UserID), @LayoutJson,
            1, 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 0
        );

        SET @ReportDashboardID = SCOPE_IDENTITY();

        UPDATE dbo.tblWF_ReportDashboard
        SET DashboardCode = 'DSB-' + RIGHT('000000' + CAST(@ReportDashboardID AS VARCHAR(20)), 6)
        WHERE ReportDashboardID = @ReportDashboardID
          AND [Enable] = 0;
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_ReportDashboard
        SET DashboardName = @DashboardName,
            LayoutJson = @LayoutJson,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE ReportDashboardID = @ReportDashboardID
          AND OwnerUserID = @sys_UserID
          AND [Enable] = 0;
    END

    UPDATE dbo.tblWF_ReportDashboardWidget
    SET [Enable] = 1,
        IsActive = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE ReportDashboardID = @ReportDashboardID
      AND [Enable] = 0;

    INSERT INTO dbo.tblWF_ReportDashboardWidget
    (
        ReportDashboardID, ReportDefinitionID, WidgetTitle, ChartType, GridX, GridY, GridW, GridH,
        SortOrder, IsPinned, IsActive, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
    )
    SELECT
        @ReportDashboardID,
        W.ReportDefinitionID,
        ISNULL(W.WidgetTitle, R.ReportName),
        ISNULL(W.ChartType, R.ChartType),
        W.GridX,
        W.GridY,
        CASE WHEN W.GridW <= 0 THEN 6 ELSE W.GridW END,
        CASE WHEN W.GridH <= 0 THEN 4 ELSE W.GridH END,
        W.SortOrder,
        1,
        1,
        @sys_UserID,
        GETDATE(),
        @sys_UserID,
        GETDATE(),
        0
    FROM @Widgets AS W
    INNER JOIN dbo.tblWF_ReportDefinition AS R
        ON R.ReportDefinitionID = W.ReportDefinitionID
       AND R.[Enable] = 0
       AND R.OwnerUserID = @sys_UserID;

    UPDATE R
    SET IsPinnedDashboard = CASE WHEN P.ReportDefinitionID IS NULL THEN 0 ELSE 1 END,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    FROM dbo.tblWF_ReportDefinition AS R
    LEFT JOIN
    (
        SELECT DISTINCT ReportDefinitionID
        FROM dbo.tblWF_ReportDashboardWidget
        WHERE ReportDashboardID = @ReportDashboardID
          AND [Enable] = 0
          AND IsActive = 1
    ) AS P
        ON P.ReportDefinitionID = R.ReportDefinitionID
    WHERE R.OwnerUserID = @sys_UserID
      AND R.[Enable] = 0;

    SELECT
        Message = N'Lưu bố cục dashboard thành công.',
        ReportDashboardID = @ReportDashboardID,
        WidgetCount = (SELECT COUNT(1) FROM dbo.tblWF_ReportDashboardWidget WHERE ReportDashboardID = @ReportDashboardID AND [Enable] = 0 AND IsActive = 1);
END
