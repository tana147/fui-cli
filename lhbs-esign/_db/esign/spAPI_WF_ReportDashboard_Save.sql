CREATE PROCEDURE [dbo].[spAPI_WF_ReportDashboard_Save]
    @ReportDashboardID BIGINT = 0,
    @sys_UserID VARCHAR(50),
    @sys_UserFullName NVARCHAR(200) = NULL,
    @sys_RawData NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DashboardName NVARCHAR(200) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DashboardName'), N'')));
    DECLARE @IsDefault BIT = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.IsDefault') AS BIT), 0);

    IF @DashboardName = N''
    BEGIN
        SET @DashboardName = N'Dashboard báo cáo của tôi';
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
            NULL, @DashboardName, @sys_UserID, ISNULL(@sys_UserFullName, @sys_UserID), N'{}',
            @IsDefault, 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 0
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
            IsDefault = @IsDefault,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE ReportDashboardID = @ReportDashboardID
          AND OwnerUserID = @sys_UserID
          AND [Enable] = 0;
    END

    IF @IsDefault = 1
    BEGIN
        UPDATE dbo.tblWF_ReportDashboard
        SET IsDefault = CASE WHEN ReportDashboardID = @ReportDashboardID THEN 1 ELSE 0 END,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE OwnerUserID = @sys_UserID
          AND [Enable] = 0;
    END

    SELECT
        Message = N'Lưu dashboard thành công.',
        ReportDashboardID = @ReportDashboardID;
END
