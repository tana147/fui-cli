CREATE PROC spAPI_EL_Student_Get_CanhBao_ByHocSinhID @HocSinhID INT
AS
BEGIN
    -- Bảng tạm chứa kết quả chung
    DECLARE @Result TABLE
    (
        Title             NVARCHAR(255)
      , DueDate           DATETIME
      , TenMonHoc_HienThi NVARCHAR(255)
      , [Type]            VARCHAR(20)
    );

    -- Insert SUBMISSION
    INSERT INTO @Result
    (
        Title
      , DueDate
      , TenMonHoc_HienThi
      , [Type]
    )
    SELECT asm.Title
         , atc.DueDate
         , mh.TenMonHoc_HienThi
         , 'ASSIGNMENT' AS [Type]
    FROM
           dbo.tblEL_Submissions              s
           INNER JOIN dbo.tblEL_AssignToClass atc ON atc.AssignToClassID  = s.AssignToClassID
                                                 AND atc.IsDeleted        = 0
           INNER JOIN dbo.tblEL_Assignments   asm ON asm.AssignmentID     = atc.AssignmentID
                                                 AND ISNULL(asm.IsDev, 0) <> 1
                                                 AND asm.IsDeleted        = 0
           INNER JOIN dbo.tblMonHoc           mh ON mh.MonHocID           = asm.MonHocID
    WHERE
           s.IsDeleted = 0
      AND  s.HocSinhID  = @HocSinhID
      AND  s.SubmissionStatus IN (0, 1)
      AND  atc.DueDate  <= GETDATE();

    -- Insert LEARNING PROGRESS
    INSERT INTO @Result
    (
        Title
      , DueDate
      , TenMonHoc_HienThi
      , [Type]
    )
    SELECT ls.Title
         , NULL     AS DueDate
         , mh.TenMonHoc_HienThi
         , 'LESSON' AS [Type]
    FROM
           dbo.tblEL_Learning_Progress  lp
           INNER JOIN dbo.tblEL_Lessons ls ON ls.LessonID         = lp.LessonID
                                          AND ISNULL(ls.IsDev, 0) <> 1
                                          AND ls.IsDeleted        = 0
           INNER JOIN dbo.tblMonHoc     mh ON mh.MonHocID         = ls.MonHocID
                                          AND mh.Enable           = 1
    WHERE
           lp.IsDeleted  = 0
      AND  lp.HocSinhID   = @HocSinhID
      AND  lp.IsCompleted = 0;

    -- Select toàn bộ kết quả
    SELECT Title
         , FORMAT(DueDate, 'dd/MM/yyyy HH:mm:ss') AS DueDate
         , TenMonHoc_HienThi
         , [Type]
         , CASE
                WHEN Type = 'LESSON' THEN N'Bài học'
                WHEN Type = 'ASSIGNMENT' THEN N'Bài tập'
                ELSE ''
           END                                    AS TenType
    FROM
           @Result;

END;
