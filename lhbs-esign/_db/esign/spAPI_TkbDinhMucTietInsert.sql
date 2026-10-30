CREATE PROCEDURE spAPI_TkbDinhMucTietInsert
    @MaMon VARCHAR(10),
    @Khoi VARCHAR(2),
    @SoTietTuan DECIMAL(4,1),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO tblTKB_DinhMucTiet (MaMon, Khoi, SoTietTuan) VALUES (@MaMon, @Khoi, @SoTietTuan);
    SELECT SCOPE_IDENTITY() AS ID;
END