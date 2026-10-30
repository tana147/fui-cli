CREATE PROCEDURE spAPI_TkbTuanHienTaiGet
    @sys_UserID varchar(9)
AS
BEGIN
    SELECT TOP 1 t.ID, t.TuanTrongNam, t.NamHoc, t.UpdateUser, t.UpdateTime, tt.TenTuan
    FROM tblTKB_TuanHienTai t
    LEFT JOIN tblTKB_Tuan tt ON tt.TuanTrongNam = t.TuanTrongNam AND tt.NamHoc = t.NamHoc
    ORDER BY t.ID DESC
END
