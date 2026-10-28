-- ========================================================
-- MIGRATION: DYNAMIC KPI & CAUSAL ENGINE (LHBS)
-- Tạo bảng Ngưỡng (tblKPI_Thresholds), Tham số (tblKPI_Parameters)
-- và chuẩn hóa bảng tblKPI_CausalNarratives theo chuẩn Biểu thức
-- ========================================================

-- 1. BẢNG NGƯỠNG ĐỘNG ĐA TẦNG: tblKPI_Thresholds
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'tblKPI_Thresholds')
BEGIN
    CREATE TABLE tblKPI_Thresholds (
        ThresholdID INT IDENTITY(1,1) PRIMARY KEY,
        KpiCode VARCHAR(50) NOT NULL,
        ScopeType VARCHAR(20) NOT NULL DEFAULT 'SYSTEM', -- SYSTEM, CAMPUS, LEVEL
        ScopeID VARCHAR(20) NOT NULL DEFAULT 'ALL',      -- ALL, MNTB, MNLK, TH, THCS, THPT
        PeriodKey VARCHAR(20) NOT NULL DEFAULT 'ALL',    -- ALL hoặc kỳ cụ thể như '2026-09'
        TargetValue FLOAT NOT NULL,                      -- Mục tiêu thiết kế / chuẩn
        WarnThreshold FLOAT NOT NULL,                    -- Ngưỡng bắt đầu cảnh báo
        CriticalThreshold FLOAT NULL,                    -- Ngưỡng nguy hiểm / giải trình
        ComparisonOperator VARCHAR(10) NOT NULL DEFAULT '>=', -- >=, <=, >, <, BETWEEN
        StatusGoodLabel NVARCHAR(50) NOT NULL DEFAULT N'AN TOÀN',
        StatusWarnLabel NVARCHAR(50) NOT NULL DEFAULT N'THEO DÕI',
        StatusBadLabel NVARCHAR(50) NOT NULL DEFAULT N'CẢNH BÁO',
        Description NVARCHAR(250) NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UpdatedAt DATETIME DEFAULT GETDATE()
    );

    CREATE INDEX IX_tblKPI_Thresholds_Lookup ON tblKPI_Thresholds (KpiCode, ScopeID, PeriodKey);
END;

-- SEED DỮ LIỆU NGƯỠNG BAN ĐẦU
IF NOT EXISTS (SELECT 1 FROM tblKPI_Thresholds WHERE KpiCode = 'TS04')
BEGIN
    INSERT INTO tblKPI_Thresholds (KpiCode, ScopeType, ScopeID, PeriodKey, TargetValue, WarnThreshold, CriticalThreshold, ComparisonOperator, StatusGoodLabel, StatusBadLabel, Description)
    VALUES 
    -- TS04: Tỷ lệ rút học (càng nhỏ càng tốt, ngưỡng năm < 10%, nhịp tháng 3 là 3.0%)
    ('TS04', 'SYSTEM', 'ALL', 'ALL', 10.0, 3.0, 10.0, '<=', N'AN TOÀN', N'CẢNH BÁO', N'Ngưỡng rút học toàn trường (< 10%/năm, nhịp hiện tại <= 3.0%)'),
    ('TS04', 'CAMPUS', 'MNLK', 'ALL', 10.0, 3.0, 10.0, '<=', N'AN TOÀN', N'CẢNH BÁO', N'Ngưỡng rút học Mầm non Long Khánh'),
    ('TS04', 'CAMPUS', 'MNTB', 'ALL', 10.0, 3.0, 10.0, '<=', N'AN TOÀN', N'CẢNH BÁO', N'Ngưỡng rút học Mầm non Trấn Biên'),
    ('TS04', 'CAMPUS', 'TH', 'ALL', 10.0, 3.0, 10.0, '<=', N'AN TOÀN', N'CẢNH BÁO', N'Ngưỡng rút học Tiểu học'),
    ('TS04', 'CAMPUS', 'THCS', 'ALL', 10.0, 3.0, 10.0, '<=', N'AN TOÀN', N'CẢNH BÁO', N'Ngưỡng rút học THCS'),
    ('TS04', 'CAMPUS', 'THPT', 'ALL', 10.0, 3.0, 10.0, '<=', N'AN TOÀN', N'CẢNH BÁO', N'Ngưỡng rút học THPT'),

    -- TS01: Tỷ lệ lấp đầy sĩ số / chỉ tiêu (càng cao càng tốt, chuẩn >= 95%, cảnh báo < 90%)
    ('TS01', 'SYSTEM', 'ALL', 'ALL', 100.0, 95.0, 90.0, '>=', N'ĐẠT CHỈ TIÊU', N'CHƯA ĐẠT', N'Tỷ lệ lấp đầy sĩ số toàn trường'),
    ('TS01', 'CAMPUS', 'MNLK', 'ALL', 100.0, 90.0, 80.0, '>=', N'ĐẠT CHỈ TIÊU', N'CẦN GIẢI TRÌNH', N'Tỷ lệ lấp đầy sĩ số MN Long Khánh'),

    -- TS06: Chuyển đổi tuyển sinh TVTS (chuẩn >= 30%, cảnh báo < 20%)
    ('TS06', 'SYSTEM', 'ALL', 'ALL', 30.0, 20.0, 10.0, '>=', N'ĐẠT ĐÍCH', N'THẤP', N'Tỷ lệ chuyển đổi TVTS Leads sang Nhập học'),

    -- CM08: Hoàn thành bài tập LMS (chuẩn >= 80%)
    ('CM08', 'SYSTEM', 'ALL', 'ALL', 80.0, 75.0, 60.0, '>=', N'TỐT', N'CẦN BỔ DƯỠNG', N'Tỷ lệ học sinh hoàn thành bài tập LMS'),

    -- TC55: Biên lợi nhuận gộp dịch vụ trường học (chuẩn >= 50%)
    ('TC55', 'SYSTEM', 'ALL', 'ALL', 50.0, 48.0, 40.0, '>=', N'ĐẠT CHỈ TIÊU', N'DƯỚI CHỈ TIÊU', N'Tỷ suất lợi nhuận gộp dịch vụ học đường');
END;

-- 2. BẢNG THAM SỐ NGHIỆP VỤ & TÍNH TOÁN LINH HOẠT: tblKPI_Parameters
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'tblKPI_Parameters')
BEGIN
    CREATE TABLE tblKPI_Parameters (
        ParamID INT IDENTITY(1,1) PRIMARY KEY,
        ParamCode VARCHAR(50) NOT NULL,
        ScopeType VARCHAR(20) NOT NULL DEFAULT 'SYSTEM',
        ScopeID VARCHAR(20) NOT NULL DEFAULT 'ALL',
        PeriodKey VARCHAR(20) NOT NULL DEFAULT 'ALL',
        ParamValue FLOAT NOT NULL,
        ParamStringValue NVARCHAR(250) NULL,
        Description NVARCHAR(250) NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UpdatedAt DATETIME DEFAULT GETDATE()
    );

    CREATE INDEX IX_tblKPI_Parameters_Lookup ON tblKPI_Parameters (ParamCode, ScopeID, PeriodKey);
END;

-- SEED DỮ LIỆU THAM SỐ BAN ĐẦU
IF NOT EXISTS (SELECT 1 FROM tblKPI_Parameters WHERE ParamCode = 'TuitionAnnual')
BEGIN
    INSERT INTO tblKPI_Parameters (ParamCode, ScopeType, ScopeID, PeriodKey, ParamValue, ParamStringValue, Description)
    VALUES
    -- Học phí niêm yết hàng năm (triệu VNĐ)
    ('TuitionAnnual', 'CAMPUS', 'ALL', 'ALL', 49.8, N'49.8 tr', N'Học phí bình quân toàn hệ thống'),
    ('TuitionAnnual', 'CAMPUS', 'MNTB', 'ALL', 37.2, N'37.2 tr', N'Học phí Mầm non Trấn Biên'),
    ('TuitionAnnual', 'CAMPUS', 'MNLK', 'ALL', 37.2, N'37.2 tr', N'Học phí Mầm non Long Khánh'),
    ('TuitionAnnual', 'CAMPUS', 'TH', 'ALL', 49.6, N'49.6 tr', N'Học phí Tiểu học'),
    ('TuitionAnnual', 'CAMPUS', 'THCS', 'ALL', 61.7, N'61.7 tr', N'Học phí THCS'),
    ('TuitionAnnual', 'CAMPUS', 'THPT', 'ALL', 63.6, N'63.6 tr', N'Học phí THPT'),

    -- Đơn giá dịch vụ xe bus bình quân năm (triệu VNĐ/HS)
    ('BusFeeAnnual', 'SYSTEM', 'ALL', 'ALL', 12.0, N'12 tr', N'Phí xe bus học sinh bình quân hàng năm'),
    
    -- Chi phí tuyển sinh bình quân (CAC) (triệu VNĐ/HS)
    ('CAC_PerStudent', 'SYSTEM', 'ALL', 'ALL', 3.3, N'3.3 tr', N'Chi phí tiếp thị và tư vấn bình quân tuyển 1 HS'),

    -- Biên lợi nhuận góp dịch vụ
    ('GrossMarginContribution', 'SYSTEM', 'ALL', 'ALL', 0.85, N'85%', N'Biên lợi nhuận góp khi duy trì sĩ số lớp hiện hữu');
END;

-- 3. NÂNG CẤP BẢNG tblKPI_CausalNarratives (THÊM AnchorKpiCode NẾU CHƯA CÓ)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'tblKPI_CausalNarratives' AND COLUMN_NAME = 'AnchorKpiCode')
BEGIN
    ALTER TABLE tblKPI_CausalNarratives ADD AnchorKpiCode VARCHAR(50) NULL;
END;

-- CHUẨN HÓA MẪU CÂU BIỂU THỨC TRONG tblKPI_CausalNarratives
UPDATE tblKPI_CausalNarratives
SET 
    AnchorKpiCode = 'TS06',
    TemplatePattern = N'Tỷ lệ chuyển đổi đạt {TS06.Actual}%. Mỗi +1% chuyển đổi giúp tuyển thêm {TS05.Actual * 0.01 | round(0)} HS, tạo thêm {TS05.Actual * 0.01 * PARAM.TuitionAnnual | currency} doanh thu học phí/năm.',
    ActionPattern = N'Phân tích tác động tuyển thêm ›'
WHERE NarrativeCode = 'NARRATIVE_ENROLLMENT_CONV';

UPDATE tblKPI_CausalNarratives
SET 
    AnchorKpiCode = 'TS04',
    TemplatePattern = N'{TS04.Reason.FAR} HS ({TS04.Reason.FAR / TS04.Actual * 100 | round(1)}%) rút vì xa trường/xe bus → Thất thu {TS04.Reason.FAR * PARAM.TuitionAnnual | currency} học phí + {TS04.Reason.FAR * PARAM.BusFeeAnnual | currency} xe bus/năm.',
    ActionPattern = N'Mở Dialog Vùng Tác Động Rút Học ›'
WHERE NarrativeCode = 'NARRATIVE_WITHDRAW_BUS';

UPDATE tblKPI_CausalNarratives
SET 
    AnchorKpiCode = 'CM08',
    TemplatePattern = N'{CM04.Actual}% học liệu số hoàn thiện thúc đẩy {CM08.Actual}% học sinh làm bài đúng hạn → Phát hiện sớm học lực yếu, bảo toàn sĩ số không phát sinh rút học vì học thuật.',
    ActionPattern = N'Xem ma trận chất lượng giáo dục ›'
WHERE NarrativeCode = 'NARRATIVE_LMS_QUALITY';

UPDATE tblKPI_CausalNarratives
SET 
    AnchorKpiCode = 'TC55',
    TemplatePattern = N'CLB đạt {TC56.Actual | currency} ({PARAM.ClbStudents | default(596)} HS), LN gộp dịch vụ {TC55.Actual}% tạo quỹ giải ngân 100% bảo trì CSVC/Điều hòa mà không tăng học phí.',
    ActionPattern = N'Xem ma trận tái đầu tư tài chính ›'
WHERE NarrativeCode = 'NARRATIVE_FINANCE_REINVEST';

-- KỊCH BẢN WHAT-IF: XE BUS
IF NOT EXISTS (SELECT 1 FROM tblKPI_CausalNarratives WHERE NarrativeCode = 'NARRATIVE_BUS_EXPANSION')
BEGIN
    INSERT INTO tblKPI_CausalNarratives (NarrativeCode, NarrativeGroup, AnchorKpiCode, Title, ConditionExpr, TemplatePattern, ActionPattern, SortOrder, IsActive)
    VALUES (
        'NARRATIVE_BUS_EXPANSION', N'Vận hành & Tuyến Xe', 'TS04',
        N'🔗 Kịch bản: Mở rộng tuyến xe bus giải tỏa áp lực rút học',
        'TS04.Reason.FAR > 5',
        N'Mở {SCENARIO.BusRoutes | default(2)} tuyến xe bus mới đưa đón {SCENARIO.BusStudents | default(40)} học sinh tại trục {SCENARIO.BusAxis | default("Trảng Dài - Hố Nai")}, giúp triệt tiêu {TS04.Reason.FAR / TS04.Actual * 100 | round(1)}% lý do rút học xa nhà, bảo toàn khoảng {SCENARIO.BusStudents * PARAM.TuitionAnnual | currency} học phí và tạo thêm {SCENARIO.BusStudents * PARAM.BusFeeAnnual | currency} doanh thu xe bus mỗi năm. Đầu mối: Tổ Xe Bus & Bán Trú.',
        N'Phê duyệt mở tuyến xe bus mới ›', 5, 1
    );
END
ELSE
BEGIN
    UPDATE tblKPI_CausalNarratives
    SET 
        AnchorKpiCode = 'TS04',
        TemplatePattern = N'Mở {SCENARIO.BusRoutes | default(2)} tuyến xe bus mới đưa đón {SCENARIO.BusStudents | default(40)} học sinh tại trục {SCENARIO.BusAxis | default("Trảng Dài - Hố Nai")}, giúp triệt tiêu {TS04.Reason.FAR / TS04.Actual * 100 | round(1)}% lý do rút học xa nhà, bảo toàn khoảng {SCENARIO.BusStudents * PARAM.TuitionAnnual | currency} học phí và tạo thêm {SCENARIO.BusStudents * PARAM.BusFeeAnnual | currency} doanh thu xe bus mỗi năm. Đầu mối: Tổ Xe Bus & Bán Trú.'
    WHERE NarrativeCode = 'NARRATIVE_BUS_EXPANSION';
END;
