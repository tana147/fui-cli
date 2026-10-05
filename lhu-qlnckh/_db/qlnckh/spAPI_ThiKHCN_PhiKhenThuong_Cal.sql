CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_PhiKhenThuong_Cal]
    @CongThucID INT,
    @MembersJson NVARCHAR(MAX),
    @HinhThucThanhToan TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    IF @HinhThucThanhToan IS NULL SET @HinhThucThanhToan = 1;

    -- 1. Lấy thông tin công thức khen thưởng từ CSDL
    -- Lưu ý: Cột MucThuong_NhomTacGia và MucThuong_GVHD trong bảng ThiKHCN_CongThucKhenThuong 
    -- đã lưu sẵn giá trị tiền thưởng chính xác theo từng công thức (đã tính 2/3 cho các giải học thuật).
    -- Tuyệt đối không nhân thêm HeSoNhan một lần nữa để tránh bị giảm 2 lần.
    DECLARE @MucThuong_NhomTacGia NUMERIC(18, 0) = 0;
    DECLARE @MucThuong_GVHD NUMERIC(18, 0) = 0;
    DECLARE @MucThuong_CanBoHoTro NUMERIC(18, 0) = 0;
    DECLARE @HeSoNhan FLOAT = 1.0;
    DECLARE @NhomKhenThuong TINYINT = 1;

    SELECT 
        @MucThuong_NhomTacGia = ISNULL(MucThuong_NhomTacGia, 0),
        @MucThuong_GVHD = ISNULL(MucThuong_GVHD, 0),
        @MucThuong_CanBoHoTro = ISNULL(MucThuong_CanBoHoTro, 0),
        @HeSoNhan = ISNULL(HeSoNhan, 1.0),
        @NhomKhenThuong = ISNULL(NhomKhenThuong, 1)
    FROM ThiKHCN_CongThucKhenThuong
    WHERE CongThucID = @CongThucID AND Is_Xoa = 0;

    -- 2. Đọc danh sách thành viên từ JSON
    DECLARE @tv TABLE (
        STT INT IDENTITY(1,1),
        ThanhVienID INT,
        MaDinhDanh VARCHAR(20),
        HoTen NVARCHAR(150),
        VaiTro TINYINT,
        Is_SinhVien BIT,
        Is_NhanVien BIT,
        TenPhongBan NVARCHAR(250),
        SoTaiKhoan NVARCHAR(50),
        NganHang NVARCHAR(250),
        TenChuTaiKhoan NVARCHAR(150),
        TyLeDongGop NUMERIC(5, 2),
        SoTienThuong NUMERIC(18, 0),
        Is_DaiDienNhanTien BIT,
        Email VARCHAR(100)
    );

    IF @MembersJson IS NOT NULL AND LEN(@MembersJson) > 2
    BEGIN
        INSERT INTO @tv (
            ThanhVienID, MaDinhDanh, HoTen, VaiTro, Is_SinhVien, Is_NhanVien,
            TenPhongBan, SoTaiKhoan, NganHang, TenChuTaiKhoan,
            TyLeDongGop, SoTienThuong, Is_DaiDienNhanTien, Email
        )
        SELECT 
            JSON_VALUE(value, '$.ThanhVienID'),
            JSON_VALUE(value, '$.MaDinhDanh'),
            JSON_VALUE(value, '$.HoTen'),
            CAST(ISNULL(JSON_VALUE(value, '$.VaiTro'), 1) AS TINYINT),
            CASE WHEN JSON_VALUE(value, '$.Is_SinhVien') IN ('true', '1') THEN 1 ELSE 0 END,
            CASE WHEN JSON_VALUE(value, '$.Is_NhanVien') IN ('false', '0') THEN 0 ELSE 1 END,
            JSON_VALUE(value, '$.TenPhongBan'),
            JSON_VALUE(value, '$.SoTaiKhoan'),
            JSON_VALUE(value, '$.NganHang'),
            JSON_VALUE(value, '$.TenChuTaiKhoan'),
            CAST(ISNULL(JSON_VALUE(value, '$.TyLeDongGop'), 0) AS NUMERIC(5, 2)),
            0,
            CASE WHEN JSON_VALUE(value, '$.Is_DaiDienNhanTien') IN ('true', '1') THEN 1 ELSE 0 END,
            JSON_VALUE(value, '$.Email')
        FROM OPENJSON(@MembersJson);
    END;

    -- 3. Chuẩn hóa tỷ lệ đóng góp nếu chưa nhập (% TyLeDongGop)
    DECLARE @CountTacGia INT = (SELECT COUNT(*) FROM @tv WHERE VaiTro IN (1, 2));
    DECLARE @CountGVHD INT = (SELECT COUNT(*) FROM @tv WHERE VaiTro = 3);
    DECLARE @CountHoTro INT = (SELECT COUNT(*) FROM @tv WHERE VaiTro = 4);

    -- 3.1. Nhóm tác giả: nếu chưa nhập tỷ lệ thì tự động chia đều và bù sai số để đủ 100.00%
    IF @CountTacGia > 0
    BEGIN
        DECLARE @SumRateTacGia NUMERIC(9, 2) = (SELECT SUM(TyLeDongGop) FROM @tv WHERE VaiTro IN (1, 2));
        IF ISNULL(@SumRateTacGia, 0) <= 0
        BEGIN
            UPDATE @tv 
            SET TyLeDongGop = ROUND(100.0 / @CountTacGia, 2)
            WHERE VaiTro IN (1, 2);

            DECLARE @DiffRateTacGia NUMERIC(5, 2) = 100.00 - (SELECT SUM(TyLeDongGop) FROM @tv WHERE VaiTro IN (1, 2));
            DECLARE @FirstAuthorRateSTT INT = (SELECT TOP 1 STT FROM @tv WHERE VaiTro IN (1, 2) ORDER BY STT ASC);
            IF @FirstAuthorRateSTT IS NOT NULL AND @DiffRateTacGia <> 0
            BEGIN
                UPDATE @tv SET TyLeDongGop = TyLeDongGop + @DiffRateTacGia WHERE STT = @FirstAuthorRateSTT;
            END;
        END;
    END;

    -- 3.2. Nhóm GVHD: nếu chưa nhập tỷ lệ thì tự động chia đều và bù sai số để đủ 100.00%
    IF @CountGVHD > 0
    BEGIN
        DECLARE @SumRateGVHD NUMERIC(9, 2) = (SELECT SUM(TyLeDongGop) FROM @tv WHERE VaiTro = 3);
        IF ISNULL(@SumRateGVHD, 0) <= 0
        BEGIN
            UPDATE @tv 
            SET TyLeDongGop = ROUND(100.0 / @CountGVHD, 2)
            WHERE VaiTro = 3;

            DECLARE @DiffRateGVHD NUMERIC(5, 2) = 100.00 - (SELECT SUM(TyLeDongGop) FROM @tv WHERE VaiTro = 3);
            DECLARE @FirstMentorRateSTT INT = (SELECT TOP 1 STT FROM @tv WHERE VaiTro = 3 ORDER BY STT ASC);
            IF @FirstMentorRateSTT IS NOT NULL AND @DiffRateGVHD <> 0
            BEGIN
                UPDATE @tv SET TyLeDongGop = TyLeDongGop + @DiffRateGVHD WHERE STT = @FirstMentorRateSTT;
            END;
        END;
    END;

    -- 4. Xử lý tính toán tiền thưởng theo hình thức nhận tiền
    -- Kiểm tra có đại diện nhận thay không (chỉ áp dụng khi HinhThucThanhToan = 2)
    DECLARE @RepSTT INT = NULL;
    IF @HinhThucThanhToan = 2
    BEGIN
        SELECT TOP 1 @RepSTT = STT FROM @tv WHERE Is_DaiDienNhanTien = 1 ORDER BY STT ASC;
        -- Nếu chọn hình thức 2 nhưng chưa đánh dấu ai làm đại diện thì mặc định là tác giả chính (hoặc thành viên đầu)
        IF @RepSTT IS NULL
        BEGIN
            SELECT TOP 1 @RepSTT = STT FROM @tv WHERE VaiTro = 1 ORDER BY STT ASC;
        END;
        IF @RepSTT IS NULL
        BEGIN
            SELECT TOP 1 @RepSTT = STT FROM @tv ORDER BY STT ASC;
        END;
    END
    ELSE
    BEGIN
        -- Nếu không phải hình thức ủy quyền thì chắc chắn không có đại diện
        UPDATE @tv SET Is_DaiDienNhanTien = 0;
    END;

    IF @RepSTT IS NOT NULL
    BEGIN
        -- GOM TOÀN BỘ TIỀN THƯỞNG VÀO ĐẠI DIỆN DUY NHẤT
        DECLARE @TongTienAll NUMERIC(18, 0) = 0;
        IF @CountTacGia > 0 SET @TongTienAll = @TongTienAll + @MucThuong_NhomTacGia;
        IF @CountGVHD > 0 SET @TongTienAll = @TongTienAll + @MucThuong_GVHD;
        IF @CountHoTro > 0 SET @TongTienAll = @TongTienAll + @MucThuong_CanBoHoTro;

        UPDATE @tv SET SoTienThuong = 0, Is_DaiDienNhanTien = 0;
        UPDATE @tv SET SoTienThuong = @TongTienAll, Is_DaiDienNhanTien = 1 WHERE STT = @RepSTT;
    END
    ELSE
    BEGIN
        -- PHÂN BỔ THEO TỶ LỆ CHO TỪNG NHÓM
        -- 4.1. Nhóm tác giả (VaiTro IN (1, 2))
        IF @CountTacGia > 0
        BEGIN
            DECLARE @CalcSumRateTacGia NUMERIC(9, 2) = (SELECT SUM(TyLeDongGop) FROM @tv WHERE VaiTro IN (1, 2));
            IF @CalcSumRateTacGia > 0
            BEGIN
                UPDATE @tv 
                SET SoTienThuong = ROUND((@MucThuong_NhomTacGia * TyLeDongGop) / @CalcSumRateTacGia, 0)
                WHERE VaiTro IN (1, 2);
            END
            ELSE
            BEGIN
                UPDATE @tv 
                SET SoTienThuong = ROUND(@MucThuong_NhomTacGia / @CountTacGia, 0)
                WHERE VaiTro IN (1, 2);
            END;

            -- Bù trừ làm tròn vào tác giả đầu tiên
            DECLARE @DiffTacGia NUMERIC(18, 0) = @MucThuong_NhomTacGia - (SELECT SUM(SoTienThuong) FROM @tv WHERE VaiTro IN (1, 2));
            DECLARE @FirstAuthorSTT INT = (SELECT TOP 1 STT FROM @tv WHERE VaiTro IN (1, 2) ORDER BY STT ASC);
            IF @FirstAuthorSTT IS NOT NULL AND @DiffTacGia <> 0
            BEGIN
                UPDATE @tv SET SoTienThuong = SoTienThuong + @DiffTacGia WHERE STT = @FirstAuthorSTT;
            END;
        END;

        -- 4.2. Nhóm GVHD (VaiTro = 3)
        IF @CountGVHD > 0
        BEGIN
            DECLARE @CalcSumRateGVHD NUMERIC(9, 2) = (SELECT SUM(TyLeDongGop) FROM @tv WHERE VaiTro = 3);
            IF @CalcSumRateGVHD > 0
            BEGIN
                UPDATE @tv 
                SET SoTienThuong = ROUND((@MucThuong_GVHD * TyLeDongGop) / @CalcSumRateGVHD, 0)
                WHERE VaiTro = 3;
            END
            ELSE
            BEGIN
                UPDATE @tv 
                SET SoTienThuong = ROUND(@MucThuong_GVHD / @CountGVHD, 0)
                WHERE VaiTro = 3;
            END;

            -- Bù trừ làm tròn vào GVHD đầu tiên
            DECLARE @DiffGVHD NUMERIC(18, 0) = @MucThuong_GVHD - (SELECT SUM(SoTienThuong) FROM @tv WHERE VaiTro = 3);
            DECLARE @FirstMentorSTT INT = (SELECT TOP 1 STT FROM @tv WHERE VaiTro = 3 ORDER BY STT ASC);
            IF @FirstMentorSTT IS NOT NULL AND @DiffGVHD <> 0
            BEGIN
                UPDATE @tv SET SoTienThuong = SoTienThuong + @DiffGVHD WHERE STT = @FirstMentorSTT;
            END;
        END;

        -- 4.3. Nhóm cán bộ hỗ trợ SHTT (VaiTro = 4)
        IF @CountHoTro > 0
        BEGIN
            UPDATE @tv SET SoTienThuong = @MucThuong_CanBoHoTro WHERE VaiTro = 4;
        END;
    END;

    -- 5. Trả về kết quả
    SELECT 
        ThanhVienID,
        MaDinhDanh,
        HoTen,
        VaiTro,
        Is_SinhVien,
        Is_NhanVien,
        TenPhongBan,
        SoTaiKhoan,
        NganHang,
        TenChuTaiKhoan,
        TyLeDongGop,
        SoTienThuong,
        Is_DaiDienNhanTien,
        Email
    FROM @tv
    ORDER BY STT ASC;
END;
