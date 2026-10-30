CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetSubmissionDetail_AssignToStudent]
    @SubmissionID BIGINT,
    @sys_UserID VARCHAR(9),
    @sys_SystemRight INT
AS
BEGIN
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    DECLARE @AssignToStudentID INT;
    DECLARE @AssignmentConfig_Sub NVARCHAR(MAX);
    DECLARE @StoredAttemptMaxScore DECIMAL(10,2);
    SELECT 
        @AssignToStudentID = AssignToStudentID,
        @AssignmentConfig_Sub = AssignmentConfig,
        @StoredAttemptMaxScore = AttemptMaxScore
    FROM dbo.tblEL_Submissions
    WHERE SubmissionID = @SubmissionID
      AND IsDeleted = 0;

    IF @AssignToStudentID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy bài nộp này.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.tblEL_AssignToStudent
        WHERE AssignToStudentID = @AssignToStudentID
          AND IsDeleted = 0
          AND (CreateUser = @sys_UserID OR @sys_SystemRight IN (3, 5, 9))
    )
    BEGIN
        RAISERROR(N'[Unauthorized] Bạn không có quyền chấm bài cho bài nộp này.', 16, 1);
        RETURN;
    END;

    DECLARE @ComputedMaxScore DECIMAL(10,2);
    IF @AssignmentConfig_Sub IS NOT NULL
    BEGIN
        SELECT @ComputedMaxScore = SUM(q.Points)
        FROM (
            SELECT ISNULL(Points, 1.00) AS Points
            FROM OPENJSON(@AssignmentConfig_Sub, '$.groups')
                WITH (questions NVARCHAR(MAX) '$.questions' AS JSON) AS Groups
            CROSS APPLY OPENJSON(Groups.questions)
                WITH (Points DECIMAL(10,2) '$.points')
            UNION ALL
            SELECT ISNULL(Points, 1.00) AS Points
            FROM OPENJSON(@AssignmentConfig_Sub, '$.questions')
                WITH (Points DECIMAL(10,2) '$.points')
        ) q;
    END;

    SELECT
        ats.AssignToStudentID,
        asm.Title,
        asm.Instructions,
        CASE 
            WHEN ats.AssignmentConfig IS NOT NULL AND ats.AssignmentConfig NOT IN ('', 'null') THEN ats.AssignmentConfig
            WHEN asm.AssignmentConfig IS NOT NULL AND asm.AssignmentConfig NOT IN ('', 'null') THEN asm.AssignmentConfig
            ELSE @AssignmentConfig_Sub
        END AS AssignmentConfig,
        ats.DueDate,
        ats.MaxScore AS MaxScore,
        @StoredAttemptMaxScore AS AttemptMaxScore,
        mh.MonHocName,
        COALESCE(l.TenLop, n.TenNhom) AS TenLop,
        mhl.LopNhomID AS LopID
    FROM dbo.tblEL_AssignToStudent ats
    JOIN dbo.tblEL_Assignments asm
        ON ats.ResourceID = asm.AssignmentID
       AND ats.ResourceType = 'ASSIGNMENT'
       AND asm.IsDeleted = 0
    JOIN dbo.tblMonHocLop mhl ON ats.MonHocLopID = mhl.MonHocLopID
    JOIN dbo.tblMonHoc mh ON mhl.MonHocID = mh.MonHocID
    LEFT JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID AND l.NienKhoa = mhl.NienKhoa AND l.Enable = 1
    LEFT JOIN dbo.tblNhom n ON mhl.LopNhomID = n.NhomID AND n.NienKhoa = mhl.NienKhoa AND n.Enable = 1
    WHERE ats.AssignToStudentID = @AssignToStudentID
      AND ats.IsDeleted = 0;

    SELECT
        s.SubmissionID,
        s.AssignToClassID,
        s.HocSinhID,
        hs.Ho + ' ' + hs.Ten AS HoTenHocSinh,
        s.SubmissionContent,
        s.AssignmentConfig AS SubmissionAssignmentConfig,
        s.SubmissionTime,
        s.SubmissionStatus,
        s.Score,
        s.TeacherComment,
        s.GradedByTeacherID,
        s.GradedDate,
        l.Reason
    FROM dbo.tblEL_Submissions s
    JOIN dbo.tblHocSinh hs ON s.HocSinhID = hs.HocSinhID
    LEFT JOIN dbo.tblEL_Log_ChamBai l ON l.Log_ChamBaiID = s.Log_ChamBaiID
    WHERE s.SubmissionID = @SubmissionID
      AND s.IsDeleted = 0;
END
