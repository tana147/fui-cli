-- ==============================================================================
-- STORED PROCEDURE: spAPI_KPI_SaveCausalReason
-- Mô tả: Cho phép người dùng cập nhật tuyến xử lý lý do rút học từ giao diện
-- DB: eSignature (esign)
-- ==============================================================================

CREATE OR ALTER PROCEDURE spAPI_KPI_SaveCausalReason
    @ReasonCode VARCHAR(50),
    @ActionOwner NVARCHAR(150),
    @WatchIndicator NVARCHAR(255),
    @RecommendedAction NVARCHAR(500),
    @ControlLevel NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE tblKPI_CausalReasons
    SET 
        ActionOwner = @ActionOwner,
        WatchIndicator = @WatchIndicator,
        RecommendedAction = @RecommendedAction,
        ControlLevel = @ControlLevel
    WHERE ReasonCode = @ReasonCode;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
