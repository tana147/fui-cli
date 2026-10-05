create proc spAPI_DonVi_Del
@MaDonVi VARCHAR(5)
,@SYS_UserId VARCHAR(9)
,@Sys_SystemRight INT
AS
BEGIN
	UPDATE DonVi
	Set Is_Xoa = 1
	where madonvi  = @MaDonVi
END