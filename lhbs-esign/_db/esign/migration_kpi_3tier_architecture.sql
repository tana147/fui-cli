-- ==============================================================================================
-- MIGRATION: KIẾN TRÚC DASHBOARD KPI 3 TẦNG (3-TIER PERFORMANCE ARCHITECTURE)
-- Dự án: LHBS eSign / KPI Workspace (LHBS Performance Management)
-- Phiên bản: 3.0 (Tháng 10/2026)
-- Mục tiêu: Quản trị 6 KPI Chiến lược Cha -> Ánh xạ 60 Tiêu chí Vận hành Con -> Cấu hình Deep-dive
-- ==============================================================================================

SET NOCOUNT ON;

-- 1. BẢNG MASTER: Quản trị 6 KPI Chiến lược Tối thượng
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tblKPI_StrategicFramework')
BEGIN
    CREATE TABLE dbo.tblKPI_StrategicFramework (
        MasterKpiCode   VARCHAR(20) PRIMARY KEY,     -- 'KPI_1', 'KPI_2', 'KPI_3', 'KPI_4', 'KPI_5', 'KPI_6'
        KpiName         NVARCHAR(250) NOT NULL,      -- Tên KPI Chiến lược
        ShortCode       VARCHAR(50) NOT NULL,        -- 'CAPACITY', 'GRADUATION', 'RETENTION', 'GROSS_MARGIN', 'ADMIN_REFORM', 'FUNNEL_SATISFACTION'
        TargetValue     DECIMAL(18,2) NOT NULL,      -- 100.0, 50.0, 10.0, 30.0...
        TargetUnit      NVARCHAR(50) NOT NULL,       -- '%', 'Chỗ', 'Ngày'
        ComparisonOp    VARCHAR(5) NOT NULL,         -- '>=', '<=', '='
        OwnerRole       NVARCHAR(150) NOT NULL,      -- 'Hiệu trưởng', 'Trưởng ban Tuyển sinh', 'Kế toán trưởng'
        DisplayOrder    INT NOT NULL,                -- 1 đến 6
        ThemeColor      VARCHAR(20) NOT NULL,        -- Màu chủ đạo (#0284c7, #16a34a, #ea580c...)
        IconClass       VARCHAR(50) NOT NULL,        -- Biểu tượng Bootstrap icon
        Description     NVARCHAR(500) NULL,
        IsActive        BIT NOT NULL DEFAULT 1
    );
END
GO

-- 2. BẢNG CẤU HÌNH BIỂU ĐỒ CHẨN ĐOÁN SÂU (Level 3 Diagnostic Configs)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tblKPI_DiagnosticConfigs')
BEGIN
    CREATE TABLE dbo.tblKPI_DiagnosticConfigs (
        ChartID         INT IDENTITY(1,1) PRIMARY KEY,
        MasterKpiCode   VARCHAR(20) NOT NULL REFERENCES dbo.tblKPI_StrategicFramework(MasterKpiCode),
        ChartCode       VARCHAR(50) NOT NULL UNIQUE, -- 'CHART_WF_SISO', 'CHART_TRANSITION_LEAK', 'CHART_FUNNEL'
        ChartTitle      NVARCHAR(250) NOT NULL,      -- Tên biểu đồ chẩn đoán
        ChartType       VARCHAR(50) NOT NULL,        -- 'WATERFALL', 'FUNNEL', 'BAR_CLUSTERED', 'COMBO_DUAL_AXIS'
        DataEndpoint    VARCHAR(100) NOT NULL,       -- Endpoint trích xuất dữ liệu
        WidthCols       INT NOT NULL DEFAULT 12,     -- Chiếm 6 hoặc 12 cột trên grid
        SortOrder       INT NOT NULL DEFAULT 1,
        IsActive        BIT NOT NULL DEFAULT 1
    );
END
GO

-- 3. CẬP NHẬT CỘT MasterKpiCode VÀO tblKPI_Definitions (NẾU CHƯA CÓ)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tblKPI_Definitions') AND name = 'MasterKpiCode')
BEGIN
    ALTER TABLE dbo.tblKPI_Definitions 
    ADD MasterKpiCode VARCHAR(20) NULL;
END
GO

-- 4. SEED DỮ LIỆU 6 KPI CHIẾN LƯỢC TỐI THƯỢNG
MERGE dbo.tblKPI_StrategicFramework AS target
USING (VALUES 
    ('KPI_1', N'Lấp đầy 100% công suất thiết kế', 'CAPACITY', 100.0, '%', '>=', N'Hội đồng trường & BGH', 1, '#0284c7', 'bi-building-check', N'Mục tiêu quy mô tối đa 2.810 học sinh toàn hệ thống'),
    ('KPI_2', N'Tỷ lệ trúng tuyển Đại học & Chuẩn đầu ra', 'GRADUATION', 95.0, '%', '>=', N'Ban Chuyên môn & Hiệu trưởng', 2, '#7c3aed', 'bi-mortarboard-fill', N'Đo lường chất lượng giáo dục, năng lực số và tỷ lệ tốt nghiệp THPT'),
    ('KPI_3', N'Tỷ lệ rút học & Giữ chân học sinh', 'RETENTION', 10.0, '%', '<=', N'Hiệu trưởng & Ban Bán trú/Y tế', 3, '#16a34a', 'bi-shield-check', N'Khống chế tỷ lệ rút học dưới 10%, kiểm soát an toàn bếp ăn và y tế 0 vụ'),
    ('KPI_4', N'Tỷ suất lợi nhuận gộp dịch vụ bán trú', 'GROSS_MARGIN', 50.0, '%', '>=', N'Kế toán trưởng & Ban Bán trú', 4, '#059669', 'bi-cash-coin', N'Hiệu quả tài chính từ 5 phân hệ dịch vụ học sinh và các CLB bổ trợ'),
    ('KPI_5', N'Cải cách TTHC & Giảm 50% thời gian xử lý', 'ADMIN_REFORM', 50.0, '%', '>=', N'Phòng Hành chính & Ban CSVC', 5, '#ea580c', 'bi-stopwatch', N'Rút ngắn thời gian xử lý PR/PO, mua sắm và luân chuyển ký số văn bản'),
    ('KPI_6', N'Tỷ lệ chuyển đổi Leads & Hài lòng PHHS', 'FUNNEL_SATISFACTION', 30.0, '%', '>=', N'Trưởng ban Tuyển sinh & CSKH', 6, '#dc2626', 'bi-funnel-fill', N'Chuyển đổi tối thiểu 30% Leads và đảm bảo mức độ hài lòng PHHS > 90%')
) AS source (MasterKpiCode, KpiName, ShortCode, TargetValue, TargetUnit, ComparisonOp, OwnerRole, DisplayOrder, ThemeColor, IconClass, Description)
ON target.MasterKpiCode = source.MasterKpiCode
WHEN MATCHED THEN 
    UPDATE SET 
        KpiName = source.KpiName,
        ShortCode = source.ShortCode,
        TargetValue = source.TargetValue,
        TargetUnit = source.TargetUnit,
        ComparisonOp = source.ComparisonOp,
        OwnerRole = source.OwnerRole,
        DisplayOrder = source.DisplayOrder,
        ThemeColor = source.ThemeColor,
        IconClass = source.IconClass,
        Description = source.Description,
        IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (MasterKpiCode, KpiName, ShortCode, TargetValue, TargetUnit, ComparisonOp, OwnerRole, DisplayOrder, ThemeColor, IconClass, Description, IsActive)
    VALUES (source.MasterKpiCode, source.KpiName, source.ShortCode, source.TargetValue, source.TargetUnit, source.ComparisonOp, source.OwnerRole, source.DisplayOrder, source.ThemeColor, source.IconClass, source.Description, 1);
GO

-- 5. SEED CẤU HÌNH BIỂU ĐỒ CHẨN ĐOÁN (LEVEL 3 DIAGNOSTICS)
MERGE dbo.tblKPI_DiagnosticConfigs AS target
USING (VALUES
    ('KPI_1', 'CHART_CAPACITY_CAMPUS', N'Tỷ lệ sử dụng Công suất theo Cấp học & Cơ sở', 'BAR_CLUSTERED', 'eSign/KPI_GetOperationsSummary', 6, 1),
    ('KPI_1', 'CHART_CLASS_DENSITY', N'Sĩ số bình quân & Số phòng học theo Khối', 'COMBO_DUAL_AXIS', 'eSign/KPI_GetOperationalFacts', 6, 2),
    ('KPI_2', 'CHART_LMS_ACADEMICS', N'Tiến độ Giảng dạy & Hoàn thành Bài tập LMS', 'BAR_CLUSTERED', 'lms/BaoCao_2_ThongKe_HocLieuSo_ByCapID', 12, 1),
    ('KPI_3', 'CHART_WF_SISO', N'Thác nước Biến động Sĩ số Toàn trường (Waterfall)', 'WATERFALL', 'eSign/KPI_GetPeriodSnapshots', 6, 1),
    ('KPI_3', 'CHART_TRANSITION_LEAK', N'Tỷ trọng Giữ chân Học sinh ở các Năm Chuyển cấp', 'BAR_CLUSTERED', 'Dashboard/ThongKeHocSinhChuyenDi', 6, 2),
    ('KPI_4', 'CHART_FINANCE_SERVICES', N'Biên Lợi nhuận gộp & Doanh thu 5 Dịch vụ Bán trú', 'BAR_CLUSTERED', 'eSign/KPI_GetFinanceServices', 12, 1),
    ('KPI_5', 'CHART_ADMIN_EFFICIENCY', N'Thời gian xử lý PR/PO & Bảo trì CSVC theo Bộ phận', 'BAR_CLUSTERED', 'eSign/KPI_GetOperationalFacts', 12, 1),
    ('KPI_6', 'CHART_FUNNEL_CONVERSION', N'Phễu Chuyển đổi Tuyển sinh (Leads -> Nhập học)', 'FUNNEL', 'eSign/KPI_GetOperationalFacts', 6, 1),
    ('KPI_6', 'CHART_CHANNEL_ROI', N'Cơ cấu Nguồn Leads Tiếp cận (Facebook, Hotline, Referral)', 'BAR_CLUSTERED', 'eSign/KPI_GetOperationalFacts', 6, 2)
) AS source (MasterKpiCode, ChartCode, ChartTitle, ChartType, DataEndpoint, WidthCols, SortOrder)
ON target.ChartCode = source.ChartCode
WHEN MATCHED THEN
    UPDATE SET 
        MasterKpiCode = source.MasterKpiCode,
        ChartTitle = source.ChartTitle,
        ChartType = source.ChartType,
        DataEndpoint = source.DataEndpoint,
        WidthCols = source.WidthCols,
        SortOrder = source.SortOrder,
        IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (MasterKpiCode, ChartCode, ChartTitle, ChartType, DataEndpoint, WidthCols, SortOrder, IsActive)
    VALUES (source.MasterKpiCode, source.ChartCode, source.ChartTitle, source.ChartType, source.DataEndpoint, source.WidthCols, source.SortOrder, 1);
GO

-- 6. ÁNH XẠ TOÀN BỘ 60 CHỈ TIÊU VÀO 6 KPI CHIẾN LƯỢC CHA
-- Nhóm 1: KPI_1 (Công suất & Quy mô)
UPDATE dbo.tblKPI_Definitions SET MasterKpiCode = 'KPI_1' WHERE KpiCode IN ('TS01', 'TS02', 'TS03', 'CM17', 'CM22', 'CM27');

-- Nhóm 2: KPI_2 (Học thuật, LMS & Đầu ra Đại học)
UPDATE dbo.tblKPI_Definitions SET MasterKpiCode = 'KPI_2' WHERE KpiCode IN ('CM08', 'CM09', 'CM10', 'CM11', 'CM12', 'CM13', 'CM14', 'CM15', 'CM16', 'CM18', 'CM19', 'CM20', 'CM23', 'CM24', 'CM25');

-- Nhóm 3: KPI_3 (Rút học, Giữ chân, Bếp ăn, Y tế & An toàn)
UPDATE dbo.tblKPI_Definitions SET MasterKpiCode = 'KPI_3' WHERE KpiCode IN ('TS04', 'DV28', 'DV29', 'DV30', 'DV31', 'DV32', 'DV33', 'DV37', 'DV38', 'DV39', 'DV40', 'DV41', 'CM21', 'CM26');

-- Nhóm 4: KPI_4 (Tài chính bán trú & Hiệu quả dịch vụ)
UPDATE dbo.tblKPI_Definitions SET MasterKpiCode = 'KPI_4' WHERE KpiCode IN ('DV34', 'DV35', 'DV36', 'DV42', 'DV43', 'DV44', 'DV45', 'DV46', 'TC55', 'TC56');

-- Nhóm 5: KPI_5 (Cải cách TTHC, Mua sắm & CSVC)
UPDATE dbo.tblKPI_Definitions SET MasterKpiCode = 'KPI_5' WHERE KpiCode IN ('DV47', 'DV48', 'DV49', 'TC52', 'TC53', 'TC54', 'TC57', 'TC58', 'TC59', 'TC60');

-- Nhóm 6: KPI_6 (Phễu tuyển sinh & Hài lòng PHHS)
UPDATE dbo.tblKPI_Definitions SET MasterKpiCode = 'KPI_6' WHERE KpiCode IN ('TS05', 'TS06', 'TS07', 'DV50', 'DV51');
GO

PRINT N'✅ Đã hoàn thành Migration Kiến trúc Dashboard 3 tầng thành công!';
