CREATE PROCEDURE spAPI_TkbMonHocDelete
    @url1_MaMon varchar(15),
    @sys_UserID varchar(9)
AS
BEGIN
    UPDATE tblTKB_MonHoc
    SET Enable = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE MaMon = @url1_MaMon

    SELECT mess = N'Đã xoá', id = @url1_MaMon
END
