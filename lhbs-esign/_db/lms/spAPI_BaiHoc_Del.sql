

CREATE PROC [dbo].[spAPI_BaiHoc_Del]
@ChuongTrinhHocID INT,
@BaiHocID INT,
@GiaoVienID VARCHAR(10),
@SYS_USERID VARCHAR(9)
AS
BEGIN
	
	UPDATE
	[dbo].tblLMSBaiHoc 
SET	
	Enable = 0,
	--Xóa flag
	UpdateUser = @SYS_USERID,
		UpdateTime = GETDATE()
WHERE
	GiaoVienID = @GiaoVienID
	AND ChuongTrinhHocID = @ChuongTrinhHocID
	AND  BaiHocID = @BaiHocID
END