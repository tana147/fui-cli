CREATE   PROCEDURE dbo.spAPI_SoGVCNTongKetNamC1Get
	@SoGVCNID varchar(10),
	@KyDanhGia varchar(20),
	@sys_UserID varchar(9),
	@sys_SystemRight varchar(10)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ID int = TRY_CONVERT(int, @SoGVCNID);
	DECLARE @KyDanhGiaCode varchar(20) = UPPER(LTRIM(RTRIM(@KyDanhGia)));

	IF @KyDanhGiaCode IS NULL OR @KyDanhGiaCode NOT IN ('GK_HK1', 'CK_HK1', 'GK_HK2', 'CK_HK2')
	BEGIN
		RAISERROR(N'Mã kỳ đánh giá không hợp lệ.', 16, 1);
		RETURN;
	END;

	-- 1. Main overview & text notes
	SELECT
		TongKetID,
		SoGVCNID,
		DuyTriSoLuong,
		NangLucPhamChat,
		KienThucKyNang,
		HoanThanhCT,
		PhongTraoKhac,
		JsonSheet1,
		JsonSheet2,
		JsonSheet3,
		JsonSheet4
	FROM dbo.tblSoGVCNTongKetNamHocC1
	WHERE SoGVCNID = @ID
	  AND Enable = 1;

	-- 2. Structured ratings table
	SELECT
		DanhGiaID,
		SoGVCNID,
		LoaiDanhGia,
		MonHocID,
		TieuChiCode,
		TenTieuChi,
		MucXepLoaiCode,
		SoLuong,
		TiLe,
		KyDanhGia
	FROM dbo.tblSoGVCNTongKetNamDanhGia
	WHERE SoGVCNID = @ID
	  AND KyDanhGia = @KyDanhGiaCode
	  AND Enable = 1;
END;
