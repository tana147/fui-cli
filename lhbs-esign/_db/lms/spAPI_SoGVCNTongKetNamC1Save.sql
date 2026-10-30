CREATE   PROCEDURE dbo.spAPI_SoGVCNTongKetNamC1Save
	@SoGVCNID varchar(10),
	@KyDanhGia varchar(20),
	@DuyTriSoLuong nvarchar(max),
	@NangLucPhamChat nvarchar(max),
	@KienThucKyNang nvarchar(max),
	@HoanThanhCT nvarchar(max),
	@PhongTraoKhac nvarchar(max),
	@JsonSheet1 nvarchar(max),
	@JsonSheet2 nvarchar(max),
	@JsonSheet3 nvarchar(max),
	@JsonSheet4 nvarchar(max),
	@JsonDanhGia nvarchar(max),
	@sys_UserID varchar(9),
	@sys_SystemRight varchar(10)
AS
BEGIN
	SET NOCOUNT ON;
	-- FUI supplies a string user identity; audit triggers read it from SESSION_CONTEXT.
	DECLARE @AuditUser varchar(20) = COALESCE(NULLIF(LTRIM(RTRIM(@sys_UserID)), ''), 'unknown/unavailable');
	EXEC sys.sp_set_session_context
	    @key = N'SoGVCN_UserID',
	    @value = @AuditUser;
	SET XACT_ABORT ON;

	DECLARE @ID int = TRY_CONVERT(int, @SoGVCNID);
	DECLARE @UserID varchar(9) = @sys_UserID;
	DECLARE @KyDanhGiaCode varchar(20) = UPPER(LTRIM(RTRIM(@KyDanhGia)));

	IF @ID IS NULL OR NOT EXISTS (
		SELECT 1
		FROM dbo.tblSoGVCN
		WHERE SoGVCNID = @ID
		  AND Enable = 1
	)
	BEGIN
		RAISERROR(N'Sổ GVCN không hợp lệ.', 16, 1);
		RETURN;
	END;

	IF @KyDanhGiaCode IS NULL OR @KyDanhGiaCode NOT IN ('GK_HK1', 'CK_HK1', 'GK_HK2', 'CK_HK2')
	BEGIN
		RAISERROR(N'Mã kỳ đánh giá không hợp lệ.', 16, 1);
		RETURN;
	END;

	BEGIN TRANSACTION;

	-- 1. Overview text & sheet snapshots
	IF EXISTS (
		SELECT 1
		FROM dbo.tblSoGVCNTongKetNamHocC1
		WHERE SoGVCNID = @ID
		  AND Enable = 1
	)
	BEGIN
		UPDATE dbo.tblSoGVCNTongKetNamHocC1
		SET
			DuyTriSoLuong = @DuyTriSoLuong,
			NangLucPhamChat = @NangLucPhamChat,
			KienThucKyNang = @KienThucKyNang,
			HoanThanhCT = @HoanThanhCT,
			PhongTraoKhac = @PhongTraoKhac,
			JsonSheet1 = @JsonSheet1,
			JsonSheet2 = @JsonSheet2,
			JsonSheet3 = @JsonSheet3,
			JsonSheet4 = @JsonSheet4,
			UpdateUser = @UserID,
			UpdateTime = GETDATE()
		WHERE SoGVCNID = @ID
		  AND Enable = 1;
	END
	ELSE
	BEGIN
		INSERT INTO dbo.tblSoGVCNTongKetNamHocC1 (
			SoGVCNID,
			DuyTriSoLuong, NangLucPhamChat, KienThucKyNang,
			HoanThanhCT, PhongTraoKhac,
			JsonSheet1, JsonSheet2, JsonSheet3, JsonSheet4,
			CreateUser, UpdateUser
		)
		VALUES (
			@ID,
			@DuyTriSoLuong, @NangLucPhamChat, @KienThucKyNang,
			@HoanThanhCT, @PhongTraoKhac,
			@JsonSheet1, @JsonSheet2, @JsonSheet3, @JsonSheet4,
			@UserID, @UserID
		);
	END;

	-- 2. Save structured ratings table (Relational Rows)
	IF @JsonDanhGia IS NOT NULL AND ISJSON(@JsonDanhGia) = 1
	BEGIN
		MERGE dbo.tblSoGVCNTongKetNamDanhGia AS target
		USING (
			SELECT
				JSON_VALUE(src.value, '$.LoaiDanhGia') AS LoaiDanhGia,
				TRY_CONVERT(int, JSON_VALUE(src.value, '$.MonHocID')) AS MonHocID,
				JSON_VALUE(src.value, '$.TieuChiCode') AS TieuChiCode,
				JSON_VALUE(src.value, '$.TenTieuChi') AS TenTieuChi,
				JSON_VALUE(src.value, '$.MucXepLoaiCode') AS MucXepLoaiCode,
				TRY_CONVERT(int, JSON_VALUE(src.value, '$.SoLuong')) AS SoLuong,
				TRY_CONVERT(decimal(5,2), JSON_VALUE(src.value, '$.TiLe')) AS TiLe
			FROM OPENJSON(@JsonDanhGia) AS src
		) AS source
		ON (
			target.SoGVCNID = @ID 
			AND target.KyDanhGia = @KyDanhGiaCode
			AND target.LoaiDanhGia = source.LoaiDanhGia 
			AND ISNULL(target.MonHocID, 0) = ISNULL(source.MonHocID, 0)
			AND ISNULL(target.TieuChiCode, '') = ISNULL(source.TieuChiCode, '')
			AND target.MucXepLoaiCode = source.MucXepLoaiCode
		)
		WHEN MATCHED THEN
			UPDATE SET
				target.TenTieuChi = source.TenTieuChi,
				target.SoLuong = source.SoLuong,
				target.TiLe = source.TiLe,
				target.Enable = 1,
				target.UpdateUser = @UserID,
				target.UpdateTime = GETDATE()
		WHEN NOT MATCHED THEN
			INSERT (
				SoGVCNID, LoaiDanhGia, MonHocID, TieuChiCode, TenTieuChi,
				MucXepLoaiCode, SoLuong, TiLe, KyDanhGia, CreateUser, UpdateUser
			)
			VALUES (
				@ID, source.LoaiDanhGia, source.MonHocID, source.TieuChiCode, source.TenTieuChi,
				source.MucXepLoaiCode, source.SoLuong, source.TiLe, @KyDanhGiaCode, @UserID, @UserID
			);
	END;

	COMMIT TRANSACTION;

	SELECT N'Thành công' AS [status];
END;
