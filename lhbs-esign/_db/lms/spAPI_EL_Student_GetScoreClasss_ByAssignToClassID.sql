CREATE PROC [dbo].[spAPI_EL_Student_GetScoreClasss_ByAssignToClassID] @AssignToClassID INT-- = 536
AS
BEGIN
    SELECT atc.AssignToClassID
         , mh.TenMonHoc_HienThi
         , asm.Title
         , atc.DueDate
    FROM
           dbo.tblEL_AssignToClass          atc
           INNER JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID     = atc.AssignmentID
                                               AND ISNULL(asm.IsDev, 0) <> 1
                                               AND asm.IsDeleted        = 0
           INNER JOIN dbo.tblMonHoc         mh ON mh.MonHocID           = asm.MonHocID
                                              AND mh.Enable             = 1
    WHERE
           atc.AssignToClassID = @AssignToClassID
      AND  atc.IsDeleted        = 0;

    SELECT TOP 10
           s.SubmissionID
         , hs.HocSinhID
         , hs.Ho + ' ' + hs.Ten                            AS HoTen
         , s.Score
         , FORMAT(s.SubmissionTime, 'dd/MM/yyyy hh:mm:ss') AS SubmissionTime_HienThi
         , s.SubmissionTime
         , s.GradedByTeacherID
		 , gv.HoGV + ' ' + gv.TenGV AS HoTenGV
    FROM
           dbo.tblEL_Submissions     s
           INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = s.HocSinhID
                                       AND hs.TinhTrang = 0
			left JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = s.GradedByTeacherID
    WHERE
           s.AssignToClassID = @AssignToClassID
      AND  s.IsDeleted        = 0
      AND  s.SubmissionStatus = 4
    ORDER BY
           s.Score DESC;
END;

 