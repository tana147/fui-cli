
CREATE PROC spAPI_AnPham_Dot_Del
@AnPham_DotID INT,
@SYS_UserID varchar(9),
@sys_SystemRight INT
AS
BEGIN
	UPDATE AnPham_Dot
		SET Is_Xoa = 1
		, UpdateUser = @SYS_UserID
		, UpdateTime = GETDATE()
	WHERE AnPham_DotID = @AnPham_DotID
END 