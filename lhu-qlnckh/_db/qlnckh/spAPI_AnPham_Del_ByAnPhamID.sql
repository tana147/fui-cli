CREATE PROCEDURE [dbo].[spAPI_AnPham_Del_ByAnPhamID]
    @AnPhamID INT,
	@SYS_UserID VARCHAR(9)
AS
BEGIN;
	UPDATE AnPham
		SET Is_Xoa = 1
			,NhanVienCapNhat  = @SYS_UserID
			,ThoiGianCapNhat = GETDATE()
			WHERE AnPhamID = @AnPhamID
	UPDATE AnPham_TacGia
		SET  Is_Xoa = 1
			,NhanVienCapNhat  = @SYS_UserID
			,ThoiGianCapNhat = GETDATE()
			WHERE AnPhamID = @AnPhamID
	UPDATE AnPham_File
		SET  Is_Xoa = 1
			,NhanVienCapNhat  = @SYS_UserID
			,ThoiGianCapNhat = GETDATE()
			WHERE AnPhamID = @AnPhamID
END;
