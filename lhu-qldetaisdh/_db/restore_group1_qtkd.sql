BEGIN TRANSACTION;
BEGIN TRY

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HS7')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HS7', 'HS7', N'Trần Nhật', N'Trường', '26NQ913', 'PSD', '43', N'Quản trị kinh doanh',
                9, 'Phd', '2026-03', '01/04/1989', N'Cà Mau', N'Nam',
                '0907211039', 'trannhattruong01041989@gmail.com', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HS7', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HS8')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HS8', 'HS8', N'Trương Đình', N'Tú', '26NQ913', 'PSD', '43', N'Quản trị kinh doanh',
                9, 'Phd', '2026-03', '12/10/1978', N'Thanh Hóa', N'Nam',
                '0945566556', 'guithuchotu2023@gmail.com', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HS8', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HS9')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HS9', 'HS9', N'Huỳnh Anh', N'Tuyên', '26NQ913', 'PSD', '43', N'Quản trị kinh doanh',
                9, 'Phd', '2026-03', '15/01/1985', N'Tây Ninh', N'Nam',
                '0903303255', 'tuyenha@moit.gov.vn', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HS9', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HS1')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HS1', 'HS1', N'Trần Vỹ', N'Châu', '26NQ913', 'PSD', '43', N'Quản trị kinh doanh',
                9, 'Phd', '2026-03', '28/11/1976', N'Khánh Hoà', N'Nam',
                '0988639099', 'vychau.ceo@gmail.com', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HS1', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HS2')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HS2', 'HS2', N'Mai Ngọc Châu', N'Hân', '26NQ913', 'PSD', '43', N'Quản trị kinh doanh',
                9, 'Phd', '2026-03', '08/03/1996', N'TPHCM', N'Nữ',
                '0963740007', 'maihanchau@gmail.com', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HS2', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HS3')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HS3', 'HS3', N'Trần Thu', N'Hương', '26NQ913', 'PSD', '43', N'Quản trị kinh doanh',
                9, 'Phd', '2026-03', '20/07/1984', N'Phú Thọ', N'Nữ',
                '0325588077', 'tranthuhuong@dntu.edu.vn', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HS3', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HS4')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HS4', 'HS4', N'Nguyễn Ngọc Thanh', N'Tân', '26NQ913', 'PSD', '43', N'Quản trị kinh doanh',
                9, 'Phd', '2026-03', '13/11/1993', N'TPHCM', N'Nam',
                '0901267639', 'nguyenngocthanhtan1993@gmail.com', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HS4', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HS5')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HS5', 'HS5', N'Phạm Nguyễn Thanh', N'Thủy', '26NQ913', 'PSD', '43', N'Quản trị kinh doanh',
                9, 'Phd', '2026-03', '23/08/1991', N'TPHCM', N'Nữ',
                '0934043133', 'pntt23@gmail.com', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HS5', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HS6')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HS6', 'HS6', N'Nguyễn Thanh', N'Trọng', '26NQ913', 'PSD', '43', N'Quản trị kinh doanh',
                9, 'Phd', '2026-03', '17/05/1995', N'Cần Thơ', N'Nam',
                '0396270638', 'nguyenthanhtrong@siu.edu.vn', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HS6', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        
COMMIT TRANSACTION;
SELECT 1 AS Success, N'Khôi phục thành công 9 học viên' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
END CATCH