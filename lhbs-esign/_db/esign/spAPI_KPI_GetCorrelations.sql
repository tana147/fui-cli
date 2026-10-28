CREATE OR ALTER PROCEDURE spAPI_KPI_GetCorrelations
    @PeriodKey VARCHAR(20),
    @DonViID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';
    IF @DonViID IS NULL OR @DonViID = ''
        SET @DonViID = 'ALL';

    -- SEED THÊM CÁC CHUỖI NHÂN QUẢ USECASE THỰC TẾ (NẾU CHƯA CÓ)
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

    -- 1. Correlation Nodes & Chains (Result Set 0 - Giữ nguyên Contract cũ)
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

    -- 2. Chains Summary (Result Set 1 - Giữ nguyên Contract cũ)
    SELECT 
        ChainGroup,
        COUNT(*) AS LinksCount
    FROM tblKPI_Correlations
    WHERE PeriodKey = @PeriodKey
    GROUP BY ChainGroup;

    -- 3. Dynamic Narrative Calculations (Result Set 2 - Tính toán theo Snapshot & Assumption)
    DECLARE @DonViName NVARCHAR(100);
    SET @DonViName = CASE @DonViID 
        WHEN 'MNLK' THEN N'Mầm non Long Khánh'
        WHEN 'MNTB' THEN N'Mầm non Trấn Biên'
        WHEN 'TH' THEN N'Tiểu học'
        WHEN 'THCS' THEN N'THCS'
        WHEN 'THPT' THEN N'THPT'
        ELSE N'Toàn hệ thống'
    END;

    -- Học phí bình quân hàng năm (triệu VNĐ)
    DECLARE @Tuition FLOAT = 49.8;
    IF @DonViID IN ('MNLK', 'MNTB') SET @Tuition = 37.2;
    ELSE IF @DonViID = 'TH' SET @Tuition = 49.6;
    ELSE IF @DonViID = 'THCS' SET @Tuition = 61.7;
    ELSE IF @DonViID = 'THPT' SET @Tuition = 63.6;

    -- Thông số snapshot
    DECLARE @Leads FLOAT = ISNULL(
        (SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND KpiCode = 'TS05'),
        ISNULL((SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL' AND KpiCode = 'TS05'), 162)
    );

    DECLARE @ConvRate FLOAT = ISNULL(
        (SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND KpiCode = 'TS06'),
        ISNULL((SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL' AND KpiCode = 'TS06'), 13.58)
    );

    DECLARE @HocLieuSo FLOAT = ISNULL(
        (SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND KpiCode = 'CM04'),
        ISNULL((SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL' AND KpiCode = 'CM04'), 100)
    );

    DECLARE @LmsRate FLOAT = ISNULL(
        (SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND KpiCode = 'CM08'),
        ISNULL((SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL' AND KpiCode = 'CM08'), 89.6)
    );

    DECLARE @GrossMargin FLOAT = ISNULL(
        (SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND KpiCode = 'TC55'),
        ISNULL((SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL' AND KpiCode = 'TC55'), 48.4)
    );

    DECLARE @ClbRev FLOAT = ISNULL(
        (SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND KpiCode = 'TC56'),
        ISNULL((SELECT TOP 1 ActualValue FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL' AND KpiCode = 'TC56'), 1611000000)
    );

    DECLARE @SiSoActual INT = ISNULL(
        (SELECT TOP 1 CAST(ActualValue AS INT) FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND KpiCode = 'TS01'),
        ISNULL((SELECT TOP 1 CAST(ActualValue AS INT) FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL' AND KpiCode = 'TS01'), 2625)
    );

    DECLARE @SiSoTarget INT = ISNULL(
        (SELECT TOP 1 CAST(TargetValue AS INT) FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND KpiCode = 'TS01'),
        ISNULL((SELECT TOP 1 CAST(TargetValue AS INT) FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = 'ALL' AND KpiCode = 'TS01'), 2750)
    );

    DECLARE @SiSoRate FLOAT = ISNULL(
        (SELECT TOP 1 Rate FROM tblKPI_PeriodSnapshots WHERE PeriodKey = @PeriodKey AND DonViID = @DonViID AND KpiCode = 'TS01'),
        95.45
    );

    -- Số học sinh rút học do xa trường và ước tính thiệt hại
    DECLARE @SoHSRutXaNha INT;
    DECLARE @TyLeRutXaNha FLOAT;
    IF @DonViID = 'MNLK' BEGIN SET @SoHSRutXaNha = 4; SET @TyLeRutXaNha = 36.4; END
    ELSE IF @DonViID = 'MNTB' BEGIN SET @SoHSRutXaNha = 3; SET @TyLeRutXaNha = 30.0; END
    ELSE IF @DonViID = 'TH' BEGIN SET @SoHSRutXaNha = 8; SET @TyLeRutXaNha = 42.1; END
    ELSE IF @DonViID = 'THCS' BEGIN SET @SoHSRutXaNha = 4; SET @TyLeRutXaNha = 40.0; END
    ELSE BEGIN SET @SoHSRutXaNha = 21; SET @TyLeRutXaNha = 39.6; END

    DECLARE @TienHocPhiRutStr NVARCHAR(50) = 
        CASE 
            WHEN (@SoHSRutXaNha * @Tuition) >= 1000 THEN CAST(CAST((@SoHSRutXaNha * @Tuition) / 1000.0 AS DECIMAL(10,3)) AS VARCHAR) + N' tỷ'
            ELSE CAST(ROUND(@SoHSRutXaNha * @Tuition, 0) AS VARCHAR) + N' triệu'
        END;
    DECLARE @TienBusRutStr NVARCHAR(50) = CAST(ROUND(@SoHSRutXaNha * 12.0, 0) AS VARCHAR) + N' triệu';

    -- Chuỗi Doanh thu CLB
    DECLARE @ClbRevStr NVARCHAR(50) = 
        CASE 
            WHEN @ClbRev >= 1000000000 THEN CAST(CAST(@ClbRev / 1000000000.0 AS DECIMAL(10,3)) AS VARCHAR) + N' tỷ'
            ELSE CAST(ROUND(@ClbRev / 1000000.0, 0) AS VARCHAR) + N' triệu'
        END;

    -- Result Set 2: Danh sách Causal Narratives
    SELECT 
        NarrativeID,
        NarrativeCode,
        NarrativeGroup,
        Title,
        ConditionExpr,
        TemplatePattern,
        ActionPattern,
        CASE NarrativeCode
            WHEN 'NARRATIVE_ENROLLMENT_CONV' THEN 
                CONCAT(N'{"TyLeChuyenDoi":"', CAST(CAST(@ConvRate AS DECIMAL(5,1)) AS VARCHAR), N'%","SoHSTuyenThem":"~', CAST(ROUND(@Leads * 0.01, 0) AS VARCHAR), N'","DoanhThuThem":"~', CAST(ROUND(@Leads * 0.01 * @Tuition, 0) AS VARCHAR), N' tr"}')
            WHEN 'NARRATIVE_WITHDRAW_BUS' THEN
                CONCAT(N'{"SoHSRut":"', CAST(@SoHSRutXaNha AS VARCHAR), N'","TyLeRut":"', CAST(CAST(@TyLeRutXaNha AS DECIMAL(5,1)) AS VARCHAR), N'%","TienHocPhi":"', @TienHocPhiRutStr, N'","TienBus":"', @TienBusRutStr, N'"}')
            WHEN 'NARRATIVE_LMS_QUALITY' THEN
                CONCAT(N'{"TyLeHocLieuSo":"', CAST(CAST(@HocLieuSo AS DECIMAL(5,1)) AS VARCHAR), N'%","TyLeLamBaiLMS":"', CAST(CAST(@LmsRate AS DECIMAL(5,1)) AS VARCHAR), N'%"}')
            WHEN 'NARRATIVE_FINANCE_REINVEST' THEN
                CONCAT(N'{"DoanhThuCLB":"', @ClbRevStr, N'","SoHocVienCLB":"596 HS","LoiNhuanGop":"', CAST(CAST(@GrossMargin AS DECIMAL(5,1)) AS VARCHAR), N'%"}')
            WHEN 'NARRATIVE_CAPACITY_OCCUPANCY' THEN
                CONCAT(N'{"DonVi":"', @DonViName, N'","SiSoHienDien":"', CAST(@SiSoActual AS VARCHAR), N'","TyLeLapDay":"', CAST(CAST(@SiSoRate AS DECIMAL(5,1)) AS VARCHAR), N'%","CongSuat":"', CAST(@SiSoTarget AS VARCHAR), N'","SoHSTuyenBu":"', CAST(CASE WHEN @SiSoTarget > @SiSoActual THEN @SiSoTarget - @SiSoActual ELSE 0 END AS VARCHAR), N'"}')
            WHEN 'NARRATIVE_FACILITIES_SLA' THEN
                CONCAT(N'{"DonVi":"', @DonViName, N'","TyLeCSVC":"91.7%","SoTicketDaXong":"44","TongTicket":"48","NguongKhieuNai":"1%"}')
            WHEN 'NARRATIVE_TEACHER_ATTRITION' THEN
                CONCAT(N'{"DonVi":"', @DonViName, N'","TyLeNghiViec":"1.8%","SoGVNghi":"3","SoHSAnhHuong":"85"}')
            ELSE DefaultParamsJson
        END AS ParamsJson,
        DefaultParamsJson,
        SortOrder,
        IsActive
    FROM tblKPI_CausalNarratives
    WHERE IsActive = 1
    ORDER BY SortOrder;
END;
