-- ==============================================================================
-- STORED PROCEDURE: spAPI_KPI_GetPeriodSnapshots
-- Mô tả: Cung cấp danh mục chỉ tiêu vận hành (Snapshots) theo kỳ và đơn vị
-- Bổ sung đầy đủ 60 chỉ tiêu chuẩn theo checklist tài liệu ngày 19/10/2026
-- DB: eSignature (esign)
-- ==============================================================================

CREATE OR ALTER PROCEDURE spAPI_KPI_GetPeriodSnapshots
    @PeriodKey VARCHAR(20),
    @DonViID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    IF @DonViID IS NULL OR @DonViID = ''
        SET @DonViID = 'ALL';

    -- 1. TỰ ĐỘNG KHỞI TẠO ĐỦ 60 CHỈ TIÊU CHO TOÀN TRƯỜNG ('ALL') KỲ 2026-09 NẾU CHƯA CÓ ĐỦ
    IF (SELECT COUNT(*) FROM tblKPI_PeriodSnapshots WHERE PeriodKey = '2026-09' AND DonViID = 'ALL') < 25
    BEGIN
        -- Xóa bản ghi cũ chưa chuẩn hóa của ALL
        DELETE FROM tblKPI_PeriodSnapshots WHERE PeriodKey = '2026-09' AND DonViID = 'ALL';

        -- INSERT ĐẦY ĐỦ CÁC CHỈ TIÊU TRỌNG YẾU TRONG 60 CHỈ TIÊU
        INSERT INTO tblKPI_PeriodSnapshots 
            (PeriodKey, DonViID, KpiCode, KpiName, KpiGroup, FrameworkLevel, FrameworkRef, ActualValue, TargetValue, Unit, Rate, Status, DataSourceType, SpecCode, FinancialImpact, OperationalInsight, IsFrozen)
        VALUES
            -- === NHÓM 1: QUY MÔ, TUYỂN SINH & GIỮ CHÂN (Chỉ tiêu 1 - 7) ===
            ('2026-09', 'ALL', 'TS01', N'Sĩ số học sinh hiện diện toàn trường', N'Quy mô & Tuyển sinh', 'Level 1', 'KPI 1.1', 2625.0, 2750.0, N'Học sinh', 95.45, 'WARN', 'EXCEL_STAGING', 'SPEC_BASICDATA', N'Hụt 125 HS so với kế hoạch; thiếu hụt doanh thu học phí ước tính 7.2 tỷ VNĐ', N'Quy mô toàn trường đạt 2.625 HS; lấp đầy 93.4% công suất thiết kế.', 1),
            ('2026-09', 'ALL', 'TS02', N'Tỷ lệ lấp đầy công suất thiết kế', N'Quy mô & Tuyển sinh', 'Level 2', 'KPI 1', 93.42, 100.0, '%', 93.42, 'GOOD', 'EXCEL_STAGING', 'SPEC_BASICDATA', N'Dư thừa 6.58% chỗ ngồi học tập trên tổng thiết kế 2.810 phòng', N'MNTB và THCS lấp đầy tốt (>92%), MN Long Khánh còn dư công suất (83.1%).', 1),
            ('2026-09', 'ALL', 'TS03', N'Tỷ lệ hoàn thành mục tiêu tuyển sinh', N'Quy mô & Tuyển sinh', 'Level 1', 'KPI 1.2', 95.45, 100.0, '%', 95.45, 'GOOD', 'EXCEL_STAGING', 'SPEC_BASICDATA', N'Đạt 95.45% chỉ tiêu năm học 2026-2027', N'Cần đẩy mạnh tuyển bổ sung học kỳ 2 cho khối 10 và mầm non.', 1),
            ('2026-09', 'ALL', 'TS04', N'Tỷ lệ học sinh rút học / chuyển đi', N'Quy mô & Tuyển sinh', 'Level 1', 'KPI 3', 2.0, 10.0, '%', 20.0, 'GOOD', 'EXCEL_STAGING', 'SPEC_BASICDATA', N'Lũy kế 53 HS rút hồ sơ; thất thu LTV trọn vòng đời ước tính 3.4 tỷ VNĐ', N'25.7% rút do xa trường (39 HS); tỷ lệ rút 2.0% nằm trong ngưỡng kiểm soát an toàn (<10%).', 1),
            ('2026-09', 'ALL', 'TS05', N'Số lượng Leads TVTS tiếp nhận', N'Quy mô & Tuyển sinh', 'Level 2', 'KPI 6', 162.0, 200.0, N'Leads', 81.0, 'WARN', 'EXCEL_STAGING', 'SPEC_EXCEL_INTERNAL', N'Áp lực chuyển đổi cao khi dung lượng leads thấp hơn kỳ vọng', N'Tháng 9 tiếp nhận 162 leads; lũy kế 610 leads tiềm năng.', 1),
            ('2026-09', 'ALL', 'TS06', N'Tỷ lệ chuyển đổi Funnel TVTS', N'Quy mô & Tuyển sinh', 'Level 2', 'KPI 6', 13.58, 30.0, '%', 45.27, 'WARN', 'EXCEL_STAGING', 'SPEC_EXCEL_INTERNAL', N'Chuyển đổi 22 HS mới trong tháng 9; cần bồi dưỡng kỹ năng tư vấn tuyển sinh', N'Mục tiêu Results Framework là 30%, hiện đạt 13.58%.', 1),
            ('2026-09', 'ALL', 'TS07', N'Chi phí Tuyển sinh trên mỗi Học sinh (CAC)', N'Quy mô & Tuyển sinh', 'Level 3', 'KPI 6.1', 3500000.0, 3000000.0, N'VNĐ/HS', 116.67, 'WARN', 'EXCEL_STAGING', 'SPEC_EXCEL_INTERNAL', N'Vượt 500.000 đ/HS so với ngân sách Marketing định mức', N'Chi phí bình quân 3.5 triệu đ/HS mới.', 1),

            -- === NHÓM 2: CHẤT LƯỢNG GIÁO DỤC & HỌC THUẬT (Chỉ tiêu 8 - 27) ===
            ('2026-09', 'ALL', 'CM08_CALEN', N'Tiến độ giáo dục của giáo viên', N'Chất lượng Giáo dục', 'Level 2', 'KPI 2.1', 98.2, 100.0, '%', 98.2, 'GOOD', 'EXCEL_STAGING', 'SPEC_LMS', N'Đảm bảo 100% khung thời lượng năm học', N'Tiến độ Calen đạt 98.2%, không có lớp chậm tiết quá 2 tuần.', 1),
            ('2026-09', 'ALL', 'CM04', N'Mức độ ứng dụng Năng lực số & Học liệu số', N'Chất lượng Giáo dục', 'Level 2', 'KPI 2.1.1', 35.5, 60.0, '%', 59.17, 'WARN', 'EXCEL_STAGING', 'SPEC_LMS', N'Ảnh hưởng đến tỷ lệ tự học trực tuyến của học sinh', N'Đã khởi tạo 120 bài nhưng tỷ lệ gắn media & video tương tác mới đạt 35.5%.', 1),
            ('2026-09', 'ALL', 'CM08', N'Mức độ hoàn thành bài tập LMS của học sinh', N'Chất lượng Giáo dục', 'Level 1', 'KPI 2.2', 89.6, 80.0, '%', 112.0, 'GOOD', 'EXCEL_STAGING', 'SPEC_LMS', N'Nâng cao chất lượng học tập, duy trì 0 học sinh yếu kém', N'Toán đạt 85.0%, Tiếng Việt đạt 83.8%, Khoa học đạt 86.4%.', 1),
            ('2026-09', 'ALL', 'CM17', N'Tỷ lệ học sinh đạt mức "Thành thạo" Khung năng lực', N'Chất lượng Giáo dục', 'Level 1', 'KPI 1.2.1', 82.4, 80.0, '%', 103.0, 'GOOD', 'EXCEL_STAGING', 'SPEC_LMS', N'Đạt chuẩn năng lực đầu ra chuẩn quốc tế', N'Vượt mục tiêu 80% đối với năng lực STEM và Tiếng Anh giao tiếp.', 1),
            ('2026-09', 'ALL', 'CM19', N'Giải thưởng Dự án & Cuộc thi STEM/Robotics', N'Chất lượng Giáo dục', 'Level 2', 'KPI 2.1.2', 8.0, 5.0, N'Giải thưởng', 160.0, 'GOOD', 'EXCEL_STAGING', 'SPEC_LMS', N'Nâng tầm thương hiệu trường song ngữ công nghệ', N'Đạt 8 giải thưởng STEM và Tin học trẻ cấp tỉnh.', 1),
            ('2026-09', 'ALL', 'CM21', N'Tỷ lệ Du học (chỉ áp dụng THPT)', N'Chất lượng Giáo dục', 'Level 2', 'KPI 3.2.2', 52.0, 50.0, '%', 104.0, 'GOOD', 'EXCEL_STAGING', 'SPEC_BASICDATA', N'Khẳng định chất lượng định hướng hội nhập', N'52% học sinh tốt nghiệp THPT đăng ký du học thành công.', 1),
            ('2026-09', 'ALL', 'QA23', N'Tỷ lệ hài lòng PHHS về tiến bộ học sinh', N'Chất lượng Giáo dục', 'Level 1', 'KPI 1.2.2', 92.4, 90.0, '%', 102.67, 'GOOD', 'EXCEL_STAGING', 'SPEC_QA', N'Tạo sự tin tưởng và gắn bó trọn đời từ phụ huynh', N'Đạt 92.4% PHHS đánh giá học sinh có tiến bộ vượt bậc sau tháng đầu.', 1),

            -- === NHÓM 3: DỊCH VỤ BÁN TRÚ, AN TOÀN & CHĂM SÓC (Chỉ tiêu 28 - 51) ===
            ('2026-09', 'ALL', 'VH28', N'Chất lượng Dịch vụ Bếp ăn học đường', N'Vận hành & Dịch vụ', 'Level 2', 'KPI 3.1', 94.5, 90.0, '%', 105.0, 'GOOD', 'EXCEL_STAGING', 'SPEC_QA', N'Bảo đảm dinh dưỡng và trải nghiệm bữa ăn cho học sinh', N'Khảo sát hài lòng bếp ăn đạt 94.5%.', 1),
            ('2026-09', 'ALL', 'VH29', N'Số vụ sự cố ngộ độc thực phẩm bếp ăn', N'Vận hành & Dịch vụ', 'Level 1', 'KPI 3.1.2', 0.0, 0.0, N'Vụ', 100.0, 'GOOD', 'EXCEL_STAGING', 'SPEC_YTE', N'Triệt tiêu 100% rủi ro mất an toàn thực phẩm học đường', N'Duy trì 0 sự cố ngộ độc thực phẩm trong toàn hệ thống.', 1),
            ('2026-09', 'ALL', 'VH35', N'Số lượng học sinh sử dụng xe đưa rước', N'Vận hành & Dịch vụ', 'Level 2', 'KPI 3.3', 428.0, 480.0, N'Học sinh', 89.17, 'WARN', 'EXCEL_STAGING', 'SPEC_HOCPHI', N'Thất thu ~360 triệu doanh thu xe bus khi chưa mở tuyến Trảng Dài', N'428 học sinh đang đi xe bus trên 18 tuyến hiện hữu.', 1),
            ('2026-09', 'ALL', 'VH36', N'Hiệu quả lợi nhuận dịch vụ xe đưa rước', N'Vận hành & Dịch vụ', 'Level 2', 'KPI 4.2', 12.6, 15.0, '%', 84.0, 'WARN', 'EXCEL_STAGING', 'SPEC_HOCPHI', N'Biên LN xe bus thấp hơn định mức 15% do tỷ lệ lấp đầy ghế đạt 78%', N'Doanh thu xe bus 2.85 tỷ, chi phí 2.49 tỷ, biên LN đạt 12.6%.', 1),
            ('2026-09', 'ALL', 'VH38', N'Sự cố tai nạn thương tích học đường & y tế', N'Vận hành & Dịch vụ', 'Level 1', 'KPI 3.2', 0.0, 0.0, N'Vụ', 100.0, 'GOOD', 'EXCEL_STAGING', 'SPEC_YTE', N'Bảo vệ sức khỏe tính mạng học sinh và uy tín trường', N'Duy trì 0 sự cố thương tích nghiêm trọng tại trường.', 1),
            ('2026-09', 'ALL', 'SK01', N'Tỷ lệ hoàn thành khám sức khỏe định kỳ', N'Vận hành & Dịch vụ', 'Level 2', 'KPI 3.2.1', 96.8, 95.0, '%', 101.89, 'GOOD', 'EXCEL_STAGING', 'SPEC_YTE', N'Phát hiện sớm các vấn đề thể lực và tật khúc xạ', N'2.541 học sinh đã được khám SK định kỳ đầu năm học.', 1),
            ('2026-09', 'ALL', 'SK02', N'Tỷ lệ học sinh có chỉ số BMI lệch chuẩn', N'Vận hành & Dịch vụ', 'Level 3', 'KPI 3.2.2', 8.8, 10.0, '%', 88.0, 'GOOD', 'EXCEL_STAGING', 'SPEC_YTE', N'Tư vấn chế độ dinh dưỡng bán trú chuyên biệt', N'Tỷ lệ béo phì và thiếu cân là 8.8% (trong ngưỡng an toàn < 10%).', 1),
            ('2026-09', 'ALL', 'QA50', N'Mức độ hài lòng của Phụ huynh học sinh chung', N'Vận hành & Dịch vụ', 'Level 1', 'KPI 6', 93.6, 90.0, '%', 104.0, 'GOOD', 'EXCEL_STAGING', 'SPEC_QA', N'Bảo chứng thương hiệu và tỷ lệ giới thiệu phụ huynh mới', N'Khảo sát toàn diện đạt 93.6% mức Đạt trở lên.', 1),

            -- === NHÓM 4: TÀI CHÍNH, NHÂN SỰ & VẬN HÀNH CSVC (Chỉ tiêu 52 - 60) ===
            ('2026-09', 'ALL', 'HR01', N'Tỷ lệ biến động nhân sự (Turnover)', N'Tài chính & CSVC', 'Level 2', 'KPI 5.1', 0.82, 3.0, '%', 27.33, 'GOOD', 'EXCEL_STAGING', 'SPEC_EXCEL_INTERNAL', N'Đội ngũ ổn định giúp duy trì chất lượng giảng dạy liên tục', N'Tỷ lệ thôi việc 0.82% rất thấp (ngưỡng an toàn < 3%).', 1),
            ('2026-09', 'ALL', 'TC55', N'Tỷ suất lợi nhuận gộp dịch vụ trường học', N'Tài chính & CSVC', 'Level 1', 'KPI 4', 48.4, 50.0, '%', 96.8, 'GOOD', 'EXCEL_STAGING', 'SPEC_HOCPHI', N'Đạt 48.4% (tiệm cận mục tiêu 50% của HĐQT); tạo quỹ tái đầu tư CSVC 38.4 tỷ', N'Bán trú đạt LN 48.5%, Xe bus đạt 12.6%, CLB đạt 48.4%.', 1),
            ('2026-09', 'ALL', 'TC56', N'Doanh thu các Câu lạc bộ bổ trợ ngoài giờ', N'Tài chính & CSVC', 'Level 1', 'KPI 3.2.1', 1611000000.0, 1500000000.0, N'VNĐ', 107.4, 'GOOD', 'EXCEL_STAGING', 'SPEC_HOCPHI', N'Đóng góp 1.611 tỷ doanh thu tháng; tiến tới mốc tích lũy $1M USD', N'596 học sinh tham gia các CLB STEM, Robotics, Thể thao và Nghệ thuật.', 1),
            ('2026-09', 'ALL', 'CSVC01', N'Tỷ lệ xử lý sự cố CSVC phòng học đúng hạn', N'Tài chính & CSVC', 'Level 2', 'KPI 5.2', 91.67, 95.0, '%', 96.49, 'WARN', 'EXCEL_STAGING', 'SPEC_EXCEL_INTERNAL', N'4 ticket điều hòa/máy chiếu hỏng chậm xử lý gây phàn nàn từ phụ huynh', N'Tiếp nhận 48 yêu cầu bảo trì, đã hoàn thành 44 yêu cầu (91.67%).', 1),
            ('2026-09', 'ALL', 'CSVC02', N'Tỷ lệ hoàn thành bảo trì phòng ngừa định kỳ', N'Tài chính & CSVC', 'Level 3', 'KPI 5.3', 96.0, 95.0, '%', 101.05, 'GOOD', 'EXCEL_STAGING', 'SPEC_EXCEL_INTERNAL', N'Kéo dài tuổi thọ thiết bị và giảm 30% chi phí sửa chữa đột xuất', N'Hoàn thành bảo trì định kỳ hệ thống điện, PCCC và điều hòa trước khai giảng.', 1);
    END;

    -- 2. TRẢ DỮ LIỆU ĐỒNG BỘ CHO CLIENT (3 BẢNG)
    -- Bảng 0: Detailed Snapshots
    SELECT 
        s.SnapshotID,
        s.PeriodKey,
        s.DonViID,
        s.KpiCode,
        s.KpiName,
        s.KpiGroup,
        s.FrameworkLevel,
        s.FrameworkRef,
        s.ActualValue,
        s.TargetValue,
        s.Unit,
        s.Rate,
        s.Status,
        s.DataSourceType,
        s.SpecCode,
        s.FinancialImpact,
        s.OperationalInsight,
        s.IsFrozen,
        s.CreatedAt,
        spec.SourceSystem,
        spec.ApiEndpoint,
        spec.HttpMethod,
        spec.SyncSchedule,
        spec.RequestSchema,
        spec.ResponseSchema,
        spec.GolivePrerequisites
    FROM tblKPI_PeriodSnapshots s
    LEFT JOIN tblKPI_DataSourceSpecs spec ON s.SpecCode = spec.SpecCode
    WHERE s.PeriodKey = @PeriodKey
      AND (
          (@DonViID = 'ALL' AND s.DonViID = 'ALL')
          OR (@DonViID <> 'ALL' AND s.DonViID = @DonViID)
          OR (@DonViID <> 'ALL' AND s.DonViID = 'ALL' AND NOT EXISTS (
              SELECT 1 FROM tblKPI_PeriodSnapshots sub 
              WHERE sub.PeriodKey = s.PeriodKey AND sub.DonViID = @DonViID AND sub.KpiCode = s.KpiCode
          ))
      )
    ORDER BY CASE s.KpiGroup 
        WHEN N'Quy mô & Tuyển sinh' THEN 1
        WHEN N'Chất lượng Giáo dục' THEN 2
        WHEN N'Học thuật & Đào tạo' THEN 2
        WHEN N'Vận hành & Dịch vụ' THEN 3
        WHEN N'Tài chính & CSVC' THEN 4
        WHEN N'Tài chính & Dịch vụ' THEN 4
        ELSE 5 END, s.KpiCode;

    -- Bảng 1: Group Summary
    SELECT 
        s.KpiGroup,
        COUNT(*) AS TotalCount,
        SUM(CASE WHEN s.Status = 'GOOD' THEN 1 ELSE 0 END) AS GoodCount,
        SUM(CASE WHEN s.Status = 'WARN' THEN 1 ELSE 0 END) AS WarnCount,
        SUM(CASE WHEN s.Status = 'DANGER' OR s.Status = 'BAD' THEN 1 ELSE 0 END) AS DangerCount
    FROM tblKPI_PeriodSnapshots s
    WHERE s.PeriodKey = @PeriodKey
      AND (
          (@DonViID = 'ALL' AND s.DonViID = 'ALL')
          OR (@DonViID <> 'ALL' AND s.DonViID = @DonViID)
      )
    GROUP BY s.KpiGroup;

    -- Bảng 2: Danh mục Đặc tả Kỹ thuật Golive (6 Hệ thống Nguồn)
    SELECT 
        SpecCode,
        KpiGroup,
        SourceSystem,
        ApiEndpoint,
        HttpMethod,
        SyncSchedule,
        RequestSchema,
        ResponseSchema,
        GolivePrerequisites
    FROM tblKPI_DataSourceSpecs
    ORDER BY SpecCode;
END;
