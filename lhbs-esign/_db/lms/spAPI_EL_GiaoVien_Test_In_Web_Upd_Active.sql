
CREATE PROC [dbo].[spAPI_EL_GiaoVien_Test_In_Web_Upd_Active]
@GiaoVienID VARCHAR(9)
AS
BEGIN
	UPDATE tblEL_User_Assign
	SET
		IsActive = 1
	WHERE SYS_USERID = @GiaoVienID

	UPDATE tblEL_User_Assign
	SET
		IsActive = 0
	WHERE SYS_USERID <> @GiaoVienID 

END