
CREATE PROC [dbo].[spAPI_PhiDangBai_Cal] --1528
@AnPhamID INT
AS
BEGIN
	DECLARE @TongSoTacGia INT , @SoTacGia_LHU INT
	SET @TongSoTacGia= (SELECT COUNT(*) FROM dbo.AnPham_TacGia WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0)
	SET @SoTacGia_LHU= (SELECT COUNT(*) FROM dbo.AnPham_TacGia WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0 AND TacGiaGroupID IN (1,2))
	
	DECLARE @PhiThongBao NUMERIC(18,2), @HoanPhi NUMERIC(18,2) 

	SET @PhiThongBao = (SELECT CASE WHEN PhiThongBao >= 25442000 THEN 25442000 ELSE PhiThongBao END FROM AnPham WHERE AnPhamID = @AnPhamID)

	DECLARE @HoTroPhiDangBai NUMERIC(18,2)
	SET  @HoTroPhiDangBai = (@SoTacGia_LHU * @PhiThongBao) / @TongSoTacGia

	IF @HoTroPhiDangBai > @PhiThongBao
	BEGIN
		SELECT @PhiThongBao AS HoTroPhiDangBai
	END	
	ELSE
	BEGIN
		SELECT @HoTroPhiDangBai AS HoTroPhiDangBai
	END	

END

