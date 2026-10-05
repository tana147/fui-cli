CREATE PROCEDURE [dbo].[spAPI_HDKH_KeKhai_CalculateAndSave]
    @SubmissionID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- ====================================================================================
    -- BƯỚC 1: PARSE VÀ VALIDATE DỮ LIỆU ĐẦU VÀO TỪ JSON
    -- ====================================================================================
    DECLARE @FormCode VARCHAR(50), @NamHoc INT, @FormID INT, @KeKhaiLienQuanID BIGINT;
    SELECT 
        @FormCode = JSON_VALUE(@sys_RawData, '$.FormCode'),
        @NamHoc = JSON_VALUE(@sys_RawData, '$.NamHoc'),
        @KeKhaiLienQuanID = JSON_VALUE(@sys_RawData, '$.KeKhai_LienQuan_ID');
        
    SELECT @FormID = FormID FROM dbo.tblHDKH_Form_Definition WHERE FormCode = @FormCode AND IsDeleted = 0;
    IF @FormID IS NULL BEGIN RAISERROR(N'Mã Form "%s" không hợp lệ.', 16, 1, @FormCode); RETURN; END

    DECLARE @InputFields TABLE (FieldName VARCHAR(50), FieldValue NVARCHAR(MAX));
    INSERT INTO @InputFields (FieldName, FieldValue) SELECT [key], [value] FROM OPENJSON(@sys_RawData, '$.Fields');

    DECLARE @InputThanhVien TABLE (isNhanVienLHU BIT, NhanVienID VARCHAR(9), HoTen NVARCHAR(150), VaiTroID INT, ViTri INT, isTacGiaLienHe BIT);
    INSERT INTO @InputThanhVien (isNhanVienLHU, NhanVienID, HoTen, VaiTroID, ViTri, isTacGiaLienHe)
    SELECT JSON_VALUE([value], '$.isNhanVienLHU'), JSON_VALUE([value], '$.NhanVienID'), JSON_VALUE([value], '$.HoTen'),
           JSON_VALUE([value], '$.VaiTroID'), JSON_VALUE([value], '$.ViTri'), ISNULL(JSON_VALUE([value], '$.isTacGiaLienHe'), 0)
    FROM OPENJSON(@sys_RawData, '$.ThanhVien');

	DECLARE @InputMinhChung TABLE (URLMinhChung NVARCHAR(MAX), FileID VARCHAR(32));
    INSERT INTO @InputMinhChung (URLMinhChung, FileID)
    SELECT JSON_VALUE([value], '$.URLMinhChung'), JSON_VALUE([value], '$.FileID')
    FROM OPENJSON(@sys_RawData, '$.MinhChung');



    -- ====================================================================================
    -- BƯỚC 2: TÌM QUY TẮC PHÙ HỢP (FIND THE RULE)
    -- ====================================================================================
    DECLARE @RuleID INT;
    WITH MatchedRules AS (
        SELECT R.RuleID, (SELECT COUNT(1) FROM dbo.tblHDKH_Rule_Condition WHERE RuleID = R.RuleID AND IsDeleted = 0) AS TotalConditionsCount,
        ISNULL((SELECT COUNT(1) FROM dbo.tblHDKH_Rule_Condition AS C JOIN dbo.tblHDKH_Field_Definition AS FD ON C.FieldID = FD.FieldID JOIN @InputFields AS IFD ON FD.FieldName = IFD.FieldName WHERE C.RuleID = R.RuleID AND C.IsDeleted = 0 AND (C.ConditionValue = IFD.FieldValue)), 0) AS MatchedConditionsCount
        FROM dbo.tblHDKH_Rule_Definition AS R WHERE R.FormID = @FormID AND R.NamHocApDung <= @NamHoc AND R.IsDeleted = 0
    )
    SELECT TOP 1 @RuleID = RuleID FROM MatchedRules WHERE MatchedConditionsCount = TotalConditionsCount ORDER BY TotalConditionsCount DESC;

    IF @RuleID IS NULL BEGIN RAISERROR(N'Không tìm thấy quy tắc tính điểm phù hợp.', 16, 1); RETURN; END

    -- ====================================================================================
    -- BƯỚC 3 & 4: THỰC THI RULE ENGINE VÀ TÍNH TOÁN
    -- ====================================================================================
    DECLARE @SoGioQuyDoi_Goc DECIMAL(10,2), @Formula_TinhGioGoc NVARCHAR(500), @MaQuyTacPhanChia VARCHAR(50), @Apply_AP_Index BIT;
    SELECT @SoGioQuyDoi_Goc = SoGioQuyDoi_Goc, @Formula_TinhGioGoc = Formula_TinhGioGoc, @MaQuyTacPhanChia = MaQuyTacPhanChia, @Apply_AP_Index = Apply_AP_Index
    FROM dbo.tblHDKH_Rule_Definition WHERE RuleID = @RuleID;

    IF @Formula_TinhGioGoc IS NOT NULL AND @Formula_TinhGioGoc LIKE '%[kinh_phi_thuc_hien]%' BEGIN
        DECLARE @KinhPhi DECIMAL(18,2) = (SELECT CAST(FieldValue AS DECIMAL(18,2)) FROM @InputFields WHERE FieldName = 'kinh_phi_thuc_hien');
        SET @SoGioQuyDoi_Goc = @KinhPhi * 2;
    END

    DECLARE @KetQuaTinhToan TABLE (NhanVienID VARCHAR(50), VaiTroID INT, SoGioQuyDoi_CaNhan DECIMAL(10,2), DienGiaiCachTinh NVARCHAR(1000));
    DECLARE @TongSoThanhVien INT = (SELECT COUNT(1) FROM @InputThanhVien);
    DECLARE @SoThanhVienLHU INT = (SELECT COUNT(1) FROM @InputThanhVien WHERE isNhanVienLHU = 1);
    DECLARE @IsAllLHU BIT = IIF(@TongSoThanhVien > 0 AND @SoThanhVienLHU = @TongSoThanhVien, 1, 0);

    -- LOGIC CHIA GIỜ (đã cập nhật)
    IF @MaQuyTacPhanChia = 'CHIA_BAI_BAO' AND @TongSoThanhVien > 0 BEGIN
	-- 12/5/2026 9h50 Tạm ẩn do quy chế phức tạp (Meeting với anh Long)
  --      IF @IsAllLHU = 1 
		--BEGIN
		--	DECLARE @DienGiai_CoBan_LHU NVARCHAR(500) = FORMATMESSAGE(N'(Giờ gốc %s: 75%%/ %d tác giả', CAST(@SoGioQuyDoi_Goc AS VARCHAR), @TongSoThanhVien);

  --          DECLARE @VaiTroChinh_BB TABLE (ID INT); 
			
		--	INSERT INTO @VaiTroChinh_BB 
		--	SELECT ID FROM dbo.tblHDKH_DM_VaiTro 
		--		WHERE TenVaiTro LIKE N'%Tác giả chính%' OR TenVaiTro LIKE N'%Tác giả liên hệ%'
            
		--	INSERT INTO @KetQuaTinhToan (NhanVienID, VaiTroID, SoGioQuyDoi_CaNhan, DienGiaiCachTinh)
		--	SELECT NhanVienID, VaiTroID, 
		--			(@SoGioQuyDoi_Goc * 0.75 / @TongSoThanhVien) + CASE WHEN VaiTroID IN (SELECT ID FROM @VaiTroChinh_BB) OR isTacGiaLienHe = 1 THEN (@SoGioQuyDoi_Goc * 0.25) ELSE 0 END,
		--			@DienGiai_CoBan_LHU + CASE WHEN VaiTroID IN (SELECT ID FROM @VaiTroChinh_BB) OR isTacGiaLienHe = 1 THEN N' + 25% vai trò chính)' ELSE N')' END
  --          FROM @InputThanhVien;
  --      END
  --      ELSE 
		BEGIN -- Có người ngoài LHU
            INSERT INTO @KetQuaTinhToan (NhanVienID, VaiTroID, SoGioQuyDoi_CaNhan, DienGiaiCachTinh)
            --SELECT NhanVienID, VaiTroID, CASE WHEN isNhanVienLHU = 1 THEN @SoGioQuyDoi_Goc / @SoThanhVienLHU ELSE 0 END
				SELECT NhanVienID, 
					VaiTroID, 
					CASE WHEN isNhanVienLHU = 1 THEN @SoGioQuyDoi_Goc / @TongSoThanhVien ELSE 0 END,
					FORMATMESSAGE(N'(Giờ gốc %s / %d tác giả)', CAST(@SoGioQuyDoi_Goc AS VARCHAR), @TongSoThanhVien)
            FROM @InputThanhVien;
        END
    END
    ELSE IF @MaQuyTacPhanChia IN ('CHIA_SACH', 'CHIA_DE_TAI','CHIA_GIAI_PHAP') AND @TongSoThanhVien > 0 BEGIN
		DECLARE @DienGiai_CoBan NVARCHAR(500) = FORMATMESSAGE( N'(Giờ gốc %s: 75%% / %d tác giả', CAST(@SoGioQuyDoi_Goc AS VARCHAR), @TongSoThanhVien );

		DECLARE @VaiTroChinh_Sach TABLE (ID INT);

		INSERT INTO @VaiTroChinh_Sach
		SELECT ID
		FROM dbo.tblHDKH_DM_VaiTro
		WHERE	TenVaiTro LIKE N'%Chủ nhiệm%'
				OR TenVaiTro LIKE N'%Chủ biên%'
				OR TenVaiTro LIKE N'%Thành viên chính%'

		INSERT INTO @KetQuaTinhToan
		(
			NhanVienID,
			VaiTroID,
			SoGioQuyDoi_CaNhan,
			DienGiaiCachTinh
		)
		SELECT	NhanVienID, VaiTroID,
				(@SoGioQuyDoi_Goc * 0.75 / @TongSoThanhVien)
				+
				CASE
					WHEN VaiTroID IN (SELECT ID FROM @VaiTroChinh_Sach)
					THEN (@SoGioQuyDoi_Goc * 0.25)
					ELSE 0
				END,

				@DienGiai_CoBan
				+
				CASE
					WHEN VaiTroID IN (SELECT ID FROM @VaiTroChinh_Sach)
					THEN N' + 25% vai trò chính)'
					ELSE N')'
				END

		FROM @InputThanhVien;
    END
    ELSE IF @MaQuyTacPhanChia = 'CHIA_DEU' AND @TongSoThanhVien > 0 BEGIN
        INSERT INTO @KetQuaTinhToan (NhanVienID, VaiTroID, SoGioQuyDoi_CaNhan, DienGiaiCachTinh)
        SELECT NhanVienID, 
				VaiTroID, 
				@SoGioQuyDoi_Goc / @TongSoThanhVien,
				FORMATMESSAGE(N'Giờ gốc %s / %d tác giả (chia đều)', CAST(@SoGioQuyDoi_Goc AS VARCHAR), @TongSoThanhVien)
		FROM @InputThanhVien;
    END
    ELSE BEGIN -- KHONG_CHIA
        INSERT INTO @KetQuaTinhToan (NhanVienID, VaiTroID, SoGioQuyDoi_CaNhan, DienGiaiCachTinh)
        SELECT NhanVienID, VaiTroID, @SoGioQuyDoi_Goc,
		FORMATMESSAGE(N'Giờ gốc %s (không chia)', CAST(@SoGioQuyDoi_Goc AS VARCHAR))
		FROM @InputThanhVien;
    END

    -- ÁP DỤNG HỆ SỐ AP INDEX
    IF @Apply_AP_Index = 1 BEGIN
        UPDATE KQT 
		SET 
			SoGioQuyDoi_CaNhan = KQT.SoGioQuyDoi_CaNhan * AP.HeSo,
			DienGiaiCachTinh = KQT.DienGiaiCachTinh + FORMATMESSAGE(N' x %s (hệ số AP vị trí %d)', CAST(AP.HeSo AS VARCHAR), ITV.ViTri)
        FROM @KetQuaTinhToan AS KQT 
			JOIN @InputThanhVien AS ITV ON KQT.NhanVienID = ITV.NhanVienID
        CROSS APPLY (SELECT CASE WHEN ITV.isTacGiaLienHe = 1 THEN 1.0 WHEN ITV.ViTri = 1 THEN 1.0 WHEN ITV.ViTri = 2 THEN 0.9 WHEN ITV.ViTri = 3 THEN 0.7 WHEN ITV.ViTri = 4 THEN 0.5 ELSE 0.3 END AS HeSo) AS AP;
    END

    -- ====================================================================================
    -- BƯỚC 5: LƯU KẾT QUẢ (LOGIC UPSERT)
    -- ====================================================================================
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @CurrentSubmissionID BIGINT = @SubmissionID;

        IF @CurrentSubmissionID > 0 -- TRƯỜNG HỢP UPDATE
        BEGIN
            UPDATE dbo.tblHDKH_KeKhai_Submission SET UpdateTime = GETDATE(), UpdateUser = @sys_UserID, KeKhai_LienQuan_ID = @KeKhaiLienQuanID
            WHERE SubmissionID = @CurrentSubmissionID;

            -- Xóa mềm dữ liệu con cũ để chèn lại
            UPDATE dbo.tblHDKH_KeKhai_FieldValue SET IsDeleted = 1, UpdateTime = GETDATE(), UpdateUser = @sys_UserID WHERE SubmissionID = @CurrentSubmissionID;
            UPDATE dbo.tblHDKH_KeKhai_ThanhVien SET IsDeleted = 1, UpdateTime = GETDATE(), UpdateUser = @sys_UserID WHERE SubmissionID = @CurrentSubmissionID;
            UPDATE dbo.tblHDKH_KeKhai_KetQua_CaNhan SET IsDeleted = 1, UpdateTime = GETDATE(), UpdateUser = @sys_UserID WHERE SubmissionID = @CurrentSubmissionID;
			UPDATE dbo.tblHDKH_KeKhai_Submission_MinhChung SET IsDeleted = 1, UpdateTime = GETDATE(), UpdateUser = @sys_UserID WHERE SubmissionID = @CurrentSubmissionID;
        END
        ELSE -- TRƯỜNG HỢP INSERT
        BEGIN
            INSERT INTO dbo.tblHDKH_KeKhai_Submission (FormID, NhanVienID_KeKhai, NamHoc, KeKhai_LienQuan_ID, CreateUser)
            VALUES (@FormID, @sys_UserID, @NamHoc, @KeKhaiLienQuanID, @sys_UserID);
            SET @CurrentSubmissionID = SCOPE_IDENTITY();
        END

        -- Chèn lại dữ liệu con mới
        INSERT INTO dbo.tblHDKH_KeKhai_FieldValue (SubmissionID, FieldID, FieldValue, CreateUser)
        SELECT @CurrentSubmissionID, FD.FieldID, IFD.FieldValue, @sys_UserID
        FROM @InputFields AS IFD JOIN dbo.tblHDKH_Field_Definition AS FD ON IFD.FieldName = FD.FieldName WHERE FD.FormID = @FormID;
        
        INSERT INTO dbo.tblHDKH_KeKhai_ThanhVien (SubmissionID, isNhanVienLHU, NhanVienID, HoTen, VaiTroID, ViTri, isTacGiaLienHe, CreateUser)
        SELECT @CurrentSubmissionID, isNhanVienLHU, NhanVienID, HoTen, VaiTroID, ViTri, isTacGiaLienHe, @sys_UserID FROM @InputThanhVien;
        
        INSERT INTO dbo.tblHDKH_KeKhai_KetQua_CaNhan (SubmissionID, NhanVienID, VaiTroID, ViTri, RuleID_ApDung, SoGioQuyDoi_CaNhan, SoGio_DaDuyet, DienGiaiCachTinh, CreateUser)
        SELECT @CurrentSubmissionID, KQT.NhanVienID, KQT.VaiTroID, ITV.ViTri, @RuleID, KQT.SoGioQuyDoi_CaNhan, NULL,  KQT.DienGiaiCachTinh, @sys_UserID
        FROM @KetQuaTinhToan AS KQT JOIN @InputThanhVien AS ITV ON KQT.NhanVienID = ITV.NhanVienID WHERE ITV.isNhanVienLHU = 1;

		INSERT INTO [dbo].[tblHDKH_KeKhai_Submission_MinhChung]([SubmissionID], [URLMinhChung], [FileID], [CreateTime], [CreateUser])
		SELECT @CurrentSubmissionID, URLMinhChung, FileID, GETDATE(), @sys_UserID FROM @InputMinhChung;

        COMMIT TRANSACTION;
        SELECT Message = N'Lưu kê khai thành công!', SubmissionID = @CurrentSubmissionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
