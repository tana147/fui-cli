CREATE PROC [dbo].[spAPI_KHCN_ThanhVien_Del_Obj]
@ThanhVienKHCNObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN
	--update vào table Thành Viên 
	UPDATE [dbo].[KHCN_ThanhVien]
	SET
		Is_Xoa = 1,
		[NhanVienCapNhat] = @SYS_UserID,
		[ThoiGianCapNhat] = GETDATE()
	FROM OPENJSON(@ThanhVienKHCNObj)
	WITH (
		ThanhVienKHCNID INT
	) AS json
	WHERE [dbo].[KHCN_ThanhVien].[ThanhVienKHCNID] = json.ThanhVienKHCNID
END