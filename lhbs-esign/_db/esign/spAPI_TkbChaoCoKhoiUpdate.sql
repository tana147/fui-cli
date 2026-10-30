CREATE PROCEDURE spAPI_TkbChaoCoKhoiUpdate
    @ID INT,
    @Khoi VARCHAR(2),
    @Thu INT,
    @Buoi VARCHAR(10),
    @Tiet INT,
    @GhiChu NVARCHAR(200) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTKB_ChaoCoKhoi
    SET Khoi = @Khoi, Thu = @Thu, Buoi = @Buoi, Tiet = @Tiet, GhiChu = @GhiChu,
        UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE ID = @ID
    SELECT mess = N'Đã cập nhật'
END