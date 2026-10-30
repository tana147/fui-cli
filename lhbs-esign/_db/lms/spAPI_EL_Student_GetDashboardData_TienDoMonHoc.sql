CREATE PROC [dbo].[spAPI_EL_Student_GetDashboardData_TienDoMonHoc]
    @TuanHocID INT
  , @HocSinhID INT
  , @NienKhoa INT
AS
BEGIN;
    SET NOCOUNT ON;

    DECLARE @MyUnits TABLE (UnitID VARCHAR(100));
    INSERT INTO @MyUnits (UnitID)
    SELECT hsl.LopID
    FROM dbo.tblHocSinhLop hsl
    JOIN dbo.tblLop l ON hsl.LopID = l.LopID AND l.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = @HocSinhID AND hsl.Enable = 1 AND hsl.NienKhoa = @NienKhoa
    UNION
    SELECT hsn.NhomID
    FROM dbo.tblHocSinhNhom hsn
    JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa
    WHERE hsn.HocSinhID = @HocSinhID AND hsn.Enable = 1;

    --[Table 1]: Lấy Trạng thái 
    WITH WaitingTasks AS
    (
        SELECT asm.MonHocID
        FROM
               dbo.tblEL_AssignToClass          atc
               LEFT JOIN dbo.tblEL_Submissions  s ON atc.AssignToClassID = s.AssignToClassID
                                                 AND s.HocSinhID         = @HocSinhID
               INNER JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID  = atc.AssignmentID
                                                   AND asm.TuanHocID     = @TuanHocID
               INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = atc.MonHocLopID
                                               AND mhl.NienKhoa = @NienKhoa
        WHERE
               atc.IsDeleted   = 0
          AND  atc.ResourceType = 'ASSIGNMENT'
          AND  s.SubmissionID IS NULL
          AND  mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits)
    )
    SELECT asm.MonHocID
         , mh.MonHocName
         , COUNT(asm.MonHocID)                                        AS TotalTask
         , SUM(CASE WHEN sub.SubmissionStatus >= 2 THEN 1 ELSE 0 END) AS CompleteTask
         , (
               SELECT COUNT(*)
               FROM
                      WaitingTasks wt
               WHERE
                      wt.MonHocID = asm.MonHocID
           )                                                          AS WaitingTask
         , SUM(CASE WHEN atc.DueDate < GETDATE() THEN 1 ELSE 0 END)   AS OverdueTask
    FROM
           dbo.tblEL_Submissions              AS sub
           INNER JOIN dbo.tblEL_AssignToClass AS atc ON atc.AssignToClassID = sub.AssignToClassID
                                                    AND atc.IsDeleted       = 0
           INNER JOIN dbo.tblEL_Assignments   AS asm ON asm.AssignmentID    = atc.AssignmentID
                                                    AND asm.IsDeleted       = 0
           INNER JOIN dbo.tblMonHocLop         AS mhl ON mhl.MonHocLopID     = atc.MonHocLopID
                                                    AND mhl.NienKhoa         = @NienKhoa
           INNER JOIN dbo.tblMonHoc           AS mh ON mh.MonHocID          = asm.MonHocID
                                                   AND mh.Enable            = 1
    WHERE
           sub.IsDeleted = 0
      AND  sub.HocSinhID  = @HocSinhID
      AND  mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits)
    GROUP BY
           asm.MonHocID
         , mh.MonHocName;
    --[Table 2]: Lấy các bài tập và bài học của học sinh trong tuần
    SELECT atc.ResourceType
         , atc.ResourceID
         , asm.Title
         , mh.MonHocName
         , asm.MonHocID
         , atc.DueDate
         , atc.MonHocLopID
         , CASE
                WHEN atc.DueDate < GETDATE() THEN 'OVERDUE'
                WHEN sub.SubmissionStatus = 1 THEN 'IN_PROGRESS'
                ELSE 'NOT_STARTED'
           END AS Status
         , 1   AS Priority
         , asm.TuanHocID
    FROM
           dbo.tblEL_AssignToClass          AS atc
           INNER JOIN dbo.tblEL_Submissions AS sub ON sub.AssignToClassID = atc.AssignToClassID
                                                  AND sub.HocSinhID       = @HocSinhID
                                                  AND sub.IsDeleted       = 0
           INNER JOIN dbo.tblEL_Assignments AS asm ON asm.AssignmentID    = atc.AssignmentID
                                                  AND asm.IsDeleted       = 0
                                                  AND asm.TuanHocID       = @TuanHocID
           INNER JOIN dbo.tblMonHocLop       AS mhl ON mhl.MonHocLopID     = atc.MonHocLopID
                                                  AND mhl.NienKhoa         = @NienKhoa
           INNER JOIN dbo.tblMonHoc         AS mh ON mh.MonHocID          = asm.MonHocID
                                                 AND mh.Enable            = 1
    WHERE
           atc.IsDeleted = 0
      AND  mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits)
    UNION
    SELECT 'LESSON'            AS ResourceType
         , atc.AssignToClassID AS ResourceID
         , les.Title
         , mh.MonHocName
         , les.MonHocID
         , TRY_CONVERT(DATETIME, atc.DueDate)
         , les.MonHocID
         , CASE
                WHEN learn.ProgressID IS NOT NULL
                 AND learn.IsCompleted = 0 THEN 'IN_PROGRESS'
                ELSE 'NOT_STARTED'
           END                 AS Status
         , 2                   AS Priority
         , les.TuanHocID
    FROM
           dbo.tblEL_AssignToClass                AS atc
           INNER JOIN dbo.tblEL_Lessons           AS les ON atc.ResourceID    = les.LessonID
                                                        AND atc.ResourceType  = 'LESSON'
                                                        AND les.TuanHocID     = @TuanHocID
           INNER JOIN dbo.tblEL_Learning_Progress AS learn ON learn.LessonID  = les.LessonID
                                                          AND learn.HocSinhID = @HocSinhID
           INNER JOIN dbo.tblMonHoc               AS mh ON mh.MonHocID        = les.MonHocID
                                                       AND mh.Enable          = 1
           INNER JOIN dbo.tblMonHocLop             AS mhl ON mhl.MonHocLopID   = atc.MonHocLopID
                                                        AND mhl.NienKhoa       = @NienKhoa
    WHERE
           atc.IsDeleted = 0
      AND  mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits);

END;
