CREATE PROCEDURE dbo.spAPI_HDKH_Admin_GetChiTietGiangVienKhoa
    @NamHoc INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Tương tự API trên, cần tính toán và trả về kết quả chi tiết cho mỗi giảng viên
    -- Kết quả phải bao gồm cả KhoaID để frontend có thể lọc
    
    -- Dữ liệu mẫu
    SELECT 
        NhanVienID = 'GV001',
        HoTen = N'Nguyễn Văn A',
        KhoaID = 'CNTT',
        DinhMuc = 150,
        DaThucHien = 160,
        BaoLuu_Thieu = 10,
        KetQua = 'DAT'
    UNION ALL
    SELECT
        NhanVienID = 'GV002',
        HoTen = N'Trần Thị B',
        KhoaID = 'QTKD',
        DinhMuc = 150,
        DaThucHien = 100,
        BaoLuu_Thieu = -50,
        KetQua = 'KHONGDAT';
END
