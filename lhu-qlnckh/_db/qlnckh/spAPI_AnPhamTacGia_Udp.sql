CREATE PROCEDURE [dbo].[spAPI_AnPhamTacGia_Udp]
    @AuthorsObjArr NVARCHAR(MAX),
    @AnPhamID INT,
    @sys_UserID VARCHAR(9)
AS
    BEGIN
        -- Update author data in AnPham_TacGia table
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
            [TrangThai] = 0,
            [NhanVienCapNhat] = @sys_UserID,
            [ThoiGianCapNhat] = GETDATE(),
            [Is_NhanVien] = json.Is_NhanVien,
            [TacGiaGroupID] = json.TacGiaGroupID,
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
                Is_NhanVien BIT,
                TacGiaGroupID TINYINT,
                Is_TacGiaChinh BIT,
                Is_TacGiaPhu BIT,
                NguoiDaiDienQuyetToan VARCHAR(9),
                NguonCapKinhPhi VARCHAR(9),
                HeSoHoTroCaoHoc FLOAT,
                Is_TacGiaLienHe BIT,
                VaiTroID INT
                ) AS json
        WHERE [dbo].[AnPham_TacGia].AnPhamTacGiaID = json.AnPhamTacGiaID;
        DECLARE
            @TongSoTacGia INT,
            @SoTacGia_LHU INT;
        SET @TongSoTacGia = (
                            SELECT
                                COUNT(*)
                            FROM AnPham_TacGia
                            WHERE AnPhamID   = @AnPhamID
                                  AND Is_Xoa = 0
                            );
        SET @SoTacGia_LHU = (
                            SELECT
                                COUNT(*)
                            FROM AnPham_TacGia
                            WHERE AnPhamID   = @AnPhamID
                                  AND Is_Xoa = 0
                                  AND TacGiaGroupID IN (1, 2)
                            ); --AND Is_NhanVien = 1)
        UPDATE
            AnPham
        SET
            TongSoTacGia = @TongSoTacGia,
            SoTacGia_LHU = @SoTacGia_LHU
        WHERE AnPhamID = @AnPhamID;

    --EXEC spCalculate_APIndex @AnPhamID
    END;
