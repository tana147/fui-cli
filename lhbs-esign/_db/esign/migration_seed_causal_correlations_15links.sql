-- Cập nhật tblKPI_Correlations cho kỳ Tháng 9/2026 với 15 liên kết đa chiều
DELETE FROM tblKPI_Correlations WHERE PeriodKey = '2026-09';

INSERT INTO tblKPI_Correlations 
(PeriodKey, ChainGroup, CauseKpiCode, CauseKpiName, EffectKpiCode, EffectKpiName, RelationshipType, Description, QuantifiedImpact, RecommendedAction, ResponsibleRole, SortOrder)
VALUES
-- Chuỗi 1: Giao thông & Rút học (Linear Direct)
('2026-09', N'Chuỗi 1: Tuyến xe bus - Rút hồ sơ - Thất thu tài chính', 'BUS01', N'Tuyến xe bus & Khoảng cách di chuyển', 'TS04', N'Học sinh rút học do nơi ở xa', 'DIRECT_IMPACT', 
 N'Hạ tầng xe bus chưa phủ tuyến xa dẫn đến 21 HS rút hồ sơ (chiếm 39.6% tổng số ca rút).', 
 N'Thất thu học phí và phí xe bus ước tính 1.37 tỷ VNĐ/năm học.', 
 N'Mở thêm 2 tuyến xe bus đưa đón trọng điểm từ Long Khánh và Biên Hòa Đông.', N'Trưởng phòng Quản trị CSVC', 1),

('2026-09', N'Chuỗi 1: Tuyến xe bus - Rút hồ sơ - Thất thu tài chính', 'TS04', N'Học sinh rút học do nơi ở xa', 'TC55', N'Thất thu doanh thu học phí & dịch vụ', 'FINANCIAL_LOSS', 
 N'Mỗi học sinh rút học làm mất dòng tiền học phí và dịch vụ bán trú trung bình 65 triệu VNĐ/năm.', 
 N'Thiệt hại lũy kế 53 HS là 3.44 tỷ VNĐ nếu không tuyển bù.', 
 N'Phòng TVTS kích hoạt chiến dịch tuyển sinh bổ sung giữa kỳ.', N'Trưởng phòng Tuyển sinh', 2),

-- Chuỗi 2: CSVC & Bảo trì (Linear Direct)
('2026-09', N'Chuỗi 2: Bảo trì CSVC - Tiện nghi - Trải nghiệm học đường', 'CSVC01', N'Hỏng hóc máy lạnh & Thiết bị (79 yêu cầu)', 'QA01', N'Mức độ hài lòng tiện nghi lớp học', 'FACILITY_IMPACT', 
 N'18 yêu cầu sửa chữa máy lạnh tập trung tại Khu B và C trong tháng 9 gây ảnh hưởng việc học trong những ngày nóng.', 
 N'Còn tồn đọng 4 ticket máy lạnh chưa hoàn thành dứt điểm.', 
 N'Ký hợp đồng bảo dưỡng định kỳ toàn diện, thay thế linh kiện trước 05/10.', N'Bộ phận Bảo trì CSVC', 3),

-- Chuỗi 3: Y tế & Sức khỏe (Linear Direct)
('2026-09', N'Chuỗi 3: Y tế học đường - Chuyên cần - Kế hoạch dạy bù', 'MED01', N'Dịch bệnh Cúm A & 53 ca sốt Tiểu học', 'CM09', N'Tỷ lệ chuyên cần học sinh & Tiết dạy bù', 'HEALTH_DISRUPTION', 
 N'Ghi nhận 131 ca bệnh y tế học đường, trong đó bùng phát Cúm A tại khối 4 và 5 Tiểu học cuối tháng 9.', 
 N'Tỷ lệ vắng mặt ngắn hạn tăng 3.2% tại khối 4-5, phát sinh nhu cầu học bù trực tuyến.', 
 N'Tổ chức khử khuẩn toàn diện phòng học cuối tuần, tuyên truyền phòng dịch cho PHHS.', N'Trưởng bộ phận Y tế', 4),

-- Chuỗi 4: Phễu CRM & Chỉ tiêu Sĩ số (Linear Direct)
('2026-09', N'Chuỗi 4: Phễu Tuyển sinh - Chuyển đổi - Sĩ số hiện diện', 'CRM01', N'Leads tiếp nhận TVTS (161 leads)', 'TS06', N'Tỷ lệ chuyển đổi Leads thành học sinh (13.04%)', 'FUNNEL_CONVERSION', 
 N'Tháng 9 thu hút 161 leads, chuyển đổi thành công 21 học sinh nhập mới (MNLK 10, MNBH 7, PTLC 4).', 
 N'Tỷ lệ chuyển đổi đạt 13.04% (thấp hơn mục tiêu 30% của Results Framework).', 
 N'Chuẩn hóa kịch bản tư vấn telesales, tăng tốc phản hồi leads dưới 15 phút.', N'Trưởng phòng Marketing - TVTS', 5),

('2026-09', N'Chuỗi 4: Phễu Tuyển sinh - Chuyển đổi - Sĩ số hiện diện', 'TS06', N'Học sinh nhập mới Tháng 9 (21 HS)', 'TS01', N'Sĩ số hiện diện toàn trường (2.625 HS)', 'CAPACITY_RECOVERY', 
 N'Nhập mới 21 HS giúp bù đắp 12 ca rút trong tháng 9 (tăng ròng +9 HS tháng 9, quy mô 2.625 HS).', 
 N'Vẫn còn thiếu hụt 248 HS so với chỉ tiêu giao đầu năm học 2.873 HS (đạt 91.37%).', 
 N'Tập trung tuyển sinh chuyển trường học kỳ 2 cho Khối 10 và Khối Mầm non.', N'Ban Giám Hiệu', 6),

-- Chuỗi 5: Nhân sự Bếp & Dịch vụ Bán trú (Linear Direct)
('2026-09', N'Chuỗi 5: Nghỉ phép nhân viên - Áp lực bếp - Chất lượng bán trú', 'HR01', N'Nghỉ phép NV Bếp (54 ngày công nghỉ)', 'OP01', N'Áp lực vận hành bếp ăn & Giờ phục vụ', 'OPERATIONAL_STRAIN', 
 N'Bộ phận bếp có 54 ngày công nghỉ phép trong 2 tháng đầu năm học, gây căng thẳng cho đội ngũ phụ bếp.', 
 N'Tiềm ẩn rủi ro trễ giờ chia suất ăn và quá tải cho các nhân sự trực ca.', 
 N'Tuyển dụng danh sách CTV phụ bếp dự phòng theo ngày cao điểm.', N'Trưởng bộ phận Bếp & Bán trú', 7),

-- Chuỗi 6: Vòng lặp CLB - Doanh thu - Tái đầu tư CSVC (Feedback Loop Dương)
('2026-09', N'Chuỗi 6: Vòng lặp CLB - Doanh thu dịch vụ - Tái đầu tư CSVC', 'CLB01', N'Doanh thu Câu lạc bộ (1.611 tỷ VNĐ)', 'TC56', N'Thặng dư tài chính ngoài học phí', 'POSITIVE_FEEDBACK_1', 
 N'36 môn CLB với 596 học viên tạo doanh thu 1.611 tỷ VNĐ (vượt chỉ tiêu tại Tiểu học 117.7%).', 
 N'Đóng góp dòng tiền tự do 480 triệu VNĐ sau chi phí giảng viên và vận hành.', 
 N'Trích 30% thặng dư để nâng cấp phòng Robotics và sân tập thể thao.', N'Kế toán trưởng & BGH', 8),

('2026-09', N'Chuỗi 6: Vòng lặp CLB - Doanh thu dịch vụ - Tái đầu tư CSVC', 'TC56', N'Tái đầu tư CSVC chất lượng cao', 'CLB01', N'Thu hút học sinh tham gia CLB chuyên sâu', 'POSITIVE_FEEDBACK_2', 
 N'Cơ sở vật chất hiện đại giúp tăng số lượng đăng ký CLB kỳ tiếp theo thêm 15-20%.', 
 N'Tạo chu trình khép kín: Dịch vụ tốt -> Doanh thu cao -> Tái đầu tư -> Giữ chân học sinh.', 
 N'Mở thêm CLB Trí tuệ nhân tạo (AI) và Kịch nghệ tiếng Anh trong học kỳ 2.', N'Phó Hiệu trưởng Đào tạo', 9),

-- Chuỗi 7: Vòng lặp Biến động Giáo viên - Giờ vắng - Giảng dạy thay (Feedback Loop Âm)
('2026-09', N'Chuỗi 7: Vòng lặp Biến động nhân sự - Giờ vắng - Áp lực dạy thay', 'HR02', N'Biến động nhân sự (45 ca) & Nghỉ phép (470 đơn)', 'CM02', N'Tiết vắng giáo viên & Bố trí dạy thay (288 tiết)', 'NEGATIVE_FEEDBACK_1', 
 N'470 lượt nghỉ phép với 551 ngày nghỉ gây áp lực lớn lên việc xếp TKB dạy thay cho 288 tiết học.', 
 N'Giáo viên nòng cốt phải kiêm nhiệm nhiều giờ dạy thay, dẫn đến giảm thời gian soạn bài chuyên sâu.', 
 N'Thiết lập ngân hàng bài giảng số LMS tự học khi có tiết vắng đột xuất.', N'Tổ trưởng Chuyên môn', 10),

('2026-09', N'Chuỗi 7: Vòng lặp Biến động nhân sự - Giờ vắng - Áp lực dạy thay', 'CM02', N'Quá tải giờ dạy thay & Mệt mỏi nghề nghiệp', 'HR02', N'Nguy cơ thôi việc của giáo viên cơ hữu', 'NEGATIVE_FEEDBACK_2', 
 N'Áp lực dạy thay liên tục kéo dài làm tăng tỷ lệ kiệt sức (burnout) và thôi việc của GV trẻ.', 
 N'Cần phá vỡ vòng lặp luẩn quẩn này bằng cơ chế bù thù lao thỏa đáng cho tiết dạy thay.', 
 N'Áp dụng đơn giá hỗ trợ dạy thay tức thì và giới hạn tối đa 6 tiết dạy thay/tuần/GV.', N'Trưởng bộ phận Nhân sự', 11),

-- Chuỗi 8: Vòng lặp Chi phí xe bus - Điểm hòa vốn - Thất thu học phí (Cost-Volume-Profit Loop)
('2026-09', N'Chuỗi 8: Nghịch lý Chi phí xe bus - Tuyến xa - Thất thu học phí', 'BUS02', N'Biên lợi nhuận dịch vụ xe bus thấp (12.6% vs 15%)', 'BUS01', N'Cắt giảm / Ngần ngại mở tuyến bus cự ly xa', 'COST_PARADOX_1', 
 N'Biên LN xe bus chỉ đạt 12.6% do chi phí xăng dầu và khấu hao cao, dẫn đến e ngại mở tuyến bao phủ.', 
 N'Việc không có xe bus đưa đón là nguyên nhân trực tiếp khiến 21 phụ huynh rút hồ sơ chuyển trường.', 
 N'Không được nhìn dịch vụ xe bus như đơn vị kinh doanh độc lập (P&L riêng lẻ).', N'Ban Giám Đốc', 12),

('2026-09', N'Chuỗi 8: Nghịch lý Chi phí xe bus - Tuyến xa - Thất thu học phí', 'BUS01', N'Mất 21 học sinh vì thiếu xe bus', 'TC55', N'Thất thu học phí gấp 5 lần chi phí bù lỗ xe bus', 'COST_PARADOX_2', 
 N'Thất thu học phí của 21 HS là 1.37 tỷ VNĐ, trong khi chi phí bù lỗ mở 2 tuyến bus chỉ 240 triệu VNĐ.', 
 N'Quyết định tối ưu cục bộ phí xe bus đã gây thiệt hại toàn cục cho tổng doanh thu trường học.', 
 N'Chính sách bù chéo: Dùng lợi nhuận học phí tài trợ mở rộng tuyến xe bus phủ xa.', N'Hội Đồng Quản Trị', 13),

-- Chuỗi 9: Cross-domain: Chậm trễ CNTT & Rủi ro vận hành (IT Bottleneck)
('2026-09', N'Chuỗi 9: Chậm trễ phần mềm CRM/Thu phí - Chi phí cơ hội vận hành', 'IT01', N'Phần mềm CRM & Thu phí chưa go-live (chờ duyệt)', 'OP02', N'Lãng phí 120 giờ nhân sự nhập liệu thủ công', 'SYSTEM_BOTTLENECK', 
 N'Báo cáo vận hành ghi đã triển khai nhưng thực tế CNTT xác nhận đang chờ duyệt và T9 vẫn làm Excel.', 
 N'Gây sai lệch dữ liệu tức thời và tốn hàng trăm giờ công đối soát dữ liệu chéo giữa các bộ phận.', 
 N'Họp BGH phê duyệt nghiệm thu đưa module vào vận hành chính thức trước ngày 15/10.', N'Trưởng phòng CNTT', 14),

-- Chuỗi 10: Cross-domain: Bẫy Đầu Ra & Nghịch Lý Hài Lòng QA
('2026-09', N'Chuỗi 10: Nghịch lý Khảo sát Hài lòng (93.6%) vs 53 ca Rút hồ sơ', 'QA01', N'Tỷ lệ hài lòng PHHS khảo sát cao (93.6%)', 'AUDIT01', N'Cỡ mẫu khảo sát quá nhỏ (65 PH) - Thiếu tính đại diện', 'DATA_PARADOX_CROSS', 
 N'Chỉ số hài lòng đạt 93.6% tạo cảm giác an tâm giả tạo, trong khi thực tế có 53 HS rút hồ sơ.', 
 N'Cỡ mẫu chỉ có 65 phụ huynh trả lời (chiếm chưa đầy 2.5% tổng số 2.625 phụ huynh toàn trường).', 
 N'Thay đổi phương thức đo lường: Bắt buộc phỏng vấn 100% phụ huynh làm đơn xin rút hồ sơ.', N'Bộ phận Đảm bảo chất lượng (QA)', 15);
