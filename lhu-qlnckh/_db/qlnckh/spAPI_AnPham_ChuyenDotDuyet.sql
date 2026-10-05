CREATE PROC [dbo].[spAPI_AnPham_ChuyenDotDuyet]
@AnPhamID INT,
@DotDuyetID INT,
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	IF (@sys_SystemRight NOT IN (1,2,9))
	BEGIN
		RAISERROR(N'Bạn không có quyền thực hiện tác vụ này', 16, 1)
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM AnPham WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0 AND TrangThai = 3)
	BEGIN
		RAISERROR(N'Chỉ có thể chuyển đợt duyệt cho ấn phẩm đã duyệt', 16, 1)
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM AnPham_DotDuyet WHERE AnPham_DotDuyetID = @DotDuyetID AND Is_Xoa = 0)
	BEGIN
		RAISERROR(N'Đợt duyệt không tồn tại hoặc đã bị xoá', 16, 1)
		RETURN
	END

	UPDATE AnPham
		SET DotDuyet = @DotDuyetID
		, NhanVienCapNhat = @SYS_UserID
		, ThoiGianCapNhat = GETDATE()
	WHERE AnPhamID = @AnPhamID

	INSERT INTO AnPham_LichSu(AnPhamID, HanhDong, MoTa, NhanVien)
		SELECT @AnPhamID, 'CHUYENDOT', N'Chuyển sang đợt: ' + TenDotDuyet, @SYS_UserID
		FROM AnPham_DotDuyet WHERE AnPham_DotDuyetID = @DotDuyetID
END
