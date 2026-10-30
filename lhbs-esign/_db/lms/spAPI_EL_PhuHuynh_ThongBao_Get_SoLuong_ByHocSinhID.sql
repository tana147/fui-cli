CREATE PROC spAPI_EL_PhuHuynh_ThongBao_Get_SoLuong_ByHocSinhID
@HocSinhID INT,
@NienKhoa INT
AS
BEGIN
    ;WITH NguonThongBao AS
    (
        SELECT tb.ThongBaoID
        FROM dbo.tblEL_ThongBao tb
        WHERE tb.NguoiNhan = CONVERT(VARCHAR(50), @HocSinhID)
          AND ISNULL(tb.IsDeleted, 0) = 0
          AND EXISTS
          (
              SELECT 1
              FROM dbo.tblHocSinhLop hsl
              INNER JOIN dbo.tblLop l ON l.LopID = hsl.LopID
                  AND l.NienKhoa = @NienKhoa
                  AND l.Enable = 1
              AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = @HocSinhID
          )
          AND
          (
              EXISTS
              (
                  SELECT 1
                  FROM dbo.tblEL_Submissions s
                  INNER JOIN dbo.tblEL_AssignToClass atc ON atc.AssignToClassID = s.AssignToClassID
                      AND atc.IsDeleted = 0
                  INNER JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID = atc.AssignmentID
                      AND asm.IsDeleted = 0
                      AND asm.NienKhoa = @NienKhoa
                  WHERE s.SubmissionID = ISNULL(tb.SubmissionID, tb.ResourceID)
                    AND s.IsDeleted = 0
                    AND s.AssignToClassID IS NOT NULL
              )
              OR EXISTS
              (
                  SELECT 1
                  FROM dbo.tblEL_Submissions s
                  INNER JOIN dbo.tblEL_AssignToStudent ats ON ats.AssignToStudentID = s.AssignToStudentID
                      AND ats.IsDeleted = 0
                  INNER JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID = ats.AssignmentID
                      AND asm.IsDeleted = 0
                      AND asm.NienKhoa = @NienKhoa
                  WHERE s.SubmissionID = ISNULL(tb.SubmissionID, tb.ResourceID)
                    AND s.IsDeleted = 0
                    AND s.AssignToStudentID IS NOT NULL
              )
              OR EXISTS
              (
                  SELECT 1
                  FROM dbo.tblEL_Learning_Progress lp
                  INNER JOIN dbo.tblEL_Lessons ls ON ls.LessonID = lp.LessonID
                      AND ls.IsDeleted = 0
                      AND ls.NienKhoa = @NienKhoa
                  WHERE lp.ProgressID = tb.ResourceID
                    AND tb.ResourceType = 'LP'
                    AND lp.IsDeleted = 0
              )
          )
    )
    SELECT 
		convert_to_object = '',
		COUNT(*) AS SoLuong
	FROM dbo.tblEL_ThongBao tb
	INNER JOIN NguonThongBao ntb ON ntb.ThongBaoID = tb.ThongBaoID
	WHERE ISNULL(tb.Is_DaXem, 0) = 0
END
