 create PROCEDURE [dbo].[spAPI_EL_Student_GetDashboardData_OLD]--'H23300048'
    @sys_UserID VARCHAR(9)
AS
BEGIN
    

	DECLARE @HocSinhID_INT INT = CAST(RIGHT(@sys_UserID,8) AS INT);
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
    DECLARE @LopID VARCHAR(10) = (
	select top 1 l.LopID
	from dbo.tblHocSinhLop hsl
	inner join tblLop l
		on hsl.LopID = l.LopID
	where hsl.HocSinhID = @HocSinhID_INT
		and hsl.Enable = 1
		and l.NienKhoa = @NienKhoa
		and l.Enable = 1);

-- === Bảng 1: Today's Focus (Nhiệm vụ cần làm ngay) ===
-- Ưu tiên 1: Quá hạn, Ưu tiên 2: Hạn trong 24h, Ưu tiên 3: Đang làm dở, Ưu tiên 4: Mới nhất
select top 5 *
from (

	-- ===== PHẦN 1: LẤY BÀI TẬP (ASSIGNMENTS) CHƯA NỘP =====
	select 'ASSIGNMENT' as ResourceType
		 , atc.AssignToClassID as ResourceID
		 , a.Title
		 , mh.MonHocName
		 , atc.DueDate
		 , case
					 when atc.DueDate < getdate() then
						 'OVERDUE'
					 when s.SubmissionStatus = 1 then
						 'IN_PROGRESS'
					 when s.SubmissionStatus = 2 then
						 'SUBMITTED'
					 when s.SubmissionStatus = 3 then
						 'SAVE_DRAFT'
					when s.SubmissionStatus = 4 then
						 'GRADED'
					 else
						 'NOT_STARTED'
		   end as Status
		 , 1 as Priority -- Ưu tiên 1 (cao nhất) cho bài tập
	from dbo.tblEL_AssignToClass atc
	join dbo.tblEL_Assignments a
		on atc.ResourceID = a.AssignmentID
			and atc.ResourceType = 'ASSIGNMENT'
	join dbo.tblMonHoc mh
		on a.MonHocID = mh.MonHocID
	left join dbo.tblEL_Submissions s
		on atc.AssignToClassID = s.AssignToClassID
			and s.HocSinhID = @HocSinhID_INT
	where atc.MonHocLopID in (select MonHocLopID from tblMonHocLop where LopNhomID = @LopID)
		and atc.IsDeleted = 0
		and a.IsDeleted = 0
		and (s.SubmissionID is null
			or s.SubmissionStatus < 2) -- Điều kiện: chưa nộp bài

	union all

	-- ===== PHẦN 2: LẤY BÀI HỌC (LESSONS) CHƯA HOÀN THÀNH =====
	select 'LESSON' as ResourceType
		 , atc.AssignToClassID as ResourceID
		 , l.Title
		 , mh.MonHocName
		 , atc.DueDate
		 , -- Vẫn lấy DueDate nếu có (dành cho bài học có hạn xem)
		   case
					 when lp.ProgressID is not null
						 and
						 lp.IsCompleted = 0 then
						 'IN_PROGRESS'
					 else
						 'NOT_STARTED'
		   end as Status
		 , 2 as Priority -- Ưu tiên 2 (thấp hơn) cho bài học
	from dbo.tblEL_AssignToClass atc
	join dbo.tblEL_Lessons l
		on atc.ResourceID = l.LessonID
			and atc.ResourceType = 'LESSON'
	join dbo.tblMonHoc mh
		on l.MonHocID = mh.MonHocID
	left join dbo.tblEL_Learning_Progress lp
		on l.LessonID = lp.LessonID
			and lp.HocSinhID = @HocSinhID_INT
	where atc.MonHocLopID in (select MonHocLopID from tblMonHocLop where LopNhomID = @LopID)
		and atc.IsDeleted = 0
		and l.IsDeleted = 0
		and (lp.ProgressID is null
			or lp.IsCompleted = 0) -- Điều kiện: chưa hoàn thành bài học

) as Tasks
order by Priority asc
	   , -- Ưu tiên Bài tập (Priority=1) lên trước Bài học (Priority=2)
		 case
				   when Status = 'OVERDUE' then
					   0
				   else
					   1
		 end
	   , -- Trong các bài tập, ưu tiên bài quá hạn
		 DueDate asc; -- Sắp xếp theo hạn nộp gần nhất


-- === Bảng 2: Week Ahead (Lịch trong tuần) ===
select cast(atc.DueDate as date)  as DueDate
	 , count(atc.AssignToClassID) as TaskCount
	 ,
	   -- (SỬA LẠI PHẦN NÀY)
	   (
		   select atc_inner.ResourceType
				, atc_inner.ResourceID
				,
				  -- Dùng CASE để lấy Title từ bảng tương ứng
				  case
							when atc_inner.ResourceType = 'ASSIGNMENT' then
								(
									select ass.Title
									from tblEL_Assignments ass
									where ass.AssignmentID = atc_inner.ResourceID)
							when atc_inner.ResourceType = 'LESSON' then
								(
									select lsn.Title
									from tblEL_Lessons lsn
									where lsn.LessonID = atc_inner.ResourceID)
							else
								N'Nhiệm vụ không xác định'
				  end as Title
		   from dbo.tblEL_AssignToClass atc_inner
		   where atc_inner.IsDeleted = 0
			   -- Lọc theo đúng ngày của dòng hiện tại
			   and cast(atc_inner.DueDate as date) = cast(atc.DueDate as date)
			   -- Lọc theo đúng lớp của học sinh
			   and atc_inner.MonHocLopID in (select MonHocLopID from tblMonHocLop where LopNhomID = @LopID)
		   for json path)		  
	   as TasksJSON
from dbo.tblEL_AssignToClass atc
where atc.IsDeleted = 0
	  and atc.DueDate between getdate() and dateadd(day, 7, getdate())
	  and atc.MonHocLopID in (select MonHocLopID from tblMonHocLop where LopNhomID = @LopID)
group by cast(atc.DueDate as date)
order by DueDate;

-- === Bảng 3: Semester Progress (Tiến độ môn học) ===
with AllTasks
as (
	select MonHocID
		 , sum(TotalCount) as TotalCount
	from (
		select a.MonHocID
			 , count(atc.AssignToClassID) as TotalCount
		from dbo.tblEL_AssignToClass atc
		join dbo.tblEL_Assignments a
			on atc.AssignmentID = a.AssignmentID
		where atc.MonHocLopID in (select MonHocLopID from tblMonHocLop where LopNhomID = @LopID)
			and atc.IsDeleted = 0
			and atc.ResourceType = 'ASSIGNMENT'
		group by a.MonHocID

		union all

		select a.MonHocID
			 , count(atc.AssignToClassID) as TotalCount
		from dbo.tblEL_AssignToClass atc
		join dbo.tblEL_Lessons a
			on atc.ResourceID = a.LessonID
		where atc.MonHocLopID in (select MonHocLopID from tblMonHocLop where LopNhomID = @LopID)
			and atc.IsDeleted = 0
			and atc.ResourceType = 'LESSON'
		group by a.MonHocID) t
	group by MonHocID),
CompletedTasks
as (
	select MonHocID
		 , sum(CompletedCount) as CompletedCount
	from   (select a.MonHocID
		 , count(s.SubmissionID) as CompletedCount
	from dbo.tblEL_Submissions s
	join dbo.tblEL_AssignToClass atc
		on s.AssignToClassID = atc.AssignToClassID
	join dbo.tblEL_Assignments a
		on atc.AssignmentID = a.AssignmentID
	where s.HocSinhID = @HocSinhID_INT
		and s.SubmissionStatus >= 2
	group by a.MonHocID
union all
SELECT a.MonHocID, COUNT(s.ProgressID) AS CompletedCount
FROM dbo.tblEL_Learning_Progress s
JOIN dbo.tblEL_Lessons a ON s.LessonID = a.LessonID
WHERE s.HocSinhID = @HocSinhID_INT
  AND s.IsCompleted = 1
  AND a.IsDeleted = 0
GROUP BY a.MonHocID
	) t
	group by MonHocID

	
)
select mh.MonHocID
	 , mh.MonHocName
	 , isnull(at.TotalCount, 0)		as TotalTasks
	 , isnull(ct.CompletedCount, 0) as CompletedTasks
from dbo.tblMonHoc mh
	left join AllTasks at
		on mh.MonHocID = at.MonHocID
	left join CompletedTasks ct
		on mh.MonHocID = ct.MonHocID
where isnull(at.TotalCount, 0) > 0 -- Chỉ lấy các môn có bài tập được giao
order by mh.Sort;


-- === Bảng 4: What's New (Bảng tin) - ĐÃ VIẾT LẠI HOÀN TOÀN ===
-- Lấy 5 hoạt động mới nhất từ nhiều nguồn khác nhau
select top 5 *
from (

	-- Hoạt động 1: BÀI TẬP ĐÃ ĐƯỢC CHẤM (GRADED)
	select 
		CASE 
			WHEN s.SubmissionStatus = 3 THEN 'SAVE_DRAFT'
			WHEN s.SubmissionStatus = 4 THEN  'GRADED'
		ELSE '' end as FeedType
		 , s.SubmissionID as ObjectID
		 , a.Title
		 , s.GradedDate as EventTime
		 , N'Điểm: ' + cast(s.Score as varchar(10)) + ' / ' + cast(atc.MaxScore as varchar(10)) as Details
		 , atc.AssignToClassID
		 , 'ASSIGNMENT' as ResourceType
	from dbo.tblEL_Submissions s
	join dbo.tblEL_AssignToClass atc
		on s.AssignToClassID = atc.AssignToClassID
	join dbo.tblEL_Assignments a
		on atc.ResourceID = a.AssignmentID
			and atc.ResourceType = 'ASSIGNMENT'
	where s.HocSinhID = @HocSinhID_INT
		and s.SubmissionStatus IN (3,4) -- Status 3 = Đã chấm

	union all

	-- Hoạt động 2: HỌC SINH VỪA NỘP BÀI (SUBMITTED)
	select 'SUBMITTED' as FeedType
		 , s.SubmissionID as ObjectID
		 , a.Title
		 , s.SubmissionTime as EventTime
		 , mh.MonHocName as Details
		 , -- Hiển thị tên môn học làm chi tiết
		   atc.AssignToClassID
		 , 'ASSIGNMENT' as ResourceType
	from dbo.tblEL_Submissions s
	join dbo.tblEL_AssignToClass atc
		on s.AssignToClassID = atc.AssignToClassID
	join dbo.tblEL_Assignments a
		on atc.ResourceID = a.AssignmentID
			and atc.ResourceType = 'ASSIGNMENT'
	join dbo.tblMonHoc mh
		on a.MonHocID = mh.MonHocID
	where s.HocSinhID = @HocSinhID_INT
		and s.SubmissionStatus = 2 -- Status 2 = Đã nộp

	union all

	-- Hoạt động 3: HỌC SINH VỪA HOÀN THÀNH BÀI HỌC (LESSON_COMPLETED)
	select 'LESSON_COMPLETED' as FeedType
		 , lp.ProgressID as ObjectID
		 , l.Title
		 , lp.CompletedDate as EventTime
		 , mh.MonHocName as Details
		 , atc.AssignToClassID
		 , 'LESSON' as ResourceType
	from dbo.tblEL_Learning_Progress lp
	join dbo.tblEL_Lessons l
		on lp.LessonID = l.LessonID
	join dbo.tblMonHoc mh
		on l.MonHocID = mh.MonHocID
	-- Tìm lần giao bài tương ứng để có thể điều hướng
	join dbo.tblEL_AssignToClass atc
		on l.LessonID = atc.ResourceID
			and atc.ResourceType = 'LESSON'
			and atc.MonHocLopID in (select MonHocLopID from tblMonHocLop where LopNhomID = @LopID)
	where lp.HocSinhID = @HocSinhID_INT
		and lp.IsCompleted = 1

	union all

	-- Hoạt động 4: HỌC SINH ĐẠT THÀNH TÍCH (ACHIEVEMENT)
	select 'ACHIEVEMENT' as FeedType
		 , ach.AchievementID as ObjectID
		 , ad.Title
		 , ach.CreateTime as EventTime
		 , '+' + cast(ach.PointsEarned as varchar(10)) + ' XP' as Details
		 , null as AssignToClassID
		 , -- Thành tích không gắn với lần giao bài cụ thể
		   null as ResourceType
	from dbo.tblEL_Achievements ach
	join dbo.tblEL_Achievement_Definitions ad
		on ach.AchievementCode = ad.AchievementCode
	where ach.HocSinhID = @HocSinhID_INT
		and ach.IsDeleted = 0) as Feeds
order by EventTime desc;


-- === Bảng 5: Recent Achievements (Thành tích gần đây) - (MỚI) ===
-- Lấy 6 thành tích mới nhất của học sinh
select top 6 ad.Title
		   , ad.Description
		   , ad.ImageUrl
		   , ad.AchievementType
		   , -- 'BADGE' hoặc 'CERTIFICATE'
			 a.CreateTime
from dbo.tblEL_Achievements a
	-- Join với bảng định nghĩa để lấy thông tin chi tiết của thành tích
	join dbo.tblEL_Achievement_Definitions ad
		on a.AchievementCode = ad.AchievementCode
where a.HocSinhID = @HocSinhID_INT
	  and a.IsDeleted = 0
order by a.CreateTime desc; -- Sắp xếp để lấy những thành tích mới nhất lên đầu
end