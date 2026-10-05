CREATE PROC [dbo].[spAPI_KHCN_SanPham_Ins_Obj]
@DeTaiKHCNID INT,
@SanPhamKHCNObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN
	--insert vào table Sản Phẩm
	INSERT INTO [dbo].[KHCN_SanPham]
	(
		[DeTaiKHCNID],
		[TenSanPhamDuKien],
		[SoLuong],
		[NhanVienCapNhat]
	)
	SELECT
		@DeTaiKHCNID,
		json.TenSanPhamDuKien,
		json.SoLuong,
		@SYS_UserID
	FROM OPENJSON(@SanPhamKHCNObj)
	WITH (
		TenSanPhamDuKien nvarchar(200),
		SoLuong INT
	) AS json;
END