-- ===================================================================================
-- MIGRATION: KHỞI TẠO BẢNG QUY TẮC SIÊU DỮ LIỆU TƯƠNG QUAN & ĐIỂM VÊNH (ZERO HARDCODE)
-- Database: eSignature
-- ===================================================================================

SET NOCOUNT ON;

-- 1. BẢNG tblKPI_CorrelationRules
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tblKPI_CorrelationRules')
BEGIN
    CREATE TABLE tblKPI_CorrelationRules (
        RuleID              INT IDENTITY(1,1) PRIMARY KEY,
        RuleCode            VARCHAR(50) NOT NULL UNIQUE,
        Category            VARCHAR(30) NOT NULL, -- 'PARADOX', 'CAUSAL', 'MISMATCH', 'BOTTLENECK'
        TitleTemplate       NVARCHAR(200) NOT NULL,
        CauseKpiCode        VARCHAR(20) NOT NULL,
        EffectKpiCode       VARCHAR(20) NULL,
        TriggerCondition    NVARCHAR(500) NOT NULL,
        PrimarySourceTpl    NVARCHAR(300) NOT NULL,
        PrimaryValueTpl     NVARCHAR(100) NOT NULL,
        SecondarySourceTpl  NVARCHAR(300) NOT NULL,
        SecondaryValueTpl   NVARCHAR(100) NOT NULL,
        VarianceTemplate    NVARCHAR(1000) NOT NULL,
        ActionOwner         NVARCHAR(150) NOT NULL,
        Severity            VARCHAR(20) DEFAULT 'WARN', -- 'INFO', 'WARN', 'CRITICAL'
        SortOrder           INT DEFAULT 1,
        IsActive            BIT DEFAULT 1,
        CreatedAt           DATETIME DEFAULT GETDATE()
    );
    PRINT 'Đã tạo bảng tblKPI_CorrelationRules.';
END
ELSE
BEGIN
    PRINT 'Bảng tblKPI_CorrelationRules đã tồn tại.';
END

-- 2. NẠP TẬP QUY TẮC CHUẨN (A kéo B, A đối nghịch B, Vênh đối soát, Điểm nghẽn)
DELETE FROM tblKPI_CorrelationRules WHERE RuleID > 0;

INSERT INTO tblKPI_CorrelationRules 
(RuleCode, Category, TitleTemplate, CauseKpiCode, EffectKpiCode, TriggerCondition, PrimarySourceTpl, PrimaryValueTpl, SecondarySourceTpl, SecondaryValueTpl, VarianceTemplate, ActionOwner, Severity, SortOrder, IsActive)
VALUES
(
    'RULE_MISMATCH_MNLK_ENROLLMENT',
    'MISMATCH',
    N'Chênh lệch Sĩ số & Rút học MN Long Khánh',
    'TS01',
    'TS04',
    'DonViID IN (''ALL'', ''MNLK'') AND TS04.Rate > 50.0',
    N'Báo cáo vận hành: Sĩ số {TS01.Actual}/{TS01.Capacity} HS ({TS01.OccupancyPct}%) · Rút học {TS04.Rate}%',
    N'{TS01.Actual} HS ({TS04.Rate}% rút)',
    N'Báo cáo trường MNLK: Công suất phòng học khác chuẩn · Tái ghi danh {RE_ENROLL_RATE}%',
    N'122 HS (94.6% tái ghi danh)',
    N'Tỷ lệ rút học {TS04.Rate}% mâu thuẫn trực tiếp với tỷ lệ tái ghi danh 94.6% của MN Long Khánh. Cần thống nhất lại công thức tính mẫu số công suất (166 hay 182 phòng) giữa báo cáo vận hành và báo cáo thực tế.',
    N'Hiệu Trưởng MN Long Khánh & Khối Vận Hành',
    'CRITICAL',
    1,
    1
),
(
    'RULE_PARADOX_QA_WITHDRAW',
    'PARADOX',
    N'Nghịch lý Khảo sát Hài lòng cao nhưng Rút học thật',
    'DV50',
    'TS04',
    'DV50.Actual >= 90.0 AND TS04.Actual >= 20',
    N'Khảo sát Đảm bảo chất lượng QA: {DV50.Actual}% Phụ huynh hài lòng mức Đạt trở lên',
    N'{DV50.Actual}% Hài lòng',
    N'Dữ liệu SIS chốt sổ: Lũy kế có {TS04.Actual} học sinh rút hồ sơ ({TS04.Reason.FAR} ca tiện đón, {TS04.Reason.ECO} ca kinh tế)',
    N'{TS04.Actual} HS rút ({TS04.Rate}%)',
    N'Khảo sát sự hài lòng rất cao ({DV50.Actual}%) nhưng có {TS04.Actual} học sinh rút hồ sơ thực tế. Cỡ mẫu khảo sát {QA.SampleSize} PH có thể chưa đại diện đúng tuyến xe và khối lớp có HS rút học (nguy cơ sai lệch mẫu khảo sát).',
    N'Bộ Phận QA & Ban Giám Hiệu',
    'CRITICAL',
    2,
    1
),
(
    'RULE_BOTTLENECK_AC_MAINT',
    'BOTTLENECK',
    N'Tồn đọng sửa chữa CSVC & Hiệu quả xe đưa rước',
    'CSVC01',
    'BUS01',
    'MAINT.AcPending > 0 OR MAINT.AcTotal >= 15',
    N'Yêu cầu CSVC: Tiếp nhận {MAINT.TotalTickets} yêu cầu, còn {MAINT.AcPending} ticket điều hòa/máy chiếu tồn đọng',
    N'{MAINT.AcPending} ticket tồn',
    N'Hiệu quả xe bus: Biên LN đạt {BUS.Margin}% (định mức 15%), tỷ lệ lấp đầy ghế {BUS.Occupancy}%',
    N'Biên LN {BUS.Margin}%',
    N'{MAINT.AcRepairs} máy lạnh hỏng tập trung tại Khu B và C làm phụ huynh phàn nàn và ảnh hưởng gián tiếp tỷ lệ rút học vì tiện ích lớp học. Đề xuất hoàn tất dứt điểm bảo dưỡng trước ngày 05 hàng tháng.',
    N'Ban Quản Trị CSVC & Tổ Xe Bus',
    'WARN',
    3,
    1
),
(
    'RULE_MISMATCH_SOFTWARE_IT',
    'MISMATCH',
    N'Vênh trạng thái triển khai Phần mềm CNTT',
    'IT01',
    'CRM01',
    'IT.StagingCount > 0',
    N'Báo cáo Vận hành: Ghi nhận CRM và Phân hệ Thu phí đã đưa vào sử dụng',
    N'Hoàn thành',
    N'Báo cáo CNTT: Xếp trong danh mục chờ nghiệm thu chuyển tiếp; TVTS vẫn theo dõi song song Excel Sheet 8',
    N'Chờ duyệt (Excel Staging)',
    N'Phân hệ Ngân sách và CRM đang chạy song song trên Excel Sheet 8 TVTS Tracking. Cần ban hành quyết định nghiệm thu chính thức và ngừng cập nhật file Excel trung gian.',
    N'Bộ Phận CNTT & Phòng Tuyển Sinh',
    'WARN',
    4,
    1
),
(
    'RULE_MISMATCH_LABOR_DISCIPLINE',
    'MISMATCH',
    N'Mâu thuẫn số liệu Kỷ luật lao động & Thôi việc',
    'HR01',
    'HR02',
    'HR.IncidentDiff != 0',
    N'Báo cáo chi tiết định kỳ: Ghi nhận 0 trường hợp kỷ luật lao động trong toàn trường',
    N'0 kỷ luật',
    N'Báo cáo điều hành: Ghi nhận 1 trường hợp tại MNLK và 1 nhân viên CSVC thôi việc do mâu thuẫn nội bộ',
    N'2 trường hợp',
    N'Cần đối soát danh sách quyết định kỷ luật chính thức của Phòng Tổ chức Nhân sự để đồng bộ với báo cáo giám sát của Hội đồng trường.',
    N'Phòng Tổ Chức - Nhân Sự',
    'INFO',
    5,
    1
),
(
    'RULE_PARADOX_LMS_QUALITY',
    'PARADOX',
    N'Bẫy Đầu Ra: Hoàn thành giáo án LMS nhưng chất lượng dự giờ hụt',
    'CM08',
    'CM10',
    'CM08.Actual >= 95.0 AND CM10.Actual < 80.0',
    N'Tiến độ giáo án số: Tỷ lệ hoàn thành học liệu số đạt {CM08.Actual}%',
    N'{CM08.Actual}% Số hóa',
    N'Chất lượng chuyên môn: Tỷ lệ giờ dạy đạt chuẩn qua dự giờ chỉ đạt {CM10.Actual}%',
    N'{CM10.Actual}% Đạt chuẩn',
    N'Hoạt động giảng dạy có dấu hiệu chạy theo tiến độ hình thức số hóa học liệu nhưng chất lượng sư phạm thực dạy chưa tương xứng. Kích hoạt dự giờ đột xuất.',
    N'Ban Chuyên Môn & Tổ Bộ Môn',
    'WARN',
    6,
    1
),
(
    'RULE_CAUSAL_BUS_WITHDRAW',
    'CAUSAL',
    N'Mắt xích Causal: Hạ tầng xe bus chưa phủ xa dẫn đến rút hồ sơ',
    'BUS01',
    'TS04',
    'TS04.Reason.FAR >= 10',
    N'Phạm vi xe đưa đón: Tuyến xe chưa bao phủ trục Long Khánh và Biên Hòa Đông',
    N'Thiếu 2 tuyến trục',
    N'Thiệt hại sĩ số: Ghi nhận {TS04.Reason.FAR} học sinh rút học vì lý do nơi ở xa / đưa đón bất tiện',
    N'{TS04.Reason.FAR} HS rút xa nhà',
    N'Mỗi học sinh rút học làm mất dòng tiền học phí trung bình 65 triệu VNĐ/năm. Tổng thiệt hại ước tính {WITHDRAW_FINANCIAL_LOSS} tỷ VNĐ. Đề xuất mở thêm 2 tuyến xe bus.',
    N'Tổ Quản Trị Xe Bus & Phòng TVTS',
    'CRITICAL',
    7,
    1
);

PRINT 'Đã nạp 7 quy tắc chuẩn vào tblKPI_CorrelationRules.';
