CREATE PROCEDURE [dbo].[spAPI_HDKH_KeKhai_GetTongHopCaNhan] -- 2025,'NV0001120'
    @NamHoc INT,
    @sys_UserID VARCHAR(9)
AS
    BEGIN
        SET NOCOUNT ON;
        IF @sys_UserID = 'GV0000611' SET @sys_UserID = 'NV0000742';

        -- ====================================================================================
        -- KHAI BÁO CÁC BIẾN CẦN THIẾT
        -- ====================================================================================
        DECLARE
            @DinhMucGoc          DECIMAL(10, 2) = 0,
            @TongGioMienGiam     DECIMAL(10, 2) = 0,
            @SoGioBaoLuuNamTruoc DECIMAL(10, 2) = 0,
            @SoGioThieuNamTruoc  DECIMAL(10, 2) = 0,
            @TongGioDaThucHien   DECIMAL(10, 2) = 0,
            @NghiaVuTrongNam     DECIMAL(10, 2) = 0,
            @PhaiThucHien        DECIMAL(10, 2) = 0,
            @ChenhLech           DECIMAL(10, 2) = 0,
            @KetLuan             NVARCHAR(50)   = N'Chưa đạt',
            @NghiaVuToiThieu     DECIMAL(10, 2) = 0,
            @TrangThaiDuyet      NVARCHAR(50);

        -- ====================================================================================
        -- BƯỚC 1: LẤY CÁC DỮ LIỆU ĐẦU VÀO TỪ CSDL
        -- ====================================================================================

        -- Lấy Định mức gốc từ học vị của nhân viên
        SELECT
            @DinhMucGoc = ISNULL(CD.DinhMucGioChuan, 0)
        FROM dbo.NhanVien NV
             JOIN dbo.tblHDKH_DM_ChucDanhHocVi CD ON NV.HocViID = CD.ID -- Giả sử NhanVien.HocViID tham chiếu đến bảng này
        WHERE NV.MaNV = @sys_UserID;

        -- Lấy Tổng giờ miễn giảm trong năm
        SELECT
            @TongGioMienGiam = ISNULL(SUM(SoGioMienGiam), 0)
        FROM dbo.tblHDKH_MienGiam
        WHERE NhanVienID    = @sys_UserID
              AND NamHoc    = @NamHoc
              AND IsDeleted = 0;

        -- Lấy Bảo lưu/Thiếu từ kết quả chốt sổ của NĂM TRƯỚC
        SELECT
            @SoGioBaoLuuNamTruoc = ISNULL(SoGioBaoLuuNamTiepTheo, 0),
            @SoGioThieuNamTruoc = ISNULL(SoGioThieuNamTiepTheo, 0)
        FROM dbo.tblHDKH_TongHop_KetQua_NamHoc
        WHERE NhanVienID    = @sys_UserID
              AND NamHoc    = @NamHoc-1
              AND IsDeleted = 0;

        -- Lấy Tổng giờ đã thực hiện và ĐƯỢC DUYỆT trong năm hiện tại
        SELECT
            @TongGioDaThucHien = ISNULL(SUM(KQC.SoGio_DaDuyet), 0),
            @TrangThaiDuyet = KQC.TrangThaiDuyet
        FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan AS KQC
             JOIN dbo.tblHDKH_KeKhai_Submission AS S ON KQC.SubmissionID = S.SubmissionID
        WHERE KQC.NhanVienID    = @sys_UserID
              AND S.NamHoc      = @NamHoc
              AND KQC.TrangThaiDuyet IN ('KHOA_DA_DUYET', 'NCKH_DA_DUYET')
              AND KQC.IsDeleted = 0
              AND S.IsDeleted   = 0
        GROUP BY KQC.TrangThaiDuyet;

        -- ====================================================================================
        -- BƯỚC 2: THỰC HIỆN LOGIC TÍNH TOÁN
        -- ====================================================================================

        -- 1. Tính nghĩa vụ của năm nay
        SET @NghiaVuTrongNam = @DinhMucGoc-@TongGioMienGiam-(IIF(@SoGioBaoLuuNamTruoc > @DinhMucGoc/2, @DinhMucGoc/2, @SoGioBaoLuuNamTruoc));
        IF @NghiaVuTrongNam < 0 SET @NghiaVuTrongNam = 0;

        -- 2. Tính tổng nghĩa vụ phải thực hiện (khong bao gồm nợ cũ)
        SET @PhaiThucHien = @NghiaVuTrongNam;

        -- 3. Tính tổng giờ đã tích lũy (bao gồm tiết kiệm cũ)
        DECLARE @TongGioTichLuy DECIMAL(10, 2) = @TongGioDaThucHien+(IIF(@SoGioBaoLuuNamTruoc > @DinhMucGoc/2, @DinhMucGoc/2, @SoGioBaoLuuNamTruoc));

        -- 4. So sánh và đưa ra kết luận
        SET @ChenhLech = @TongGioTichLuy-@PhaiThucHien;
        IF @ChenhLech > 0 SET @KetLuan = N'Đạt';
        ELSE SET @KetLuan = N'Chưa đạt';

        -- ====================================================================================
        -- BƯỚC 3: TRẢ VỀ KẾT QUẢ TỔNG HỢP
        -- ====================================================================================
        SELECT
            DinhMuc_Goc = @DinhMucGoc,
            TongGio_MienGiam = @TongGioMienGiam,
            NghiaVuTrongNam = @NghiaVuTrongNam,
            TongGio_BaoLuu_TuNamTruoc = @SoGioBaoLuuNamTruoc,
            SoGio_Thieu_TuNamTruoc = @SoGioThieuNamTruoc,
            NghiaVu_PhaiThucHien = @PhaiThucHien,
            TongGio_DaThucHien = @TongGioDaThucHien, -- Chỉ giờ làm trong năm
            TrangThaiDuyet = @TrangThaiDuyet,
            KetLuan = @KetLuan,
            SoGioConThieu = CASE WHEN @ChenhLech < 0 THEN -@ChenhLech ELSE 0 END,
            SoGioDu = CASE WHEN @ChenhLech > 0 THEN @ChenhLech ELSE 0 END;
    --SELECT @sys_UserID
    END;
