CREATE OR ALTER PROCEDURE spAPI_KPI_GetCorrelations
    @PeriodKey VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    -- SEED THÊM CÁC CHUỖI NHÂN QUẢ USECASE THỰC TẾ
    IF NOT EXISTS (SELECT 1 FROM tblKPI_Correlations WHERE CauseKpiCode = 'BUS01')
    BEGIN
        INSERT INTO tblKPI_Correlations (
            PeriodKey, ChainGroup, CauseKpiCode, CauseKpiName, EffectKpiCode, EffectKpiName,
            RelationshipType, Description, QuantifiedImpact, RecommendedAction, ResponsibleRole, SortOrder, CreatedAt
        )
        VALUES 
        (
            '2026-09', N'Tuyến Xe Bus & Rút Học', 'BUS01', N'Mở thêm 2 tuyến xe bus (Trảng Dài - Hố Nai)',
            'TS04', N'Giảm tỷ lệ học sinh rút học vì xa trường', 'DIRECT_MITIGATION',
            N'25.7% học sinh rút học (39 em) vì lý do xa nhà và ngoài tuyến xe đưa rước. Việc mở 2 tuyến mới giải quyết trực diện nhu cầu này.',
            N'Dự kiến giữ chân 25–30 học sinh, bảo toàn khoảng 1.5 tỷ học phí và tạo thêm 360 triệu doanh thu xe bus mỗi năm.',
            N'Phê duyệt ngân sách thuê 2 xe 29 chỗ và bố trí 2 nhân sự giám sát tuyến từ tháng 11/2026.',
            N'Tổ Xe Bus & Trưởng Ban Vận Hành Dịch Vụ', 1, GETDATE()
        ),
        (
            '2026-09', N'Giữ Chân Chuyển Cấp', 'TRANS01', N'Chính sách ưu đãi 5% học phí chuyển cấp (Khối 5 lên 6 & Khối 9 lên 10)',
            'TS01', N'Bảo toàn quy mô học sinh đầu cấp', 'RETENTION_INCENTIVE',
            N'Khoảng 15% học sinh cuối cấp có xu hướng phân vân chuyển sang trường công lập. Chính sách ưu đãi sớm giúp phụ huynh cam kết gắn bó.',
            N'Tăng tỷ lệ chuyển tiếp từ 70% lên 85%, giữ chân thêm 45 học sinh, tiết kiệm hơn 150 triệu VNĐ chi phí tuyển sinh Marketing (CAC).',
            N'Ban hành chính sách ưu đãi và tổ chức tuần lễ trải nghiệm THCS/THPT trước ngày 30/11/2026.',
            N'Ban Giám Hiệu & Bộ Phận Tuyển Sinh', 2, GETDATE()
        ),
        (
            '2026-09', N'An Toàn Học Đường & Niềm Tin', 'SAFE01', N'Duy trì 0 vụ sự cố ngộ độc thực phẩm & tai nạn thương tích',
            'QA01', N'Chỉ số hài lòng của Phụ huynh học sinh (> 90%)', 'FOUNDATIONAL_TRUST',
            N'Chất lượng bữa ăn học đường và y tế là nền tảng sống còn. 1 sự cố ngộ độc có thể dẫn đến làn sóng rút hồ sơ dây chuyền.',
            N'Bảo toàn chỉ số hài lòng PHHS đạt 93.6%, triệt tiêu hoàn toàn rủi ro khủng hoảng truyền thông và giữ vững uy tín thương hiệu LHBS.',
            N'Kiểm định định kỳ nhà cung cấp thực phẩm theo chuẩn ISO 22000 và diễn tập sơ cấp cứu y tế học đường hàng tháng.',
            N'Bộ Phận Y Tế & Quản Lý Bếp Ăn', 3, GETDATE()
        );
    END;

    -- 1. Correlation Nodes & Chains
    SELECT 
        CorrelationID,
        PeriodKey,
        ChainGroup,
        CauseKpiCode,
        CauseKpiName,
        EffectKpiCode,
        EffectKpiName,
        RelationshipType,
        Description,
        QuantifiedImpact,
        RecommendedAction,
        ResponsibleRole,
        SortOrder,
        CreatedAt
    FROM tblKPI_Correlations
    WHERE PeriodKey = @PeriodKey
    ORDER BY ChainGroup, SortOrder;

    -- 2. Chains Summary
    SELECT 
        ChainGroup,
        COUNT(*) AS LinksCount
    FROM tblKPI_Correlations
    WHERE PeriodKey = @PeriodKey
    GROUP BY ChainGroup;
END;
