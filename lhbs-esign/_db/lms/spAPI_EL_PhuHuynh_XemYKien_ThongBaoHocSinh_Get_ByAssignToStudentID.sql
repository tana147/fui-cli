CREATE PROC spAPI_EL_PhuHuynh_XemYKien_ThongBaoLop_Get_ByAssignToStudentID
	@AssignToStudentID INT
AS
BEGIN
	SELECT 
		s.HocSinhID,
		hs.Ho + ' ' + hs.Ten AS HoTen,
		yk.SoLanXem,
		yk.NoiDungPhuHuynh,
		yk.PhuHuynhXacNhan,
		yk.ThoiGianXacNhan,
		yk.PhuHuynhTruyCap,
		yk.PhuHuynhTruyCapLanCuoi
	FROM dbo.tblEL_YKienPhuHuynh yk
		LEFT JOIN dbo.tblEL_Submissions s ON s.SubmissionID = yk.SubmissionID AND s.IsDeleted = 0
											AND s.AssignToStudentID = @AssignToStudentID
		LEFT JOIN dbo.tblHocSinh hs ON hs.HocSinhID = s.HocSinhID AND hs.TinhTrang = 0
	WHERE yk.IsDeleted = 0
END