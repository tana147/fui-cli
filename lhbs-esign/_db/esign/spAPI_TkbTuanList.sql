CREATE PROCEDURE spAPI_TkbTuanList
    @NamHoc     varchar(9) = '',
    @sys_UserID varchar(9)
AS
BEGIN
    SELECT TuanTrongNam, NamHoc, ThangHoc, NgayBatDau, NgayKetThuc, TenTuan
    FROM tblTKB_Tuan
    WHERE Enable = 1
      AND (@NamHoc = '' OR NamHoc = @NamHoc)
    ORDER BY TuanTrongNam
END
