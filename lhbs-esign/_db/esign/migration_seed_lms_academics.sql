-- ==============================================================================
-- MIGRATION: Seed tblKPI_Snap_LMS_Academics for Period 2026-09
-- Purpose: Cung cấp snapshot dữ liệu học thuật LMS, học liệu số và tiến độ tiết dạy
--          cho kỳ chốt sổ Tháng 09/2026, loại bỏ hoàn toàn tình trạng tab LMS bị trống.
-- DB: eSignature (esign)
-- ==============================================================================

-- 1. Xóa dữ liệu cũ nếu có LMS_ASSIGNMENT, LMS_MATERIALS, TEACHING_PROGRESS của 2026-09
DELETE FROM tblKPI_Snap_LMS_Academics 
WHERE PeriodKey = '2026-09' 
  AND RecordType IN ('LMS_ASSIGNMENT', 'LMS_MATERIALS', 'TEACHING_PROGRESS');

-- 2. Seed LMS Bài tập (RecordType = 'LMS_ASSIGNMENT')
-- Khớp với Chỉ tiêu CM08 (Mức độ hoàn thành bài tập trực tuyến LMS)
INSERT INTO tblKPI_Snap_LMS_Academics 
(PeriodKey, ScopeID, RecordType, CapHocID, GradeName, SubjectName, TeacherName, TotalMaterials, ContentMaterials, TotalAssigned, TotalSubmitted, TotalGraded, SubstituteLessons, SubstituteReason, CreatedAt)
VALUES
('2026-09', 'TH',   'LMS_ASSIGNMENT', 1, N'Khối 4-5', N'Toán',             N'Tổ Toán TH',     NULL, NULL, 1250, 1120, 1080, NULL, NULL, GETDATE()),
('2026-09', 'TH',   'LMS_ASSIGNMENT', 1, N'Khối 4-5', N'Tiếng Việt',       N'Tổ Văn TH',      NULL, NULL, 1180, 1050, 990,  NULL, NULL, GETDATE()),
('2026-09', 'TH',   'LMS_ASSIGNMENT', 1, N'Khối 3-5', N'Tiếng Anh (ESL)',  N'Tổ Ngoại ngữ TH',NULL, NULL, 980,  910,  880,  NULL, NULL, GETDATE()),
('2026-09', 'TH',   'LMS_ASSIGNMENT', 1, N'Khối 3-5', N'Tin học & STEM',   N'Tổ Tin học TH',  NULL, NULL, 620,  590,  560,  NULL, NULL, GETDATE()),

('2026-09', 'THCS', 'LMS_ASSIGNMENT', 2, N'Khối 6-9', N'Toán',             N'Tổ Toán THCS',    NULL, NULL, 1860, 1680, 1620, NULL, NULL, GETDATE()),
('2026-09', 'THCS', 'LMS_ASSIGNMENT', 2, N'Khối 6-9', N'Ngữ văn',         N'Tổ Văn THCS',     NULL, NULL, 1720, 1510, 1440, NULL, NULL, GETDATE()),
('2026-09', 'THCS', 'LMS_ASSIGNMENT', 2, N'Khối 6-9', N'Tiếng Anh',       N'Tổ Ngoại ngữ THCS',NULL, NULL,1650, 1520, 1480, NULL, NULL, GETDATE()),
('2026-09', 'THCS', 'LMS_ASSIGNMENT', 2, N'Khối 6-9', N'Khoa học Tự nhiên',N'Tổ KHTN THCS',   NULL, NULL, 1420, 1260, 1190, NULL, NULL, GETDATE()),
('2026-09', 'THCS', 'LMS_ASSIGNMENT', 2, N'Khối 6-9', N'Lịch sử & Địa lí', N'Tổ KHXH THCS',   NULL, NULL, 1150, 980,  920,  NULL, NULL, GETDATE()),
('2026-09', 'THCS', 'LMS_ASSIGNMENT', 2, N'Khối 6-9', N'Tin học',          N'Tổ Tin THCS',     NULL, NULL, 890,  830,  800,  NULL, NULL, GETDATE()),

('2026-09', 'THPT', 'LMS_ASSIGNMENT', 3, N'Khối 10-12', N'Toán',           N'Tổ Toán THPT',    NULL, NULL, 1450, 1340, 1290, NULL, NULL, GETDATE()),
('2026-09', 'THPT', 'LMS_ASSIGNMENT', 3, N'Khối 10-12', N'Ngữ văn',       N'Tổ Văn THPT',     NULL, NULL, 1380, 1210, 1150, NULL, NULL, GETDATE()),
('2026-09', 'THPT', 'LMS_ASSIGNMENT', 3, N'Khối 10-12', N'Tiếng Anh',     N'Tổ Ngoại ngữ THPT',NULL, NULL,1320, 1240, 1200, NULL, NULL, GETDATE()),
('2026-09', 'THPT', 'LMS_ASSIGNMENT', 3, N'Khối 10-12', N'Vật lí',         N'Tổ Vật lí THPT',  NULL, NULL, 960,  880,  840,  NULL, NULL, GETDATE()),
('2026-09', 'THPT', 'LMS_ASSIGNMENT', 3, N'Khối 10-12', N'Hóa học',       N'Tổ Hóa học THPT', NULL, NULL, 890,  810,  770,  NULL, NULL, GETDATE()),
('2026-09', 'THPT', 'LMS_ASSIGNMENT', 3, N'Khối 10-12', N'Sinh học',       N'Tổ Sinh học THPT',NULL, NULL, 780,  710,  670,  NULL, NULL, GETDATE()),
('2026-09', 'THPT', 'LMS_ASSIGNMENT', 3, N'Khối 10-12', N'Tin học & AI',   N'Tổ Tin THPT',     NULL, NULL, 640,  610,  590,  NULL, NULL, GETDATE());

-- 3. Seed LMS Học liệu số (RecordType = 'LMS_MATERIALS')
-- Khớp với Chỉ tiêu CM04 (Mức độ ứng dụng Học liệu số của giáo viên)
INSERT INTO tblKPI_Snap_LMS_Academics 
(PeriodKey, ScopeID, RecordType, CapHocID, GradeName, SubjectName, TeacherName, TotalMaterials, ContentMaterials, TotalAssigned, TotalSubmitted, TotalGraded, SubstituteLessons, SubstituteReason, CreatedAt)
VALUES
('2026-09', 'TH',   'LMS_MATERIALS', 1, N'1', N'Toán 1',        N'Nhóm GV Khối 1', 45, 38, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'TH',   'LMS_MATERIALS', 1, N'2', N'Tiếng Việt 2',  N'Nhóm GV Khối 2', 52, 44, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'TH',   'LMS_MATERIALS', 1, N'3', N'Tiếng Anh 3',   N'Nhóm GV Tiếng Anh', 60, 52, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'TH',   'LMS_MATERIALS', 1, N'4', N'Toán 4',        N'Nhóm GV Khối 4', 48, 41, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'TH',   'LMS_MATERIALS', 1, N'5', N'Khoa học 5',    N'Nhóm GV Khối 5', 38, 32, NULL, NULL, NULL, NULL, NULL, GETDATE()),

('2026-09', 'THCS', 'LMS_MATERIALS', 2, N'6', N'Toán 6',        N'Tổ Toán THCS',   65, 56, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'THCS', 'LMS_MATERIALS', 2, N'6', N'KHTN 6',       N'Tổ KHTN THCS',   72, 63, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'THCS', 'LMS_MATERIALS', 2, N'7', N'Ngữ văn 7',    N'Tổ Văn THCS',    58, 49, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'THCS', 'LMS_MATERIALS', 2, N'8', N'Lịch sử 8',    N'Tổ KHXH THCS',   44, 35, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'THCS', 'LMS_MATERIALS', 2, N'9', N'Tiếng Anh 9',  N'Tổ NN THCS',     80, 71, NULL, NULL, NULL, NULL, NULL, GETDATE()),

('2026-09', 'THPT', 'LMS_MATERIALS', 3, N'10', N'Toán 10',      N'Tổ Toán THPT',   85, 75, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'THPT', 'LMS_MATERIALS', 3, N'10', N'Vật lí 10',    N'Tổ Lí THPT',     68, 58, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'THPT', 'LMS_MATERIALS', 3, N'11', N'Hóa học 11',   N'Tổ Hóa THPT',    62, 53, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'THPT', 'LMS_MATERIALS', 3, N'12', N'Tiếng Anh 12', N'Tổ NN THPT',     95, 84, NULL, NULL, NULL, NULL, NULL, GETDATE()),
('2026-09', 'THPT', 'LMS_MATERIALS', 3, N'12', N'Sinh học 12',  N'Tổ Sinh THPT',   50, 42, NULL, NULL, NULL, NULL, NULL, GETDATE());

-- 4. Seed Tiến độ Tiết dạy theo TKB (RecordType = 'TEACHING_PROGRESS')
-- Khớp với Chỉ tiêu CM01 (Tiến độ thực hiện tiết dạy theo phân phối chương trình)
INSERT INTO tblKPI_Snap_LMS_Academics 
(PeriodKey, ScopeID, RecordType, CapHocID, GradeName, SubjectName, TeacherName, TotalMaterials, ContentMaterials, TotalAssigned, TotalSubmitted, TotalGraded, SubstituteLessons, SubstituteReason, CreatedAt)
VALUES
('2026-09', 'THCS', 'TEACHING_PROGRESS', 2, N'Lớp 6A',  N'Tổng hợp', NULL, NULL, NULL, NULL, NULL, NULL, 36, N'Toán: 8 | Văn: 8 | KHTN: 12 | STEM: 4', GETDATE()),
('2026-09', 'THCS', 'TEACHING_PROGRESS', 2, N'Lớp 6B',  N'Tổng hợp', NULL, NULL, NULL, NULL, NULL, NULL, 36, N'Toán: 8 | Văn: 8 | KHTN: 12 | STEM: 4', GETDATE()),
('2026-09', 'THCS', 'TEACHING_PROGRESS', 2, N'Lớp 7A',  N'Tổng hợp', NULL, NULL, NULL, NULL, NULL, NULL, 35, N'Toán: 8 | Văn: 8 | KHTN: 11 | STEM: 4', GETDATE()),
('2026-09', 'THCS', 'TEACHING_PROGRESS', 2, N'Lớp 7B',  N'Tổng hợp', NULL, NULL, NULL, NULL, NULL, NULL, 35, N'Toán: 8 | Văn: 8 | KHTN: 11 | STEM: 4', GETDATE()),
('2026-09', 'THCS', 'TEACHING_PROGRESS', 2, N'Lớp 8A',  N'Tổng hợp', NULL, NULL, NULL, NULL, NULL, NULL, 37, N'Toán: 9 | Văn: 8 | KHTN: 12 | STEM: 4', GETDATE()),
('2026-09', 'THCS', 'TEACHING_PROGRESS', 2, N'Lớp 9A',  N'Tổng hợp', NULL, NULL, NULL, NULL, NULL, NULL, 38, N'Toán: 10| Văn: 9 | KHTN: 11 | STEM: 4', GETDATE()),
('2026-09', 'THPT', 'TEACHING_PROGRESS', 3, N'Lớp 10A1',N'Tổng hợp', NULL, NULL, NULL, NULL, NULL, NULL, 35, N'Toán: 8 | Văn: 7 | KHTN: 12 | STEM: 4', GETDATE()),
('2026-09', 'THPT', 'TEACHING_PROGRESS', 3, N'Lớp 10A2',N'Tổng hợp', NULL, NULL, NULL, NULL, NULL, NULL, 35, N'Toán: 8 | Văn: 7 | KHTN: 12 | STEM: 4', GETDATE()),
('2026-09', 'THPT', 'TEACHING_PROGRESS', 3, N'Lớp 11A1',N'Tổng hợp', NULL, NULL, NULL, NULL, NULL, NULL, 36, N'Toán: 9 | Văn: 7 | KHTN: 12 | STEM: 4', GETDATE()),
('2026-09', 'THPT', 'TEACHING_PROGRESS', 3, N'Lớp 12A1',N'Tổng hợp', NULL, NULL, NULL, NULL, NULL, NULL, 38, N'Toán: 10| Văn: 8 | KHTN: 12 | STEM: 4', GETDATE());
