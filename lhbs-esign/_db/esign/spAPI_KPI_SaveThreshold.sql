-- ========================================================
-- STORED PROCEDURE: spAPI_KPI_SaveThreshold
-- Lưu / cập nhật ngưỡng KPI động
-- DB: eSignature (esign)
-- ========================================================
CREATE   PROCEDURE spAPI_KPI_SaveThreshold
    @ThresholdID INT,
    @KpiCode VARCHAR(50),
    @ScopeType VARCHAR(20),
    @ScopeID VARCHAR(20),
    @PeriodKey VARCHAR(20),
    @TargetValue FLOAT,
    @WarnThreshold FLOAT,
    @CriticalThreshold FLOAT,
    @ComparisonOperator VARCHAR(10),
    @StatusGoodLabel NVARCHAR(50),
    @StatusWarnLabel NVARCHAR(50),
    @StatusBadLabel NVARCHAR(50),
    @Description NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;

    IF @ScopeType IS NULL OR @ScopeType = '' SET @ScopeType = 'SYSTEM';
    IF @ScopeID IS NULL OR @ScopeID = '' SET @ScopeID = 'ALL';
    IF @PeriodKey IS NULL OR @PeriodKey = '' SET @PeriodKey = 'ALL';
    IF @ComparisonOperator IS NULL OR @ComparisonOperator = '' SET @ComparisonOperator = '>=';
    IF @StatusGoodLabel IS NULL OR @StatusGoodLabel = '' SET @StatusGoodLabel = N'AN TOÀN';
    IF @StatusWarnLabel IS NULL OR @StatusWarnLabel = '' SET @StatusWarnLabel = N'THEO DÕI';
    IF @StatusBadLabel IS NULL OR @StatusBadLabel = '' SET @StatusBadLabel = N'CẢNH BÁO';

    IF @ThresholdID IS NOT NULL AND @ThresholdID > 0 AND EXISTS (SELECT 1 FROM tblKPI_Thresholds WHERE ThresholdID = @ThresholdID)
    BEGIN
        UPDATE tblKPI_Thresholds
        SET 
            KpiCode = @KpiCode,
            ScopeType = @ScopeType,
            ScopeID = @ScopeID,
            PeriodKey = @PeriodKey,
            TargetValue = @TargetValue,
            WarnThreshold = @WarnThreshold,
            CriticalThreshold = @CriticalThreshold,
            ComparisonOperator = @ComparisonOperator,
            StatusGoodLabel = @StatusGoodLabel,
            StatusWarnLabel = @StatusWarnLabel,
            StatusBadLabel = @StatusBadLabel,
            Description = @Description,
            UpdatedAt = GETDATE()
        WHERE ThresholdID = @ThresholdID;
    END
    ELSE IF EXISTS (SELECT 1 FROM tblKPI_Thresholds WHERE KpiCode = @KpiCode AND ScopeID = @ScopeID AND PeriodKey = @PeriodKey)
    BEGIN
        UPDATE tblKPI_Thresholds
        SET 
            TargetValue = @TargetValue,
            WarnThreshold = @WarnThreshold,
            CriticalThreshold = @CriticalThreshold,
            ComparisonOperator = @ComparisonOperator,
            StatusGoodLabel = @StatusGoodLabel,
            StatusWarnLabel = @StatusWarnLabel,
            StatusBadLabel = @StatusBadLabel,
            Description = @Description,
            UpdatedAt = GETDATE()
        WHERE KpiCode = @KpiCode AND ScopeID = @ScopeID AND PeriodKey = @PeriodKey;
    END
    ELSE
    BEGIN
        INSERT INTO tblKPI_Thresholds (
            KpiCode, ScopeType, ScopeID, PeriodKey,
            TargetValue, WarnThreshold, CriticalThreshold, ComparisonOperator,
            StatusGoodLabel, StatusWarnLabel, StatusBadLabel, Description,
            CreatedAt, UpdatedAt
        )
        VALUES (
            @KpiCode, @ScopeType, @ScopeID, @PeriodKey,
            @TargetValue, @WarnThreshold, @CriticalThreshold, @ComparisonOperator,
            @StatusGoodLabel, @StatusWarnLabel, @StatusBadLabel, @Description,
            GETDATE(), GETDATE()
        );
    END

    SELECT 1 AS Success, N'Đã cập nhật cấu hình ngưỡng KPI' AS Message;
END;
