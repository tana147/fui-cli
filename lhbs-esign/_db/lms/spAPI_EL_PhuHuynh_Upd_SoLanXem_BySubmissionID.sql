CREATE PROC spAPI_EL_PhuHuynh_Upd_SoLanXem_BySubmissionID
	@SubmissionID INT ,
	@SYS_USERID VARCHAR(9)
AS
BEGIN
     IF NOT EXISTS (SELECT TOP 1 * FROM tblEL_YKienPhuHuynh WHERE SubmissionID = @SubmissionID )
	 BEGIN
	       INSERT INTO tblEL_YKienPhuHuynh (SubmissionID,  SoLanXem, PhuHuynhTruyCap, PhuHuynhTruyCapLanCuoi)
			VALUES (
				@SubmissionID, 1, @SYS_USERID, GETDATE()
			)
	 END
	 ELSE
	 BEGIN
	     UPDATE tblEL_YKienPhuHuynh
		 SET
			SoLanXem = ISNULL(SoLanXem, 0) + 1,
			PhuHuynhTruyCap = @SYS_USERID,
			PhuHuynhTruyCapLanCuoi = GETDATE()
		 WHERE SubmissionID = @SubmissionID
	 END
END