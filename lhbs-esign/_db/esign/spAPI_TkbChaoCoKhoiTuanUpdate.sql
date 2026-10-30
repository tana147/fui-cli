CREATE PROCEDURE spAPI_TkbChaoCoKhoiTuanUpdate
    @ID INT,
    @Tuan INT,
    @Khoi VARCHAR(10),
    @Thu INT,
    @Buoi VARCHAR(10),
    @Tiet INT,
    @GhiChu NVARCHAR(200) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTKB_ChaoCoKhoi_Tuan
    SET Tuan = @Tuan, Khoi = @Khoi, Thu = @Thu, Buoi = @Buoi, Tiet = @Tiet, GhiChu = @GhiChu,
        UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE ID = @ID
    SELECT mess = N'Đã cập nhật'
END
