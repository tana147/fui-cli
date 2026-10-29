-- Migration: Seed Basic Data Students Snapshots for Period 2026-09
-- Database: eSignature (esign)

IF NOT EXISTS (SELECT 1 FROM tblKPI_Snap_BasicData_Students WHERE PeriodKey = '2026-09')
BEGIN
    -- 1. Cơ sở Biên Hòa
    INSERT INTO tblKPI_Snap_BasicData_Students (PeriodKey, ScopeID, GradeID, GradeName, ClassID, ClassName, StudentCount, CapacityMax, RecordType, CreatedAt)
    VALUES
        ('2026-09', 'MNBH', -4, N'18 Tháng', NULL, N'Nhóm 18T', 17, 25, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'MNBH', -3, N'MG Mầm', NULL, N'Khối Mầm', 66, 80, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'MNBH', -2, N'MG Chồi', NULL, N'Khối Chồi', 94, 110, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'MNBH', -1, N'MG Lá', NULL, N'Khối Lá', 135, 150, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'TH', 1, N'Khối 1', NULL, N'Khối 1', 207, 220, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'TH', 2, N'Khối 2', NULL, N'Khối 2', 221, 230, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'TH', 3, N'Khối 3', NULL, N'Khối 3', 219, 230, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'TH', 4, N'Khối 4', NULL, N'Khối 4', 213, 230, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'TH', 5, N'Khối 5', NULL, N'Khối 5', 185, 200, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'THCS', 6, N'Khối 6', NULL, N'Khối 6', 226, 240, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'THCS', 7, N'Khối 7', NULL, N'Khối 7', 213, 230, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'THCS', 8, N'Khối 8', NULL, N'Khối 8', 185, 200, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'THCS', 9, N'Khối 9', NULL, N'Khối 9', 181, 200, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'THPT', 10, N'Khối 10', NULL, N'Khối 10', 154, 180, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'THPT', 11, N'Khối 11', NULL, N'Khối 11', 106, 150, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'THPT', 12, N'Khối 12', NULL, N'Khối 12', 77, 120, 'GRADE_SUMMARY', GETDATE()),

    -- 2. Cơ sở Long Khánh
        ('2026-09', 'MNLK', -4, N'18 Tháng', NULL, N'Nhóm 18T LK', 12, 25, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'MNLK', -3, N'MG Mầm', NULL, N'Khối Mầm LK', 24, 35, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'MNLK', -2, N'MG Chồi', NULL, N'Khối Chồi LK', 28, 35, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'MNLK', -1, N'MG Lá', NULL, N'Khối Lá LK', 34, 40, 'GRADE_SUMMARY', GETDATE()),
        ('2026-09', 'MNLK', 1, N'Khối 1', NULL, N'Khối 1 LK', 35, 45, 'GRADE_SUMMARY', GETDATE());

    -- 3. Chi tiết Rút học (WITHDRAWAL)
    INSERT INTO tblKPI_Snap_BasicData_Students (PeriodKey, ScopeID, GradeID, GradeName, ClassID, ClassName, StudentCount, CapacityMax, RecordType, StudentCode, StudentName, EventDate, WithdrawReasonCode, WithdrawReasonText, CreatedAt)
    VALUES
        ('2026-09', 'TH', 3, N'Khối 3', 32, N'03B', 1, NULL, 'WITHDRAWAL', 'HS00101', N'Dương Bình Minh', '2026-06-05', 'REASON_HOUSE', N'Chuyển chỗ ở', GETDATE()),
        ('2026-09', 'THCS', 7, N'Khối 7', 74, N'07D', 1, NULL, 'WITHDRAWAL', 'HS00204', N'Nguyễn Thanh Nhân', '2026-06-05', 'REASON_ABROAD', N'Định cư nước ngoài', GETDATE()),
        ('2026-09', 'THCS', 7, N'Khối 7', 71, N'07A', 1, NULL, 'WITHDRAWAL', 'HS00208', N'Lại Nguyễn Bảo Vy', '2026-06-05', 'REASON_DISTANCE', N'Xa trường, đi lại khó khăn', GETDATE()),
        ('2026-09', 'TH', 3, N'Khối 3', 37, N'03G', 1, NULL, 'WITHDRAWAL', 'HS00142', N'Lại Nguyễn Khả Hân', '2026-06-05', 'REASON_DISTANCE', N'Xa trường, đi lại khó khăn', GETDATE()),
        ('2026-09', 'TH', 4, N'Khối 4', 46, N'04F', 1, NULL, 'WITHDRAWAL', 'HS00155', N'Nguyễn Thanh Phúc', '2026-06-05', 'REASON_ABROAD', N'Định cư nước ngoài', GETDATE()),
        ('2026-09', 'TH', 4, N'Khối 4', 41, N'04A', 1, NULL, 'WITHDRAWAL', 'HS00160', N'Phan Nguyên Ước', '2026-08-14', 'REASON_STUDY_ABROAD', N'Du học', GETDATE()),
        ('2026-09', 'THPT', 10, N'Khối 10', 101, N'10A', 1, NULL, 'WITHDRAWAL', 'HS00301', N'Nguyễn Hồng Hải', '2026-09-30', 'REASON_STUDY_ABROAD', N'Du học', GETDATE()),
        ('2026-09', 'TH', 1, N'Khối 1', 16, N'01F', 1, NULL, 'WITHDRAWAL', 'HS00088', N'Chướng Nguyễn Hạo Nhiên', '2026-10-14', 'REASON_FINANCE', N'Có hoàn cảnh kinh tế gia đình', GETDATE());
END;
