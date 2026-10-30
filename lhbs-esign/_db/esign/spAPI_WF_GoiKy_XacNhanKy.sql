CREATE PROCEDURE spAPI_WF_GoiKy_XacNhanKy
    @GoiKyID bigint,
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM tblWF_NguoiKy WHERE GoiKyID = @GoiKyID AND GiaTriNguoiKy = @sys_UserID AND TrangThai = 'CHO' AND Enable = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy lượt ký đang chờ của bạn trên văn bản này.', 16, 1);
        RETURN;
    END

    -- Ghi nhận lượt ký của người dùng hiện tại
    UPDATE tblWF_NguoiKy
    SET TrangThai = 'DA_KY', NgayKy = GETDATE(), UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE GoiKyID = @GoiKyID AND GiaTriNguoiKy = @sys_UserID AND TrangThai = 'CHO' AND Enable = 1;

    -- Nếu tất cả người ký đã ký xong -> gói ký hoàn tất
    IF NOT EXISTS (SELECT 1 FROM tblWF_NguoiKy WHERE GoiKyID = @GoiKyID AND TrangThai = 'CHO' AND Enable = 1)
    BEGIN
        UPDATE tblWF_GoiKy SET TrangThai = 'DA_KY', UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE GoiKyID = @GoiKyID;
    END
    ELSE
    BEGIN
        UPDATE tblWF_GoiKy SET TrangThai = 'CHO_KY', UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE GoiKyID = @GoiKyID AND TrangThai = 'MOI';
    END

    SELECT mess = N'Xác nhận ký thành công.', id = @GoiKyID;
END