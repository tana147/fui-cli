-- =========================================================================
-- MIGRATION: BỔ SUNG 5 ĐIỂM NGHIỆP VỤ CỐT LÕI CHO HỆ THỐNG KPI & CHUỖI NHÂN QUẢ
-- DB: eSignature (esign)
-- 1. ApplicableScopes & ValueFormat trong tblKPI_Definitions
-- 2. Chuẩn hóa Target TS06=30% và cân đối Sĩ số - Công suất LHBS
-- 3. ScenarioType & VerificationPrompt trong tblKPI_CausalNarratives / Scenarios
-- 4. Định dạng BOOLEAN_MILESTONE cho các chỉ tiêu ISO / Quy trình
-- 5. Kịch bản Nghịch lý dữ liệu (Paradox) & Kiểm toán cân đối (Audit)
-- =========================================================================

-- 1. Bổ sung cột vào tblKPI_Definitions
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblKPI_Definitions') AND name = 'ApplicableScopes')
BEGIN
    ALTER TABLE tblKPI_Definitions ADD ApplicableScopes VARCHAR(100) NOT NULL CONSTRAINT DF_tblKPI_Definitions_Scopes DEFAULT 'ALL';
END;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblKPI_Definitions') AND name = 'ValueFormat')
BEGIN
    ALTER TABLE tblKPI_Definitions ADD ValueFormat VARCHAR(20) NOT NULL CONSTRAINT DF_tblKPI_Definitions_Format DEFAULT 'NUMBER';
END;

-- 2. Bổ sung cột vào tblKPI_CausalNarratives
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblKPI_CausalNarratives') AND name = 'ScenarioType')
BEGIN
    ALTER TABLE tblKPI_CausalNarratives ADD ScenarioType VARCHAR(30) NOT NULL CONSTRAINT DF_tblKPI_Narratives_Type DEFAULT 'CAUSAL_IMPACT';
END;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblKPI_CausalNarratives') AND name = 'VerificationPrompt')
BEGIN
    ALTER TABLE tblKPI_CausalNarratives ADD VerificationPrompt NVARCHAR(500) NULL;
END;

-- 3. Bổ sung cột vào tblKPI_CausalScenarios
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblKPI_CausalScenarios') AND name = 'ScenarioType')
BEGIN
    ALTER TABLE tblKPI_CausalScenarios ADD ScenarioType VARCHAR(30) NOT NULL CONSTRAINT DF_tblKPI_Scenarios_Type DEFAULT 'CAUSAL_IMPACT';
END;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblKPI_CausalScenarios') AND name = 'VerificationPrompt')
BEGIN
    ALTER TABLE tblKPI_CausalScenarios ADD VerificationPrompt NVARCHAR(500) NULL;
END;
-- =========================================================================
-- MIGRATION PHẦN 2: CẬP NHẬT DỮ LIỆU & CHUẨN HÓA 5 ĐIỂM NGHIỆP VỤ LHBS
-- =========================================================================

-- 1. Cập nhật ApplicableScopes trong tblKPI_Definitions
UPDATE tblKPI_Definitions SET ApplicableScopes = 'ALL' WHERE ApplicableScopes IS NULL OR ApplicableScopes = '';
UPDATE tblKPI_Definitions SET ApplicableScopes = 'THCS,THPT' WHERE KpiCode = 'CM14';
UPDATE tblKPI_Definitions SET ApplicableScopes = 'MNTB,MNLK' WHERE KpiCode = 'CM18';
UPDATE tblKPI_Definitions SET ApplicableScopes = 'THPT' WHERE KpiCode IN ('CM20', 'CM21');

-- Cập nhật ValueFormat trong tblKPI_Definitions
UPDATE tblKPI_Definitions SET ValueFormat = 'PERCENT' WHERE Unit = '%';
UPDATE tblKPI_Definitions SET ValueFormat = 'CURRENCY' WHERE Unit LIKE N'%triệu%' OR Unit LIKE N'%VNĐ%';
UPDATE tblKPI_Definitions SET ValueFormat = 'BOOLEAN_MILESTONE', Unit = N'Đạt chuẩn' WHERE KpiCode IN ('CM26', 'DV30', 'DV32', 'DV44', 'TC57');

-- 2. Chuẩn hóa Target TS06 (Tỷ lệ chuyển đổi Funnel) = 30% toàn hệ thống
UPDATE tblKPI_Definitions
SET DefaultTarget = 30.0, DefaultWarn = 20.0, DefaultCritical = 10.0, DefaultOperator = '>='
WHERE KpiCode = 'TS06';

UPDATE tblKPI_Thresholds
SET TargetValue = 30.0, WarnThreshold = 20.0, CriticalThreshold = 10.0, ComparisonOperator = '>=',
    StatusGoodLabel = N'Đạt mục tiêu (>=30%)',
    StatusWarnLabel = N'Cảnh báo hụt Funnel (20-30%)',
    StatusBadLabel = N'Nguy hiểm hụt tuyển sinh (<10%)'
WHERE KpiCode = 'TS06';

-- Cân đối Sĩ số - Công suất trong tblKPI_Thresholds
UPDATE tblKPI_Thresholds SET TargetValue = 2873, WarnThreshold = 2700, CriticalThreshold = 2500 WHERE KpiCode = 'TS01' AND ScopeID = 'ALL';
UPDATE tblKPI_Thresholds SET TargetValue = 210, WarnThreshold = 180, CriticalThreshold = 150 WHERE KpiCode = 'TS01' AND ScopeID = 'MNLK';
UPDATE tblKPI_Thresholds SET TargetValue = 360, WarnThreshold = 320, CriticalThreshold = 300 WHERE KpiCode = 'TS01' AND ScopeID = 'MNTB';
UPDATE tblKPI_Thresholds SET TargetValue = 1020, WarnThreshold = 950, CriticalThreshold = 900 WHERE KpiCode = 'TS01' AND ScopeID = 'TH';
UPDATE tblKPI_Thresholds SET TargetValue = 720, WarnThreshold = 680, CriticalThreshold = 630 WHERE KpiCode = 'TS01' AND ScopeID = 'THCS';
UPDATE tblKPI_Thresholds SET TargetValue = 563, WarnThreshold = 520, CriticalThreshold = 480 WHERE KpiCode = 'TS01' AND ScopeID = 'THPT';

-- Cập nhật Công suất thiết kế và Sĩ số kế hoạch trong tblKPI_Parameters
MERGE tblKPI_Parameters AS target
USING (
    VALUES 
        ('PlannedCapacity', 'CAMPUS', 'MNTB', 'ALL', 400.0, N'400', N'Công suất phòng học MN Trấn Biên'),
        ('PlannedCapacity', 'CAMPUS', 'MNLK', 'ALL', 250.0, N'250', N'Công suất phòng học MN Long Khánh'),
        ('PlannedCapacity', 'CAMPUS', 'TH',   'ALL', 1150.0, N'1150', N'Công suất phòng học Tiểu học (Thiết kế chuẩn)'),
        ('PlannedCapacity', 'CAMPUS', 'THCS', 'ALL', 800.0, N'800', N'Công suất phòng học THCS'),
        ('PlannedCapacity', 'CAMPUS', 'THPT', 'ALL', 600.0, N'600', N'Công suất phòng học THPT'),
        ('PlannedCapacity', 'SYSTEM', 'ALL',  'ALL', 3200.0, N'3200', N'Tổng công suất toàn trường LHBS'),

        ('TargetEnrollment', 'CAMPUS', 'MNTB', 'ALL', 360.0, N'360', N'Chỉ tiêu sĩ số kế hoạch MN Trấn Biên'),
        ('TargetEnrollment', 'CAMPUS', 'MNLK', 'ALL', 210.0, N'210', N'Chỉ tiêu sĩ số kế hoạch MN Long Khánh'),
        ('TargetEnrollment', 'CAMPUS', 'TH',   'ALL', 1020.0, N'1020', N'Chỉ tiêu sĩ số kế hoạch Tiểu học'),
        ('TargetEnrollment', 'CAMPUS', 'THCS', 'ALL', 720.0, N'720', N'Chỉ tiêu sĩ số kế hoạch THCS'),
        ('TargetEnrollment', 'CAMPUS', 'THPT', 'ALL', 563.0, N'563', N'Chỉ tiêu sĩ số kế hoạch THPT'),
        ('TargetEnrollment', 'SYSTEM', 'ALL',  'ALL', 2873.0, N'2873', N'Tổng sĩ số kế hoạch toàn trường LHBS'),

        -- Biến phụ trợ kiểm toán dữ liệu (Audit & QA)
        ('QA_SampleSize',   'SYSTEM', 'ALL',  'ALL', 450.0, N'450', N'Cỡ mẫu khảo sát mức độ hài lòng PHHS toàn trường'),
        ('QA_SampleSize',   'CAMPUS', 'MNLK', 'ALL', 65.0,  N'65',  N'Cỡ mẫu khảo sát PHHS MN Long Khánh'),
        ('QA_SampleSize',   'CAMPUS', 'MNTB', 'ALL', 85.0,  N'85',  N'Cỡ mẫu khảo sát PHHS MN Trấn Biên'),
        ('QA_SampleSize',   'CAMPUS', 'TH',   'ALL', 160.0, N'160', N'Cỡ mẫu khảo sát PHHS Tiểu học'),
        ('QA_SampleSize',   'CAMPUS', 'THCS', 'ALL', 90.0,  N'90',  N'Cỡ mẫu khảo sát PHHS THCS'),
        ('QA_SampleSize',   'CAMPUS', 'THPT', 'ALL', 50.0,  N'50',  N'Cỡ mẫu khảo sát PHHS THPT')
) AS source (ParamCode, ScopeType, ScopeID, PeriodKey, ParamValue, ParamStringValue, Description)
ON (target.ParamCode = source.ParamCode AND target.ScopeID = source.ScopeID AND target.PeriodKey = source.PeriodKey)
WHEN MATCHED THEN
    UPDATE SET 
        ParamValue = source.ParamValue,
        ParamStringValue = source.ParamStringValue,
        Description = source.Description,
        UpdatedAt = GETDATE()
WHEN NOT MATCHED THEN
    INSERT (ParamCode, ScopeType, ScopeID, PeriodKey, ParamValue, ParamStringValue, Description, CreatedAt, UpdatedAt)
    VALUES (source.ParamCode, source.ScopeType, source.ScopeID, source.PeriodKey, source.ParamValue, source.ParamStringValue, source.Description, GETDATE(), GETDATE());

-- 3. Cập nhật VerificationPrompt và ScenarioType cho chuỗi nhân quả hiện có
UPDATE tblKPI_CausalNarratives
SET 
    ScenarioType = 'CAUSAL_IMPACT',
    VerificationPrompt = N'Đã đối soát danh sách HS rút học với lộ trình tuyến xe bus thực tế chưa? Xác nhận mức độ thất thu học phí và phí bus trước khi xuất bản lên Dashboard BĐH.'
WHERE NarrativeCode = 'NARRATIVE_WITHDRAW_BUS';

UPDATE tblKPI_CausalNarratives
SET 
    ScenarioType = 'CAUSAL_IMPACT',
    VerificationPrompt = N'Kiểm tra lại chất lượng đầu vào của Lead và tốc độ phản hồi tư vấn viên TVTS trước khi báo cáo hụt chuyển đổi Funnel.'
WHERE NarrativeCode = 'NARRATIVE_FUNNEL_CONV';

UPDATE tblKPI_CausalNarratives
SET 
    ScenarioType = 'OUTPUT_TRAP',
    VerificationPrompt = N'Đối chiếu % nộp bài LMS với điểm bài kiểm tra giữa kỳ thực tế của học sinh để loại trừ trường hợp nộp bài chống đối.'
WHERE NarrativeCode = 'NARRATIVE_LMS_ACADEMIC';

-- 4. Bổ sung Kịch bản Nghịch lý (DATA_PARADOX) và Kiểm toán (AUDIT_DISCREPANCY)
MERGE tblKPI_CausalNarratives AS target
USING (
    VALUES 
        (
            'NARRATIVE_PARADOX_SATISFACTION',
            N'Nghịch lý Dữ liệu',
            'DV50',
            N'Nghịch lý: Hài lòng PHHS cao nhưng tỷ lệ rút học tăng',
            'DV50.Actual >= 90 AND TS04.Actual > 3',
            N'Khảo sát chất lượng ghi nhận {DV50.Actual}% PHHS hài lòng (Cỡ mẫu {QA.SampleSize} PH), nhưng tỷ lệ rút học đạt mức {TS04.Actual}% ({TS04.Reason.FAR} HS xa trường) -> Nguy cơ sai lệch mẫu hoặc sự cố âm thầm chưa phản ánh qua khảo sát định kỳ.',
            N'Rà soát cỡ mẫu & Khảo sát nhóm rút học ›',
            'DATA_PARADOX',
            N'Cần kiểm tra xem cỡ mẫu khảo sát QA.SampleSize có đại diện đúng khối lớp/tuyến xe có HS rút học hay không trước khi công bố.',
            5
        ),
        (
            'NARRATIVE_AUDIT_ROLL_DISCREPANCY',
            N'Kiểm toán Dữ liệu',
            'TS01',
            N'Lệch kiểm toán cân đối sĩ số học sinh',
            'AUDIT.RollDiff != 0',
            N'Phát hiện độ lệch {AUDIT.RollDiff} học sinh giữa chốt sĩ số cuối kỳ ({TS01.Actual} HS) và công thức cân đối luân chuyển (Đầu kỳ + Nhập mới - Rút học) -> Cần kiểm toán lại trạng thái bảo lưu.',
            N'Kiểm toán hồ sơ luân chuyển học sinh ›',
            'AUDIT_DISCREPANCY',
            N'Đối chiếu danh sách chốt của Basic Data với hồ sơ tiếp nhận thực tế của ban Tuyển sinh và bộ phận Quản lý học viên.',
            6
        ),
        (
            'NARRATIVE_OUTPUT_TRAP_LMS',
            N'Bẫy Đầu Ra',
            'CM08',
            N'Bẫy Đầu Ra: Hoàn thành giáo án LMS nhưng chất lượng hụt',
            'CM08.Actual >= 95 AND CM10.Actual < 80',
            N'Tiến độ giáo dục đạt {CM08.Actual}%, nhưng tỷ lệ dự giờ đạt chuẩn chỉ đạt {CM10.Actual}% -> Hoạt động giảng dạy chạy theo tiến độ hình thức, chưa đảm bảo chiều sâu chất lượng.',
            N'Kiểm tra đột xuất chất lượng dự giờ ›',
            'OUTPUT_TRAP',
            N'Yêu cầu Tổ trưởng bộ môn cung cấp phiếu đánh giá dự giờ độc lập trước khi kết luận chất lượng giảng dạy.',
            7
        )
) AS source (NarrativeCode, NarrativeGroup, AnchorKpiCode, Title, ConditionExpr, TemplatePattern, ActionPattern, ScenarioType, VerificationPrompt, SortOrder)
ON (target.NarrativeCode = source.NarrativeCode)
WHEN MATCHED THEN
    UPDATE SET 
        NarrativeGroup = source.NarrativeGroup,
        AnchorKpiCode = source.AnchorKpiCode,
        Title = source.Title,
        ConditionExpr = source.ConditionExpr,
        TemplatePattern = source.TemplatePattern,
        ActionPattern = source.ActionPattern,
        ScenarioType = source.ScenarioType,
        VerificationPrompt = source.VerificationPrompt,
        SortOrder = source.SortOrder
WHEN NOT MATCHED THEN
    INSERT (NarrativeCode, NarrativeGroup, AnchorKpiCode, Title, ConditionExpr, TemplatePattern, ActionPattern, ScenarioType, VerificationPrompt, SortOrder, IsActive, CreatedAt)
    VALUES (source.NarrativeCode, source.NarrativeGroup, source.AnchorKpiCode, source.Title, source.ConditionExpr, source.TemplatePattern, source.ActionPattern, source.ScenarioType, source.VerificationPrompt, source.SortOrder, 1, GETDATE());
