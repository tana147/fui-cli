CREATE PROC [dbo].[spAPI_EL_PhuHuynh_XemYKien_ThongBaoLop_Get_ByAssignToClassID]
	@AssignToClassID INT
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
		yk.PhuHuynhTruyCapLanCuoi,
		s.SubmissionID,
		yk.SubmissionID,
		 s.AssignToClassID
	FROM dbo.tblEL_YKienPhuHuynh yk
		right JOIN dbo.tblEL_Submissions s ON s.SubmissionID = yk.SubmissionID AND s.IsDeleted = 0 
		inner JOIN dbo.tblHocSinh hs ON hs.HocSinhID = s.HocSinhID AND hs.TinhTrang = 0
	WHERE s.AssignToClassID = @AssignToClassID
END

