CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_MienGiam_Delete]
    @MienGiamID BIGINT,
    @sys_UserID VARCHAR(9)
AS
    BEGIN
        SET NOCOUNT ON;
        UPDATE
            dbo.tblHDKH_MienGiam
        SET
            IsDeleted = 1,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE MienGiamID    = @MienGiamID
              AND IsDeleted = 0;
        IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR(N'Không tìm thấy bản ghi miễn giảm hoặc nó đã được xóa.', 16, 1);
                RETURN 0;
            END;
        SELECT Message = N'Xóa thông tin miễn giảm thành công.';
    END;
