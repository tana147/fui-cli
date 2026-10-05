CREATE PROC [dbo].[spAPI_AnPham_DotDuyet_Del]
@AnPham_DotDuyetID INT,
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	UPDATE AnPham_DotDuyet
		SET Is_Xoa = 1
		, UpdateUser = @SYS_UserID
		, UpdateTime = GETDATE()
	WHERE AnPham_DotDuyetID = @AnPham_DotDuyetID
END
