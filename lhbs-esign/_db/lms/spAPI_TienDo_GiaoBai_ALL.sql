
CREATE PROCEDURE [dbo].[spAPI_TienDo_GiaoBai] 
	@NienKhoa INT = NULL,
	@CapID INT = NULL,
	@KhoiID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SELECT 
		COUNT(DISTINCT ass.AssignmentID) AS TongBaiTap,
		COUNT(DISTINCT l.LessonID) AS TongBaiHoc,
		COUNT(DISTINCT ass.AssignmentID) + COUNT(DISTINCT l.LessonID) AS TongTatCa
	FROM dbo.tblGiaoVien gv
	LEFT JOIN dbo.tblEL_Assignments ass 
		ON ass.CreateUser = gv.GiaoVienID 
		AND ass.IsDeleted = 0
	LEFT JOIN dbo.tblEL_Lessons l 
		ON l.CreateUser = gv.GiaoVienID 
		AND l.IsDeleted = 0
	WHERE gv.Enable = 1;
END
