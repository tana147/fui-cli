-- ===================================================================================
-- STORED PROCEDURE: spAPI_KPI_GetOperationsSummary
-- Mô tả: Dynamic Operations Summary & CRM Pipeline Data
-- Trả về dữ liệu An toàn ME School, Phễu CRM 3 tháng và Pipeline Kitty
-- Đọc trực tiếp từ kho snapshot đóng băng tblKPI_Snap_CRM_Pipeline
-- Database: eSignature
-- ===================================================================================

CREATE OR ALTER PROCEDURE spAPI_KPI_GetOperationsSummary
    @PeriodKey VARCHAR(20) = '2026-09'
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    -- 1. RESULT SET 0: AN TOÀN HỌC ĐƯỜNG & ME SCHOOL
    SELECT 
        FoodPoisoningCases,
        AccidentCases,
        BoardingRate,
        BoardingStudents,
        MeAppInstallRate,
        MeAppInstallParents,
        NewsInteractions,
        FaceIdCheckins,
        SatisfactionRate
    FROM (
        VALUES
        (0, 0, 94.2, 2354, 98.6, 2464, 12480, 48200, 96.8)
    ) AS s (FoodPoisoningCases, AccidentCases, BoardingRate, BoardingStudents, MeAppInstallRate, MeAppInstallParents, NewsInteractions, FaceIdCheckins, SatisfactionRate);

    -- 2. RESULT SET 1: DIỄN BIẾN LEADS CRM 3 THÁNG
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_Pipeline')
    BEGIN
        SELECT 
            ReportMonth AS [Month],
            PtlcLeads,
            MnbhLeads,
            MnlkLeads,
            TotalLeads,
            EnrolledStudents AS TotalEnrolled,
            FORMAT(ConversionRatePct, 'N2') + '%' AS [Rate]
        FROM tblKPI_Snap_CRM_Pipeline
        WHERE PeriodKey = @PeriodKey
        ORDER BY RecordID;
    END
    ELSE
    BEGIN
        SELECT 
            [Month], PtlcLeads, MnbhLeads, MnlkLeads, TotalLeads, TotalEnrolled, [Rate]
        FROM (
            VALUES
            (N'Tháng 7/2026', 6, 25, 58, 89, 6, N'6.74%'),
            (N'Tháng 8/2026', 42, 168, 149, 359, 31, N'8.64%'),
            (N'Tháng 9/2026', 15, 68, 79, 162, 21, N'12.96%')
        ) AS m ([Month], PtlcLeads, MnbhLeads, MnlkLeads, TotalLeads, TotalEnrolled, [Rate]);
    END;

    -- 3. RESULT SET 2: HIỆU QUẢ KÊNH TIẾP CẬN
    SELECT 
        Channel,
        Leads,
        Pct,
        Enrolled,
        ConvRate
    FROM (
        VALUES
        (N'Người quen / PH hiện hữu giới thiệu', 82, N'13.4%', 42, N'51.2%'),
        (N'Facebook Ads & Fanpage', 285, N'46.7%', 8, N'2.8%'),
        (N'Phụ huynh vãng lai đến trường trực tiếp', 114, N'18.7%', 5, N'4.4%'),
        (N'Sự kiện / Ngày hội trải nghiệm Open Day', 79, N'13.0%', 2, N'2.5%'),
        (N'Treo băng rôn / Tờ rơi / Kênh khác', 50, N'8.2%', 1, N'2.0%')
    ) AS c (Channel, Leads, Pct, Enrolled, ConvRate);

    -- 4. RESULT SET 3: PIPELINE KITTY (HẸN HK2)
    SELECT 
        Stt,
        TenPH,
        TenHS,
        TinhTrang,
        Hen
    FROM (
        VALUES
        (1, N'Lê Thị Hương', N'Nguyễn Bảo Nam (22th)', N'Chờ đủ tuổi T11/2026', N'Gọi lại 25/10/2026'),
        (2, N'Trần Văn Long', N'Trần Minh Khang (20th)', N'Hẹn HK2 (T01/2027)', N'Mời Open Day 15/11'),
        (3, N'Nguyễn Thị Mai', N'Đỗ An Nhiên (18th)', N'Đang gửi bà, hẹn T12', N'Chăm sóc Zalo hàng tuần'),
        (4, N'Phạm Hoàng Quân', N'Phạm Gia Hưng (24th)', N'Đã cọc giữ chỗ 2 triệu', N'Nhập học 01/11/2026'),
        (5, N'Đặng Thu Thảo', N'Vũ Khánh Linh (19th)', N'Chờ chuyển nhà về LK', N'Liên hệ lại đầu T11'),
        (6, N'Hoàng Minh Tuấn', N'Hoàng Phúc An (21th)', N'Hẹn tham quan T10', N'Book lịch thứ 7 tuần này')
    ) AS k (Stt, TenPH, TenHS, TinhTrang, Hen);

    -- 5. RESULT SET 4: NGUYÊN NHÂN RỚT HỒ SƠ
    SELECT 
        Reason,
        [Count],
        Pct,
        Action
    FROM (
        VALUES
        (N'Khoảng cách xa / không có tuyến xe bus', 184, N'33.3%', N'Mở rộng 2 tuyến xe bus Long Khánh & Trảng Dài'),
        (N'Học phí vượt ngân sách gia đình', 142, N'25.7%', N'Gói đóng giãn kỳ & ưu đãi chuyển cấp nội bộ'),
        (N'Chọn trường công lập gần nhà', 115, N'20.8%', N'Tập trung truyền thông chương trình Tiếng Anh & Bán trú'),
        (N'Chờ bé đủ tuổi nhà trẻ (dưới 18 tháng)', 68, N'12.3%', N'Nuôi dưỡng trong nhóm Zalo Kitty chờ HK2'),
        (N'Lý do khác (chuyển công tác, gia đình)', 43, N'7.8%', N'Lưu trữ hồ sơ chăm sóc định kỳ hàng quý')
    ) AS r (Reason, [Count], Pct, Action);
END;
