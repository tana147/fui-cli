-- ========================================================
-- STORED PROCEDURE: spAPI_KPI_SaveParameter
-- Lưu / cập nhật tham số nghiệp vụ linh hoạt
-- DB: eSignature (esign)
-- ========================================================
CREATE   PROCEDURE spAPI_KPI_SaveParameter
    @ParamID INT,
    @ParamCode VARCHAR(50),
    @ScopeType VARCHAR(20),
    @ScopeID VARCHAR(20),
    @PeriodKey VARCHAR(20),
    @ParamValue FLOAT,
    @ParamStringValue NVARCHAR(250),
    @Description NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;

    IF @ScopeType IS NULL OR @ScopeType = '' SET @ScopeType = 'SYSTEM';
    IF @ScopeID IS NULL OR @ScopeID = '' SET @ScopeID = 'ALL';
    IF @PeriodKey IS NULL OR @PeriodKey = '' SET @PeriodKey = 'ALL';

    IF @ParamID IS NOT NULL AND @ParamID > 0 AND EXISTS (SELECT 1 FROM tblKPI_Parameters WHERE ParamID = @ParamID)
    BEGIN
        UPDATE tblKPI_Parameters
        SET 
            ParamCode = @ParamCode,
            ScopeType = @ScopeType,
            ScopeID = @ScopeID,
            PeriodKey = @PeriodKey,
            ParamValue = @ParamValue,
            ParamStringValue = @ParamStringValue,
            Description = @Description,
            UpdatedAt = GETDATE()
        WHERE ParamID = @ParamID;
    END
    ELSE IF EXISTS (SELECT 1 FROM tblKPI_Parameters WHERE ParamCode = @ParamCode AND ScopeID = @ScopeID AND PeriodKey = @PeriodKey)
    BEGIN
        UPDATE tblKPI_Parameters
        SET 
            ParamValue = @ParamValue,
            ParamStringValue = @ParamStringValue,
            Description = @Description,
            UpdatedAt = GETDATE()
        WHERE ParamCode = @ParamCode AND ScopeID = @ScopeID AND PeriodKey = @PeriodKey;
    END
    ELSE
    BEGIN
        INSERT INTO tblKPI_Parameters (
            ParamCode, ScopeType, ScopeID, PeriodKey, ParamValue, ParamStringValue, Description, CreatedAt, UpdatedAt
        )
        VALUES (
            @ParamCode, @ScopeType, @ScopeID, @PeriodKey, @ParamValue, @ParamStringValue, @Description, GETDATE(), GETDATE()
        );
    END

    SELECT 1 AS Success, N'Đã cập nhật tham số nghiệp vụ' AS Message;
END;
