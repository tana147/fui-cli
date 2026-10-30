CREATE PROCEDURE [dbo].[spAPI_TienDo_GiaoBai_DetailByGiaoVienID]
	@GiaoVienID varchar(9),
	@KhoiID int,
	@MonHocID int
	as
	begin
	--Table 1: Lấy danh sách bài tập
select ass.AssignmentID,
		ass.KhoiID,
		ass.Instructions,
		N'Tuần ' + CAST(t.Tuan AS VARCHAR(2))
		+ N' - Tháng ' + CAST(t.ThangHoc as varchar(2))
		+ N' - (' + FORMAT(t.NgayBatDau ,'dd/MM/yyyy') 
		+ N' - ' + FORMAT(t.NgayKetThuc,'dd/MM/yyyy') + ')'  AS Tuan_HienThi,
		ass.Chuong,
		ass.Title,
		ass.MaxScore,
		ass.CreateTime,
		ass.CreateUser
from tblEL_Assignments ass
	inner join tblTuanHocTap t on t.TuanHocID = ass.TuanHocID
where ass.CreateUser = @GiaoVienID and ass.IsDeleted = 0 and ass.KhoiID = @KhoiID and ass.MonHocID = @MonHocID  AND ass.IsDev is null

--Table 2: Lấy danh sách bài học
select l.LessonID,
	l.KhoiID,
	l.Title,
	l.Description,
	N'Tuần ' + CAST(t.Tuan AS VARCHAR(2))
		+ N' - Tháng ' + CAST(t.ThangHoc as varchar(2))
		+ N' - (' + FORMAT(t.NgayBatDau ,'dd/MM/yyyy') 
		+ N' - ' + FORMAT(t.NgayKetThuc,'dd/MM/yyyy') + ')'  AS Tuan_HienThi,
	l.CreateTime,
	l.CreateUser
	from tblEL_Lessons l
	inner join tblTuanHocTap t on t.TuanHocID = l.TuanHocID
where l.CreateUser = @GiaoVienID and l.IsDeleted = 0 and l.KhoiID = @KhoiID and l.MonHocID = @MonHocID  AND l.IsDev is null

--Table 3: Lấy tất cả các lớp được giao bài
		SELECT l.LopID
		, l.TenLop
		, atc.AssignToClassID
		, atc.CreateTime
		,atc.DueDate
		,atc.ResourceType
		, atc.ResourceID
		from tblEL_AssignToClass atc
			INNER JOIN tblMonHocLop mhl on mhl.MonHocLopID = atc.MonHocLopID
			INNER JOIN tblLop l on mhl.LopNhomID = l.LopID and l.KhoiID = @KhoiID and l.Enable = 1 AND l.NienKhoa = mhl.NienKhoa
		where atc.CreateUser = @GiaoVienID and atc.IsDeleted = 0

end
