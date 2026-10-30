CREATE PROCEDURE spAPI_TkbChayAutoLogNgayApDungUpdate
    @RunID       int,
    @NgayApDung  date,
    @sys_UserID  varchar(9)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID AND Enable = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy phiên TKB', 16, 1)
        RETURN
    END

    UPDATE tblTKB_ChayAutoLog
    SET NgayApDungTu = @NgayApDung
    WHERE RunID = @RunID

    SELECT mess = N'Đã cập nhật ngày áp dụng', id = @RunID
END
