
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetFocusTasks_Student]
    @sys_UserID      VARCHAR(9)
  , @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    -- [FIX] Local variable chống parameter sniffing
    DECLARE @UserID VARCHAR(50) = dbo.fn_GetUser_LMS(@sys_UserID);

    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();

    -- ============================================================
    -- [FIX] Materialize TotalStudents per AssignmentID ra temp table
    -- Tránh OUTER APPLY re-evaluate N lần, fix thêm IsDeleted filter
    -- ============================================================
    CREATE TABLE #AssignStudentCount
    (
        AssignmentID  INT PRIMARY KEY
      , TotalStudents INT NOT NULL
    );

    INSERT INTO #AssignStudentCount
    (
        AssignmentID
      , TotalStudents
    )
    SELECT AssignmentID
         , COUNT(*) AS TotalStudents
    FROM
           dbo.tblEL_AssignToStudent
    WHERE
           IsDeleted = 0
    GROUP BY
           AssignmentID;

    -- ============================================================
    -- Main query
    -- ============================================================
   SELECT asm.AssignmentID
     , asm.Title                                                                                AS AssignmentTitle
     , asm.MonHocID
     , asm.Chuong
     , ats.DueDate

     -- Submission stats
     , SUM(CASE WHEN s.SubmissionStatus >= 2 THEN 1 ELSE 0 END)                                AS SubmittedCount
     , SUM(CASE WHEN s.SubmissionStatus = 2 AND s.Score IS NULL THEN 1 ELSE 0 END)             AS PendingGradingCount
     , SUM(CASE WHEN s.SubmissionStatus = 4 THEN 1 ELSE 0 END)                                 AS GradedCount
     , SUM(CASE WHEN s.SubmissionStatus = 4 THEN 1 ELSE 0 END)                                 AS CompletedCount

     -- Total & remaining
     , COALESCE(sc.TotalStudents, 0)                                                           AS TotalStudents
     , COALESCE(sc.TotalStudents, 0) - SUM(CASE WHEN s.SubmissionStatus >= 2 THEN 1 ELSE 0 END) AS RemainingToComplete

     -- Subject
     , m.MonHocName
     , asm.KhoiID

     -- Teacher
     , gv.HoGV + ' ' + gv.TenGV                                                               AS TenGiaoVien

     -- Assignment type & status
     , 'STUDENT'                                                                               AS AssignType
     , CASE
            WHEN SUM(CASE WHEN s.SubmissionStatus = 2 AND s.Score IS NULL THEN 1 ELSE 0 END) > 0
             AND ats.DueDate > GETDATE() THEN 'PENDING_GRADING'
            WHEN ats.DueDate < GETDATE() THEN 'OVERDUE'
            ELSE 'UPCOMING'
       END                                                                                     AS Status
FROM
       dbo.tblEL_AssignToStudent       ats
       JOIN dbo.tblEL_Assignments      asm ON asm.AssignmentID  = ats.AssignmentID
                                          AND asm.IsDeleted     = 0
       JOIN dbo.tblMonHocLop           mhl ON mhl.MonHocLopID   = ats.MonHocLopID
       JOIN dbo.tblMonHoc              m   ON m.MonHocID        = mhl.MonHocID

       -- Teacher
       LEFT JOIN dbo.tblGiaoVien       gv  ON gv.GiaoVienID    = ats.CreateUser
       LEFT JOIN dbo.tblEL_Submissions s   ON s.AssignToStudentID = ats.AssignToStudentID
                                          AND s.IsDeleted       = 0
       LEFT JOIN #AssignStudentCount   sc  ON sc.AssignmentID   = ats.AssignmentID
WHERE
       ats.CreateUser = @UserID
  AND  ats.IsDeleted  = 0
GROUP BY
       asm.AssignmentID
     , asm.Title
     , asm.MonHocID
     , asm.Chuong
     , ats.DueDate
     , COALESCE(sc.TotalStudents, 0)
     , m.MonHocName
     , asm.KhoiID
     , gv.HoGV + ' ' + gv.TenGV
HAVING
       SUM(CASE WHEN s.SubmissionStatus = 4 THEN 1 ELSE 0 END) <> COALESCE(sc.TotalStudents, 0)
ORDER BY
       CASE
            WHEN SUM(CASE WHEN s.SubmissionStatus = 2 AND s.Score IS NULL THEN 1 ELSE 0 END) > 0 THEN 0
            ELSE 1
       END
     , ats.DueDate ASC;

    -- Cleanup
    DROP TABLE IF EXISTS #AssignStudentCount;

END;