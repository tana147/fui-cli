CREATE PROC spAPI_EL_PhuHuynh_YKien_Upd_By_SubmissionID
	@SubmissionID INT,
	@NoiDungPhuHuynh NVARCHAR(1000),
	@SYS_USERID VARCHAR(9)
AS
BEGIN
	UPDATE tblEL_YKienPhuHuynh
	SET
		NoiDungPhuHuynh = @NoiDungPhuHuynh,
		PhuHuynhXacNhan = @SYS_USERID,
		ThoiGianXacNhan = GETDATE()
	WHERE SubmissionID = @SubmissionID
END