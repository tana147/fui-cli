--}
--{"AnPhamID":2650,"CongThucKhenThuongID":6,"DiemHoiDong":"0.75","HeSo_IF":"2.6","HeSoChatLuongID":3}
--  exec [dbo].[spAPI_PhiKhenThuong_Cal] 7271, 46, 0.75, 0, 0

CREATE PROC [dbo].[spAPI_PhiKhenThuong_Cal]
    @AnPhamID INT,
    @CongThucKhenThuongID INT,
    @DiemHoiDong NUMERIC(18, 2),
    @HeSo_IF NUMERIC(18, 2),
    @HeSoChatLuongID INT
AS
    BEGIN
        DECLARE
            @TongSoTacGia      INT,
            @SoTacGia_LHU      INT,
            @HinhThucThanhToan TINYINT,
            @NhomAnPham        TINYINT,
            @LoaiSubAnPhamID   INT;
        SET @TongSoTacGia = (
                            SELECT
                                COUNT(*)
                            FROM dbo.AnPham_TacGia
                            WHERE AnPhamID   = @AnPhamID
                                  AND Is_Xoa = 0
                            );
        SET @SoTacGia_LHU = (
                            SELECT
                                COUNT(*)
                            FROM dbo.AnPham_TacGia
                            WHERE AnPhamID   = @AnPhamID
                                  AND Is_Xoa = 0
                                  AND TacGiaGroupID IN (1, 2)
                            );
        SELECT
            @HinhThucThanhToan = HinhThucThanhToan,
            @NhomAnPham = NhomAnPham,
            @LoaiSubAnPhamID = LoaiSubAnPhamID
        FROM dbo.AnPham
        WHERE AnPhamID   = @AnPhamID
              AND Is_Xoa = 0;
        DECLARE @DiemHeSoChatLuong NUMERIC(18, 2);
        SET @DiemHeSoChatLuong = (
                                 SELECT
                                     DiemHeSoChatLuong
                                 FROM dbo.HeSoChatLuong HS
                                 WHERE HS.HeSoChatLuongID = @HeSoChatLuongID
                                 );
        DECLARE @tacgia AS TABLE(
                                AnPhamTacGiaID INT NOT NULL,
                                ViTri INT NOT NULL,
                                AP_Index NUMERIC(18, 2) NOT NULL,
                                KhenThuong NUMERIC(18, 2) NOT NULL,
                                Is_NhanVien BIT NOT NULL,
                                Is_TacGiaChinh BIT NOT NULL,
                                TacGiaGroupID INT NOT NULL,
                                NguoiDaiDienQuyetToan BIT NOT NULL,
                                HeSoHoTroCaoHoc NUMERIC(18, 2) NOT NULL
                                );
        INSERT INTO @tacgia(
                           AnPhamTacGiaID,
                           ViTri,
                           AP_Index,
                           KhenThuong,
                           Is_NhanVien,
                           Is_TacGiaChinh,
                           TacGiaGroupID,
                           NguoiDaiDienQuyetToan,
                           HeSoHoTroCaoHoc
                           )
        SELECT
            A.AnPhamTacGiaID,
            ROW_NUMBER() OVER (ORDER BY A.AnPhamTacGiaID),
            ISNULL(AP_Index, 1), --- 10/6/2026 20h, đã bỏ AP nhưng vẫn để 1 nhằm mục đích dùng lại hàm cũ
            0,
            Is_NhanVien,
            A.Is_TacGiaChinh,
            TacGiaGroupID,
            A.NguoiDaiDienQuyetToan,
            A.HeSoHoTroCaoHoc
        FROM dbo.AnPham_TacGia A
        WHERE A.AnPhamID   = @AnPhamID
              AND A.Is_Xoa = 0;
        DECLARE @STT INT = 1;
        WHILE @STT < (SELECT COUNT(*)FROM @tacgia)+1
            BEGIN
                DECLARE @AP NUMERIC(18, 2);
                DECLARE @HeSoHoTroCaoHoc NUMERIC(18, 2);
                DECLARE @KhenThuong NUMERIC(18, 2);
                DECLARE @tblKT AS TABLE(VT INT IDENTITY(1, 1), KT NUMERIC(18, 2) NOT NULL);
                DECLARE @NguoiDaiDienQuyetToan INT;
                DECLARE @Is_TacGiaChinh BIT;
                DECLARE @Is_NhanVien BIT;
                SELECT
                    @AP = AP_Index,
                    @HeSoHoTroCaoHoc = ISNULL(HeSoHoTroCaoHoc, 1),
                    @NguoiDaiDienQuyetToan = NguoiDaiDienQuyetToan,
                    @Is_TacGiaChinh = Is_TacGiaChinh,
                    @Is_NhanVien = Is_NhanVien
                FROM @tacgia
                WHERE ViTri = @STT;
                SET @DiemHeSoChatLuong = ISNULL(@DiemHeSoChatLuong, 0);
                IF @HeSo_IF > 5 --Theo yêu cầu TTNCKH nếu IF > 5 thì chỉ tính là 5
                    BEGIN
                        SET @HeSo_IF = 5;
                    END;
                SET @AP = 1 -- Theo quy định mới thì bỏ AP, vẫn giữ để không sửa cấu trúc hiện tại (Tân 8/5/2026)
                IF @NhomAnPham = 2
                   AND @CongThucKhenThuongID = 75 --NhomAnPham =2 :Hỗ trợ đầu vào cao học; @CongThucKhenThuongID = 75 : Tạp chí Khoa học Lạc Hồng
                    BEGIN
                        INSERT INTO @tblKT(KT)
                        EXEC [dbo].[CalculatePayment]
                            @CongThucKhenThuongID,
                            @DiemHoiDong,
                            @AP,
                            @TongSoTacGia,
                            @HeSo_IF,
                            @DiemHeSoChatLuong;
                        SET @KhenThuong = (SELECT TOP 1 KT FROM @tblKT WHERE VT = @STT);
                        UPDATE
                            @tacgia
                        SET
                            KhenThuong = CASE WHEN @NguoiDaiDienQuyetToan = 1 THEN 5000000 * ISNULL(@HeSoHoTroCaoHoc, 1)
                            ELSE 0 END
                        WHERE ViTri = @STT;
                    END;
                ELSE
                    BEGIN
                    -- 1. Sửa kiểu dữ liệu sang FLOAT để tránh mất số thập phân khi chia
                    DECLARE @HeSo FLOAT = 1;
                      IF @CongThucKhenThuongID IN (42, 44, 46, 48)
                        BEGIN
                            IF @Is_TacGiaChinh = 1 SET @HeSo = 1;
                                     ELSE SET @HeSo = 0.7;
                            END;
                            ELSE IF @CongThucKhenThuongID IN (53, 55, 57, 59, 61, 63, 65, 67, 69, 71)
                                      BEGIN
                                          SET @AP = @SoTacGia_LHU;
                                          SET @HeSo = 1.0 / CAST(@SoTacGia_LHU AS FLOAT); -- Ép kiểu khi chia
                                      END;
                            ELSE IF @CongThucKhenThuongID IN (72, 73, 74)BEGIN
										SET @HeSo = 1.0;
										END;
                            ELSE IF @CongThucKhenThuongID IN (52, 54, 56, 58, 60, 62, 64, 66, 68, 70)
                                BEGIN
									SET @TongSoTacGia = 1.0;
							    END;
                        ELSE     
                            BEGIN
								SET @HeSo = 1.0 / CAST(@SoTacGia_LHU AS FLOAT);
                            END;
                    IF @NhomAnPham = 2 AND @HeSoHoTroCaoHoc IN (1.2, 1.5) SET @HeSo = 1;--- 8/8/2026 Tân xử lý note không nhân hệ số tác giả phụ cho hỗ trợ đầu vào cao học
                    INSERT INTO @tblKT(KT)
                    EXEC [dbo].[CalculatePayment]
                    @FormulaID = @CongThucKhenThuongID,
                    @Score = @DiemHoiDong,
                    @AuthorPosition = @AP,
                    @TotalAuthors = @TongSoTacGia,
                    @ImpactFactor = @HeSo_IF,
                    @QualityFactor = @DiemHeSoChatLuong;
                    SET @KhenThuong = (SELECT TOP 1 KT FROM @tblKT WHERE VT = @STT);
                    UPDATE
                    @tacgia
                    SET
                    KhenThuong = CAST(@KhenThuong * @HeSo *(CASE WHEN TacGiaGroupID IN (1, 2) THEN @HeSoHoTroCaoHoc ELSE 1 END) AS NUMERIC(18, 2))* IIF(@Is_NhanVien = 1, 1, 0)
                    WHERE ViTri = @STT;
                    END;
                    IF (@CongThucKhenThuongID IN (52, 54, 56, 58, 60, 62, 64, 66, 68, 70)) and ((@Is_TacGiaChinh = 0) OR (@NguoiDaiDienQuyetToan = 0)) --- 20/8/2026 Tân xử lý note không chia số tác giả đối với các bài báo quốc tế, chỉ tính chính / phụ. Phụ thì công thức riêng
                    BEGIN
									UPDATE
                                    @tacgia
                                    SET
                                    KhenThuong = 0
                                    WHERE ViTri = @STT;
					END;
                SET @STT = @STT+1;
            END;
        --1: Đại diện 1 thành viên nhận ; 2: Phân bổ cho các thành viên; 
        IF @HinhThucThanhToan = 1
            BEGIN
                DECLARE @TongKhenThuong NUMERIC(18, 2) = (SELECT SUM(ISNULL(KhenThuong, 0))FROM @tacgia);
                IF EXISTS (SELECT 1 FROM @tacgia WHERE NguoiDaiDienQuyetToan = 1)
                    BEGIN
                        UPDATE
                            @tacgia
                        SET
                            KhenThuong = @TongKhenThuong
                        WHERE NguoiDaiDienQuyetToan = 1;
                        UPDATE @tacgia SET KhenThuong = 0 WHERE NguoiDaiDienQuyetToan = 0;
                    END;
        ELSE
            BEGIN
                IF(SELECT COUNT(*)FROM @tacgia) = 1
                UPDATE @tacgia SET KhenThuong = @TongKhenThuong; -- 1 tác giả: nhận hết
                    -- else: giữ nguyên phân bổ đã tính (hoặc tự set ViTri=1 làm đại diện tùy quy chế)
            END;
            END;
        SELECT
            t.AnPhamTacGiaID,
            t.ViTri,
            t.AP_Index,
            t.KhenThuong,
            t.Is_NhanVien,
            t.TacGiaGroupID,
            t.NguoiDaiDienQuyetToan,
            t.HeSoHoTroCaoHoc,
            t.Is_TacGiaChinh
        FROM @tacgia t;
    END;