CREATE PROCEDURE [dbo].[spAPI_GiaoVienLop_Del]
    @GVLopID INT,
    @Sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Lấy thông tin bản ghi trước khi xóa để đồng bộ GVCN
        DECLARE @LopID VARCHAR(9);
        DECLARE @VaiTro INT;
        DECLARE @NienKhoa INT;

        SELECT 
            @LopID = LopID, 
            @VaiTro = VaiTro, 
            @NienKhoa = NienKhoa
        FROM [dbo].[tblGiaoVienLop]
        WHERE GVLopID = @GVLopID;

        -- Xóa bản ghi có GVLopID và NienKhoa tương ứng
        DELETE FROM [dbo].[tblGiaoVienLop]
        WHERE GVLopID = @GVLopID

        -- Kiểm tra nếu không có dòng nào bị xóa
        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Không tìm thấy bản ghi để xóa', 16, 1);
            RETURN;
        END

        -- Đồng bộ đặt GVCN về NULL trong tblLop nếu bản ghi bị xóa là GVCN (VaiTro = 1)
        IF @VaiTro = 1
        BEGIN
            UPDATE [dbo].[tblLop]
            SET GVCN = NULL,
                UpdateUser = @Sys_UserID,
                UpdateTime = GETDATE()
            WHERE LopID = @LopID AND NienKhoa = @NienKhoa;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Xử lý lỗi và báo lỗi chi tiết
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
