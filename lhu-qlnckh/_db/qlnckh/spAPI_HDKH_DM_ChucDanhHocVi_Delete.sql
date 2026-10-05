CREATE  PROCEDURE dbo.spAPI_HDKH_DM_ChucDanhHocVi_Delete
    @ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.tblHDKH_DM_ChucDanhHocVi WHERE ID = @ID)
    BEGIN
        RAISERROR(N'Không tìm thấy định mức với ID %d.', 16, 1, @ID);
        RETURN;
    END

    -- Thực hiện xóa mềm bằng cách cập nhật cờ IsActive
    UPDATE dbo.tblHDKH_DM_ChucDanhHocVi
    SET IsActive = 0
    WHERE ID = @ID;

    -- Kiểm tra xem có dòng nào bị ảnh hưởng không
    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR(N'Xóa định mức không thành công hoặc định mức đã được đánh dấu xóa.', 16, 1);
        RETURN;
    END

    SELECT Message = N'Xóa định mức thành công.';
END
