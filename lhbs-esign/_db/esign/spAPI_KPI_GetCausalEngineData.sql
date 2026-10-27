-- ==============================================================================
-- STORED PROCEDURE: spAPI_KPI_GetCausalEngineData
-- Mô tả: Cung cấp toàn bộ dữ liệu cấu hình động cho Causal Engine (Vùng tác động)
-- Bổ sung đầy đủ kịch bản, lý do, quy tắc và ma trận phân công theo tài liệu kỹ thuật
-- DB: eSignature (esign)
-- ==============================================================================

CREATE OR ALTER PROCEDURE spAPI_KPI_GetCausalEngineData
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. SEED / UPSERT DANH MỤC KỊCH BẢN (tblKPI_CausalScenarios)
    IF NOT EXISTS (SELECT 1 FROM tblKPI_CausalScenarios WHERE ScenarioCode = 'MO_TUYEN_BUS')
    BEGIN
        INSERT INTO tblKPI_CausalScenarios (ScenarioCode, ScenarioName, ScenarioDescription, DefaultUnit, IsActive)
        VALUES 
        ('MO_TUYEN_BUS', N'Mở tuyến xe bus mới', N'Mở tuyến xe bus đưa đón khu vực Trảng Dài - Hố Nai giải quyết 25.7% lý do rút học xa trường', 'TH', 1),
        ('GIU_CHAN_CHUYEN_CAP', N'Ưu đãi giữ chân chuyển cấp', N'Chính sách ưu đãi 5% học phí trọn cấp giữ chân học sinh cuối cấp MN lên Lớp 1, Khối 5 lên 6, Khối 9 lên 10', 'TH', 1),
        ('MO_RONG_CLB', N'Phát triển CLB ngoài giờ', N'Mở rộng các CLB STEM, Robotics, AI, Lập trình tạo doanh thu dịch vụ bổ trợ đạt mốc $1M USD', 'TH', 1),
        ('SU_CO_AN_TOAN', N'Ứng phó sự cố an toàn & y tế', N'Kịch bản kiểm soát rủi ro an toàn thực phẩm và sự cố y tế học đường, bảo toàn chỉ tiêu 0 sự cố', 'ALL', 1);
    END;

    -- 2. SEED / UPSERT DANH MỤC LÝ DO RÚT HỌC & BIẾN ĐỘNG SĨ SỐ (tblKPI_CausalReasons)
    -- Đảm bảo có đủ 9 lý do phân loại rủi ro chuẩn hóa theo docs
    IF NOT EXISTS (SELECT 1 FROM tblKPI_CausalReasons WHERE ReasonCode = 'REASON_PUBLIC')
    BEGIN
        INSERT INTO tblKPI_CausalReasons (ReasonCode, ScenarioCode, ReasonName, SortOrder, ResponsibleOwner, ActionOwner, WatchIndicator, RecommendedAction, ControlLevel, HistoricalCount, IsActive)
        VALUES 
        ('REASON_PUBLIC', 'RUT_HOC', N'Chuyển sang trường công lập', 3, N'Hiệu trưởng {Unit}', N'Ban Giám Hiệu & GV Chủ Nhiệm', N'Khảo sát nguyện vọng sau kỳ thi chuyển cấp', N'Truyền thông lợi thế chương trình song ngữ, hỗ trợ tâm lý chuyển cấp', N'Trung bình', 6, 1),
        ('REASON_ACADEMIC', 'RUT_HOC', N'Học lực không theo kịp / Tiếng Anh', 4, N'Hiệu trưởng {Unit}', N'Ban Chuyên Môn & Tổ Bộ Môn', N'Tỷ lệ nộp bài LMS < 70%, điểm kiểm tra định kỳ', N'Kèm phụ đạo cá nhân hóa 1-1, kích hoạt học liệu bổ trợ LMS', N'Cao', 4, 1),
        ('REASON_RELOCATION', 'RUT_HOC', N'Chuyển nơi ở / Chuyển tỉnh', 5, N'Hiệu trưởng {Unit}', N'Bộ phận Tuyển Sinh & TVTS', N'Đơn xin rút hồ sơ chuyển vùng công tác phụ huynh', N'Hỗ trợ kết nối chuyển trường trong hệ thống hoặc bảo lưu hồ sơ', N'Thấp', 8, 1);
    END;

    -- 3. SEED / UPSERT MA TRẬN PHÂN CÔNG TRÁCH NHIỆM (tblKPI_CausalActionAssignments)
    IF NOT EXISTS (SELECT 1 FROM tblKPI_CausalActionAssignments WHERE ScenarioCode = 'MO_TUYEN_BUS')
    BEGIN
        INSERT INTO tblKPI_CausalActionAssignments (ScenarioCode, RoleCode, RoleTitle, ActionDescription, SortOrder)
        VALUES 
        ('MO_TUYEN_BUS', 'BUS_SERVICE', N'Tổ Xe Bus & Vận Hành', N'Lập phương án lộ trình tuyến mới (Trảng Dài - Hố Nai), tính toán điểm đón và thời gian di chuyển', 1),
        ('MO_TUYEN_BUS', 'ACCOUNTING', N'Kế toán Quản trị', N'Dự toán chi phí thuê xe, định mức hòa vốn (tối thiểu 12 HS/xe) và biên lợi nhuận dịch vụ xe bus', 2),
        ('MO_TUYEN_BUS', 'ADMISSIONS', N'Tuyển sinh & CSKH', N'Khảo sát nhu cầu phụ huynh hiện tại và truyền thông tuyến xe mới đến phụ huynh tiềm năng', 3),

        ('GIU_CHAN_CHUYEN_CAP', 'PRINCIPAL', N'Hiệu trưởng Khối Chuyển Tiếp', N'Tổ chức ngày hội trải nghiệm cấp học mới cho học sinh và phụ huynh khối 5, khối 9', 1),
        ('GIU_CHAN_CHUYEN_CAP', 'ADMISSIONS', N'Tuyển sinh & CSKH', N'Gửi thư mời và chính sách ưu đãi 5% học phí trọn cấp, chốt danh sách xác nhận học tiếp trước 30/11', 2),
        ('GIU_CHAN_CHUYEN_CAP', 'ACCOUNTING', N'Kế toán', N'Khóa sổ học phí ưu đãi chuyển cấp và cập nhật dự báo dòng tiền niên khóa mới', 3),

        ('MO_RONG_CLB', 'ACADEMIC', N'Ban Chuyên Môn CLB', N'Xây dựng chương trình STEM, Robotics, AI, Lập trình và tuyển chọn huấn luyện viên chất lượng cao', 1),
        ('MO_RONG_CLB', 'ADMISSIONS', N'Tổ Chăm Sóc Khách Hàng', N'Tổ chức tuần lễ trải nghiệm học thử CLB miễn phí, nâng tỷ lệ tham gia CLB của học sinh', 2),
        ('MO_RONG_CLB', 'ACCOUNTING', N'Kế toán', N'Theo dõi doanh thu CLB riêng biệt trên PM FTS hướng tới mục tiêu $1M tích lũy', 3),

        ('SU_CO_AN_TOAN', 'HEALTH_SAFETY', N'Bộ Phận Y Tế & Bếp Ăn', N'Kích hoạt quy trình ứng phó khẩn cấp, cô lập mẫu thực phẩm, chăm sóc y tế tại chỗ', 1),
        ('SU_CO_AN_TOAN', 'PRINCIPAL', N'Ban Giám Hiệu', N'Trực tiếp gặp gỡ đối thoại với phụ huynh trong 2 giờ đầu, báo cáo khẩn Hội Đồng Quản Trị', 2),
        ('SU_CO_AN_TOAN', 'QA_ISO', N'Bộ Phận Đảm Bảo Chất Lượng', N'Thanh tra quy trình VSATTP theo chuẩn ISO 22000, ban hành biện pháp khắc phục triệt để', 3);
    END;

    -- 4. SEED / UPSERT QUY TẮC CẢNH BÁO TỰ ĐỘNG (tblKPI_CausalRules)
    IF NOT EXISTS (SELECT 1 FROM tblKPI_CausalRules WHERE RuleCode = 'RULE_ZERO_INCIDENT_BREACH')
    BEGIN
        INSERT INTO tblKPI_CausalRules (RuleCode, RuleName, ConditionExpr, Severity, OutcomeSummary, IsActive)
        VALUES 
        ('RULE_BUS_UNDERUTILIZED', N'Tỷ lệ lấp đầy ghế xe bus dưới 65%', N'BUS_SEAT_PCT < 0.65', 'WARN', N'Tuyến xe bus vận hành dưới điểm hòa vốn, biên lợi nhuận dịch vụ bị âm', 1),
        ('RULE_TRANSITION_LAG', N'Tỷ lệ xác nhận chuyển cấp dưới 75%', N'TRANSITION_PCT < 0.75', 'WARN', N'Hụt nguồn tuyển nội bộ giữa các cấp, áp lực tuyển sinh đầu cấp tăng cao', 1),
        ('RULE_ZERO_INCIDENT_BREACH', N'Phát sinh sự cố y tế hoặc ATTP', N'INCIDENT_COUNT > 0', 'DANGER', N'Vi phạm chỉ tiêu an toàn học đường 0 sự cố, kích hoạt xử lý khủng hoảng cấp trường', 1),
        ('RULE_LMS_DIGITAL_LAG', N'Tỷ lệ số hóa học liệu môn chính dưới 60%', N'LMS_DIGITAL_PCT < 0.60', 'WARN', N'Tiến độ học liệu số chậm so với cam kết, ảnh hưởng chất lượng tự học của học sinh', 1);
    END;

    -- 5. TRẢ DỮ LIỆU ĐỒNG BỘ CHO CLIENT (5 BẢNG)
    -- Bảng 0: Danh mục kịch bản (Scenarios)
    SELECT 
        ScenarioCode,
        ScenarioName,
        ScenarioDescription,
        DefaultUnit,
        IsActive
    FROM tblKPI_CausalScenarios
    WHERE IsActive = 1
    ORDER BY CASE 
        WHEN ScenarioCode = 'RUT_HOC' THEN 1
        WHEN ScenarioCode = 'TUYEN_THEM' THEN 2
        WHEN ScenarioCode = 'MO_TUYEN_BUS' THEN 3
        WHEN ScenarioCode = 'GIU_CHAN_CHUYEN_CAP' THEN 4
        WHEN ScenarioCode = 'MO_RONG_CLB' THEN 5
        WHEN ScenarioCode = 'CHUYEN_DOI' THEN 6
        ELSE 7 END;

    -- Bảng 1: Thông số giả định theo đơn vị (Assumptions)
    SELECT 
        UnitCode,
        UnitName,
        OwnerTitle,
        PlannedCapacity,
        CurrentEnrollment,
        AnnualTuitionMillion,
        GrossMarginPct,
        RemainingYearsInLevel,
        NextLevelTuitionMillion,
        NextLevelYears,
        TransitionProbability,
        MonthlyLeads,
        ConversionRate,
        ClbParticipationRate,
        ClbAvgFeeMillion,
        ClassCount
    FROM tblKPI_CausalAssumptions
    ORDER BY CASE 
        WHEN UnitCode = 'MNBH' THEN 1
        WHEN UnitCode = 'MNLK' THEN 2
        WHEN UnitCode = 'TH' THEN 3
        WHEN UnitCode = 'THCS' THEN 4
        WHEN UnitCode = 'THPT' THEN 5
        ELSE 6 END;

    -- Bảng 2: Danh mục lý do & tuyến xử lý (Reasons)
    SELECT 
        ReasonCode,
        ScenarioCode,
        ReasonName,
        SortOrder,
        ResponsibleOwner,
        ActionOwner,
        WatchIndicator,
        RecommendedAction,
        ControlLevel,
        HistoricalCount,
        IsActive
    FROM tblKPI_CausalReasons
    WHERE IsActive = 1
    ORDER BY SortOrder ASC;

    -- Bảng 3: Danh mục phân công trách nhiệm (Assignments)
    SELECT 
        AssignmentID,
        ScenarioCode,
        RoleCode,
        RoleTitle,
        ActionDescription,
        SortOrder
    FROM tblKPI_CausalActionAssignments
    ORDER BY ScenarioCode, SortOrder ASC;

    -- Bảng 4: Danh mục quy tắc IF/ELSE (Rules)
    SELECT 
        RuleID,
        RuleCode,
        RuleName,
        ConditionExpr,
        Severity,
        OutcomeSummary,
        IsActive
    FROM tblKPI_CausalRules
    WHERE IsActive = 1
    ORDER BY CASE Severity WHEN 'DANGER' THEN 1 WHEN 'BAD' THEN 2 WHEN 'WARN' THEN 3 ELSE 4 END;
END;
