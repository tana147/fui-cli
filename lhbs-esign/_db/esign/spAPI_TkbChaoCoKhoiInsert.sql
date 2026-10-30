CREATE PROCEDURE spAPI_TkbChaoCoKhoiInsert
    @Khoi VARCHAR(2),
    @Thu INT,
    @Buoi VARCHAR(10),
    @Tiet INT,
    @GhiChu NVARCHAR(200) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO tblTKB_ChaoCoKhoi (Khoi, Thu, Buoi, Tiet, GhiChu, CreateUser, CreateTime, UpdateUser, UpdateTime, Enable)
    VALUES (@Khoi, @Thu, @Buoi, @Tiet, @GhiChu, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1)
    SELECT mess = N'Đã thêm'
END