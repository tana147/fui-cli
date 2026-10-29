-- Migration: Seed full 21 Student Bus/Distance Withdrawal Facts
-- Target: Align 1-1 with tblKPI_PeriodBreakdowns (BUS = 21 across campuses)
-- Database: eSignature

IF (SELECT COUNT(*) FROM tblKPI_Snap_BasicData_Students WHERE PeriodKey = '2026-09' AND RecordType = 'WITHDRAWAL' AND (WithdrawReasonCode = 'REASON_DISTANCE' OR WithdrawReasonCode = 'REASON_BUS')) < 21
BEGIN
    INSERT INTO tblKPI_Snap_BasicData_Students (
        PeriodKey, ScopeID, GradeID, GradeName, ClassID, ClassName, StudentCount, CapacityMax, RecordType, StudentCode, StudentName, EventDate, WithdrawReasonCode, WithdrawReasonText, CreatedAt
    )
    VALUES
        -- 1. TH (Tiểu học: cần thêm 7 HS để đủ 8 HS)
        ('2026-09', 'TH', 1, N'Khối 1', 11, N'01A', 1, NULL, 'WITHDRAWAL', 'HS00112', N'Trần Hoàng Bảo Nam', '2026-06-12', 'REASON_DISTANCE', N'Xa trường, tuyến bus Long Thành > 45p', GETDATE()),
        ('2026-09', 'TH', 2, N'Khối 2', 22, N'02B', 1, NULL, 'WITHDRAWAL', 'HS00125', N'Lê Ngọc Phương Uyên', '2026-06-15', 'REASON_DISTANCE', N'Xa trường, đưa đón bất tiện', GETDATE()),
        ('2026-09', 'TH', 2, N'Khối 2', 23, N'02C', 1, NULL, 'WITHDRAWAL', 'HS00128', N'Phạm Gia Hưng', '2026-06-18', 'REASON_DISTANCE', N'Tuyến xe bus không đón tận nhà', GETDATE()),
        ('2026-09', 'TH', 3, N'Khối 3', 31, N'03A', 1, NULL, 'WITHDRAWAL', 'HS00133', N'Đặng Minh Khang', '2026-06-20', 'REASON_DISTANCE', N'Cự ly di chuyển xa (>15km)', GETDATE()),
        ('2026-09', 'TH', 4, N'Khối 4', 42, N'04B', 1, NULL, 'WITHDRAWAL', 'HS00148', N'Vũ Quỳnh Chi', '2026-06-22', 'REASON_DISTANCE', N'Xa trường, phụ huynh đổi việc làm', GETDATE()),
        ('2026-09', 'TH', 5, N'Khối 5', 51, N'05A', 1, NULL, 'WITHDRAWAL', 'HS00159', N'Ngô Đình Trí', '2026-06-25', 'REASON_DISTANCE', N'Xa trường, thời gian ngồi bus dài', GETDATE()),
        ('2026-09', 'TH', 5, N'Khối 5', 52, N'05B', 1, NULL, 'WITHDRAWAL', 'HS00163', N'Bùi Thảo My', '2026-07-01', 'REASON_DISTANCE', N'Chuyển về trường gần nhà', GETDATE()),

        -- 2. MNBH (Mầm non Biên Hòa: 3 HS)
        ('2026-09', 'MNBH', -3, N'MG Mầm', 2, N'Mầm 1', 1, NULL, 'WITHDRAWAL', 'HS00015', N'Nguyễn Đức Anh', '2026-06-10', 'REASON_DISTANCE', N'Bé say xe bus tuyến Biên Hòa Đông', GETDATE()),
        ('2026-09', 'MNBH', -2, N'MG Chồi', 5, N'Chồi 2', 1, NULL, 'WITHDRAWAL', 'HS00028', N'Hoàng Thục Quyên', '2026-06-14', 'REASON_DISTANCE', N'Xa trường, phụ huynh không tiện gửi', GETDATE()),
        ('2026-09', 'MNBH', -1, N'MG Lá', 8, N'Lá 1', 1, NULL, 'WITHDRAWAL', 'HS00042', N'Đỗ Minh Quân', '2026-06-28', 'REASON_DISTANCE', N'Thời gian đưa đón xe bus quá sớm', GETDATE()),

        -- 3. MNLK (Mầm non Long Khánh: 4 HS)
        ('2026-09', 'MNLK', -4, N'18 Tháng', 1, N'18T LK', 1, NULL, 'WITHDRAWAL', 'HS00051', N'Lý Thiên An', '2026-06-08', 'REASON_DISTANCE', N'Đường vào nhà xe bus lớn không vào được', GETDATE()),
        ('2026-09', 'MNLK', -3, N'MG Mầm', 3, N'Mầm LK', 1, NULL, 'WITHDRAWAL', 'HS00062', N'Trịnh Khôi Nguyên', '2026-06-16', 'REASON_DISTANCE', N'Cự ly xã Bình Lộc xa điểm đón', GETDATE()),
        ('2026-09', 'MNLK', -2, N'MG Chồi', 6, N'Chồi LK', 1, NULL, 'WITHDRAWAL', 'HS00071', N'Võ Diệp Chi', '2026-06-24', 'REASON_DISTANCE', N'Xa trường, chuyển về trường gần nhà', GETDATE()),
        ('2026-09', 'MNLK', -1, N'MG Lá', 9, N'Lá LK', 1, NULL, 'WITHDRAWAL', 'HS00080', N'Phan Hoàng Phúc', '2026-07-05', 'REASON_DISTANCE', N'Xa trường, gia đình dọn về Suối Tre', GETDATE()),

        -- 4. THCS (Trung học cơ sở: cần thêm 3 HS để đủ 4 HS)
        ('2026-09', 'THCS', 6, N'Khối 6', 62, N'06B', 1, NULL, 'WITHDRAWAL', 'HS00215', N'Nguyễn Tuấn Kiệt', '2026-06-15', 'REASON_DISTANCE', N'Xa trường, học sinh say xe bus', GETDATE()),
        ('2026-09', 'THCS', 8, N'Khối 8', 81, N'08A', 1, NULL, 'WITHDRAWAL', 'HS00234', N'Huỳnh Mai Phương', '2026-06-20', 'REASON_DISTANCE', N'Thời gian đi lại buổi chiều bị kẹt xe', GETDATE()),
        ('2026-09', 'THCS', 9, N'Khối 9', 93, N'09C', 1, NULL, 'WITHDRAWAL', 'HS00249', N'Lâm Quốc Bảo', '2026-07-10', 'REASON_DISTANCE', N'Học thêm tối xa trường, chuyển về địa phương', GETDATE()),

        -- 5. THPT (Trung học phổ thông: 2 HS)
        ('2026-09', 'THPT', 10, N'Khối 10', 102, N'10B', 1, NULL, 'WITHDRAWAL', 'HS00310', N'Dương Gia Hân', '2026-07-15', 'REASON_DISTANCE', N'Cự ly đưa đón xa, đi xe tuyến mệt', GETDATE()),
        ('2026-09', 'THPT', 11, N'Khối 11', 111, N'11A', 1, NULL, 'WITHDRAWAL', 'HS00322', N'Trần Tiến Dũng', '2026-08-01', 'REASON_DISTANCE', N'Xa trường, học sinh tự đi xe máy nguy hiểm', GETDATE());
END;
