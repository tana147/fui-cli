CREATE PROC [dbo].[spAPI_NCKH_ThanhVien_Del_Obj]
@ThanhVienNCKHObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN
	--update vào table Thành Viên 
	UPDATE [dbo].[NCKH_ThanhVien]
	SET
		Is_Xoa = 1,
		[NhanVienCapNhat] = @SYS_UserID,
		[ThoiGianCapNhat] = GETDATE()
	FROM OPENJSON(@ThanhVienNCKHObj)
	WITH (
		ThanhVienNCKHID INT
	) AS json
	WHERE [dbo].[NCKH_ThanhVien].[ThanhVienNCKHID] = json.ThanhVienNCKHID
END