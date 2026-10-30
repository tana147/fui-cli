CREATE PROCEDURE spAPI_TkbChaoCoKhoiTuanInsert
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
    INSERT INTO tblTKB_ChaoCoKhoi_Tuan (Tuan, Khoi, Thu, Buoi, Tiet, GhiChu, CreateUser, CreateTime, Enable)
    VALUES (@Tuan, @Khoi, @Thu, @Buoi, @Tiet, @GhiChu, @sys_UserID, GETDATE(), 1)
    SELECT mess = N'Đã thêm'
END
