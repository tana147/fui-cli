CREATE PROCEDURE [dbo].[spAPI_AnPham_Udp_Obj]
    @AnPhamObj NVARCHAR(MAX),
    @AuthorsObjArr NVARCHAR(MAX),
    @ProofSObjArr NVARCHAR(MAX),
    @TrangThai TINYINT, --TrangThai = 2 THEN N'Đã duyệt'
    @DotDuyetID INT,
    @SYS_UserID VARCHAR(9)
AS
    BEGIN;

        IF @TrangThai = 3
        BEGIN
            IF @DotDuyetID IS NULL OR @DotDuyetID <= 0
            BEGIN
                RAISERROR(N'Vui lòng chọn đợt duyệt trước khi duyệt ấn phẩm', 16, 1)
                RETURN
            END
            IF NOT EXISTS (SELECT 1 FROM AnPham_DotDuyet WHERE AnPham_DotDuyetID = @DotDuyetID AND Is_Xoa = 0)
            BEGIN
                RAISERROR(N'Đợt duyệt không tồn tại hoặc đã bị xoá', 16, 1)
                RETURN
            END
        END

        /* Step 1: UPDATE THÔNG TIN ẤN PHẨM */
        DECLARE
            @AnPhamID                   INT,
            @DanhMucLoaiTapChiID        INT,
            @TenLoaiDanhMucTapChi       NVARCHAR(500),
            @LoaiAnPhamID               INT,
            @TenLoaiAnPham              NVARCHAR(500),
            @LoaiSubAnPhamID            INT,
            @TenLoaiSubAnPham           NVARCHAR(500),
            @TenTapChi                  NVARCHAR(500),
            @TenAnPham                  NVARCHAR(500),
            @MaNhanVienDaiDien          VARCHAR(9),
            @TenNhanVienDaiDien         NVARCHAR(250),
            @DonViDaiDien               NVARCHAR(250),
            @SoTacGia_LHU               INT,
            @DuongDanBaiBao             NVARCHAR(500),
            @NamDangBai                 INT,
            @NoiDangBai                 NVARCHAR(500),
            @DiemHoiDong                NUMERIC(18, 2),
            @HeSo_IF                    NUMERIC(18, 2),
            -- @TenHeSoChatLuong           VARCHAR(10),
            --  @HeSoChatLuongID            INT,
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
            @CongThucKhenThuongID       INT,
            @HinhThucThanhToan          TINYINT,
            @NguonCapKinhPhi            VARCHAR(9),
            @NhomAnPham                 TINYINT,
            @FileIDMinhChungHoTroCaoHoc CHAR(32),
            @FileIDMinhChungWos         CHAR(32),
            @FileIDMinhChungScopus      CHAR(32),
            @FileIDMinhChungHDCDGSNN    CHAR(32),
            @FileIDMinhChungLacHong     CHAR(32),
            @FileIDMinhChungKhac     CHAR(32),
            @Is_DeNghiXetThuong         BIT,
            @TapSoTrang                 NVARCHAR(100),
            @ThangDang                  TINYINT,
            @TheLoaiBienSoanID          INT,
            @DoiLink                    NVARCHAR(500)
        -- Parse JSON input
        SELECT
            @AnPhamID = json.AnPhamID,
            @DanhMucLoaiTapChiID = json.DanhMucLoaiTapChiID,
            @TenLoaiDanhMucTapChi = json.TenLoaiDanhMucTapChi,
            @LoaiAnPhamID = json.LoaiAnPhamID,
            @TenLoaiAnPham = json.TenLoaiAnPham,
            @LoaiSubAnPhamID = json.LoaiSubAnPhamID,
            @TenLoaiSubAnPham = json.TenLoaiSubAnPham,
            @TenTapChi = json.TenTapChi,
            @TenAnPham = json.TenAnPham,
            @MaNhanVienDaiDien = json.MaNhanVienDaiDien,
            @TenNhanVienDaiDien = json.TenNhanVienDaiDien,
            @DonViDaiDien = json.DonViDaiDien,
            @SoTacGia_LHU = json.SoTacGia_LHU,
            @DuongDanBaiBao = json.DuongDanBaiBao,
            @NamDangBai = json.NamDangBai,
            @NoiDangBai = json.NoiDangBai,
            @DiemHoiDong = json.DiemHoiDong,
            @HeSo_IF = json.HeSo_IF,
            --  @TenHeSoChatLuong = json.TenHeSoChatLuong,
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
            @CongThucKhenThuongID = json.CongThucKhenThuongID,
            @HinhThucThanhToan = json.HinhThucThanhToan,
            @NguonCapKinhPhi = json.NguonCapKinhPhi,
            @NhomAnPham = json.NhomAnPham,
            @FileIDMinhChungHoTroCaoHoc = json.FileIDMinhChungHoTroCaoHoc,
            @FileIDMinhChungWos = json.FileIDMinhChungWos,
            @FileIDMinhChungScopus = json.FileIDMinhChungScopus,
            @FileIDMinhChungHDCDGSNN = json.FileIDMinhChungHDCDGSNN,
            @FileIDMinhChungLacHong = json.FileIDMinhChungLacHong,
            @FileIDMinhChungKhac = json.FileIDMinhChungKhac,
            @Is_DeNghiXetThuong = json.Is_DeNghiXetThuong,
            @TapSoTrang = json.TapSoTrang,
            @ThangDang = json.ThangDang,
            @TheLoaiBienSoanID = json.TheLoaiBienSoanID,
            @DoiLink = json.DoiLink
        FROM
            OPENJSON(@AnPhamObj)
            WITH(
                AnPhamID INT,
                DanhMucLoaiTapChiID INT,
                TenLoaiDanhMucTapChi NVARCHAR(500),
                LoaiAnPhamID INT,
                TenLoaiAnPham NVARCHAR(500),
                LoaiSubAnPhamID INT,
                TenLoaiSubAnPham NVARCHAR(500),
                TenTapChi NVARCHAR(500),
                TenAnPham NVARCHAR(500),
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
                CongThucKhenThuongID INT,
                HinhThucThanhToan TINYINT,
                NguonCapKinhPhi VARCHAR(9),
                NhomAnPham TINYINT,
                FileIDMinhChungHoTroCaoHoc CHAR(32),
                FileIDMinhChungWos CHAR(32),
                FileIDMinhChungScopus CHAR(32),
                FileIDMinhChungHDCDGSNN CHAR(32),
                FileIDMinhChungLacHong CHAR(32),
                FileIDMinhChungKhac CHAR(32),
                Is_DeNghiXetThuong BIT,
                TapSoTrang NVARCHAR(100),
                ThangDang TINYINT,
                TheLoaiBienSoanID INT,
                DoiLink NVARCHAR(500)
                ) AS json;
        --DECLARE @DiemHeSoChatLuong NUMERIC(18, 2);
        --SET @DiemHeSoChatLuong = (
        --                         SELECT
        --                             DiemHeSoChatLuong
        --                         FROM HeSoChatLuong HS
        --                         WHERE HS.HeSoChatLuongID = @HeSoChatLuongID
        --                         );
        UPDATE
            [dbo].[AnPham]
        SET
            [DanhMucLoaiTapChiID] = @DanhMucLoaiTapChiID,
            [TenLoaiDanhMucTapChi] = @TenLoaiDanhMucTapChi,
            [LoaiAnPhamID] = @LoaiAnPhamID,
            [TenLoaiAnPham] = @TenLoaiAnPham,
            [LoaiSubAnPhamID] = @LoaiSubAnPhamID,
            [TenLoaiSubAnPham] = @TenLoaiSubAnPham,
            [TenTapChi] = @TenTapChi,
            [TenAnPham] = @TenAnPham,
            [MaNhanVienDaiDien] = @MaNhanVienDaiDien,
            [TenNhanVienDaiDien] = @TenNhanVienDaiDien,
            [DonViDaiDien] = @DonViDaiDien,
            [SoTacGia_LHU] = @SoTacGia_LHU,
            [DuongDanBaiBao] = @DuongDanBaiBao,
            [NamDangBai] = @NamDangBai,
            [NoiDangBai] = @NoiDangBai,
            [DiemHoiDong] = @DiemHoiDong,
            [HeSo_IF] = @HeSo_IF,
            --   [TenHeSoChatLuong] = @TenHeSoChatLuong,
            --  [DiemHeSoChatLuong] = @DiemHeSoChatLuong,
            --  [HeSoChatLuongID] = @HeSoChatLuongID,
            [PhiThongBao] = @PhiThongBao,
            [PhiDangBai] = @PhiDangBai,
            [HoanPhiDangBai] = @HoanPhiDangBai,
            [ISSN] = @ISSN,
            [Dieu] = @Dieu,
            [Khoan] = @Khoan,
            [Muc] = @Muc,
            [TongSoTienThuong] = @TongSoTienThuong,
            [GhiChu] = @GhiChu,
            [SoQuyetDinhKhenThuong] = @SoQuyetDinhKhenThuong,
            [FileIDKhenThuong] = @FileIDKhenThuong,
            [FileIDAnPham] = @FileIDAnPham,
            [CongThucKhenThuongID] = @CongThucKhenThuongID,
            [TrangThai] = @TrangThai,
            [DotDuyet] = CASE WHEN @TrangThai = 3 THEN @DotDuyetID ELSE [DotDuyet] END,
            [ThoiGianDuyet] = CASE WHEN @TrangThai = 3 THEN CONVERT(VARCHAR(10), GETDATE(), 120) ELSE [ThoiGianDuyet] END,
            [NhanVienCapNhat] = @SYS_UserID,
            [ThoiGianCapNhat] = GETDATE(),
            HinhThucThanhToan = @HinhThucThanhToan,
            NguonCapKinhPhi = @NguonCapKinhPhi,
            NhomAnPham = @NhomAnPham,
            FileIDMinhChungHoTroCaoHoc = @FileIDMinhChungHoTroCaoHoc,
            FileIDMinhChungWos = @FileIDMinhChungWos,
            FileIDMinhChungScopus = @FileIDMinhChungScopus,
            FileIDMinhChungHDCDGSNN = @FileIDMinhChungHDCDGSNN,
            FileIDMinhChungLacHong = @FileIDMinhChungLacHong,
            FileIDMinhChungKhac = @FileIDMinhChungKhac,
            Is_DeNghiXetThuong = ISNULL(@Is_DeNghiXetThuong, [Is_DeNghiXetThuong]),
            TapSoTrang = @TapSoTrang,
            ThangDang = @ThangDang,
            TheLoaiBienSoanID = @TheLoaiBienSoanID,
            DoiLink = @DoiLink,
            GroupAnPham_Edit = CASE WHEN LoaiAnPhamID IN (1, 2) THEN 3 --Hội thảo
                                    WHEN LoaiAnPhamID IN (4, 5, 13, 15, 16) THEN 1 -- Quốc tế
                                    WHEN (LoaiAnPhamID = 3 AND (LoaiSubAnPhamID IN (8, 23) OR LoaiSubAnPhamID IS NULL))
                                         OR (LoaiAnPhamID = 12) THEN 2 -- Hội đồng giáo sư nhà nước
                                    WHEN (LoaiAnPhamID = 3 AND LoaiSubAnPhamID = 9)
                                         OR LoaiAnPhamID = 10 THEN 4 -- Bài báo Lạc Hồng
                                    WHEN LoaiAnPhamID = 6 THEN 5 -- Sách
                                    ELSE NULL END
        WHERE AnPhamID = @AnPhamID;

        IF @TrangThai = 3
            INSERT INTO AnPham_LichSu(AnPhamID, HanhDong, MoTa, NhanVien)
                VALUES(@AnPhamID, 'DUYET', NULL, @SYS_UserID)
        ELSE IF @TrangThai = 2
            INSERT INTO AnPham_LichSu(AnPhamID, HanhDong, MoTa, NhanVien)
                VALUES(@AnPhamID, 'CHINHSUA', NULL, @SYS_UserID)

        /* Step 2: UPDATE THÔNG TIN TÁC GIẢ*/
        UPDATE
            [dbo].[AnPham_TacGia]
        SET
            [MaNhanVien] = json.MaNhanVien,
            [HoTacGia] = json.HoTacGia,
            [TenTacGia] = json.TenTacGia,
            [EmailTacGia] = json.EmailTacGia,
            [AP_Index] = json.AP_Index,
            [TenPhongBan] = json.TenPhongBan,
            [SoTaiKhoan] = json.SoTaiKhoan,
            [NganHang] = json.NganHang,
            [TenChuTaiKhoan] = json.TenChuTaiKhoan,
            [SoTienKhenThuong] = json.SoTienKhenThuong,
            [SoTienHoanPhiDangBai] = json.SoTienHoanPhiDangBai,
            [CongThucKhenThuongID] = json.CongThucKhenThuongID,
            [NoiDungCongThucKhenThuong] = json.NoiDungCongThucKhenThuong,
            [TrangThai] = 0,
            [NhanVienCapNhat] = @SYS_UserID,
            [ThoiGianCapNhat] = GETDATE(),
            [Is_NhanVien] = json.Is_NhanVien,
            [Is_Xoa] = 0,
            [Is_TacGiaChinh] = json.Is_TacGiaChinh,
            [Is_TacGiaPhu] = json.Is_TacGiaPhu,
            [NguoiDaiDienQuyetToan] = json.NguoiDaiDienQuyetToan,
            [NguonCapKinhPhi] = json.NguonCapKinhPhi,
            [HeSoHoTroCaoHoc] = json.HeSoHoTroCaoHoc,
            [Is_TacGiaLienHe] = ISNULL(json.Is_TacGiaLienHe, 0),
            [VaiTroID] = json.VaiTroID
        FROM
            OPENJSON(@AuthorsObjArr)
            WITH(
                AnPhamTacGiaID INT,
                MaNhanVien VARCHAR(9),
                HoTacGia NVARCHAR(150),
                TenTacGia NVARCHAR(150),
                EmailTacGia VARCHAR(50),
                AP_Index NUMERIC(18, 2),
                TenPhongBan NVARCHAR(250),
                SoTaiKhoan NVARCHAR(50),
                NganHang NVARCHAR(250),
                TenChuTaiKhoan NVARCHAR(150),
                SoTienKhenThuong NUMERIC(18, 2),
                SoTienHoanPhiDangBai NUMERIC(18, 2),
                CongThucKhenThuongID INT,
                NoiDungCongThucKhenThuong NVARCHAR(500),
                Is_NhanVien BIT,
                Is_TacGiaChinh BIT,
                Is_TacGiaPhu BIT,
                NguoiDaiDienQuyetToan BIT,
                NguonCapKinhPhi VARCHAR(9),
                HeSoHoTroCaoHoc FLOAT,
                Is_TacGiaLienHe BIT,
                VaiTroID INT
                ) AS json
        WHERE [dbo].[AnPham_TacGia].[AnPhamTacGiaID] = json.AnPhamTacGiaID;
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

        /* Step 2: UPDATE THÔNG TIN MINH CHỨNG HOÀN PHÍ*/
        -- Parse JSON proofs data
        UPDATE
            [dbo].[AnPham_File]
        SET
            [FileIDList] = json.FileIDList,
            [LoaiFile] = json.LoaiFile,
            [MoTa] = json.MoTa,
            [NhanVienCapNhat] = @SYS_UserID,
            [ThoiGianCapNhat] = GETDATE()
        FROM
            OPENJSON(@ProofSObjArr)
            WITH(
                AnPhamFileID INT,
                FileIDList CHAR(500),
                LoaiFile TINYINT,
                MoTa NVARCHAR(500)
                ) AS json
        WHERE [dbo].[AnPham_File].AnPhamFileID = json.AnPhamFileID;

        /* Step 3: UPDATE THÔNG TIN Đại diện */
        UPDATE
            AnPham
        SET
            MaNhanVienDaiDien = B.MaNhanVien,
            TenNhanVienDaiDien = B.HoTacGia+' '+B.TenTacGia,
            DonViDaiDien = B.TenPhongBan
        FROM AnPham A
             INNER JOIN AnPham_TacGia B ON A.AnPhamID = B.AnPhamID
        WHERE A.AnPhamID            = @AnPhamID
              AND B.Is_Xoa          = 0
              AND (B.Is_TacGiaChinh = 1 OR (AP_Index = 1 AND B.Is_NhanVien = 1));
    END;
