CREATE PROCEDURE spAPI_TkbPhanCongDelete
    @url1_PhanCongID bigint,
    @sys_UserID      varchar(9)
AS
BEGIN
    UPDATE tblTKB_PhanCongGiangDay
    SET Enable = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE PhanCongID = @url1_PhanCongID

    SELECT mess = N'Đã xoá', id = @url1_PhanCongID
END
