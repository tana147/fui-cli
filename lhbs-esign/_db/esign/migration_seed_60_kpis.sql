-- ==============================================================================
-- MIGRATION: SEED 60 CHỈ TIÊU KPI CHUẨN HÓA & 5 CƠ SỞ TRƯỜNG LHBS
-- Căn cứ: Tài liệu gốc họp Ban Điều Hành ngày 19/10/2026
-- DB: eSignature (esign)
-- ==============================================================================

-- 1. BẢNG DANH MỤC 60 CHỈ TIÊU GỐC: tblKPI_Definitions
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'tblKPI_Definitions')
BEGIN
    CREATE TABLE tblKPI_Definitions (
        KpiCode VARCHAR(50) PRIMARY KEY,
        KpiName NVARCHAR(250) NOT NULL,
        KpiGroup NVARCHAR(100) NOT NULL,
        GroupOrder INT NOT NULL DEFAULT 1,
        SortOrder INT NOT NULL DEFAULT 1,
        Unit NVARCHAR(50) NOT NULL,
        Frequency NVARCHAR(50) NOT NULL DEFAULT N'Tháng',
        SourceSystem NVARCHAR(150) NOT NULL,
        DefaultTarget FLOAT NULL,
        DefaultWarn FLOAT NULL,
        DefaultCritical FLOAT NULL,
        DefaultOperator VARCHAR(10) NOT NULL DEFAULT '>=',
        FrameworkRef NVARCHAR(50) NULL,
        Description NVARCHAR(500) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UpdatedAt DATETIME DEFAULT GETDATE()
    );
END;

-- SEED TOÀN BỘ 60 CHỈ TIÊU GỐC (NẾU CHƯA CÓ)
IF NOT EXISTS (SELECT 1 FROM tblKPI_Definitions WHERE KpiCode = 'TS01')
BEGIN
    INSERT INTO tblKPI_Definitions (KpiCode, KpiName, KpiGroup, GroupOrder, SortOrder, Unit, Frequency, SourceSystem, DefaultTarget, DefaultWarn, DefaultCritical, DefaultOperator, FrameworkRef, Description)
    VALUES
    -- ==============================================================================
    -- NHÓM 1: QUY MÔ, TUYỂN SINH & GIỮ CHÂN HỌC SINH (7 CHỈ TIÊU: TS01–TS07)
    -- ==============================================================================
    ('TS01', N'Sĩ số học sinh hiện diện', N'Quy mô & Tuyển sinh', 1, 1, N'Học sinh', N'Hàng tháng', N'Basic Data (https://basicdata.lhbs.vn/)', 2750, 2600, 2400, '>=', N'KPI 1', N'Tổng số HS đang học tại ngày chốt cuối tháng'),
    ('TS02', N'Tỷ lệ lấp đầy công suất', N'Quy mô & Tuyển sinh', 1, 2, N'%', N'Hàng tháng', N'Basic Data (https://basicdata.lhbs.vn/)', 100.0, 95.0, 90.0, '>=', N'KPI 1', N'Sĩ số hiện diện / Tổng công suất thiết kế phòng học'),
    ('TS03', N'Tỷ lệ hoàn thành mục tiêu tuyển sinh năm học', N'Quy mô & Tuyển sinh', 1, 3, N'%', N'Hàng tháng', N'Basic Data & Kế hoạch tuyển sinh', 100.0, 95.0, 90.0, '>=', NULL, N'Sĩ số hiện diện / Tổng mục tiêu tuyển sinh niên khóa'),
    ('TS04', N'Tỷ lệ học sinh rút học / chuyển đi', N'Quy mô & Tuyển sinh', 1, 4, N'%', N'Hàng tháng', N'Basic Data (HS chuyển đi)', 10.0, 3.0, 10.0, '<=', N'KPI 3', N'Học sinh rút ròng trong kỳ / Tổng sĩ số đầu năm (Ngưỡng năm < 10%, nhịp tháng <= 3%)'),
    ('TS05', N'Số lượng Leads (Khách hàng tiềm năng)', N'Quy mô & Tuyển sinh', 1, 5, N'Leads', N'Hàng tháng', N'CRM Tuyển sinh & TVTS Tracking', 200, 150, 100, '>=', NULL, N'Tổng data lead thu thập qua Digital, Event, Hotline, Giới thiệu'),
    ('TS06', N'Tỷ lệ chuyển đổi Funnel tuyển sinh', N'Quy mô & Tuyển sinh', 1, 6, N'%', N'Hàng tháng', N'CRM Tuyển sinh & TVTS Tracking', 30.0, 20.0, 10.0, '>=', N'KPI 6', N'Số học sinh nhập học mới / Tổng số Leads quan tâm (Đích 30%)'),
    ('TS07', N'Chi phí Tuyển sinh trên mỗi Học sinh (CAC)', N'Quy mô & Tuyển sinh', 1, 7, N'triệu VNĐ/HS', N'Hàng tháng', N'Kế toán FTS & Basic Data', 3.5, 4.5, 6.0, '<=', NULL, N'Tổng chi phí Marketing & Tuyển sinh / Số học sinh nhập học mới'),

    -- ==============================================================================
    -- NHÓM 2: CHẤT LƯỢNG GIÁO DỤC & HỌC THUẬT (20 CHỈ TIÊU: CM08–CM27)
    -- ==============================================================================
    ('CM08', N'Tiến độ giáo dục của giáo viên', N'Giáo dục & Học thuật', 2, 8, N'%', N'Hàng tháng', N'Calen & LMS giai đoạn 3', 100.0, 95.0, 90.0, '>=', NULL, N'Tỷ lệ số tiết thực dạy đúng tiến độ phân phối chương trình'),
    ('CM09', N'Số lượt vắng nghỉ, trễ của giáo viên', N'Giáo dục & Học thuật', 2, 9, N'Số buổi', N'Hàng tháng', N'HRM & Calen', 5.0, 10.0, 15.0, '<=', NULL, N'Tổng hợp số buổi vắng, nghỉ, trễ của đội ngũ giáo viên'),
    ('CM10', N'Kết quả đánh giá dự giờ giáo viên', N'Giáo dục & Học thuật', 2, 10, N'% Đạt', N'Hàng tháng', N'Tổ khối chuyên môn & LMS', 90.0, 80.0, 70.0, '>=', NULL, N'Tỷ lệ tiết dạy đạt loại Khá - Tốt trở lên'),
    ('CM11', N'Mức độ ứng dụng Học liệu số của giáo viên', N'Giáo dục & Học thuật', 2, 11, N'%', N'Hàng tháng', N'LMS Học tập (https://lms.lhbs.vn/)', 100.0, 80.0, 60.0, '>=', NULL, N'Tỷ lệ môn học/khối lớp có đầy đủ học liệu số tương tác'),
    ('CM12', N'Sáng kiến & Biện pháp đổi mới phương pháp dạy', N'Giáo dục & Học thuật', 2, 12, N'Sáng kiến', N'Học kỳ', N'Ban Chuyên môn & Hội đồng khoa học', 10.0, 5.0, 2.0, '>=', N'KPI 2.1.1', N'Số lượng sáng kiến, biện pháp đổi mới được công nhận (10% GV)'),
    ('CM13', N'Chuyên cần của học sinh', N'Giáo dục & Học thuật', 2, 13, N'Ngày nghỉ/HS', N'Hàng tháng', N'Thi đua học sinh & Báo nghỉ', 1.0, 2.0, 3.0, '<=', NULL, N'Số ngày vắng nghỉ trung bình trong tháng của học sinh'),
    ('CM14', N'Nề nếp học sinh (cấp Trung học)', N'Giáo dục & Học thuật', 2, 14, N'Số lượt vi phạm', N'Hàng tháng', N'Thi đua học sinh & Calen', 5.0, 10.0, 20.0, '<=', NULL, N'Số lượt vi phạm nội quy học đường theo khối lớp'),
    ('CM15', N'Mức độ hoàn thành bài tập trực tuyến LMS', N'Giáo dục & Học thuật', 2, 15, N'%', N'Hàng tháng', N'LMS Học tập (https://lms.lhbs.vn/)', 80.0, 75.0, 60.0, '>=', NULL, N'Tỷ lệ học sinh làm bài tập đúng hạn trên hệ thống LMS'),
    ('CM16', N'Kết quả rèn luyện học tập định kỳ', N'Giáo dục & Học thuật', 2, 16, N'% Khá Giỏi', N'Học kỳ', N'LMS & Học bạ điện tử', 85.0, 75.0, 65.0, '>=', NULL, N'Tỷ lệ HS xếp loại học lực Khá, Giỏi theo quy chế Bộ GD&ĐT'),
    ('CM17', N'Tỷ lệ học sinh đạt mức "Thành thạo" khung năng lực', N'Giáo dục & Học thuật', 2, 17, N'%', N'Học kỳ', N'LMS & Khung năng lực LHBS', 80.0, 70.0, 60.0, '>=', N'KPI 1.2.1', N'Tỷ lệ HS đạt mức Thành thạo trở lên về STEM, AI và Số (Mục tiêu >= 80%)'),
    ('CM18', N'Tỷ lệ hoàn thành mục tiêu độ tuổi (Mầm non)', N'Giáo dục & Học thuật', 2, 18, N'%', N'Học kỳ', N'BGH Mầm non & Sổ phát triển trẻ', 100.0, 95.0, 90.0, '>=', NULL, N'Tỷ lệ trẻ đạt chuẩn phát triển thể chất, ngôn ngữ và sẵn sàng vào Lớp 1'),
    ('CM19', N'Giải thưởng Dự án, Cuộc thi Học thuật & STEM', N'Giáo dục & Học thuật', 2, 19, N'Giải thưởng', N'Năm học', N'Ban Chuyên môn & PTLC', 15.0, 10.0, 5.0, '>=', N'KPI 2.1.2', N'Tổng số giải thưởng STEM, Robotics, AI cấp tỉnh, quốc gia, quốc tế (+5 giải/năm)'),
    ('CM20', N'Tỷ lệ trúng tuyển Đại học (Khối 12)', N'Giáo dục & Học thuật', 2, 20, N'%', N'Năm học', N'Giáo vụ & Khảo sát cựu HS', 98.0, 95.0, 90.0, '>=', N'KPI 2', N'Số HS lớp 12 trúng tuyển ĐH trong nước và quốc tế'),
    ('CM21', N'Tỷ lệ Du học nước ngoài (cấp THPT)', N'Giáo dục & Học thuật', 2, 21, N'%', N'Năm học', N'Basic Data & Đối ngoại', 50.0, 40.0, 30.0, '>=', N'KPI 3.2.2', N'Tỷ lệ học sinh tốt nghiệp chọn đi du học quốc tế (> 50%)'),
    ('CM22', N'Chương trình giáo dục quốc tế (Song bằng/Cambridge)', N'Giáo dục & Học thuật', 2, 22, N'% Học sinh', N'Hàng tháng', N'BGH PTLC & Tuyển sinh QT', 10.0, 5.0, 2.0, '>=', N'KPI 1.1.2', N'Số học sinh theo học lộ trình song ngữ quốc tế (Mục tiêu 10% đến 2030)'),
    ('CM23', N'Tỷ lệ hài lòng của PHHS về mức độ tiến bộ của HS', N'Giáo dục & Học thuật', 2, 23, N'%', N'Học kỳ', N'Hệ thống QA (https://qa.lhbs.vn/)', 90.0, 85.0, 80.0, '>=', N'KPI 1.2.2', N'Tỷ lệ phụ huynh đánh giá mức Hài lòng trở lên (> 90%)'),
    ('CM24', N'Số lượt giao lưu văn hóa & học thuật quốc tế', N'Giáo dục & Học thuật', 2, 24, N'Lượt', N'Năm học', N'Ban Giám Hiệu & Đối ngoại', 20.0, 15.0, 10.0, '>=', N'KPI 2.2.1', N'Số lượng đoàn GV, HS quốc tế giao lưu tại LHBS (Mục tiêu 20 lượt/năm)'),
    ('CM25', N'Liên minh STEM các cơ sở giáo dục', N'Giáo dục & Học thuật', 2, 25, N'% Cơ sở', N'Năm học', N'BGH & Ban Điều Hành', 10.0, 8.0, 5.0, '>=', N'KPI 2.2.2', N'Tỷ lệ cơ sở giáo dục tại Đồng Nai tham gia mạng lưới STEM LHBS'),
    ('CM26', N'Kiểm định chất lượng giáo dục ISO 21001:2018', N'Giáo dục & Học thuật', 2, 26, N'Chứng nhận', N'Năm học', N'Ban ISO & Ban Đảm bảo chất lượng', 1.0, 1.0, 0.0, '>=', N'KPI 3.1.1', N'Đạt chứng nhận tiêu chuẩn hệ thống quản lý giáo dục ISO 21001'),
    ('CM27', N'Kiểm định chất lượng giáo dục quốc tế', N'Giáo dục & Học thuật', 2, 27, N'Chứng nhận', N'Năm học', N'Ban Giám Hiệu & Tổ chức kiểm định', 1.0, 1.0, 0.0, '>=', N'KPI 1.1.1', N'Kiểm định chất lượng theo chuẩn kiểm định giáo dục quốc tế'),

    -- ==============================================================================
    -- NHÓM 3: DỊCH VỤ BÁN TRÚ, AN TOÀN & CHĂM SÓC HỌC SINH (24 CHỈ TIÊU: DV28–DV51)
    -- ==============================================================================
    ('DV28', N'Chất lượng dịch vụ Bếp ăn & Bán trú', N'Dịch vụ & An toàn', 3, 28, N'% Hài lòng', N'Cuối kỳ', N'Bán trú & Hệ thống QA', 90.0, 85.0, 80.0, '>=', NULL, N'Tỷ lệ hài lòng của PH/HS và nội bộ về chất lượng bữa ăn'),
    ('DV29', N'Số vụ sự cố ngộ độc thực phẩm trong trường', N'Dịch vụ & An toàn', 3, 29, N'Vụ', N'Hàng tháng', N'Bếp ăn & Y tế học đường', 0.0, 0.0, 1.0, '<=', NULL, N'Chỉ tiêu sống còn: Duy trì 0 vụ ngộ độc thực phẩm (ISO 22000)'),
    ('DV30', N'Chứng nhận An toàn thực phẩm ISO 22000:2018', N'Dịch vụ & An toàn', 3, 30, N'Chứng nhận', N'Năm học', N'Ban ISO & Bếp ăn', 1.0, 1.0, 0.0, '>=', N'KPI 3.1.2', N'Đạt và duy trì chứng nhận an toàn thực phẩm ISO 22000'),
    ('DV31', N'Bộ tiêu chí đánh giá nhà cung cấp thực phẩm', N'Dịch vụ & An toàn', 3, 31, N'% Đạt', N'Năm học', N'Bộ phận Mua sắm & Bếp', 100.0, 95.0, 90.0, '>=', NULL, N'100% nhà cung ứng thực phẩm đạt tiêu chuẩn an toàn truy xuất nguồn gốc'),
    ('DV32', N'Ban hành Sổ tay Vệ sinh An toàn thực phẩm', N'Dịch vụ & An toàn', 3, 32, N'Bộ', N'Năm học', N'Ban ISO & Bán trú', 1.0, 1.0, 0.0, '>=', NULL, N'Chuẩn hóa sổ tay quy trình vận hành và kiểm soát rủi ro bếp ăn'),
    ('DV33', N'Tỷ lệ nhân sự được tập huấn VSATTP', N'Dịch vụ & An toàn', 3, 33, N'%', N'Hàng năm', N'Bếp ăn & Y tế', 100.0, 100.0, 90.0, '>=', NULL, N'100% nhân sự cấp dưỡng và phục vụ bữa ăn được đào tạo chứng chỉ'),
    ('DV34', N'Số lượt học sinh sử dụng dịch vụ ăn sáng', N'Dịch vụ & An toàn', 3, 34, N'Học sinh', N'Hàng tháng', N'Bán trú & Học phí FTS', 500.0, 450.0, 400.0, '>=', NULL, N'Quy mô học sinh đăng ký dịch vụ ăn sáng bán trú'),
    ('DV35', N'Số lượng học sinh sử dụng dịch vụ xe đưa rước', N'Dịch vụ & An toàn', 3, 35, N'Học sinh', N'Hàng tháng', N'Tổ Xe Bus & Học phí FTS', 250.0, 220.0, 180.0, '>=', NULL, N'Tổng số học sinh các tuyến xe bus đưa đón hàng ngày'),
    ('DV36', N'Hiệu quả tài chính dịch vụ xe đưa rước', N'Dịch vụ & An toàn', 3, 36, N'% Biên LN', N'Hàng tháng', N'Kế toán FTS & Tổ Xe Bus', 15.0, 12.0, 10.0, '>=', NULL, N'(Doanh thu bus - Chi phí thuê xe - Chi phí giám sát) / Doanh thu bus'),
    ('DV37', N'An toàn dịch vụ đưa rước học sinh', N'Dịch vụ & An toàn', 3, 37, N'% Chuẩn', N'Hàng tháng', N'Tổ Xe Bus & Sổ nhật ký tuyến', 100.0, 99.0, 98.0, '>=', NULL, N'Tỷ lệ chuyến xe đúng giờ, điểm danh đủ học sinh, 0 vi phạm an toàn'),
    ('DV38', N'Sự cố tai nạn thương tích học đường, dị ứng, y tế', N'Dịch vụ & An toàn', 3, 38, N'Vụ', N'Hàng tháng', N'Y tế học đường (https://yte.lhbs.vn/)', 0.0, 0.0, 1.0, '<=', NULL, N'Chỉ tiêu sống còn: Duy trì 0 vụ tai nạn thương tích nghiêm trọng'),
    ('DV39', N'Tỷ lệ hoàn thành khám sức khỏe định kỳ học sinh', N'Dịch vụ & An toàn', 3, 39, N'%', N'Học kỳ', N'Y tế học đường (https://yte.lhbs.vn/)', 100.0, 98.0, 95.0, '>=', NULL, N'Tỷ lệ học sinh được khám sức khỏe đầu năm và lập hồ sơ theo dõi'),
    ('DV40', N'Báo cáo chỉ số BMI lệch chuẩn của học sinh', N'Dịch vụ & An toàn', 3, 40, N'% Lệch', N'Hàng tháng', N'Y tế học đường (https://yte.lhbs.vn/)', 8.0, 10.0, 15.0, '<=', NULL, N'Tỷ lệ học sinh có chỉ số BMI ngoài ngưỡng độ tuổi (chuẩn WHO)'),
    ('DV41', N'Tối ưu hóa ngân sách y tế trên mỗi Học sinh', N'Dịch vụ & An toàn', 3, 41, N'% Định mức', N'Hàng tháng', N'Kế toán & Y tế', 100.0, 100.0, 110.0, '<=', NULL, N'Kiểm soát chi phí thuốc men và vật tư y tế trong định mức duyệt'),
    ('DV42', N'Tỷ lệ đáp ứng đồng phục, sách vở đúng & đủ đầu năm', N'Dịch vụ & An toàn', 3, 42, N'%', N'Đầu năm', N'Dịch vụ bán lẻ PM FTS', 98.0, 95.0, 90.0, '>=', NULL, N'Tỷ lệ học sinh nhận đủ đồng phục, sách vở trước ngày khai giảng'),
    ('DV43', N'Tỷ lệ sản phẩm đồng phục lỗi / đổi trả', N'Dịch vụ & An toàn', 3, 43, N'%', N'Hàng tháng', N'Dịch vụ bán lẻ PM FTS', 1.0, 2.0, 3.0, '<=', NULL, N'Tỷ lệ đồng phục bị lỗi đường may, sai size phải đổi trả'),
    ('DV44', N'Độ hài lòng PHHS về đồng phục & sách vở', N'Dịch vụ & An toàn', 3, 44, N'%', N'Hàng tháng', N'Hệ thống QA (https://qa.lhbs.vn/)', 95.0, 90.0, 85.0, '>=', NULL, N'Tỷ lệ phụ huynh hài lòng về chất liệu, độ bền và tính thẩm mỹ'),
    ('DV45', N'Biên lợi nhuận gộp bán lẻ đồng phục & sách', N'Dịch vụ & An toàn', 3, 45, N'%', N'Hàng tháng', N'Kế toán FTS phân hệ bán lẻ', 30.0, 28.0, 25.0, '>=', NULL, N'Tỷ suất lợi nhuận gộp mảng bán lẻ đồng phục, đồ dùng học tập'),
    ('DV46', N'Tỷ lệ hàng tồn kho đồng phục & sách giáo khoa', N'Dịch vụ & An toàn', 3, 46, N'%', N'Hàng tháng', N'Kho vận & Kế toán FTS', 10.0, 15.0, 20.0, '<=', NULL, N'Giá trị hàng tồn kho cuối kỳ / Tổng giá trị nhập hàng'),
    ('DV47', N'Tỷ lệ giao hàng đúng hạn (OTD) của nhà cung cấp', N'Dịch vụ & An toàn', 3, 47, N'%', N'Hàng tháng', N'Bộ phận Mua sắm PM FTS', 98.0, 95.0, 90.0, '>=', NULL, N'Số đơn hàng mua sắm/trang thiết bị giao đúng tiến độ hợp đồng'),
    ('DV48', N'Thời gian xử lý PR/PO mua sắm trang thiết bị', N'Dịch vụ & An toàn', 3, 48, N'Ngày', N'Hàng tháng', N'Bộ phận Mua sắm PM FTS', 3.0, 5.0, 7.0, '<=', N'KPI 5', N'Thời gian từ khi trình yêu cầu mua sắm đến khi duyệt đơn hàng PO'),
    ('DV49', N'Tỷ lệ tiết kiệm chi phí mua sắm qua đấu thầu', N'Dịch vụ & An toàn', 3, 49, N'%', N'Hàng tháng', N'Bộ phận Mua sắm & Kế toán', 5.0, 3.0, 1.0, '>=', NULL, N'Giá trị thương lượng tiết kiệm được so với dự toán ban đầu'),
    ('DV50', N'Mức độ hài lòng chung của Phụ huynh học sinh', N'Dịch vụ & An toàn', 3, 50, N'%', N'Học kỳ', N'Bộ phận CSKH & QA', 92.0, 90.0, 85.0, '>=', N'KPI 6', N'Tỷ lệ PHHS đánh giá mức Đạt trở lên về chất lượng tổng thể (> 90%)'),
    ('DV51', N'Tỷ lệ xử lý Khiếu nại PHHS đúng hạn cam kết', N'Dịch vụ & An toàn', 3, 51, N'%', N'Hàng tháng', N'Bộ phận CSKH & Hotline', 95.0, 90.0, 80.0, '>=', NULL, N'Tỷ lệ khiếu nại, phản ánh được giải quyết trong 24–48 giờ'),

    -- ==============================================================================
    -- NHÓM 4: TÀI CHÍNH, NHÂN SỰ & VẬN HÀNH CSVC (9 CHỈ TIÊU: TC52–TC60)
    -- ==============================================================================
    ('TC52', N'Tỷ lệ biến động nhân sự (Turnover Rate)', N'Tài chính & CSVC', 4, 52, N'%', N'Hàng tháng', N'Phòng Nhân sự HRM', 2.0, 3.0, 5.0, '<=', NULL, N'Số GV/NV nghỉ việc trong tháng / Tổng nhân sự bình quân'),
    ('TC53', N'Tỷ lệ lấp đầy vị trí tuyển dụng định biên', N'Tài chính & CSVC', 4, 53, N'%', N'Hàng tháng', N'Phòng Nhân sự HRM', 98.0, 95.0, 90.0, '>=', NULL, N'Số vị trí tuyển đủ / Tổng nhu cầu định biên giáo viên và nhân viên'),
    ('TC54', N'Số lượt vắng nghỉ, trễ của khối nhân viên', N'Tài chính & CSVC', 4, 54, N'Số buổi', N'Hàng tháng', N'HRM & Máy chấm công', 5.0, 10.0, 20.0, '<=', NULL, N'Tổng hợp số buổi vắng nghỉ, đi trễ của khối văn phòng và dịch vụ'),
    ('TC55', N'Tỷ suất lợi nhuận gộp dịch vụ trường học', N'Tài chính & CSVC', 4, 55, N'%', N'Hàng tháng', N'Kế toán PM FTS (Học phí & Dịch vụ)', 50.0, 48.0, 40.0, '>=', N'KPI 4', N'Chỉ tiêu tập đoàn Holding: Lợi nhuận gộp dịch vụ đạt tối thiểu 50%'),
    ('TC56', N'Doanh thu các Câu lạc bộ ngoại khóa bổ trợ', N'Tài chính & CSVC', 4, 56, N'triệu VNĐ', N'Hàng tháng', N'Kế toán PM FTS & Ban Chuyên môn', 1500.0, 1200.0, 1000.0, '>=', N'KPI 3.2.1', N'Doanh thu CLB STEM, Robotics, AI, Lập trình (Mục tiêu tích lũy $1M)'),
    ('TC57', N'Thời gian xử lý Thủ tục hành chính điện tử', N'Tài chính & CSVC', 4, 57, N'Giờ', N'Học kỳ', N'Khối CNTT & eSignature', 12.0, 24.0, 48.0, '<=', N'KPI 5', N'Mức độ giảm 50% thời gian xử lý thủ tục hành chính sau khi số hóa eSign'),
    ('TC58', N'Mức độ ổn định hệ thống phần mềm (Uptime)', N'Tài chính & CSVC', 4, 58, N'% Uptime', N'Hàng tháng', N'CNTT Quản trị hệ thống', 99.5, 99.0, 98.0, '>=', NULL, N'Tỷ lệ Uptime của các phần mềm quản lý (HRM, BasicData, LMS, FTS)'),
    ('TC59', N'Số lượng sự cố CSVC phòng học tồn đọng', N'Tài chính & CSVC', 4, 59, N'Ticket', N'Hàng tháng', N'Quản lý tài sản CSVC Helpdesk', 5.0, 10.0, 20.0, '<=', NULL, N'Số ticket báo hỏng điều hòa, đèn, máy chiếu chưa xử lý quá 24h'),
    ('TC60', N'Tỷ lệ hoàn thành bảo trì phòng ngừa CSVC', N'Tài chính & CSVC', 4, 60, N'%', N'Hàng tháng', N'Quản lý tài sản CSVC', 100.0, 95.0, 90.0, '>=', NULL, N'Tỷ lệ hoàn thành kiểm tra bảo dưỡng định kỳ hệ thống điện lạnh, sân bãi');
END;

-- 2. SEED NGƯỠNG CHUẨN TOÀN TRƯỜNG & GHI ĐÈ 5 ĐƠN VỊ VÀO tblKPI_Thresholds
-- Seed Ngưỡng chuẩn toàn trường (ScopeID = 'ALL') từ tblKPI_Definitions
INSERT INTO tblKPI_Thresholds (KpiCode, ScopeType, ScopeID, PeriodKey, TargetValue, WarnThreshold, CriticalThreshold, ComparisonOperator, StatusGoodLabel, StatusWarnLabel, StatusBadLabel, Description)
SELECT 
    d.KpiCode,
    'SYSTEM',
    'ALL',
    'ALL',
    ISNULL(d.DefaultTarget, 100),
    ISNULL(d.DefaultWarn, 90),
    ISNULL(d.DefaultCritical, 80),
    d.DefaultOperator,
    CASE WHEN d.DefaultOperator IN ('<=', '<') THEN N'AN TOÀN' ELSE N'ĐẠT CHỈ TIÊU' END,
    N'THEO DÕI',
    CASE WHEN d.DefaultOperator IN ('<=', '<') THEN N'CẢNH BÁO' ELSE N'CHƯA ĐẠT' END,
    N'Chuẩn toàn trường mặc định: ' + d.KpiName
FROM tblKPI_Definitions d
WHERE NOT EXISTS (SELECT 1 FROM tblKPI_Thresholds WHERE KpiCode = d.KpiCode AND ScopeID = 'ALL');

-- Seed Ghi đè đặc thù cho TS01 (Sĩ số) và TS02 (Lấp đầy) theo 5 cơ sở
IF NOT EXISTS (SELECT 1 FROM tblKPI_Thresholds WHERE KpiCode = 'TS01' AND ScopeID = 'MNTB')
BEGIN
    INSERT INTO tblKPI_Thresholds (KpiCode, ScopeType, ScopeID, PeriodKey, TargetValue, WarnThreshold, CriticalThreshold, ComparisonOperator, StatusGoodLabel, StatusBadLabel, Description)
    VALUES
    ('TS01', 'CAMPUS', 'MNTB', 'ALL', 406.0, 380.0, 350.0, '>=', N'ĐẠT CHỈ TIÊU', N'CHƯA ĐẠT', N'Sĩ số kế hoạch MN Trấn Biên (406 HS)'),
    ('TS01', 'CAMPUS', 'MNLK', 'ALL', 160.0, 140.0, 120.0, '>=', N'ĐẠT CHỈ TIÊU', N'CHƯA ĐẠT', N'Sĩ số kế hoạch MN Long Khánh (160 HS)'),
    ('TS01', 'CAMPUS', 'TH', 'ALL', 1080.0, 1020.0, 950.0, '>=', N'ĐẠT CHỈ TIÊU', N'CHƯA ĐẠT', N'Sĩ số kế hoạch Tiểu học (1080 HS)'),
    ('TS01', 'CAMPUS', 'THCS', 'ALL', 650.0, 620.0, 580.0, '>=', N'ĐẠT CHỈ TIÊU', N'CHƯA ĐẠT', N'Sĩ số kế hoạch THCS (650 HS)'),
    ('TS01', 'CAMPUS', 'THPT', 'ALL', 480.0, 450.0, 400.0, '>=', N'ĐẠT CHỈ TIÊU', N'CHƯA ĐẠT', N'Sĩ số kế hoạch THPT (480 HS)');
END;

-- 3. SEED ĐẦY ĐỦ THAM SỐ VẬN HÀNH CHO 5 CƠ SỞ VÀO tblKPI_Parameters
-- Sĩ số thiết kế tối đa (PlannedCapacity)
IF NOT EXISTS (SELECT 1 FROM tblKPI_Parameters WHERE ParamCode = 'PlannedCapacity')
BEGIN
    INSERT INTO tblKPI_Parameters (ParamCode, ScopeType, ScopeID, PeriodKey, ParamValue, ParamStringValue, Description)
    VALUES
    ('PlannedCapacity', 'CAMPUS', 'ALL', 'ALL', 2810.0, N'2.810 HS', N'Tổng công suất thiết kế toàn trường'),
    ('PlannedCapacity', 'CAMPUS', 'MNTB', 'ALL', 406.0, N'406 HS', N'Công suất thiết kế MN Trấn Biên'),
    ('PlannedCapacity', 'CAMPUS', 'MNLK', 'ALL', 166.0, N'166 HS', N'Công suất thiết kế MN Long Khánh'),
    ('PlannedCapacity', 'CAMPUS', 'TH', 'ALL', 1050.0, N'1.050 HS', N'Công suất thiết kế Tiểu học'),
    ('PlannedCapacity', 'CAMPUS', 'THCS', 'ALL', 650.0, N'650 HS', N'Công suất thiết kế THCS'),
    ('PlannedCapacity', 'CAMPUS', 'THPT', 'ALL', 480.0, N'480 HS', N'Công suất thiết kế THPT');
END;

-- Phí suất ăn bán trú hàng tháng (MealFeeMonthly)
IF NOT EXISTS (SELECT 1 FROM tblKPI_Parameters WHERE ParamCode = 'MealFeeMonthly')
BEGIN
    INSERT INTO tblKPI_Parameters (ParamCode, ScopeType, ScopeID, PeriodKey, ParamValue, ParamStringValue, Description)
    VALUES
    ('MealFeeMonthly', 'SYSTEM', 'ALL', 'ALL', 1.65, N'1.65 tr/tháng', N'Phí suất ăn bán trú & ăn sáng bình quân'),
    ('MealFeeMonthly', 'CAMPUS', 'MNLK', 'ALL', 1.45, N'1.45 tr/tháng', N'Phí suất ăn mầm non Long Khánh'),
    ('MealFeeMonthly', 'CAMPUS', 'MNTB', 'ALL', 1.55, N'1.55 tr/tháng', N'Phí suất ăn mầm non Trấn Biên'),
    ('MealFeeMonthly', 'CAMPUS', 'TH', 'ALL', 1.65, N'1.65 tr/tháng', N'Phí suất ăn Tiểu học'),
    ('MealFeeMonthly', 'CAMPUS', 'THCS', 'ALL', 1.75, N'1.75 tr/tháng', N'Phí suất ăn THCS'),
    ('MealFeeMonthly', 'CAMPUS', 'THPT', 'ALL', 1.85, N'1.85 tr/tháng', N'Phí suất ăn THPT');
END;
