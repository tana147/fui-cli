CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetKhoi_MonHoc_ByGiaoVienID]
	@NienKhoa int,
	@HocKi INT,
	@sys_UserID VARCHAR(9)
as
begin
	SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID)
	--Lấy danh sách khối
	select DISTINCT gvl.KhoiID from tblGiaoVienLop gvl
	where (gvl.GiaoVienID = @sys_UserID ) and gvl.Enable = 1 and NienKhoa = @NienKhoa AND gvl.HocKy = @HocKi
	UNION 
	select DISTINCT gvl.KhoiID from tblEL_GiaoVienLop gvl
	where (gvl.GiaoVienID = @sys_UserID ) and gvl.Enable = 1 and NienKhoa = @NienKhoa  AND gvl.HocKy = @HocKi
	order by gvl.KhoiID
	-- Lấy danh sách môn học
	select DISTINCT  gvl.KhoiID,mh.MonHocID,mh.TenMonHoc_HienThi from tblGiaoVienLop gvl
		inner join tblMonHoc mh on mh.MonHocID = gvl.MonHocID and mh.Enable = 1
	where (gvl.GiaoVienID = @sys_UserID ) and gvl.Enable = 1 and NienKhoa = @NienKhoa  AND gvl.HocKy = @HocKi
	UNION
	select DISTINCT  gvl.KhoiID,mh.MonHocID,mh.TenMonHoc_HienThi from tblEL_GiaoVienLop gvl
		inner join tblMonHoc mh on mh.MonHocID = gvl.MonHocID and mh.Enable = 1
	where (gvl.GiaoVienID = @sys_UserID ) and gvl.Enable = 1 and NienKhoa = @NienKhoa  AND gvl.HocKy = @HocKi
end