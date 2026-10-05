CREATE PROC [dbo].[spAPI_AnPham_Udp_TrangThai]
@AnPhamID INT,
@TrangThai TINYINT,
@LyDoReject NVARCHAR(500),
@SYS_UserID VARCHAR(9)
AS
BEGIN
	IF EXISTS (SELECT TOP 1 A.AnPhamID FROM AnPham A WHERE A.AnPhamID = @AnPhamID AND A.Is_Xoa = 0)
	BEGIN
		UPDATE AnPham 
			SET TrangThai = @TrangThai
			, LyDoReject =  CASE WHEN @TrangThai = 5 THEN @LyDoReject END 
			, CongThucKhenThuongID = CASE WHEN @TrangThai = 5 THEN NULL ELSE CongThucKhenThuongID END 
			, NhanVienCapNhat = @SYS_UserID
			, ThoiGianCapNhat = GETDATE() 
		WHERE AnPhamID = @AnPhamID

		IF @TrangThai = 5 -- REJECTED
		BEGIN

			UPDATE AnPham_TacGia
				SET SoTienKhenThuong = 0
				, SoTienHoanPhiDangBai = 0
				, CongThucKhenThuongID = NULL
			WHERE AnPhamID = @AnPhamID

			UPDATE AnPham
				SET TongSoTienThuong = 0
				WHERE AnPhamID = @AnPhamID

			INSERT INTO AnPham_LichSu(AnPhamID, HanhDong, MoTa, NhanVien)
				VALUES(@AnPhamID, 'TUCHOI', @LyDoReject, @SYS_UserID)

		END
	END
	ELSE
	BEGIN
		RAISERROR(N'Ấn phẩm này không tồn tại để cập nhật trạng thái', 16, 1);
		RETURN 0;
	END
END

