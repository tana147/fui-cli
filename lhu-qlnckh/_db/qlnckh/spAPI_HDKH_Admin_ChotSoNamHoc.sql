CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_ChotSoNamHoc]
    @NamHocCanChot INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM dbo.tblHDKH_TongHop_KetQua_NamHoc WHERE NamHoc = @NamHocCanChot;

        DECLARE @AllGiangVien TABLE (NhanVienID VARCHAR(9), HoTen NVARCHAR(150), HocViID INT, KhoaID VARCHAR(50));
        INSERT INTO @AllGiangVien (NhanVienID, HoTen, HocViID, KhoaID)
        SELECT MaNV, HoTen, HocViID, MaDonVi FROM dbo.NhanVien WHERE Is_ThamGiaNCKH = 1 and IsActive = 1

        DECLARE @CurrentNhanVienID VARCHAR(9);
        DECLARE cur CURSOR FOR SELECT NhanVienID FROM @AllGiangVien;
        OPEN cur;
        FETCH NEXT FROM cur INTO @CurrentNhanVienID;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @DinhMucGoc DECIMAL(10,2)=0, @TongGioMienGiam DECIMAL(10,2)=0, @LyDoMienGiam NVARCHAR(500),
                    @SoGioBaoLuuNamTruoc DECIMAL(10,2)=0, @SoGioThieuNamTruoc DECIMAL(10,2)=0, 
                    @TongGioDaThucHien DECIMAL(10,2)=0, @NghiaVuTrongNam DECIMAL(10,2)=0, 
                    @PhaiThucHien DECIMAL(10,2)=0, @ChenhLech DECIMAL(10,2)=0, @KetQua NVARCHAR(50)=N'Chưa đạt',
                    @SoGioBaoLuuNamTiepTheo DECIMAL(10,2)=0, @SoGioThieuNamTiepTheo DECIMAL(10,2)=0,
                    @NghiaVuToiThieu DECIMAL(10,2) = 0; -- <-- ĐÃ SỬA: Khai báo @NghiaVuToiThieu ở đây

            -- Lấy dữ liệu đầu vào
            SELECT @DinhMucGoc = ISNULL(CD.DinhMucGioChuan, 0) FROM @AllGiangVien GV JOIN dbo.tblHDKH_DM_ChucDanhHocVi CD ON GV.HocViID = CD.ID WHERE GV.NhanVienID = @CurrentNhanVienID;
            SELECT @TongGioMienGiam = ISNULL(SUM(SoGioMienGiam), 0),
                   @LyDoMienGiam = STUFF((SELECT '; ' + LyDo FROM dbo.tblHDKH_MienGiam WHERE NhanVienID = @CurrentNhanVienID AND NamHoc = @NamHocCanChot AND IsDeleted = 0 FOR XML PATH('')), 1, 2, '')
            FROM dbo.tblHDKH_MienGiam WHERE NhanVienID = @CurrentNhanVienID AND NamHoc = @NamHocCanChot AND IsDeleted = 0;
            SELECT @SoGioBaoLuuNamTruoc = ISNULL(SoGioBaoLuuNamTiepTheo, 0), @SoGioThieuNamTruoc = ISNULL(SoGioThieuNamTiepTheo, 0) FROM dbo.tblHDKH_TongHop_KetQua_NamHoc WHERE NhanVienID = @CurrentNhanVienID AND NamHoc = @NamHocCanChot - 1 AND IsDeleted = 0;
            SELECT @TongGioDaThucHien = ISNULL(SUM(KQC.SoGio_DaDuyet), 0) FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan KQC
            WHERE KQC.NhanVienID = @CurrentNhanVienID AND KQC.IsDeleted = 0 AND KQC.TrangThaiDuyet LIKE '%DA_DUYET%'
              AND EXISTS (SELECT 1 FROM dbo.tblHDKH_KeKhai_Submission S WHERE S.SubmissionID = KQC.SubmissionID AND S.NamHoc = @NamHocCanChot);

            -- Thực hiện tính toán
            SET @NghiaVuTrongNam = @DinhMucGoc - @TongGioMienGiam;
            IF @NghiaVuTrongNam < 0 SET @NghiaVuTrongNam = 0;
            SET @PhaiThucHien = @NghiaVuTrongNam + @SoGioThieuNamTruoc;
            DECLARE @TongGioTichLuy DECIMAL(10,2) = @TongGioDaThucHien + @SoGioBaoLuuNamTruoc;
            SET @ChenhLech = @TongGioTichLuy - @PhaiThucHien;
            IF @ChenhLech >= 0 SET @KetQua = N'Đạt';
            
            -- Tính toán giờ chuyển sang năm tiếp theo
            SET @NghiaVuToiThieu = @NghiaVuTrongNam * 0.5;
            IF @ChenhLech >= 0 -- Thừa giờ
            BEGIN
                SET @SoGioThieuNamTiepTheo = 0;
                IF @TongGioDaThucHien >= @NghiaVuToiThieu
                    -- ĐÃ SỬA: Thay thế LEAST() bằng CASE WHEN
                    SET @SoGioBaoLuuNamTiepTheo = CASE WHEN @ChenhLech < @NghiaVuToiThieu THEN @ChenhLech ELSE @NghiaVuToiThieu END;
                ELSE
                    SET @SoGioBaoLuuNamTiepTheo = 0;
            END
            ELSE -- Thiếu giờ
            BEGIN
                SET @SoGioBaoLuuNamTiepTheo = 0;
                SET @SoGioThieuNamTiepTheo = -@ChenhLech;
            END

            -- INSERT "Ảnh chụp" kết quả
            INSERT INTO dbo.tblHDKH_TongHop_KetQua_NamHoc
                (NhanVienID, NamHoc, DinhMucGoc, SoGioMienGiam, SoGioThieuNamTruoc, SoGioBaoLuuNamTruoc,
                 TongGioDaThucHien, NghiaVuTrongNam, SoGioChuanPhaiThucHien, KetQua, 
                 SoGioBaoLuu_Thieu_TrongNam, SoGioBaoLuuNamTiepTheo, SoGioThieuNamTiepTheo, 
                 LyDoMienGiam, CreateUser)
            VALUES
                (@CurrentNhanVienID, @NamHocCanChot, @DinhMucGoc, @TongGioMienGiam, @SoGioThieuNamTruoc, @SoGioBaoLuuNamTruoc,
                 @TongGioDaThucHien, @NghiaVuTrongNam, @PhaiThucHien, @KetQua,
                 @ChenhLech, @SoGioBaoLuuNamTiepTheo, @SoGioThieuNamTiepTheo,
                 @LyDoMienGiam, @sys_UserID);

            FETCH NEXT FROM cur INTO @CurrentNhanVienID;
        END
        CLOSE cur;
        DEALLOCATE cur;
        
        COMMIT TRANSACTION;
        SELECT Message = N'Đã chốt sổ thành công cho năm học ' + CAST(@NamHocCanChot AS VARCHAR) + '.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
