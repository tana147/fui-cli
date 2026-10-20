CREATE PROCEDURE [dbo].[spAPI_HDKH_KeKhai_CalculateAndSave_BACKUP]
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- ====================================================================================
    -- BƯỚC 1: PARSE VÀ VALIDATE DỮ LIỆU ĐẦU VÀO TỪ JSON
    -- ====================================================================================
    DECLARE @FormCode VARCHAR(50), @NamHoc INT, @NhanVienKeKhai VARCHAR(9), @FormID INT, @KeKhaiLienQuanID BIGINT;
    SELECT 
        @FormCode = JSON_VALUE(@sys_RawData, '$.FormCode'),
        @NamHoc = JSON_VALUE(@sys_RawData, '$.NamHoc'),
        @KeKhaiLienQuanID = JSON_VALUE(@sys_RawData, '$.KeKhai_LienQuan_ID'),
        @NhanVienKeKhai = @sys_UserID;
        
    SELECT @FormID = FormID FROM dbo.tblHDKH_Form_Definition WHERE FormCode = @FormCode AND IsDeleted = 0;
    IF @FormID IS NULL BEGIN
        RAISERROR(N'Mã Form "%s" không hợp lệ hoặc không tồn tại.', 16, 1, @FormCode);
        RETURN;
    END

    DECLARE @InputFields TABLE (FieldName VARCHAR(50), FieldValue NVARCHAR(MAX));
    INSERT INTO @InputFields (FieldName, FieldValue)
    SELECT [key], [value] FROM OPENJSON(@sys_RawData, '$.Fields');

    DECLARE @InputThanhVien TABLE (NhanVienID VARCHAR(50), VaiTroID INT, ViTri INT); -- Tăng độ rộng NhanVienID
    INSERT INTO @InputThanhVien (NhanVienID, VaiTroID, ViTri)
    SELECT JSON_VALUE([value], '$.NhanVienID'), JSON_VALUE([value], '$.VaiTroID'), JSON_VALUE([value], '$.ViTri')
    FROM OPENJSON(@sys_RawData, '$.ThanhVien');

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

    IF @RuleID IS NULL BEGIN
        RAISERROR(N'Không tìm thấy quy tắc tính điểm nào phù hợp.', 16, 1);
        RETURN;
    END

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

    DECLARE @KetQuaTinhToan TABLE (NhanVienID VARCHAR(50), VaiTroID INT, SoGioQuyDoi_CaNhan DECIMAL(10,2));
    DECLARE @TongSoThanhVien INT = (SELECT COUNT(1) FROM @InputThanhVien);
    DECLARE @SoThanhVienLHU INT = (SELECT COUNT(1) FROM @InputThanhVien WHERE LEN(NhanVienID) = 9 AND (NhanVienID LIKE 'NV%' OR NhanVienID LIKE 'GV%'));
    DECLARE @IsAllLHU BIT = IIF(@TongSoThanhVien > 0 AND @SoThanhVienLHU = @TongSoThanhVien, 1, 0);

    -- LOGIC CHIA GIỜ
    IF @MaQuyTacPhanChia = 'CHIA_BAI_BAO' AND @TongSoThanhVien > 0 BEGIN
        IF @IsAllLHU = 1 BEGIN
            DECLARE @VaiTroChinh_BB TABLE (ID INT); INSERT INTO @VaiTroChinh_BB SELECT ID FROM dbo.tblHDKH_DM_VaiTro WHERE TenVaiTro LIKE N'%Tác giả chính%' OR TenVaiTro LIKE N'%Tác giả liên hệ%';
            INSERT INTO @KetQuaTinhToan (NhanVienID, VaiTroID, SoGioQuyDoi_CaNhan)
            SELECT NhanVienID, VaiTroID, (@SoGioQuyDoi_Goc * 0.75 / @TongSoThanhVien) + CASE WHEN VaiTroID IN (SELECT ID FROM @VaiTroChinh_BB) THEN (@SoGioQuyDoi_Goc * 0.25) ELSE 0 END
            FROM @InputThanhVien;
        END
        ELSE BEGIN -- Có người ngoài LHU
            INSERT INTO @KetQuaTinhToan (NhanVienID, VaiTroID, SoGioQuyDoi_CaNhan)
            SELECT NhanVienID, VaiTroID, CASE WHEN LEN(NhanVienID) = 9 AND (NhanVienID LIKE 'NV%' OR NhanVienID LIKE 'GV%') THEN @SoGioQuyDoi_Goc / @SoThanhVienLHU ELSE 0 END
            FROM @InputThanhVien;
        END
    END
    ELSE IF @MaQuyTacPhanChia IN ('CHIA_SACH', 'CHIA_DETAI_TRUONG') AND @TongSoThanhVien > 0 BEGIN
        DECLARE @VaiTroChinh_Sach TABLE (ID INT); INSERT INTO @VaiTroChinh_Sach SELECT ID FROM dbo.tblHDKH_DM_VaiTro WHERE TenVaiTro LIKE N'%Chủ nhiệm%' OR TenVaiTro LIKE N'%Chủ biên%';
        INSERT INTO @KetQuaTinhToan (NhanVienID, VaiTroID, SoGioQuyDoi_CaNhan)
        SELECT NhanVienID, VaiTroID, (@SoGioQuyDoi_Goc * 0.75 / @TongSoThanhVien) + CASE WHEN VaiTroID IN (SELECT ID FROM @VaiTroChinh_Sach) THEN (@SoGioQuyDoi_Goc * 0.25) ELSE 0 END
        FROM @InputThanhVien;
    END
    ELSE IF @MaQuyTacPhanChia = 'CHIA_DEU' AND @TongSoThanhVien > 0 BEGIN
        INSERT INTO @KetQuaTinhToan (NhanVienID, VaiTroID, SoGioQuyDoi_CaNhan)
        SELECT NhanVienID, VaiTroID, @SoGioQuyDoi_Goc / @TongSoThanhVien FROM @InputThanhVien;
    END
    ELSE BEGIN -- KHONG_CHIA
        INSERT INTO @KetQuaTinhToan (NhanVienID, VaiTroID, SoGioQuyDoi_CaNhan)
        SELECT NhanVienID, VaiTroID, @SoGioQuyDoi_Goc FROM @InputThanhVien;
    END

    -- ÁP DỤNG HỆ SỐ AP INDEX
    IF @Apply_AP_Index = 1 BEGIN
        UPDATE KQT SET SoGioQuyDoi_CaNhan = KQT.SoGioQuyDoi_CaNhan * AP.HeSo
        FROM @KetQuaTinhToan AS KQT JOIN @InputThanhVien AS ITV ON KQT.NhanVienID = ITV.NhanVienID
        CROSS APPLY (SELECT CASE WHEN ITV.ViTri = 1 THEN 1.0 WHEN ITV.ViTri = 2 THEN 0.9 WHEN ITV.ViTri = 3 THEN 0.7 WHEN ITV.ViTri = 4 THEN 0.5 ELSE 0.3 END AS HeSo) AS AP;
    END

    -- ====================================================================================
    -- BƯỚC 5: LƯU KẾT QUẢ VÀO CÁC BẢNG NGHIỆP VỤ
    -- ====================================================================================
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @CurrentSubmissionID BIGINT;
        INSERT INTO dbo.tblHDKH_KeKhai_Submission (FormID, NhanVienID_KeKhai, NamHoc, KeKhai_LienQuan_ID, CreateUser)
        VALUES (@FormID, @NhanVienKeKhai, @NamHoc, @KeKhaiLienQuanID, @sys_UserID);
        SET @CurrentSubmissionID = SCOPE_IDENTITY();
        
        INSERT INTO dbo.tblHDKH_KeKhai_FieldValue (SubmissionID, FieldID, FieldValue, CreateUser)
        SELECT @CurrentSubmissionID, FD.FieldID, IFD.FieldValue, @sys_UserID
        FROM @InputFields AS IFD
        JOIN dbo.tblHDKH_Field_Definition AS FD ON IFD.FieldName = FD.FieldName WHERE FD.FormID = @FormID;
        
        INSERT INTO dbo.tblHDKH_KeKhai_KetQua_CaNhan (SubmissionID, NhanVienID, VaiTroID, RuleID_ApDung, SoGioQuyDoi_CaNhan, CreateUser)
        SELECT @CurrentSubmissionID, NhanVienID, VaiTroID, @RuleID, SoGioQuyDoi_CaNhan, @sys_UserID
        FROM @KetQuaTinhToan;

        COMMIT TRANSACTION;
        SELECT Message = N'Kê khai thành công!', SubmissionID = @CurrentSubmissionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
