CREATE PROCEDURE spAPI_TkbChaoCoKhoiTuanList
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, Tuan, Khoi, Thu, Buoi, Tiet, GhiChu
    FROM tblTKB_ChaoCoKhoi_Tuan
    WHERE Enable = 1
    ORDER BY Tuan DESC, Khoi;
END
