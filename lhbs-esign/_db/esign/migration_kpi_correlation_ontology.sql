-- ===================================================================================
-- MIGRATION: KHỞI TẠO BẢNG TỔNG QUÁT MÔ HÌNH TƯƠNG QUAN NGỮ NGHĨA (CORRELATION ONTOLOGY)
-- Zero Hardcode: Không lưu chuỗi tĩnh, không gắn cứng tên cơ sở hay kỳ báo cáo
-- Database: eSignature
-- ===================================================================================

SET NOCOUNT ON;

-- 1. BẢNG tblKPI_CorrelationOntology
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tblKPI_CorrelationOntology')
BEGIN
    CREATE TABLE tblKPI_CorrelationOntology (
        RelationID          INT IDENTITY(1,1) PRIMARY KEY,
        RelationCode        VARCHAR(50) NOT NULL UNIQUE,
        RelationType        VARCHAR(30) NOT NULL, -- 'PARADOX', 'CAUSAL', 'BOTTLENECK', 'BALANCE'
        SourceKpiCode       VARCHAR(20) NOT NULL, -- KPI 1 / Nguyên nhân
        TargetKpiCode       VARCHAR(20) NOT NULL, -- KPI 2 / Hệ quả / Đối chiếu
        ExpectedPolarity    VARCHAR(20) NOT NULL, -- 'SAME' (Đồng biến), 'OPPOSITE' (Nghịch biến)
        ElasticityRatio     DECIMAL(10,4) DEFAULT 1.0, -- Hệ số co giãn tác động
        FinancialKpiCode    VARCHAR(20) NULL DEFAULT 'TC55',
        UnitFinancialImpact DECIMAL(18,2) DEFAULT 0, -- Giá trị tài chính quy đổi trên 1 đơn vị lệch (VNĐ)
        ActionRoleOwner     NVARCHAR(150) NOT NULL, -- Vai trò đầu mối chịu trách nhiệm
        SeverityLevel       VARCHAR(20) DEFAULT 'WARN', -- 'CRITICAL', 'WARN', 'INFO'
        SortOrder           INT DEFAULT 1,
        IsActive            BIT DEFAULT 1,
        CreatedAt           DATETIME DEFAULT GETDATE()
    );
    PRINT 'Đã tạo bảng tblKPI_CorrelationOntology.';
END
ELSE
BEGIN
    PRINT 'Bảng tblKPI_CorrelationOntology đã tồn tại.';
END

-- 2. NẠP CÁC QUAN HỆ TOÁN HỌC & NGỮ NGHĨA CHUẨN (KHÔNG CHỨA DỮ LIỆU CỨNG CỦA CƠ SỞ HAY THÁNG CỤ THỂ)
DELETE FROM tblKPI_CorrelationOntology WHERE RelationID > 0;

INSERT INTO tblKPI_CorrelationOntology
(RelationCode, RelationType, SourceKpiCode, TargetKpiCode, ExpectedPolarity, ElasticityRatio, FinancialKpiCode, UnitFinancialImpact, ActionRoleOwner, SeverityLevel, SortOrder, IsActive)
VALUES
(
    'REL_PARADOX_QA_WITHDRAW',
    'PARADOX',
    'QA50', -- Hài lòng chung PHHS (càng cao càng tốt)
    'TS04', -- Tỷ lệ rút học (càng thấp càng tốt)
    'OPPOSITE',
    1.0,
    'TC55',
    65000000.0, -- 65 tr/HS/năm
    N'Bộ Phận QA & Ban Giám Hiệu',
    'CRITICAL',
    1,
    1
),
(
    'REL_BALANCE_ROLL_EQUATION',
    'BALANCE',
    'TS01', -- Sĩ số hiện diện
    'TS04', -- Rút học / chuyển đi
    'SAME',
    1.0,
    'TC55',
    65000000.0,
    N'Hiệu Trưởng Cơ Sở & Khối Vận Hành',
    'CRITICAL',
    2,
    1
),
(
    'REL_BOTTLENECK_CSVC_MAINT',
    'BOTTLENECK',
    'CSVC01', -- Hỏng hóc sửa chữa CSVC
    'TC56',   -- Biên LN dịch vụ / Hiệu quả vận hành
    'OPPOSITE',
    0.25,
    'TC56',
    15000000.0,
    N'Ban Quản Trị CSVC & Tổ Xe Bus',
    'WARN',
    3,
    1
),
(
    'REL_CAUSAL_BUS_WITHDRAW',
    'CAUSAL',
    'TS04', -- Rút học vì khoảng cách
    'TC55', -- Thất thu doanh thu học phí
    'OPPOSITE',
    1.0,
    'TC55',
    65000000.0,
    N'Tổ Quản Trị Xe Bus & Phòng TVTS',
    'CRITICAL',
    4,
    1
),
(
    'REL_MISMATCH_SYSTEM_INTEGRATION',
    'BALANCE',
    'TS05', -- Leads TVTS
    'TS06', -- Tỷ lệ chuyển đổi
    'SAME',
    1.0,
    'TC55',
    3500000.0,
    N'Bộ Phận CNTT & Phòng Tuyển Sinh',
    'WARN',
    5,
    1
),
(
    'REL_MISMATCH_HR_INCIDENTS',
    'BALANCE',
    'HR01', -- Biến động nhân sự
    'HR01',
    'SAME',
    1.0,
    NULL,
    0,
    N'Phòng Tổ Chức - Nhân Sự',
    'INFO',
    6,
    1
),
(
    'REL_PARADOX_LMS_QUALITY',
    'PARADOX',
    'CM08', -- Tiến độ hoàn thành giáo án số LMS
    'CM04', -- Học liệu số hóa thực chất / dự giờ
    'SAME',
    1.0,
    NULL,
    0,
    N'Ban Chuyên Môn & Tổ Bộ Môn',
    'WARN',
    7,
    1
);

PRINT 'Đã nạp 7 quan hệ logic vào tblKPI_CorrelationOntology.';
