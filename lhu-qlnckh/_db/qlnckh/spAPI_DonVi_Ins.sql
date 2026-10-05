create proc spAPI_DonVi_Ins
@MaDonVi VARCHAR(5)
,@TenDonVi NVARCHAR(100)
,@SYS_UserId VARCHAR(9)
,@Sys_SystemRight INT
AS
BEGIN
	INSERT DonVi([MaDonVi], [TenDonVi], [Is_Xoa], [CreateUser], [CreateTime])
	VALUES(@MaDonVi, @TenDonVi, 0, @SYS_UserId, GETDATE())
END