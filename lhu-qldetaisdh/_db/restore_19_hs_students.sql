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
    

    IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HSKH1')
    BEGIN
        INSERT INTO StudentInfo (
            StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
            HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
            SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
        ) VALUES (
            'HSKH1', 'HSKH1', N'Đinh Thị Hồng', N'Loan', '26NC913', 'PSD', '44', N'Khoa học máy tính',
            9, 'Phd', '2026-2029', '05/05/1984', N'Đak Lak', N'Nữ',
            '0975303032', 'dinhthihongloan05@gmail.com', 1, 0, 'NV0001364', GETDATE()
        );

        EXEC spAPI_Process_Student_Ins 4, 'HSKH1', NULL, 'NV0001364', 1, 9, 0, '[2]';
    END
    

    IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HSKH2')
    BEGIN
        INSERT INTO StudentInfo (
            StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
            HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
            SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
        ) VALUES (
            'HSKH2', 'HSKH2', N'Văn Đình Vỹ', N'Phương', '26NC913', 'PSD', '44', N'Khoa học máy tính',
            9, 'Phd', '2026-2029', '06/08/1984', N'Đồng Nai', N'Nữ',
            '0967389665', 'phuong@lhu.edu.vn', 1, 0, 'NV0001364', GETDATE()
        );

        EXEC spAPI_Process_Student_Ins 4, 'HSKH2', NULL, 'NV0001364', 1, 9, 0, '[2]';
    END
    

    IF NOT EXISTS (SELECT 1 FROM StudentInfo WHERE StudentID = 'HSKH3')
    BEGIN
        INSERT INTO StudentInfo (
            StudentID, MaHoSo, HoSV, TenSV, LopID, KhoaID, NganhID, TenNganh,
            HeDaoTaoID, HeDaoTao, NienKhoa, NgaySinh, NoiSinh, GioiTinh,
            SoDienThoai, Email, IsXuLyHocVu, IsHoanThanhThacSi, CreateUser, CreateTime
        ) VALUES (
            'HSKH3', 'HSKH3', N'Nguyễn Văn', N'Quyết', '26NC913', 'PSD', '44', N'Khoa học máy tính',
            9, 'Phd', '2026-2029', '25/05/1986', N'Hải Phòng', N'Nam',
            '0915860525', 'minhquyet25051986@gmail.com', 1, 0, 'NV0001364', GETDATE()
        );

        EXEC spAPI_Process_Student_Ins 4, 'HSKH3', NULL, 'NV0001364', 1, 9, 0, '[2]';
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
SELECT 1 AS Success, N'Khôi phục thành công 19 học viên' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
END CATCH