-- [dbo].[spAPI_EL_Assigment_Get_ByUser] 8, 2025, 'NA0000022', 9
CREATE PROC [dbo].[spAPI_EL_Assigment_Get_ByUser]
	@KhoiID INT,
	@MonHocID INT,
	@NienKhoa INT,
	@Status INT,
	@SYS_USERID VARCHAR(9),
	@SYS_GROUPID INT,
	@sys_SystemRight INT
as
begin
	if(@sys_SystemRight NOT IN (5,9))
	BEGIN
		select 
			 *
		from tblEL_Assignments  AS asm
			inner join tblMonHoc as mh	on mh.MonHocID = asm.MonHocID and mh.Enable = 1
				where asm.NienKhoa = @NienKhoa and asm.MonHocID = @MonHocID 
	END
	ELSE
	BEGIN
		select 
			 *
		from tblEL_Assignments  AS asm
			inner join tblMonHoc as mh	on mh.MonHocID = asm.MonHocID and mh.Enable = 1 
		where asm.NienKhoa = @NienKhoa and asm.MonHocID = @MonHocID 
	END
end
