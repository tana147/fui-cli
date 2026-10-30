CREATE PROCEDURE spAPI_WF_GoiKy_TuChoi
    @GoiKyID bigint,
    @LyDo nvarchar(500),
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM tblWF_NguoiKy WHERE GoiKyID = @GoiKyID AND GiaTriNguoiKy = @sys_UserID AND TrangThai = 'CHO' AND Enable = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy lượt ký đang chờ của bạn trên văn bản này.', 16, 1);
        RETURN;
    END

    UPDATE tblWF_NguoiKy
    SET TrangThai = 'TU_CHOI', NgayKy = GETDATE(), UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE GoiKyID = @GoiKyID AND GiaTriNguoiKy = @sys_UserID AND TrangThai = 'CHO' AND Enable = 1;

    UPDATE tblWF_GoiKy SET TrangThai = 'TU_CHOI', UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE GoiKyID = @GoiKyID;

    SELECT mess = N'Đã từ chối ký văn bản.', id = @GoiKyID;
END