CREATE PROCEDURE [dbo].[spAPI_AnPhamTacGia_INS]
    @AuthorsObjArr NVARCHAR(MAX),
	@AnPhamID INT,
    @sys_UserID varchar(9)
AS
BEGIN
    -- Insert author data into AnPham_TacGia table
        INSERT INTO [dbo].[AnPham_TacGia]
        (
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
			 json.AnPhamID,
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
             json.Is_NhanVien,
			 json.TacGiaGroupID,
			 0,
			 json.Is_TacGiaChinh,
             json.Is_TacGiaPhu,
			 json.NguoiDaiDienQuyetToan,
			 json.NguonCapKinhPhi,
			 json.HeSoHoTroCaoHoc
        FROM OPENJSON(@AuthorsObjArr)
        WITH (
            AnPhamID INT,
			MaNhanVien VARCHAR(9),
            HoTacGia NVARCHAR(150),
            TenTacGia NVARCHAR(150),
            EmailTacGia VARCHAR(50),
            AP_Index NUMERIC(18,2),
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
			HeSoHoTroCaoHoc FLOAT
        ) AS json;

	DECLARE @TongSoTacGia INT , @SoTacGia_LHU INT
	SET @TongSoTacGia= (SELECT COUNT(*) FROM AnPham_TacGia WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0)
	SET @SoTacGia_LHU= (SELECT COUNT(*) FROM AnPham_TacGia WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0  AND TacGiaGroupID IN (1,2)) --AND Is_NhanVien = 1)
	UPDATE AnPham SET TongSoTacGia = @TongSoTacGia, SoTacGia_LHU = @SoTacGia_LHU WHERE AnPhamID = @AnPhamID

	--EXEC spCalculate_APIndex @AnPhamID
END;