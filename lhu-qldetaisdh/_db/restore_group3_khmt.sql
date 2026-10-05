BEGIN TRANSACTION;
BEGIN TRY

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
        
COMMIT TRANSACTION;
SELECT 1 AS Success, N'Khôi phục thành công 3 học viên' AS Message;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
END CATCH