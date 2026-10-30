CREATE PROCEDURE spAPI_StemPhanCongDelete
    @url1_StemPhanCongID bigint,
    @sys_UserID          varchar(9)
AS
BEGIN
    UPDATE tblTKB_StemPhanCong
    SET Enable = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE StemPhanCongID = @url1_StemPhanCongID

    SELECT mess = N'Đã xoá', id = @url1_StemPhanCongID
END
