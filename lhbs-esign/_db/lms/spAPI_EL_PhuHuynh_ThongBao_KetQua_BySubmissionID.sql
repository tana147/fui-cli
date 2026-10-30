-- [dbo].[spAPI_EL_PhuHuynh_ThongBao_KetQua_BySubmissionID] 3267
CREATE PROC [dbo].[spAPI_EL_PhuHuynh_ThongBao_KetQua_BySubmissionID] @SubmissionID INT
AS
BEGIN
    DECLARE @AssignToClassID INT = 0;
    DECLARE @AssignToStudentID INT = 0;
    DECLARE @HocSinhID INT = 0;
    SELECT @AssignToClassID   = AssignToClassID
         , @AssignToStudentID = AssignToStudentID
         , @HocSinhID         = HocSinhID
    FROM
           dbo.tblEL_Submissions
    WHERE
           SubmissionID = @SubmissionID;

    --Lấy các câu Đúng sai sử dụng dạng trắc nghiệm
    SELECT SUM(CASE WHEN IsCorrect = 1 THEN 1 ELSE 0 END)     AS SoCauDung
         , SUM(CASE WHEN IsCorrect = 0 THEN 1 ELSE 0 END)     AS SoCauSai
         , SUM(CASE WHEN IsCorrect IS NULL THEN 1 ELSE 0 END) AS SoCauKoDuDiem
    FROM
           dbo.tblEL_Analytics_QuestionResults
    WHERE
           SubmissionID = @SubmissionID
      AND  HocSinhID     = @HocSinhID
      AND  QuestionType LIKE 'QUIZ%';


    IF (@AssignToClassID > 0)
    BEGIN
        SELECT atc.*
             , asm.Title
             , mh.TenMonHoc_HienThi
             , gv.HoGV + ' ' + gv.TenGV AS HoTenGV_GiaoBai
        FROM
               dbo.tblEL_AssignToClass          atc
               INNER JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID = atc.AssignmentID
                                                   AND asm.IsDeleted    = 0
               INNER JOIN dbo.tblMonHoc         mh ON mh.MonHocID       = asm.MonHocID
                                                  AND mh.Enable         = 1
               INNER JOIN dbo.tblGiaoVien       gv ON gv.GiaoVienID     = atc.CreateUser
        WHERE
               atc.AssignToClassID = @AssignToClassID;
        SELECT s.*
             , gv.HoGV + ' ' + gv.TenGV AS HoTenGV_ChamBai
        FROM
               dbo.tblEL_Submissions      s
               INNER JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = s.GradedByTeacherID
        WHERE
               s.SubmissionID = @SubmissionID;
    END;

    ELSE IF (@AssignToStudentID > 0)
    BEGIN
        SELECT *
        FROM
               dbo.tblEL_AssignToStudent
        WHERE
               AssignToStudentID = @AssignToStudentID;
        SELECT *
        FROM
               dbo.tblEL_Submissions
        WHERE
               SubmissionID = @SubmissionID;
    END;
END;