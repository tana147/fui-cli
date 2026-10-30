CREATE PROCEDURE spAPI_Teacher_GetDSHocSinh_AssignToStudent_ByLopID
	@LopID INT,
	@AssignmentID INT,
	@NienKhoa INT
as
begin
		IF (@NienKhoa IS NULL OR @NienKhoa = 0)
		BEGIN
			RAISERROR(N'NienKhoa là bắt buộc khi tra học sinh đã giao bài theo LopID.', 16, 1);
			RETURN;
		END;

		select ats.AssignToStudentID,ats.HocSinhID from tblEL_AssignToStudent ats
			inner join tblMonHocLop mhl on mhl.MonHocLopID = ats.MonHocLopID
				AND mhl.NienKhoa = @NienKhoa
			inner join tblLop l on l.LopID = mhl.LopNhomID AND l.NienKhoa = mhl.NienKhoa
		where l.LopID = @LopID and ats.AssignmentID = @AssignmentID and ats.IsDeleted = 0
end
