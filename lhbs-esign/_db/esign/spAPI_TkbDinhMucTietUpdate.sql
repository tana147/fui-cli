CREATE PROCEDURE spAPI_TkbDinhMucTietUpdate
    @ID INT,
    @MaMon VARCHAR(10),
    @Khoi VARCHAR(2),
    @SoTietTuan DECIMAL(4,1),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTKB_DinhMucTiet SET MaMon = @MaMon, Khoi = @Khoi, SoTietTuan = @SoTietTuan WHERE ID = @ID;
END