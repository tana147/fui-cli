CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_Udp_Obj]
    @KhenThuongObj NVARCHAR(MAX),
    @MembersObjArr NVARCHAR(MAX),
    @FilesObjArr NVARCHAR(MAX),
    @TrangThai INT,
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @KhenThuongID INT,
        @DotID INT,
        @LoaiKhenThuong TINYINT,
        @TenCuocThi_CongTrinh NVARCHAR(500),
        @CapDoCuocThi TINYINT,
        @LoaiHinhCuocThi TINYINT,
        @GiaiThuong TINYINT,
        @LoaiSHTT TINYINT,
        @PhamViSHTT TINYINT,
        @Is_DauRaDeTaiCoSo BIT,
        @SoQuyetDinh_VanBang VARCHAR(100),
        @NgayBanHanh DATE,
        @HinhThucThanhToan TINYINT,
        @CongThucID INT,
        @TongTienThuong NUMERIC(18,2),
        @GhiChu NVARCHAR(500),
        @NoiCapVanBang NVARCHAR(250),
        @MaSoDeTai VARCHAR(50);

    SELECT 
        @KhenThuongID = json.KhenThuongID,
        @DotID = json.DotID,
        @LoaiKhenThuong = json.LoaiKhenThuong,
        @TenCuocThi_CongTrinh = json.TenCuocThi_CongTrinh,
        @CapDoCuocThi = json.CapDoCuocThi,
        @LoaiHinhCuocThi = json.LoaiHinhCuocThi,
        @GiaiThuong = json.GiaiThuong,
        @LoaiSHTT = json.LoaiSHTT,
        @PhamViSHTT = json.PhamViSHTT,
        @Is_DauRaDeTaiCoSo = ISNULL(json.Is_DauRaDeTaiCoSo, 0),
        @SoQuyetDinh_VanBang = json.SoQuyetDinh_VanBang,
        @NgayBanHanh = json.NgayBanHanh,
        @HinhThucThanhToan = ISNULL(json.HinhThucThanhToan, 1),
        @CongThucID = json.CongThucID,
        @TongTienThuong = json.TongTienThuong,
        @GhiChu = json.GhiChu,
        @NoiCapVanBang = json.NoiCapVanBang,
        @MaSoDeTai = json.MaSoDeTai
    FROM OPENJSON(@KhenThuongObj)
    WITH (
        KhenThuongID INT,
        DotID INT,
        LoaiKhenThuong TINYINT,
        TenCuocThi_CongTrinh NVARCHAR(500),
        CapDoCuocThi TINYINT,
        LoaiHinhCuocThi TINYINT,
        GiaiThuong TINYINT,
        LoaiSHTT TINYINT,
        PhamViSHTT TINYINT,
        Is_DauRaDeTaiCoSo BIT,
        SoQuyetDinh_VanBang VARCHAR(100),
        NgayBanHanh DATE,
        HinhThucThanhToan TINYINT,
        CongThucID INT,
        TongTienThuong NUMERIC(18,2),
        GhiChu NVARCHAR(500),
        NoiCapVanBang NVARCHAR(250),
        MaSoDeTai VARCHAR(50)
    ) AS json;

    -- 1. Update bảng chính
    UPDATE ThiKHCN_KhenThuong
    SET 
        DotID = ISNULL(@DotID, DotID),
        LoaiKhenThuong = @LoaiKhenThuong,
        TenCuocThi_CongTrinh = @TenCuocThi_CongTrinh,
        CapDoCuocThi = @CapDoCuocThi,
        LoaiHinhCuocThi = @LoaiHinhCuocThi,
        GiaiThuong = @GiaiThuong,
        LoaiSHTT = @LoaiSHTT,
        PhamViSHTT = @PhamViSHTT,
        Is_DauRaDeTaiCoSo = @Is_DauRaDeTaiCoSo,
        SoQuyetDinh_VanBang = @SoQuyetDinh_VanBang,
        NgayBanHanh = @NgayBanHanh,
        NoiCapVanBang = @NoiCapVanBang,
        MaSoDeTai = @MaSoDeTai,
        HinhThucThanhToan = @HinhThucThanhToan,
        CongThucID = ISNULL(@CongThucID, CongThucID),
        TongTienThuong = ISNULL(@TongTienThuong, TongTienThuong),
        TrangThai = @TrangThai,
        LyDoReject = CASE WHEN @TrangThai = 2 THEN '' ELSE LyDoReject END,
        GhiChu = @GhiChu,
        NhanVienCapNhat = @SYS_UserID,
        ThoiGianCapNhat = GETDATE()
    WHERE KhenThuongID = @KhenThuongID;

    -- 2. Cập nhật danh sách thành viên (Xóa cũ nạp mới nếu có gửi mảng mới)
    IF @MembersObjArr IS NOT NULL AND LEN(@MembersObjArr) > 2
    BEGIN
        DELETE FROM ThiKHCN_ThanhVien WHERE KhenThuongID = @KhenThuongID;

        -- Nếu có CongThucID: Tự động chạy tính toán chuẩn từ Backend để chống can thiệp từ Client
        IF @CongThucID IS NOT NULL AND @CongThucID > 0
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

            -- Cập nhật lại tổng tiền thưởng chính xác vào bảng Khen thưởng
            UPDATE ThiKHCN_KhenThuong
            SET TongTienThuong = (SELECT ISNULL(SUM(SoTienThuong), 0) FROM @calc)
            WHERE KhenThuongID = @KhenThuongID;

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

    -- 3. Cập nhật danh sách file minh chứng
    IF @FilesObjArr IS NOT NULL AND LEN(@FilesObjArr) > 2
    BEGIN
        DELETE FROM ThiKHCN_File WHERE KhenThuongID = @KhenThuongID;

        INSERT INTO ThiKHCN_File (
            KhenThuongID,
            FileID,
            FileName,
            DinhDangFile,
            LoaiMinhChung,
            MoTa,
            CreateUser,
            CreateTime,
            Is_Xoa
        )
        SELECT 
            @KhenThuongID,
            f.FileID,
            f.FileName,
            f.DinhDangFile,
            f.LoaiMinhChung,
            f.MoTa,
            @SYS_UserID,
            GETDATE(),
            0
        FROM OPENJSON(@FilesObjArr)
        WITH (
            FileID CHAR(32),
            FileName NVARCHAR(250),
            DinhDangFile VARCHAR(10),
            LoaiMinhChung TINYINT,
            MoTa NVARCHAR(500)
        ) AS f;
    END;

    -- 4. Ghi log lịch sử
    INSERT INTO ThiKHCN_LichSu (KhenThuongID, HanhDong, MoTa, NhanVien, ThoiGian)
    VALUES (
        @KhenThuongID, 
        'CAP_NHAT', 
        N'Cập nhật thông tin hồ sơ đề xuất', 
        @SYS_UserID, 
        GETDATE()
    );

    SELECT @KhenThuongID AS KhenThuongID;
END;