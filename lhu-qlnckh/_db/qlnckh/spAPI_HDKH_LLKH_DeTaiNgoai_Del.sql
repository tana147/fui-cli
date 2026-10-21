CREATE PROCEDURE [dbo].[spAPI_HDKH_LLKH_DeTaiNgoai_Del]
	@DeTaiID bigint,
	@sys_UserID varchar(9)
AS
-- Lý lịch khoa học: Xóa đề tài ngoài trường tự khai
BEGIN
	SET NOCOUNT ON;

	UPDATE tblHDKH_Profile_DeTaiDaThamGia
	SET IsDeleted = 1,
		UpdateTime = GETDATE(),
		UpdateUser = @sys_UserID
	WHERE DeTaiID = @DeTaiID AND NhanVienID = @sys_UserID;

	SELECT Status = 1, Message = N'Xóa đề tài thành công';
END;
