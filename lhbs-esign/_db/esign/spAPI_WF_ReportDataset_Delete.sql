CREATE PROCEDURE [dbo].[spAPI_WF_ReportDataset_Delete]
    @sys_UserID VARCHAR(50),
    @sys_RawData NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DatasetCode VARCHAR(50) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DatasetCode'), '')));
    DECLARE @ReportDatasetID INT = 0;
    DECLARE @DatasetName NVARCHAR(200) = N'';
    DECLARE @DatasetType VARCHAR(20) = '';
    DECLARE @SourceKind VARCHAR(20) = '';
    DECLARE @OwnerUserID VARCHAR(50) = '';

    IF @DatasetCode = ''
    BEGIN
        RAISERROR(N'Không xác định được dataset cần xóa.', 16, 1);
        RETURN;
    END

    SELECT TOP (1)
        @ReportDatasetID = D.ReportDatasetID,
        @DatasetName = D.DatasetName,
        @DatasetType = ISNULL(D.DatasetType, 'DB'),
        @SourceKind = ISNULL(D.SourceKind, 'DATABASE'),
        @OwnerUserID = ISNULL(D.OwnerUserID, '')
    FROM dbo.tblWF_ReportDataset AS D
    WHERE D.DatasetCode = @DatasetCode
      AND D.[Enable] = 0;

    IF ISNULL(@ReportDatasetID, 0) <= 0
    BEGIN
        RAISERROR(N'Dataset không tồn tại hoặc đã bị xóa trước đó.', 16, 1);
        RETURN;
    END

    IF NOT (@DatasetType = 'FILE' OR @SourceKind = 'API')
    BEGIN
        RAISERROR(N'Chỉ được xóa dataset file hoặc dataset API/store do người dùng đăng ký.', 16, 1);
        RETURN;
    END

    IF @OwnerUserID = '' OR @OwnerUserID <> @sys_UserID
    BEGIN
        RAISERROR(N'Bạn không có quyền xóa dataset này.', 16, 1);
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM dbo.tblWF_ReportDefinition AS R
        WHERE R.DatasetCode = @DatasetCode
          AND R.[Enable] = 0
          AND R.IsActive = 1
    )
    BEGIN
        RAISERROR(N'Dataset đang được dùng bởi widget đang active. Hãy gỡ hoặc ngừng kích hoạt widget trước khi xóa dataset.', 16, 1);
        RETURN;
    END

    UPDATE dbo.tblWF_ReportDataset
    SET [Enable] = 1,
        IsActive = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE ReportDatasetID = @ReportDatasetID
      AND [Enable] = 0;

    UPDATE dbo.tblWF_ReportDatasetField
    SET [Enable] = 1,
        IsActive = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE ReportDatasetID = @ReportDatasetID
      AND [Enable] = 0;

    SELECT
        Message = N'Đã xóa dataset khỏi catalog nguồn dữ liệu.',
        ReportDatasetID = @ReportDatasetID,
        DatasetCode = @DatasetCode,
        DatasetName = @DatasetName;
END
