-- ===================================================================================
-- MIGRATION V2: DROP LEGACY / DEPRECATED TABLES
-- Mục đích: Dọn dẹp dứt điểm các bảng generic cũ sau khi đã chuyển sang 8 bảng tblKPI_Snap_*
-- Database: eSignature
-- Chú ý: Lệnh DROP TABLE trên bảng vật lý bị FUI CLI guard chặn tự động vì lý do an toàn.
--        Vui lòng chạy script này trực tiếp trên SSMS, DBeaver hoặc Azure Data Studio.
-- ===================================================================================
SET NOCOUNT ON;

-- 1. XOÁ BẢNG SUPER TABLE GENERIC CŨ (Đã chuyển giao sang 8 bảng tblKPI_Snap_*)
DROP TABLE IF EXISTS tblKPI_OperationalFacts_deprecated;
DROP TABLE IF EXISTS tblKPI_OperationalFacts;
PRINT N'Đã xoá tblKPI_OperationalFacts.';

-- 2. XOÁ CÁC BẢNG DIMENSION GENERIC
DROP TABLE IF EXISTS tblKPI_DimensionMembers_deprecated;
DROP TABLE IF EXISTS tblKPI_DimensionMembers;
DROP TABLE IF EXISTS tblKPI_DimensionTypes_deprecated;
DROP TABLE IF EXISTS tblKPI_DimensionTypes;
PRINT N'Đã xoá tblKPI_DimensionMembers và tblKPI_DimensionTypes.';

-- 3. XOÁ BẢNG LUẬT QUAN HỆ CŨ (Đã có tblKPI_CorrelationOntology thay thế)
DROP TABLE IF EXISTS tblKPI_CorrelationRules_deprecated;
DROP TABLE IF EXISTS tblKPI_CorrelationRules;
PRINT N'Đã xoá tblKPI_CorrelationRules.';

-- 4. XOÁ BẢNG NHẬN ĐỊNH CŨ (Đã có tblKPI_CausalNarratives thay thế)
DROP TABLE IF EXISTS tblKPI_PeriodNarratives_deprecated;
DROP TABLE IF EXISTS tblKPI_PeriodNarratives;
PRINT N'Đã xoá tblKPI_PeriodNarratives.';
