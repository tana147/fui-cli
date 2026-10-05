BEGIN TRANSACTION;
BEGIN TRY

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HSXD5')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HSXD5', 'HSXD5', N'Nguyễn Trần', N'Toàn', '26NX913', 'PSD', '58', N'Kỹ thuật xây dựng',
                9, 'Phd', '2026-03', '20/10/1992', N'Bình Định', N'Nam',
                '0332772737', 'nguyentrantoan92@gmail.com', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HSXD5', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HSXD6')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HSXD6', 'HSXD6', N'Lê Hữu', N'Thọ', '26NX913', 'PSD', '58', N'Kỹ thuật xây dựng',
                9, 'Phd', '2026-03', '14/08/1986', N'Đồng Nai', N'Nam',
                '0909095755', 'huutho@lhu.edu.vn', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HSXD6', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HSXD7')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HSXD7', 'HSXD7', N'Lê Quốc', N'Huy', '26NX913', 'PSD', '58', N'Kỹ thuật xây dựng',
                9, 'Phd', '2026-03', '20/11/1988', N'Đồng Nai', N'Nam',
                '0911187088', 'Lehuy.ewa@gmail.com', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HSXD7', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HSXD1')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HSXD1', 'HSXD1', N'Lê Hoàng', N'Phong', '26NX913', 'PSD', '58', N'Kỹ thuật xây dựng',
                9, 'Phd', '2026-03', '05/05/1981', N'Cà Mau', N'Nam',
                '0912142058', 'lehoangphong1983@gmail.com', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HSXD1', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HSXD2')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HSXD2', 'HSXD2', N'Nguyễn Bá', N'Chuyên', '26NX913', 'PSD', '58', N'Kỹ thuật xây dựng',
                9, 'Phd', '2026-03', '03/02/1976', N'Nghệ An', N'Nam',
                '0989620629', 'chuyennguyen@szb.com.vn', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HSXD2', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HSXD3')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HSXD3', 'HSXD3', N'Nguyễn Quốc', N'Hưng', '26NX913', 'PSD', '58', N'Kỹ thuật xây dựng',
                9, 'Phd', '2026-03', '06/09/1992', N'Khánh Hoà', N'Nam',
                '0911443575', 'nguyenquochung.lhu@gmail.com', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HSXD3', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        

        IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HSXD4')
        BEGIN
            INSERT INTO StudentInfo (
                StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
                HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
                SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
            ) VALUES (
                'HSXD4', 'HSXD4', N'Nguyễn Đăng', N'Khoa', '26NX913', 'PSD', '58', N'Kỹ thuật xây dựng',
                9, 'Phd', '2026-03', '28/08/1986', N'Đồng Nai', N'Nam',
                '0979027037', 'dangkhoa@lhu.edu.vn', 1, 0, 'NV0001364', GETDATE()
            );

            EXEC spAPI_Process_Student_Ins 4, 'HSXD4', NULL, 'NV0001364', 1, 9, 0, '[2]';
        END
        
COMMIT TRANSACTION;
SELECT 1 AS Success, N'Khôi phục thành công 7 học viên' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
END CATCH