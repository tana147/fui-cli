create   proc spAPI_GiaoVienLop_Get_MaDonVi_ByUserID
@NienKHoa INT,
@SYS_USERID VARCHAR(9)
as
begin
	select MaDonVi, VaiTro from tblGiaoVienLop where GiaoVienID = @SYS_USERID and Enable = 1 and NienKhoa = @NienKHoa
end