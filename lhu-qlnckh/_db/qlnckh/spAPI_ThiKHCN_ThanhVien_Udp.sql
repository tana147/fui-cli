CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_ThanhVien_Udp]
    @KhenThuongID INT,
    @CongThucID INT,
    @TongTienThuong NUMERIC(18,2),
    @HinhThucThanhToan TINYINT,
    @MembersObjArr NVARCHAR(MAX),
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF @HinhThucThanhToan IS NULL
    BEGIN
        SELECT @HinhThucThanhToan = ISNULL(HinhThucThanhToan, 1) FROM ThiKHCN_KhenThuong WHERE KhenThuongID = @KhenThuongID;
    END;

    -- Nếu có CongThucID > 0: Tự động tính toán tiền từ Backend để chống can thiệp từ client
    IF @CongThucID IS NOT NULL AND @CongThucID > 0 AND @MembersObjArr IS NOT NULL AND LEN(@MembersObjArr) > 2
    BEGIN
        DECLARE @calc TABLE (
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

        INSERT INTO @calc
        EXEC spAPI_ThiKHCN_PhiKhenThuong_Cal @CongThucID, @MembersObjArr, @HinhThucThanhToan;

        -- Ghi đè TongTienThuong chuẩn từ Backend
        SELECT @TongTienThuong = ISNULL(SUM(SoTienThuong), 0) FROM @calc;

        UPDATE ThiKHCN_KhenThuong
        SET 
            CongThucID = @CongThucID,
            TongTienThuong = @TongTienThuong,
            HinhThucThanhToan = @HinhThucThanhToan,
            NhanVienCapNhat = @SYS_UserID,
            ThoiGianCapNhat = GETDATE()
        WHERE KhenThuongID = @KhenThuongID;

        -- Đồng bộ toàn bộ danh sách thành viên (xóa cũ thêm mới để hỗ trợ cả thêm/sửa/xóa thành viên)
        DELETE FROM ThiKHCN_ThanhVien WHERE KhenThuongID = @KhenThuongID;

        INSERT INTO ThiKHCN_ThanhVien (
            KhenThuongID,
            VaiTro,
            Is_NhanVien,
            Is_SinhVien,
            MaDinhDanh,
            HoTen,
            Email,
            TenPhongBan,
            SoTaiKhoan,
            NganHang,
            TenChuTaiKhoan,
            TyLeDongGop,
            SoTienThuong,
            Is_DaiDienNhanTien,
            Is_Xoa
        )
        SELECT 
            @KhenThuongID,
            c.VaiTro,
            c.Is_NhanVien,
            c.Is_SinhVien,
            c.MaDinhDanh,
            c.HoTen,
            c.Email,
            c.TenPhongBan,
            c.SoTaiKhoan,
            c.NganHang,
            c.TenChuTaiKhoan,
            c.TyLeDongGop,
            c.SoTienThuong,
            c.Is_DaiDienNhanTien,
            0
        FROM @calc c;
    END
    ELSE
    BEGIN
        UPDATE ThiKHCN_KhenThuong
        SET 
            CongThucID = @CongThucID,
            TongTienThuong = @TongTienThuong,
            HinhThucThanhToan = ISNULL(@HinhThucThanhToan, HinhThucThanhToan),
            NhanVienCapNhat = @SYS_UserID,
            ThoiGianCapNhat = GETDATE()
        WHERE KhenThuongID = @KhenThuongID;

        IF @MembersObjArr IS NOT NULL AND LEN(@MembersObjArr) > 2
        BEGIN
            DELETE FROM ThiKHCN_ThanhVien WHERE KhenThuongID = @KhenThuongID;

            INSERT INTO ThiKHCN_ThanhVien (
                KhenThuongID,
                VaiTro,
                Is_NhanVien,
                Is_SinhVien,
                MaDinhDanh,
                HoTen,
                Email,
                TenPhongBan,
                SoTaiKhoan,
                NganHang,
                TenChuTaiKhoan,
                TyLeDongGop,
                SoTienThuong,
                Is_DaiDienNhanTien,
                Is_Xoa
            )
            SELECT 
                @KhenThuongID,
                m.VaiTro,
                ISNULL(m.Is_NhanVien, 1),
                ISNULL(m.Is_SinhVien, 0),
                m.MaDinhDanh,
                m.HoTen,
                m.Email,
                m.TenPhongBan,
                m.SoTaiKhoan,
                m.NganHang,
                m.TenChuTaiKhoan,
                ISNULL(m.TyLeDongGop, 100),
                ISNULL(m.SoTienThuong, 0),
                ISNULL(m.Is_DaiDienNhanTien, 0),
                0
            FROM OPENJSON(@MembersObjArr)
            WITH (
                VaiTro TINYINT,
                Is_NhanVien BIT,
                Is_SinhVien BIT,
                MaDinhDanh VARCHAR(20),
                HoTen NVARCHAR(200),
                Email VARCHAR(100),
                TenPhongBan NVARCHAR(250),
                SoTaiKhoan NVARCHAR(50),
                NganHang NVARCHAR(250),
                TenChuTaiKhoan NVARCHAR(150),
                TyLeDongGop FLOAT,
                SoTienThuong NUMERIC(18,2),
                Is_DaiDienNhanTien BIT
            ) AS m;
        END;
    END;

    INSERT INTO ThiKHCN_LichSu (KhenThuongID, HanhDong, MoTa, NhanVien, ThoiGian)
    VALUES (@KhenThuongID, 'TINH_TIEN', N'Tính tiền và phân bổ thưởng cho thành viên', @SYS_UserID, GETDATE());

    SELECT 1 AS Result;
END;