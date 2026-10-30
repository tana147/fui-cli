CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetResourcePublic]
	@NienKhoa int,
	@MonHocID int,
	@KhoiID int,
	@SYS_USERID VARCHAR(9)
as
begin
	SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID)
	SELECT 
		ass.AssignmentID AS ResourceID
		, mh.MonHocID
		, 'ASSIGNMENT' as ResourceType
		, mh.TenMonHoc_HienThi
		, ass.KhoiID
		, ass.Title
		, ass.Instructions
		, ass.NienKhoa
		, t.Tuan
		,  N'Tuần ' + CAST(t.Tuan AS VARCHAR(2)) 
			+ N' - Tháng ' + CAST(t.ThangHoc as varchar(2))
			+ N' - (' + FORMAT(NgayBatDau ,'dd/MM/yyyy') 
			+ N' - ' + FORMAT(NgayKetThuc,'dd/MM/yyyy') + ')'  AS Tuan_HienThi
		, ass.Chuong
		, CONCAT(gv.HoGV,' ',gv.TenGV) AS NguoiTao
		, CASE 
        WHEN EXISTS (SELECT 1 FROM tblEL_Assignments WHERE IsCopy = 1 and IsDeleted = 0 and CreateUser = @SYS_USERID and CopyFromAssignmentID = ass.AssignmentID)
        THEN 1
        ELSE 0
    END AS IsGetResource
	FROM tblEL_Assignments ass
		INNER JOIN tblMonHoc mh on mh.MonHocID = ass.MonHocID
		INNER JOIN tblTuanHocTap t on t.TuanHocID = ass.TuanHocID
		INNER JOiN tblGiaoVien gv on gv.GiaoVienID = ass.CreateUser and gv.Enable = 1
	WHERE ass.IsDeleted = 0 AND ass.IsPublic = 1 AND ass.NienKhoa = @NienKhoa AND ass.KhoiID = @KhoiID AND ass.MonHocID = @MonHocID

	UNION
	SELECT 
		les.LessonID  AS ResourceID
		, mh.MonHocID
		, 'LESSON' as ResourceType
		, mh.TenMonHoc_HienThi
		, les.KhoiID
		, les.Title
		, les.Description AS Instructions
		, les.NienKhoa
		, t.Tuan
		,  N'Tuần ' + CAST(t.Tuan AS VARCHAR(2)) 
			+ N' - Tháng ' + CAST(t.ThangHoc as varchar(2))
			+ N' - (' + FORMAT(NgayBatDau ,'dd/MM/yyyy') 
			+ N' - ' + FORMAT(NgayKetThuc,'dd/MM/yyyy') + ')'  AS Tuan_HienThi
		, les.Chuong
		, CONCAT(gv.HoGV,' ',gv.TenGV) AS NguoiTao
		, CASE 
        WHEN EXISTS (SELECT 1 FROM tblEL_Lessons WHERE IsCopy = 1 and IsDeleted = 0 and CreateUser = @SYS_USERID and CopyFromLessonID = les.LessonID)
        THEN 1
        ELSE 0
    END AS IsGetResource
	FROM dbo.tblEL_Lessons les
		INNER JOIN tblMonHoc mh on mh.MonHocID = les.MonHocID
		INNER JOIN tblTuanHocTap t on t.TuanHocID = les.TuanHocID
		INNER JOiN tblGiaoVien gv on gv.GiaoVienID = les.CreateUser and gv.Enable = 1
	WHERE les.IsDeleted = 0 AND les.IsPublic = 1 AND les.NienKhoa = @NienKhoa AND les.KhoiID = @KhoiID AND les.MonHocID = @MonHocID
end

