CREATE PROC spAPI_EL_PhuHuynh_TienDoBaiHoc_ByHocSinhID
 @HocSinhID INT,
 @NienKhoa INT
AS
BEGIN
    
SELECT 
	lp.ProgressID,
	lp.LessonID,
	mh.TenMonHoc_HienThi,
	mh.Color,
	mh.Icon,
	ls.Title,
	ls.[Description],
	ls.TuanHocID,
	dbo.fnGetTuanHoc_HienThi(th.Tuan, th.ThangHoc, th.NgayBatDau, th.NgayKetThuc) AS TuanHienThi,
	lp.IsCompleted,
	lp.TimeSpentSeconds,
	lp.CompletedDate,
	lp.LastAccessed
FROM dbo.tblEL_Learning_Progress lp
	INNER JOIN dbo.tblEL_Lessons ls ON ls.LessonID = lp.LessonID AND ls.IsDeleted = 0 AND ISNULL(ls.IsDev, 0) <> 1
	INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = ls.MonHocID AND mh.Enable = 1 
	INNER JOIN dbo.tblTuanHocTap th ON th.TuanHocID = ls.TuanHocID 
WHERE HocSinhID = @HocSinhID
  AND ls.NienKhoa = @NienKhoa
  AND lp.IsDeleted = 0
END
