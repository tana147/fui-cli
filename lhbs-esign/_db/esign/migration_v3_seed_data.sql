-- ===================================================================================
-- SEED DATA V3: DỮ LIỆU ĐÓNG BĂNG THÁNG 9 & KHỞI TẠO THÁNG 10
-- Database: eSignature
-- ===================================================================================

-- 1. SEED tblKPI_Snap_Safety_Me CHO THÁNG 09/2026
DELETE FROM tblKPI_Snap_Safety_Me WHERE PeriodKey = '2026-09';
INSERT INTO tblKPI_Snap_Safety_Me (
    PeriodKey, ScopeID, FoodPoisoningCases, AccidentCases, BoardingRate, BoardingStudents,
    MeAppInstallRate, MeAppInstallParents, NewsInteractions, FaceIdCheckins, SatisfactionRate, Note
) VALUES (
    '2026-09', 'ALL', 0, 0, 94.2, 2354, 98.6, 2464, 12480, 48200, 96.8, N'Chốt sổ Tháng 9/2026 ISO 22000'
);

-- 2. SEED tblKPI_Snap_CRM_Channels CHO THÁNG 09/2026
DELETE FROM tblKPI_Snap_CRM_Channels WHERE PeriodKey = '2026-09';
INSERT INTO tblKPI_Snap_CRM_Channels (
    PeriodKey, ScopeID, ChannelName, LeadsCount, LeadsPct, EnrolledCount, ConvRatePct, RankOrder
) VALUES 
('2026-09', 'ALL', N'Facebook Fanpage / Ads', 521, 85.4, 34, 6.5, 1),
('2026-09', 'ALL', N'Người quen / PH hiện hữu giới thiệu', 22, 3.6, 12, 54.5, 2),
('2026-09', 'ALL', N'Nhận diện thương hiệu (Vãng lai đến trường)', 28, 4.6, 6, 21.4, 3),
('2026-09', 'ALL', N'Phụ huynh LHBS hiện hữu', 15, 2.5, 5, 33.3, 4),
('2026-09', 'ALL', N'Cán bộ GV / Nhân viên', 11, 1.8, 4, 36.4, 5),
('2026-09', 'ALL', N'Đại sứ / Sự kiện trải nghiệm Open Day', 8, 1.3, 0, 0.0, 6),
('2026-09', 'ALL', N'Zalo / Hotline tiếp nhận', 5, 0.8, 1, 20.0, 7);

-- 3. SEED tblKPI_Snap_CRM_DropReasons CHO THÁNG 09/2026
DELETE FROM tblKPI_Snap_CRM_DropReasons WHERE PeriodKey = '2026-09';
INSERT INTO tblKPI_Snap_CRM_DropReasons (
    PeriodKey, ScopeID, ReasonText, ReasonCount, ReasonPct, SolutionAction, RankOrder
) VALUES 
('2026-09', 'ALL', N'Liên hệ / nhắn tin 3 lần không phản hồi', 414, 75.0, N'Chuyển Cold Leads, gửi tin Zalo định kỳ', 1),
('2026-09', 'ALL', N'Bé chưa đủ tuổi đi học (Chờ HK2)', 22, 4.0, N'Đưa vào danh sách chăm sóc nuôi dưỡng Kitty HK2', 2),
('2026-09', 'ALL', N'Phụ huynh tham khảo thông tin trước', 8, 1.4, N'Gửi tài liệu chương trình học và bảng phí', 3),
('2026-09', 'ALL', N'Ngoài tuyến xe đưa đón học sinh', 4, 0.7, N'Khảo sát mở rộng điểm đón tuyến mới Long Khánh & Trảng Dài', 4),
('2026-09', 'ALL', N'Học phí cao / Chưa có chính sách ưu đãi', 3, 0.5, N'Áp dụng học bổng hoặc đóng phí theo đợt', 5),
('2026-09', 'ALL', N'Không đạt quy chế / Từ chối khảo sát', 5, 0.9, N'Tư vấn lộ trình bồi dưỡng trước nhập học', 6);

-- 4. SEED tblKPI_Snap_CRM_Prospects CHO THÁNG 09/2026 (15 HỒ SƠ CHỜ HK2)
DELETE FROM tblKPI_Snap_CRM_Prospects WHERE PeriodKey = '2026-09';
INSERT INTO tblKPI_Snap_CRM_Prospects (
    PeriodKey, ScopeID, CampaignCode, Stt, MonthLabel, ParentName, ClassOrTarget, StudentName, StatusDescription, AppointmentNote, RankOrder
) VALUES 
('2026-09', 'ALL', 'KITTY_HK2', 87, N'T08/2026', N'Kiều Anh Vũ', N'Kitty', N'Bé sinh 01/2025', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 01/2027 liên hệ lại', 1),
('2026-09', 'ALL', 'KITTY_HK2', 107, N'T08/2026', N'Khánh Linh', N'Kitty', N'Nguyễn Ngọc Nhã Vy (01/2025)', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 01/2027 liên hệ lại', 2),
('2026-09', 'ALL', 'KITTY_HK2', 117, N'T08/2026', N'Bích Nguyệt', N'Kitty', N'Nguyễn Minh Anh (02/01/2026)', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 01/2027 liên hệ lại', 3),
('2026-09', 'ALL', 'KITTY_HK2', 118, N'T08/2026', N'Nguyễn Thủy Tiên', N'Kitty', N'Bé sinh 12/2025', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 01/2027 liên hệ lại', 4),
('2026-09', 'ALL', 'KITTY_HK2', 121, N'T08/2026', N'Như Loan', N'Kitty', N'Bé sinh 02/2025', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 02/2027 liên hệ lại', 5),
('2026-09', 'ALL', 'KITTY_HK2', 164, N'T09/2026', N'Con cô Như Vy (GV)', N'Kitty', N'Võ Chí Kiên (22/04/2025)', N'Chưa đủ tuổi (Hẹn HK2)', N'Dự kiến 06/2027 đi học', 6),
('2026-09', 'ALL', 'KITTY_HK2', 168, N'T09/2026', N'Dược Huỳnh', N'Kitty', N'Bé sinh 02/2025', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 11/2026 liên hệ lại', 7),
('2026-09', 'ALL', 'KITTY_HK2', 174, N'T09/2026', N'Con thầy Kim Cương (GV)', N'Kitty', N'Dương Kim Trọng (28/10/2025)', N'Đã tư vấn xong (Nhập học T10)', N'Tháng 10/2026 làm hồ sơ', 8),
('2026-09', 'ALL', 'KITTY_HK2', 176, N'T09/2026', N'Con cô Anh Thư (GV)', N'Kitty', N'Mai Hoàng Khánh An (10/2025)', N'Đã tư vấn xong (Nhập học T10)', N'Tháng 10/2026 làm hồ sơ', 9),
('2026-09', 'ALL', 'KITTY_HK2', 109, N'T02/2026', N'Nguyễn Đỗ Thúy Ngân', N'Kitty', N'Nguyễn Thùy Tiên (06/2025)', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 12/2026 liên hệ lại', 10),
('2026-09', 'ALL', 'KITTY_HK2', 130, N'T03/2026', N'Trương Mỹ Hoa', N'Kitty', N'Minh Đăng (03/02/2025)', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 02/2027 liên hệ lại', 11),
('2026-09', 'ALL', 'KITTY_HK2', 476, N'T06/2026', N'Ninh Nguyễn Xuân', N'Kitty', N'Bé sinh 01/2026', N'Chưa đủ tuổi (Hẹn HK2)', N'Tuyển sinh HK2 liên hệ', 12),
('2026-09', 'ALL', 'KITTY_HK2', 479, N'T06/2026', N'Nguyễn Rosa', N'Kitty', N'Bé sinh 11/2025', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 11/2026 liên hệ lại', 13),
('2026-09', 'ALL', 'KITTY_HK2', 528, N'T07/2026', N'Tâm Như', N'Kitty', N'Bé sinh 14/12/2025', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 12/2026 nhập học', 14),
('2026-09', 'ALL', 'KITTY_HK2', 550, N'T07/2026', N'Chị Đài', N'Kitty', N'Nguyễn Trần Khánh Ngọc (07/2025)', N'Chưa đủ tuổi (Hẹn HK2)', N'Tháng 12/2026 liên hệ lại', 15);
