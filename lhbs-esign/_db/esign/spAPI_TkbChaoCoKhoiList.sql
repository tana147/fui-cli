CREATE PROCEDURE spAPI_TkbChaoCoKhoiList
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Khoi, Thu, Buoi, Tiet, GhiChu
    FROM tblTKB_ChaoCoKhoi
    WHERE Enable = 1
    ORDER BY Khoi;
END