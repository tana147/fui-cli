CREATE PROCEDURE [dbo].[spAPI_AnPhamTacGia_Del]
    @AnPhamTacGiaID INT,
	@AnPhamID INT,
    @sys_UserID varchar(9)
AS
BEGIN
    -- Update author data in AnPham_TacGia table
	UPDATE [dbo].[AnPham_TacGia]
	SET
		
		[NhanVienCapNhat] = @SYS_UserID,
		[ThoiGianCapNhat] = GETDATE(),
		[Is_Xoa] = 1
	
	WHERE
		[dbo].[AnPham_TacGia].AnPhamTacGiaID = @AnPhamTacGiaID;

	DECLARE @TongSoTacGia INT , @SoTacGia_LHU INT
	SET @TongSoTacGia= (SELECT COUNT(*) FROM AnPham_TacGia WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0)
	SET @SoTacGia_LHU= (SELECT COUNT(*) FROM AnPham_TacGia WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0  AND TacGiaGroupID IN (1,2)) --AND Is_NhanVien = 1)
	UPDATE AnPham SET TongSoTacGia = @TongSoTacGia, SoTacGia_LHU = @SoTacGia_LHU WHERE AnPhamID = @AnPhamID

	--EXEC spCalculate_APIndex @AnPhamID

END;
