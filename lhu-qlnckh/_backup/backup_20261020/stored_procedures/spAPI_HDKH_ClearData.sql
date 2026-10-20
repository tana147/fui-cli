-- exec [spAPI_HDKH_ClearData]
CREATE PROC [dbo].[spAPI_HDKH_ClearData]
AS
    BEGIN
        BEGIN TRANSACTION;
        BEGIN TRY
            PRINT '--- Bắt đầu quá trình dọn dẹp dữ liệu kê khai ---';

            -- Bước 1: Xóa dữ liệu từ các bảng con không có khóa ngoại trỏ đến nó
            DELETE FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan;
            DBCC CHECKIDENT('dbo.tblHDKH_KeKhai_KetQua_CaNhan', RESEED, 0);
            PRINT '1/5: Đã xóa toàn bộ dữ liệu trong [tblHDKH_KeKhai_KetQua_CaNhan].';

            -- Bước 2: Xóa dữ liệu từ bảng con tblHDKH_KeKhai_FieldValue
            DELETE FROM dbo.tblHDKH_KeKhai_FieldValue;
            DBCC CHECKIDENT('dbo.tblHDKH_KeKhai_FieldValue', RESEED, 0);
            PRINT '2/5: Đã xóa toàn bộ dữ liệu trong [tblHDKH_KeKhai_FieldValue].';

            -- Bước 3: Xóa dữ liệu từ bảng con tblHDKH_KeKhai_ThanhVien
            DELETE FROM dbo.tblHDKH_KeKhai_ThanhVien;
            DBCC CHECKIDENT('dbo.tblHDKH_KeKhai_ThanhVien', RESEED, 0);
            PRINT '3/5: Đã xóa toàn bộ dữ liệu trong [tblHDKH_KeKhai_ThanhVien].';

            -- Bước 4: Xóa dữ liệu từ bảng cha tblHDKH_KeKhai_Submission
            -- Phải xử lý ràng buộc tự tham chiếu trước
            IF EXISTS (
                      SELECT
                          1
                      FROM sys.foreign_keys
                      WHERE name = 'FK_KeKhai_Submission_LienQuan'
                      )
                BEGIN
                    ALTER TABLE dbo.tblHDKH_KeKhai_Submission NOCHECK CONSTRAINT FK_KeKhai_Submission_LienQuan;
                    PRINT 'Tạm thời vô hiệu hóa ràng buộc tự tham chiếu.';
                END;
            DELETE FROM dbo.tblHDKH_KeKhai_Submission;
            DBCC CHECKIDENT('dbo.tblHDKH_KeKhai_Submission', RESEED, 0);

            -- Kích hoạt lại ràng buộc
            IF EXISTS (
                      SELECT
                          1
                      FROM sys.foreign_keys
                      WHERE name = 'FK_KeKhai_Submission_LienQuan'
                      )
                BEGIN
                    ALTER TABLE dbo.tblHDKH_KeKhai_Submission WITH CHECK CHECK CONSTRAINT FK_KeKhai_Submission_LienQuan;
                    PRINT 'Kích hoạt lại ràng buộc tự tham chiếu.';
                END;
            PRINT '4/5: Đã xóa toàn bộ dữ liệu trong [tblHDKH_KeKhai_Submission].';

            -- Bước 5: Xóa dữ liệu chốt sổ và miễn giảm (tùy chọn nhưng khuyến khích để reset hoàn toàn)
            DELETE FROM dbo.tblHDKH_TongHop_KetQua_NamHoc;
            DBCC CHECKIDENT('dbo.tblHDKH_TongHop_KetQua_NamHoc', RESEED, 0);
            PRINT '5/5: Đã xóa toàn bộ dữ liệu trong [tblHDKH_TongHop_KetQua_NamHoc].';
            DELETE FROM dbo.tblHDKH_MienGiam;
            DBCC CHECKIDENT('dbo.tblHDKH_MienGiam', RESEED, 0);
            PRINT '(Tùy chọn): Đã xóa toàn bộ dữ liệu trong [tblHDKH_MienGiam].';
            DELETE FROM dbo.tblHDKH_KeKhai_Submission_MinhChung;
            DBCC CHECKIDENT('dbo.tblHDKH_KeKhai_Submission_MinhChung', RESEED, 0);
            PRINT '(Tùy chọn): Đã xóa toàn bộ dữ liệu trong [tblHDKH_KeKhai_Submission_MinhChung].';
            COMMIT TRANSACTION;
            PRINT '--- Quá trình dọn dẹp dữ liệu đã hoàn tất thành công. ---';
        END TRY
        BEGIN CATCH
            -- Nếu có lỗi, hủy bỏ tất cả thay đổi
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            PRINT '!!! ĐÃ XẢY RA LỖI. Giao dịch đã được rollback. Dữ liệu chưa được xóa. !!!';
            -- Kích hoạt lại ràng buộc nếu nó đã bị vô hiệu hóa
            IF EXISTS (
                      SELECT
                          1
                      FROM sys.foreign_keys
                      WHERE name = 'FK_KeKhai_Submission_LienQuan'
                      )
                BEGIN
                    ALTER TABLE dbo.tblHDKH_KeKhai_Submission WITH CHECK CHECK CONSTRAINT FK_KeKhai_Submission_LienQuan;
                END;
        END CATCH;

        -- Kiểm tra lại, các bảng này phải trống
        PRINT '--- Kiểm tra lại số lượng bản ghi ---';
        SELECT
            'tblHDKH_KeKhai_Submission' AS TableName,
            COUNT(*) AS RecordCount
        FROM dbo.tblHDKH_KeKhai_Submission
        UNION ALL
        SELECT
            'tblHDKH_KeKhai_FieldValue',
            COUNT(*)
        FROM dbo.tblHDKH_KeKhai_FieldValue
        UNION ALL
        SELECT
            'tblHDKH_KeKhai_ThanhVien',
            COUNT(*)
        FROM dbo.tblHDKH_KeKhai_ThanhVien
        UNION ALL
        SELECT
            'tblHDKH_KeKhai_KetQua_CaNhan',
            COUNT(*)
        FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan
        UNION ALL
        SELECT
            'tblHDKH_TongHop_KetQua_NamHoc',
            COUNT(*)
        FROM dbo.tblHDKH_TongHop_KetQua_NamHoc
        UNION ALL
        SELECT 'tblHDKH_MienGiam', COUNT(*)FROM dbo.tblHDKH_MienGiam
        UNION ALL
        SELECT
            'tblHDKH_KeKhai_Submission_MinhChung',
            COUNT(*)
        FROM dbo.tblHDKH_KeKhai_Submission_MinhChung;
    END;