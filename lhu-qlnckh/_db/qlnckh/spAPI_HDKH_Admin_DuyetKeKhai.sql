CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_DuyetKeKhai]
    @SubmissionID BIGINT,
    @TrangThaiMoi VARCHAR(20),
    @GhiChuTuChoi NVARCHAR(1000) = NULL,
    @KetQuaDuyetJSON NVARCHAR(MAX) = NULL,

    -- Tham số hệ thống
    @sys_UserID VARCHAR(9),
    @sys_SystemRight INT, -- Thêm tham số SystemRight để kiểm tra quyền
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- ======================================================================
    -- BƯỚC 1: VALIDATION DỮ LIỆU ĐẦU VÀO
    -- ======================================================================
    
    IF @TrangThaiMoi NOT IN ('KHOA_DA_DUYET', 'KHOA_TU_CHOI', 'NCKH_DA_DUYET', 'NCKH_TU_CHOI')
    BEGIN
        RAISERROR(N'Trạng thái duyệt không hợp lệ.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.tblHDKH_KeKhai_Submission WHERE SubmissionID = @SubmissionID AND IsDeleted = 0)
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin kê khai với ID %I64d.', 16, 1, @SubmissionID);
        RETURN;
    END

    IF @TrangThaiMoi LIKE '%DA_DUYET%' AND ISJSON(ISNULL(@KetQuaDuyetJSON, '')) != 1
    BEGIN
        RAISERROR(N'Khi duyệt, tham số KetQuaDuyetJSON là bắt buộc và phải là một mảng JSON hợp lệ.', 16, 1);
        RETURN;
    END

    -- ======================================================================
    -- BƯỚC 2: XÁC ĐỊNH QUYỀN CỦA NGƯỜI DUYỆT
    -- ======================================================================
    DECLARE @NguoiDuyet_KhoaID VARCHAR(50);
    SELECT @NguoiDuyet_KhoaID = MaDonVi FROM dbo.NhanVien WHERE MaNV = @sys_UserID;
    IF @sys_UserID IN ('NV0000166','NV0000267') SET @NguoiDuyet_KhoaID = 'KCB';
    
    -- ======================================================================
    -- BƯỚC 3: THỰC THI LOGIC
    -- ======================================================================
    BEGIN TRANSACTION;
    BEGIN TRY
        IF @TrangThaiMoi LIKE '%DA_DUYET%'
        BEGIN
            DECLARE @KetQuaDuyet TABLE (KetQuaID BIGINT, SoGio_DaDuyet DECIMAL(10,2));
            INSERT INTO @KetQuaDuyet (KetQuaID, SoGio_DaDuyet)
            SELECT JSON_VALUE(val.value, '$.KetQuaID'), JSON_VALUE(val.value, '$.SoGio_DaDuyet')
            FROM OPENJSON(@KetQuaDuyetJSON) AS val;
            
            UPDATE KQC
            SET 
                KQC.SoGio_DaDuyet = KQD.SoGio_DaDuyet,
                KQC.TrangThaiDuyet = @TrangThaiMoi,
                KQC.GhiChuTuChoi = NULL, -- Xóa ghi chú cũ nếu có
                KQC.NgayDuyet = GETDATE(),
                KQC.NguoiDuyet = @sys_UserID
            FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan AS KQC
            JOIN @KetQuaDuyet AS KQD ON KQC.KetQuaID = KQD.KetQuaID
            JOIN dbo.NhanVien AS NV_BiDuyet ON KQC.NhanVienID = NV_BiDuyet.MaNV
            WHERE 
                KQC.SubmissionID = @SubmissionID
                -- Điều kiện phân quyền
                AND (
                    @sys_UserID = 'GV0000611' -- Quyền đặc biệt cho user này
                    OR @sys_SystemRight IN (3, 9) -- Quyền cho các cấp quản lý cao
                    OR NV_BiDuyet.MaDonVi = @NguoiDuyet_KhoaID -- Quyền cho trưởng khoa
                );
        END
        ELSE -- Nếu là TỪ CHỐI (KHOA_TU_CHOI, NCKH_TU_CHOI)
        BEGIN
            UPDATE KQC
            SET 
                KQC.SoGio_DaDuyet = NULL,
                KQC.TrangThaiDuyet = @TrangThaiMoi,
                KQC.GhiChuTuChoi = @GhiChuTuChoi,
                KQC.NgayDuyet = GETDATE(),
                KQC.NguoiDuyet = @sys_UserID
            FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan AS KQC
            JOIN dbo.NhanVien AS NV_BiDuyet ON KQC.NhanVienID = NV_BiDuyet.MaNV
            WHERE 
                KQC.SubmissionID = @SubmissionID
                -- Điều kiện phân quyền
                AND (
                       @sys_UserID = 'GV0000611' -- account anh Tam
                    OR @sys_UserID = 'NV0000401' -- account anh Long
                    OR @sys_UserID = 'NV0000388' -- account chi Huong
                    OR @sys_SystemRight IN (3, 9)
                    OR NV_BiDuyet.MaDonVi = @NguoiDuyet_KhoaID
                );
        END
        
        COMMIT TRANSACTION;
        SELECT Message = N'Cập nhật trạng thái duyệt thành công.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
