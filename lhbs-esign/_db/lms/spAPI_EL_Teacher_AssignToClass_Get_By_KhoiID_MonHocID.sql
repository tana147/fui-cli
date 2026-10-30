CREATE PROC [dbo].[spAPI_EL_Teacher_AssignToClass_Get_By_KhoiID_MonHocID]
	@KhoiID INT = 0,
	@MonHocID INT = 0,
	@SYS_USERID VARCHAR(9)
as
begin
	DECLARE @Table_assignment table (AssignmentID INT)
	Insert into @Table_assignment (AssignmentID )
	select AssignmentID
	from tblEL_Assignments
	where  (KhoiID = @KhoiID or @KhoiID = 0)
		and (MonHocID=@MonHocID or @MonHocID = 0)
		AND IsDeleted = 0
		and CreateUser = @SYS_USERID
	
	select 
		atc.*,
		asm.*,
		mh.MonHocName
	from tblEL_AssignToClass as atc
		inner join tblEL_Assignments as asm on asm.AssignmentID = atc.AssignmentID and asm.IsDeleted = 0
		inner join tblMonHoc as mh on asm.MonHocID = mh.MonHocID and mh.Enable = 1
	where atc.AssignmentID in (select AssignmentID from @Table_assignment)
	AND atc.IsDeleted = 0
end 