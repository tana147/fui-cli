CREATE PROC [dbo].[spAPI_GiaiThuong_QuyetDinh_Del]
	@Sys_UserId VARCHAR(9),
	@QDID INT
AS
BEGIN
	-- Kiểm tra quyết định đã gán cho giải thưởng chưa
	IF EXISTS (
		SELECT 1
		FROM dbo.GiaiThuong gt 
		WHERE gt.Is_Xoa = 0
			AND gt.QDID = @QDID
	)
	BEGIN
	    RAISERROR(N'Không thể xóa quyết định đã được gán cho giải thưởng', 16, 1)
		RETURN 0;
	END

	UPDATE dbo.QuyetDinh
	SET Is_Xoa = 1,
		NhanVienCapNhat = @Sys_UserId,
		ThoiGianCapNhat = GETDATE()
	WHERE QDID = @QDID
END