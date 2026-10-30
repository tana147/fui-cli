CREATE PROCEDURE spAPI_TkbTuanHienTaiSet
    @TuanTrongNam int,
    @NamHoc       varchar(9),
    @sys_UserID   varchar(9)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblTKB_Tuan WHERE TuanTrongNam = @TuanTrongNam AND NamHoc = @NamHoc AND Enable = 1)
    BEGIN
        RAISERROR(N'Tuần không tồn tại trong danh mục', 16, 1)
        RETURN
    END

    INSERT INTO tblTKB_TuanHienTai (TuanTrongNam, NamHoc, UpdateUser, UpdateTime)
    VALUES (@TuanTrongNam, @NamHoc, @sys_UserID, GETDATE())

    SELECT mess = N'Đã cập nhật tuần hiện tại'
END
