
CREATE PROC [dbo].[spAPI_GiaoAn_Del]
@ChuongTrinhHocID INT,
@GiaoVienID	VARCHAR(10),
@SYS_USERID VARCHAR(9)
AS
BEGIN
	
	UPDATE [dbo].tblLMSChuongTrinhHoc 
	SET	
		Enable = 0, --Xóa
		UpdateUser	= @SYS_USERID,
		UpdateTime	= GETDATE()
	WHERE GiaoVienID = @GiaoVienID AND ChuongTrinhHocID = @ChuongTrinhHocID
END