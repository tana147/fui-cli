create proc spAPI_DonVi_Upd
@MaDonVi VARCHAR(5)
,@TenDonVi NVARCHAR(100)
,@SYS_UserId VARCHAR(9)
,@Sys_SystemRight INT
AS
BEGIN
	UPDATE DonVi
	Set TenDonVi = @TenDonVi,
		CreateUser = @SYS_UserId,
		CreateTime = Getdate()
	where madonvi  = @MaDonVi
END