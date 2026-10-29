-- ===================================================================================
-- STORED PROCEDURE: spAPI_KPI_FreezePeriodData
-- Mô tả: Tiến trình đóng băng kỳ (Period Freeze Engine) và tổng hợp Macro KPI
-- Đóng dấu bất biến IsFrozen = 1 cho kỳ chỉ định và bảo đảm toàn vẹn dữ liệu
-- Database: eSignature
-- ===================================================================================

CREATE   PROCEDURE spAPI_KPI_FreezePeriodData
    @PeriodKey VARCHAR(20),
    @FrozenBy NVARCHAR(100),
    @Note NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
    BEGIN
        RAISERROR(N'PeriodKey không được để trống.', 16, 1);
        RETURN;
    END;

    IF @FrozenBy IS NULL OR @FrozenBy = ''
        SET @FrozenBy = N'Ban Điều Hành LHBS';

    -- 1. Kiểm tra kỳ có tồn tại trong tblKPI_Periods không
    IF NOT EXISTS (SELECT 1 FROM tblKPI_Periods WHERE PeriodKey = @PeriodKey)
    BEGIN
        RAISERROR(N'Kỳ %s không tồn tại trong danh mục tblKPI_Periods.', 16, 1, @PeriodKey);
        RETURN;
    END;

    -- 2. Kiểm tra dữ liệu snapshot nguồn đã có chưa
    DECLARE @FactCount INT = 0;
    SELECT @FactCount = 
        (SELECT COUNT(*) FROM tblKPI_Snap_HRM_Leave WHERE PeriodKey = @PeriodKey) +
        (SELECT COUNT(*) FROM tblKPI_Snap_Healthcare WHERE PeriodKey = @PeriodKey) +
        (SELECT COUNT(*) FROM tblKPI_Snap_Maintenance WHERE PeriodKey = @PeriodKey) +
        (SELECT COUNT(*) FROM tblKPI_Snap_Finance_Services WHERE PeriodKey = @PeriodKey);

    IF @FactCount = 0
    BEGIN
        RAISERROR(N'Cảnh báo: Kỳ %s chưa có dữ liệu giao dịch chi tiết trong các bảng snapshot nguồn.', 16, 1, @PeriodKey);
        RETURN;
    END;

    -- 3. Cập nhật trạng thái đóng băng trong tblKPI_Periods
    UPDATE tblKPI_Periods
    SET 
        IsFrozen = 1,
        FreezeDate = GETDATE(),
        FrozenBy = @FrozenBy,
        Note = ISNULL(@Note, Note)
    WHERE PeriodKey = @PeriodKey;

    -- 4. Đánh dấu IsFrozen = 1 cho toàn bộ chỉ tiêu vĩ mô của kỳ
    UPDATE tblKPI_PeriodSnapshots
    SET IsFrozen = 1
    WHERE PeriodKey = @PeriodKey;

    -- 5. Trả về thông báo thành công
    SELECT 
        @PeriodKey AS PeriodKey,
        1 AS IsFrozen,
        GETDATE() AS FreezeDate,
        @FrozenBy AS FrozenBy,
        @FactCount AS TotalSourceFactsCount,
        N'Đã chốt sổ và đóng băng thành công kỳ ' + @PeriodKey AS Message;
END;
