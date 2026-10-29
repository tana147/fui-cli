-- ===================================================================================
-- MIGRATION V2: DROP LEGACY / DEPRECATED TABLES
-- Mục đích: Dọn dẹp sạch sẽ các bảng generic cũ, chống phình to dữ liệu và duplicate
-- Database: eSignature
-- ===================================================================================
SET NOCOUNT ON;

-- 1. XOÁ BẢNG SUPER TABLE GENERIC CŨ (Đã chuyển giao sang 8 bảng tblKPI_Snap_*)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_OperationalFacts')
BEGIN
    DROP TABLE tblKPI_OperationalFacts;
    PRINT N'Đã xoá bảng tblKPI_OperationalFacts (Super table generic cũ).';
END;

-- 2. XOÁ CÁC BẢNG DIMENSION GENERIC
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_DimensionMembers')
BEGIN
    DROP TABLE tblKPI_DimensionMembers;
    PRINT N'Đã xoá bảng tblKPI_DimensionMembers.';
END;

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_DimensionTypes')
BEGIN
    DROP TABLE tblKPI_DimensionTypes;
    PRINT N'Đã xoá bảng tblKPI_DimensionTypes.';
END;

-- 3. XOÁ BẢNG QUAN HỆ PHẲNG VÀ LUẬT NHÂN QUẢ ĐỜI CŨ (Đã có tblKPI_CorrelationOntology thay thế)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Correlations')
BEGIN
    DROP TABLE tblKPI_Correlations;
    PRINT N'Đã xoá bảng tblKPI_Correlations cũ.';
END;

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_CorrelationRules')
BEGIN
    DROP TABLE tblKPI_CorrelationRules;
    PRINT N'Đã xoá bảng tblKPI_CorrelationRules cũ.';
END;

-- 4. XOÁ BẢNG NHẬN ĐỊNH CŨ (Đã có tblKPI_CausalNarratives thay thế)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_PeriodNarratives')
BEGIN
    DROP TABLE tblKPI_PeriodNarratives;
    PRINT N'Đã xoá bảng tblKPI_PeriodNarratives cũ.';
END;
