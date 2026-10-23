CREATE PROCEDURE [dbo].[spAPI_AnPham_INS_Obj]
    @AnPhamObj NVARCHAR(MAX),
    @AuthorsObjArr NVARCHAR(MAX),
    @ProofSObjArr NVARCHAR(MAX),
    @TrangThai INT,
    @SYS_UserID VARCHAR(9)
AS
    BEGIN;
        /* Step 1: INSERT DANH SÁCH ẤN PHẨM */
        DECLARE
            @DanhMucLoaiTapChiID        INT,
            @TenLoaiDanhMucTapChi       NVARCHAR(500),
            @LoaiAnPhamID               INT,
            @TenAnPham                  NVARCHAR(500),
            @LoaiSubAnPhamID            INT,
            @TenLoaiSubAnPham           NVARCHAR(500),
            @TenLoaiAnPham              NVARCHAR(500),
            @TenTapChi                  NVARCHAR(500),
            @MaNhanVienDaiDien          VARCHAR(9),
            @TenNhanVienDaiDien         NVARCHAR(250),
            @DonViDaiDien               NVARCHAR(250),
            @SoTacGia_LHU               INT,
            @DuongDanBaiBao             NVARCHAR(500),
            @NamDangBai                 INT,
            @NoiDangBai                 NVARCHAR(500),
            @DiemHoiDong                NUMERIC(18, 2),
            @HeSo_IF                    NUMERIC(18, 2),
            @TenHeSoChatLuong           VARCHAR(10),
            --@HeSoChatLuongID INT,
            @PhiThongBao                NUMERIC(18, 2),
            @PhiDangBai                 NUMERIC(18, 2),
            @HoanPhiDangBai             NUMERIC(18, 2),
            @ISSN                       VARCHAR(30),
            @Dieu                       INT,
            @Khoan                      INT,
            @Muc                        CHAR(1),
            @TongSoTienThuong           NUMERIC(18, 2),
            @GhiChu                     NVARCHAR(500),
            @SoQuyetDinhKhenThuong      NVARCHAR(20),
            @FileIDKhenThuong           CHAR(32),
            @FileIDAnPham               CHAR(32),
            @HinhThucThanhToan          TINYINT,
            @NguonCapKinhPhi            VARCHAR(9),
            @NhomAnPham                 TINYINT,
            @FileIDMinhChungHoTroCaoHoc CHAR(32),
            @FileIDMinhChungWos         CHAR(32),
            @FileIDMinhChungScopus      CHAR(32),
            @FileIDMinhChungHDCDGSNN    CHAR(32),
            @FileIDMinhChungLacHong     CHAR(32),
            @FileIDMinhChungKhac        CHAR(32)

        -- Parse JSON input
        SELECT
            @DanhMucLoaiTapChiID = json.DanhMucLoaiTapChiID,
            @TenLoaiDanhMucTapChi = json.TenLoaiDanhMucTapChi,
            @TenTapChi = json.TenTapChi,
            @TenAnPham = json.TenAnPham,
            @LoaiAnPhamID = json.LoaiAnPhamID,
            @TenLoaiAnPham = json.TenLoaiAnPham,
            @LoaiSubAnPhamID = json.LoaiSubAnPhamID,
            @TenLoaiSubAnPham = json.TenLoaiSubAnPham,
            @MaNhanVienDaiDien = json.MaNhanVienDaiDien,
            @TenNhanVienDaiDien = json.TenNhanVienDaiDien,
            @DonViDaiDien = json.DonViDaiDien,
            @SoTacGia_LHU = json.SoTacGia_LHU,
            @DuongDanBaiBao = json.DuongDanBaiBao,
            @NamDangBai = json.NamDangBai,
            @NoiDangBai = json.NoiDangBai,
            @DiemHoiDong = json.DiemHoiDong,
            @HeSo_IF = json.HeSo_IF,
            @TenHeSoChatLuong = json.TenHeSoChatLuong,
            --  @HeSoChatLuongID = json.HeSoChatLuongID,
            @PhiThongBao = json.PhiThongBao,
            @PhiDangBai = json.PhiDangBai,
            @HoanPhiDangBai = json.HoanPhiDangBai,
            @ISSN = json.ISSN,
            @Dieu = json.Dieu,
            @Khoan = json.Khoan,
            @Muc = json.Muc,
            @TongSoTienThuong = json.TongSoTienThuong,
            @GhiChu = json.GhiChu,
            @SoQuyetDinhKhenThuong = json.SoQuyetDinhKhenThuong,
            @FileIDKhenThuong = json.FileIDKhenThuong,
            @FileIDAnPham = json.FileIDAnPham,
            @HinhThucThanhToan = json.HinhThucThanhToan,
            @NguonCapKinhPhi = json.NguonCapKinhPhi,
            @NhomAnPham = json.NhomAnPham,
            @FileIDMinhChungHoTroCaoHoc = json.FileIDMinhChungHoTroCaoHoc,
            @FileIDMinhChungWos = json.FileIDMinhChungWos,
            @FileIDMinhChungScopus = json.FileIDMinhChungScopus,
            @FileIDMinhChungHDCDGSNN = json.FileIDMinhChungHDCDGSNN,
            @FileIDMinhChungLacHong = json.FileIDMinhChungLacHong,
            @FileIDMinhChungKhac = json.FileIDMinhChungKhac

        FROM
            OPENJSON(@AnPhamObj)
            WITH(
                DanhMucLoaiTapChiID INT,
                TenLoaiDanhMucTapChi NVARCHAR(500),
                TenTapChi NVARCHAR(500),
                TenAnPham NVARCHAR(500),
                LoaiAnPhamID INT,
                TenLoaiAnPham NVARCHAR(500),
                LoaiSubAnPhamID INT,
                TenLoaiSubAnPham NVARCHAR(500),
                MaNhanVienDaiDien VARCHAR(9),
                TenNhanVienDaiDien NVARCHAR(250),
                DonViDaiDien NVARCHAR(250),
                SoTacGia_LHU INT,
                DuongDanBaiBao NVARCHAR(500),
                NamDangBai INT,
                NoiDangBai NVARCHAR(500),
                DiemHoiDong NUMERIC(18, 2),
                HeSo_IF NUMERIC(18, 2),
                TenHeSoChatLuong VARCHAR(10),
                HeSoChatLuongID INT,
                PhiThongBao NUMERIC(18, 2),
                PhiDangBai NUMERIC(18, 2),
                HoanPhiDangBai NUMERIC(18, 2),
                ISSN VARCHAR(30),
                Dieu INT,
                Khoan INT,
                Muc CHAR(1),
                TongSoTienThuong NUMERIC(18, 2),
                GhiChu NVARCHAR(500),
                SoQuyetDinhKhenThuong NVARCHAR(20),
                FileIDKhenThuong CHAR(32),
                FileIDAnPham CHAR(32),
                HinhThucThanhToan TINYINT,
                NguonCapKinhPhi VARCHAR(9),
                NhomAnPham TINYINT,
                FileIDMinhChungHoTroCaoHoc CHAR(32),
                FileIDMinhChungWos CHAR(32),
                FileIDMinhChungScopus CHAR(32),
                FileIDMinhChungHDCDGSNN CHAR(32),
                FileIDMinhChungLacHong CHAR(32),
                FileIDMinhChungKhac CHAR(32)
                ) AS json;
        --DECLARE @DiemHeSoChatLuong NUMERIC(18, 2);
        --SET @DiemHeSoChatLuong = (
        --                         SELECT
        --                             DiemHeSoChatLuong
        --                         FROM HeSoChatLuong HS
        --                         WHERE HS.HeSoChatLuongID = @HeSoChatLuongID
        --                         );
        DECLARE @GroupAnPham_Edit INT;
        SET @GroupAnPham_Edit = CASE WHEN @LoaiAnPhamID IN (1, 2) THEN 3
                                     WHEN @LoaiAnPhamID IN (4, 5, 13, 15, 16) THEN 1
                                     WHEN (
                                          @LoaiAnPhamID = 3
                                          AND (@LoaiSubAnPhamID IN (8, 23) OR @LoaiSubAnPhamID IS NULL)
                                          )
                                          OR (@LoaiAnPhamID = 12) THEN 2
                                     WHEN (@LoaiAnPhamID = 3 AND @LoaiSubAnPhamID = 9)
                                          OR @LoaiAnPhamID = 10 THEN 4
                                     WHEN @LoaiAnPhamID = 6 THEN 5 -- Sách
                                     ELSE NULL END;
        -- Your existing INSERT statement remains the same
        INSERT INTO [dbo].[AnPham](
                                  [DanhMucLoaiTapChiID],
                                  [TenLoaiDanhMucTapChi],
                                  [LoaiAnPhamID],
                                  [TenLoaiAnPham],
                                  [LoaiSubAnPhamID],
                                  [TenLoaiSubAnPham],
                                  [TenTapChi],
                                  [TenAnPham],
                                  [MaNhanVienDaiDien],
                                  [TenNhanVienDaiDien],
                                  [DonViDaiDien],
                                  [SoTacGia_LHU],
                                  [DuongDanBaiBao],
                                  [NamDangBai],
                                  [NoiDangBai],
                                  [DiemHoiDong],
                                  [HeSo_IF],
                                  -- [TenHeSoChatLuong],
                                  -- [DiemHeSoChatLuong],
                                  --   [HeSoChatLuongID],
                                  [PhiThongBao],
                                  [PhiDangBai],
                                  [HoanPhiDangBai],
                                  [ISSN],
                                  [Dieu],
                                  [Khoan],
                                  [Muc],
                                  [TongSoTienThuong],
                                  [GhiChu],
                                  [SoQuyetDinhKhenThuong],
                                  [FileIDKhenThuong],
                                  [FileIDAnPham],
                                  [TrangThai],
                                  [NhanVienSubmit],
                                  [ThoiGianSubmit],
                                  [NhanVienCapNhat],
                                  [ThoiGianCapNhat],
                                  [Is_Xoa],
                                  [HinhThucThanhToan],
                                  [NguonCapKinhPhi],
                                  [NhomAnPham],
                                  [FileIDMinhChungHoTroCaoHoc],
                                  [FileIDMinhChungWos],
                                  [FileIDMinhChungScopus],
                                  [FileIDMinhChungHDCDGSNN],
                                  FileIDMinhChungLacHong,
                                  FileIDMinhChungKhac,
                                  [GroupAnPham_Edit]
                                  )
        VALUES
             (
             @DanhMucLoaiTapChiID,
             @TenLoaiDanhMucTapChi,
             @LoaiAnPhamID,
             @TenLoaiAnPham,
             @LoaiSubAnPhamID,
             @TenLoaiSubAnPham,
             @TenTapChi,
             @TenAnPham,
             @MaNhanVienDaiDien,
             @TenNhanVienDaiDien,
             @DonViDaiDien,
             @SoTacGia_LHU,
             @DuongDanBaiBao,
             @NamDangBai,
             @NoiDangBai,
             @DiemHoiDong,
             @HeSo_IF,
             -- @TenHeSoChatLuong,
             -- @DiemHeSoChatLuong,
             --   @HeSoChatLuongID,
             @PhiThongBao,
             @PhiDangBai,
             @HoanPhiDangBai,
             @ISSN,
             @Dieu,
             @Khoan,
             @Muc,
             @TongSoTienThuong,
             @GhiChu,
             @SoQuyetDinhKhenThuong,
             @FileIDKhenThuong,
             @FileIDAnPham,
             @TrangThai,
             @SYS_UserID,
             GETDATE(),
             @SYS_UserID,
             GETDATE(),
             0,
             @HinhThucThanhToan,
             @NguonCapKinhPhi,
             @NhomAnPham,
             @FileIDMinhChungHoTroCaoHoc,
             @FileIDMinhChungWos,
             @FileIDMinhChungScopus,
             @FileIDMinhChungHDCDGSNN,
             @FileIDMinhChungLacHong,
             @FileIDMinhChungKhac,
             @GroupAnPham_Edit
             );

        /* Step 2: INSERT DANH SÁCH TÁC GIẢ*/
        DECLARE @AnPhamID INT;
        IF @@ROWCOUNT > 0 SELECT @AnPhamID = @@IDENTITY;

        -- Insert author data into AnPham_TacGia table
        INSERT INTO [dbo].[AnPham_TacGia](
                                         [AnPhamID],
                                         [MaNhanVien],
                                         [HoTacGia],
                                         [TenTacGia],
                                         [EmailTacGia],
                                         [AP_Index],
                                         [TenPhongBan],
                                         [SoTaiKhoan],
                                         [NganHang],
                                         [TenChuTaiKhoan],
                                         [TrangThai],
                                         [NhanVienCapNhat],
                                         [ThoiGianCapNhat],
                                         [Is_NhanVien],
                                         [TacGiaGroupID],
                                         [Is_Xoa],
                                         [Is_TacGiaChinh],
                                         [Is_TacGiaPhu],
                                         [NguoiDaiDienQuyetToan],
                                         [NguonCapKinhPhi],
                                         [HeSoHoTroCaoHoc]
                                         )
        SELECT
            @AnPhamID,
            json.MaNhanVien,
            json.HoTacGia,
            json.TenTacGia,
            json.EmailTacGia,
            json.AP_Index,
            json.TenPhongBan,
            json.SoTaiKhoan,
            json.NganHang,
            json.TenChuTaiKhoan,
            0,
            @SYS_UserID,
            GETDATE(),
            CASE WHEN json.TacGiaGroupID IN (1, 2) THEN 1
                 ELSE ISNULL(json.Is_NhanVien, 0) END,
            json.TacGiaGroupID,
            0,
            json.Is_TacGiaChinh,
            json.Is_TacGiaPhu,
            json.NguoiDaiDienQuyetToan,
            json.NguonCapKinhPhi,
            json.HeSoHoTroCaoHoc
        FROM
            OPENJSON(@AuthorsObjArr)
            WITH(
                MaNhanVien VARCHAR(9),
                HoTacGia NVARCHAR(150),
                TenTacGia NVARCHAR(150),
                EmailTacGia VARCHAR(50),
                AP_Index NUMERIC(18, 2),
                TenPhongBan NVARCHAR(250),
                SoTaiKhoan NVARCHAR(50),
                NganHang NVARCHAR(250),
                TenChuTaiKhoan NVARCHAR(150),
                Is_NhanVien BIT,
                TacGiaGroupID TINYINT,
                Is_TacGiaChinh BIT,
                Is_TacGiaPhu BIT,
                NguoiDaiDienQuyetToan BIT,
                NguonCapKinhPhi VARCHAR(9),
                HeSoHoTroCaoHoc FLOAT
                ) AS json;
        DECLARE @TongSoTacGia INT;
        SET @TongSoTacGia = (
                            SELECT
                                COUNT(*)
                            FROM AnPham_TacGia
                            WHERE AnPhamID   = @AnPhamID
                                  AND Is_Xoa = 0
                            );
        --SET @SoTacGia_LHU= (SELECT COUNT(*) FROM AnPham_TacGia WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0 AND Is_NhanVien = 1)
        SET @SoTacGia_LHU = (
                            SELECT
                                COUNT(*)
                            FROM AnPham_TacGia
                            WHERE AnPhamID   = @AnPhamID
                                  AND Is_Xoa = 0
                                  AND TacGiaGroupID IN (1, 2)
                            );
        UPDATE
            AnPham
        SET
            TongSoTacGia = @TongSoTacGia,
            SoTacGia_LHU = @SoTacGia_LHU
        WHERE AnPhamID = @AnPhamID;

        --EXEC spCalculate_APIndex @AnPhamID

        /* Step 3: INSERT DANH SÁCH FILE MINH CHỨNG HOÀN PHÍ */
        -- Parse JSON proofs data
        INSERT INTO [dbo].[AnPham_File](
                                       [AnPhamID],
                                       [FileIDList],
                                       [LoaiFile],
                                       [MoTa],
                                       [TrangThai],
                                       [NhanVienCapNhat],
                                       [ThoiGianCapNhat],
                                       [Is_Xoa]
                                       )
        SELECT
            @AnPhamID,
            json.FileIDList,
            json.LoaiFile,
            json.MoTa,
            0,
            @SYS_UserID,
            GETDATE(),
            0
        FROM
            OPENJSON(@ProofSObjArr)
            WITH(FileIDList CHAR(500), LoaiFile TINYINT, MoTa NVARCHAR(500)) AS json;
        SELECT @AnPhamID AS AnPhamID;
    END;