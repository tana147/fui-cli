CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_INS_Obj]
    @KhenThuongObj NVARCHAR(MAX),
    @MembersObjArr NVARCHAR(MAX),
    @FilesObjArr NVARCHAR(MAX),
    @TrangThai INT,
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
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
        @GhiChu NVARCHAR(500);

    SELECT 
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
        @GhiChu = json.GhiChu
    FROM OPENJSON(@KhenThuongObj)
    WITH (
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
        GhiChu NVARCHAR(500)
    ) AS json;

    -- 1. Insert bảng chính
    INSERT INTO ThiKHCN_KhenThuong (
        DotID,
        LoaiKhenThuong,
        TenCuocThi_CongTrinh,
        CapDoCuocThi,
        LoaiHinhCuocThi,
        GiaiThuong,
        LoaiSHTT,
        PhamViSHTT,
        Is_DauRaDeTaiCoSo,
        SoQuyetDinh_VanBang,
        NgayBanHanh,
        TongTienThuong,
        HinhThucThanhToan,
        TrangThai,
        GhiChu,
        NhanVienSubmit,
        ThoiGianSubmit,
        NhanVienCapNhat,
        ThoiGianCapNhat,
        Is_Xoa
    ) VALUES (
        @DotID,
        @LoaiKhenThuong,
        @TenCuocThi_CongTrinh,
        @CapDoCuocThi,
        @LoaiHinhCuocThi,
        @GiaiThuong,
        @LoaiSHTT,
        @PhamViSHTT,
        @Is_DauRaDeTaiCoSo,
        @SoQuyetDinh_VanBang,
        @NgayBanHanh,
        0,
        @HinhThucThanhToan,
        @TrangThai,
        @GhiChu,
        @SYS_UserID,
        GETDATE(),
        @SYS_UserID,
        GETDATE(),
        0
    );

    DECLARE @KhenThuongID INT = SCOPE_IDENTITY();

    -- 2. Insert danh sách thành viên
    IF @MembersObjArr IS NOT NULL AND LEN(@MembersObjArr) > 2
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
            0,
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
            Is_DaiDienNhanTien BIT
        ) AS m;
    END;

    -- 3. Insert danh sách file minh chứng
    IF @FilesObjArr IS NOT NULL AND LEN(@FilesObjArr) > 2
    BEGIN
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
        CASE WHEN @TrangThai = 1 THEN 'TAO_NHAP' ELSE 'NOP_DE_XUAT' END,
        CASE WHEN @TrangThai = 1 THEN N'Tạo hồ sơ nháp' ELSE N'Nộp hồ sơ đề xuất khen thưởng' END,
        @SYS_UserID, 
        GETDATE()
    );

    SELECT @KhenThuongID AS KhenThuongID;
END;