CREATE PROC [dbo].[spAPI_KHCN_SanPham_Del_Obj]
@SanPhamKHCNObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN
	--update vào table Sản Phẩm
	UPDATE [dbo].[KHCN_SanPham]
	SET
		[Is_Xoa] = 1,
		[NhanVienCapNhat] = @SYS_UserID
	FROM OPENJSON(@SanPhamKHCNObj)
	WITH (
		SanPhamKHCNID INT,
		TenSanPhamDuKien nvarchar(200),
		SoLuong INT
	) AS json
	WHERE [KHCN_SanPham].[SanPhamKHCNID] = json.SanPhamKHCNID
END