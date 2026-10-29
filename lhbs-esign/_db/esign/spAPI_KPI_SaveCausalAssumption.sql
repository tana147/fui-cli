-- ==============================================================================
-- STORED PROCEDURE: spAPI_KPI_SaveCausalAssumption
-- Mô tả: Cho phép người dùng cập nhật thông số giả định đơn vị từ giao diện
-- DB: eSignature (esign)
-- ==============================================================================

CREATE   PROCEDURE spAPI_KPI_SaveCausalAssumption
    @UnitCode VARCHAR(20),
    @AnnualTuitionMillion FLOAT,
    @GrossMarginPct FLOAT,
    @RemainingYearsInLevel FLOAT,
    @MonthlyLeads INT,
    @ConversionRate FLOAT,
    @PlannedCapacity INT,
    @CurrentEnrollment INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE tblKPI_CausalAssumptions
    SET 
        AnnualTuitionMillion = @AnnualTuitionMillion,
        GrossMarginPct = @GrossMarginPct,
        RemainingYearsInLevel = @RemainingYearsInLevel,
        MonthlyLeads = @MonthlyLeads,
        ConversionRate = @ConversionRate,
        PlannedCapacity = ISNULL(@PlannedCapacity, PlannedCapacity),
        CurrentEnrollment = ISNULL(@CurrentEnrollment, CurrentEnrollment),
        UpdatedAt = GETDATE()
    WHERE UnitCode = @UnitCode;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
