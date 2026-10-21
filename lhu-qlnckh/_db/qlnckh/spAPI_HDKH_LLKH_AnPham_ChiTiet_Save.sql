CREATE PROCEDURE [dbo].[spAPI_HDKH_LLKH_AnPham_ChiTiet_Save]
	@AnPhamID int,
	@TapSoTrang nvarchar(100),
	@ThangDang tinyint,
	@VaiTroID int,
	@Is_TacGiaLienHe bit,
	@TheLoaiBienSoanID int,
	@DoiLink nvarchar(500),
	@TenSachChuaChuong nvarchar(500),
	@sys_UserID varchar(9)
AS
-- Lý lịch khoa học: bổ sung thông tin chi tiết cho ấn phẩm/bài báo đồng bộ vào Single Source of Truth
BEGIN
	SET NOCOUNT ON;

	-- Thêm cột TenSachChuaChuong nếu chưa có
	IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('AnPham') AND name = 'TenSachChuaChuong')
	BEGIN
		EXEC('ALTER TABLE AnPham ADD TenSachChuaChuong nvarchar(500) NULL');
	END;
	IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblHDKH_LLKH_AnPham_ChiTiet') AND name = 'TenSachChuaChuong')
	BEGIN
		EXEC('ALTER TABLE tblHDKH_LLKH_AnPham_ChiTiet ADD TenSachChuaChuong nvarchar(500) NULL');
	END;

	-- 1. Kiểm tra quyền tác giả
	IF NOT EXISTS (
		SELECT 1 FROM AnPham_TacGia
		WHERE AnPhamID = @AnPhamID AND MaNhanVien = @sys_UserID AND Is_Xoa = 0
	)
	BEGIN
		RAISERROR(N'Bạn không phải là tác giả của ấn phẩm này hoặc ấn phẩm đã bị xóa', 16, 1);
		RETURN;
	END

	-- 2. Kiểm tra dữ liệu hợp lệ
	IF @ThangDang IS NOT NULL AND (@ThangDang < 1 OR @ThangDang > 12)
	BEGIN
		RAISERROR(N'Tháng đăng phải từ 1 đến 12', 16, 1);
		RETURN;
	END

	SET @TapSoTrang = NULLIF(LTRIM(RTRIM(@TapSoTrang)), '');
	SET @DoiLink = NULLIF(LTRIM(RTRIM(@DoiLink)), '');
	SET @TenSachChuaChuong = NULLIF(LTRIM(RTRIM(@TenSachChuaChuong)), '');

	-- 3. Cập nhật trực tiếp bảng AnPham & AnPham_TacGia (Single Source of Truth)
	UPDATE AnPham
	SET TapSoTrang = @TapSoTrang,
		ThangDang = @ThangDang,
		TheLoaiBienSoanID = @TheLoaiBienSoanID,
		DoiLink = @DoiLink,
		TenSachChuaChuong = @TenSachChuaChuong,
		NhanVienCapNhat = @sys_UserID,
		ThoiGianCapNhat = GETDATE()
	WHERE AnPhamID = @AnPhamID;

	UPDATE AnPham_TacGia
	SET VaiTroID = @VaiTroID,
		Is_TacGiaLienHe = ISNULL(@Is_TacGiaLienHe, 0),
		NhanVienCapNhat = @sys_UserID,
		ThoiGianCapNhat = GETDATE()
	WHERE AnPhamID = @AnPhamID AND MaNhanVien = @sys_UserID AND Is_Xoa = 0;

	-- 4. Lưu bản sao vào bảng tblHDKH_LLKH_AnPham_ChiTiet
	IF EXISTS (SELECT 1 FROM tblHDKH_LLKH_AnPham_ChiTiet WHERE AnPhamID = @AnPhamID AND MaNhanVien = @sys_UserID)
	BEGIN
		UPDATE tblHDKH_LLKH_AnPham_ChiTiet
		SET TapSoTrang = @TapSoTrang,
			ThangDang = @ThangDang,
			VaiTroID = @VaiTroID,
			Is_TacGiaLienHe = @Is_TacGiaLienHe,
			TheLoaiBienSoanID = @TheLoaiBienSoanID,
			DoiLink = @DoiLink,
			TenSachChuaChuong = @TenSachChuaChuong,
			NgayCapNhat = GETDATE(),
			NguoiCapNhat = @sys_UserID,
			IsDeleted = 0
		WHERE AnPhamID = @AnPhamID AND MaNhanVien = @sys_UserID;
	END
	ELSE
	BEGIN
		INSERT INTO tblHDKH_LLKH_AnPham_ChiTiet (
			AnPhamID, MaNhanVien, TapSoTrang, ThangDang, VaiTroID,
			Is_TacGiaLienHe, TheLoaiBienSoanID, DoiLink, TenSachChuaChuong, NgayCapNhat, NguoiCapNhat, IsDeleted
		) VALUES (
			@AnPhamID, @sys_UserID, @TapSoTrang, @ThangDang, @VaiTroID,
			@Is_TacGiaLienHe, @TheLoaiBienSoanID, @DoiLink, @TenSachChuaChuong, GETDATE(), @sys_UserID, 0
		);
	END

	SELECT Message = N'Cập nhật chi tiết ấn phẩm thành công', Status = 1;
END;
