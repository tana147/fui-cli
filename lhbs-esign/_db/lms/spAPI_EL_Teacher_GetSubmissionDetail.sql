CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetSubmissionDetail]
    @SubmissionID BIGINT,
    @HocKi INT,
    @sys_UserID VARCHAR(9),
    @sys_SystemRight INT
AS
BEGIN
    SELECT @sys_UserID = SYS_USERID, @sys_SystemRight = SYS_SystemRight
    FROM Table_GetUser_LMS(@sys_UserID, @sys_SystemRight);

    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();
    DECLARE @MonHocLopIDs TABLE (MonHocLopID INT);

    INSERT INTO @MonHocLopIDs (MonHocLopID)
    SELECT MonHocLopID
    FROM tblGiaoVienLop gvl
    INNER JOIN tblMonHocLop mhl
        ON mhl.MonHocID = gvl.MonHocID
       AND mhl.LopNhomID = gvl.LopID
       AND gvl.NienKhoa = @NienKhoa_HienTai
    WHERE GiaoVienID = @sys_UserID
      AND GVL.Enable = 1
      AND GVL.HocKy = @HocKi;

    DECLARE @AssignToClassID INT;
    DECLARE @AssignmentConfig_Sub NVARCHAR(MAX);
    DECLARE @StoredAttemptMaxScore DECIMAL(10,2);
    SELECT 
        @AssignToClassID = AssignToClassID,
        @AssignmentConfig_Sub = AssignmentConfig,
        @StoredAttemptMaxScore = AttemptMaxScore
    FROM dbo.tblEL_Submissions
    WHERE SubmissionID = @SubmissionID
      AND IsDeleted = 0;

    IF @AssignToClassID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy bài nộp này.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.tblEL_AssignToClass atc
        INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = atc.MonHocLopID
        LEFT JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID = atc.ResourceID
                                            AND atc.ResourceType = 'ASSIGNMENT'
        WHERE atc.AssignToClassID = @AssignToClassID
          AND atc.IsDeleted = 0
          AND (
              atc.CreateUser = @sys_UserID
              OR @sys_SystemRight IN (3, 5, 9)
              OR atc.MonHocLopID IN (SELECT MonHocLopID FROM @MonHocLopIDs)
              OR atc.AssignToClassID IN (
                  SELECT AssignToClassID
                  FROM tblEL_Resoucre_TeacherPermissions
                  WHERE Enable = 1 AND GiaoVienID = @sys_UserID
              )
              OR EXISTS (
                  -- Chỉ quyền SUBJECT có IsGrade mới được mở chi tiết để chấm bài.
                  SELECT 1
                  FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                  WHERE rtp.Enable = 1
                    AND rtp.GiaoVienID = @sys_UserID
                    AND rtp.PermissionScope = 'SUBJECT'
                    AND rtp.IsGrade = 1
                    AND rtp.MonHocID = ISNULL(asm.MonHocID, mhl.MonHocID)
                    AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = mhl.NienKhoa)
              )
          )
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
        atc.AssignToClassID,
        asm.Title,
        asm.Instructions,
        CASE 
            WHEN atc.AssignmentConfig IS NOT NULL AND atc.AssignmentConfig NOT IN ('', 'null') THEN atc.AssignmentConfig
            WHEN asm.AssignmentConfig IS NOT NULL AND asm.AssignmentConfig NOT IN ('', 'null') THEN asm.AssignmentConfig
            ELSE @AssignmentConfig_Sub
        END AS AssignmentConfig,
        atc.DueDate,
        atc.MaxScore AS MaxScore,
        @StoredAttemptMaxScore AS AttemptMaxScore,
        mh.MonHocName,
        COALESCE(l.TenLop, n.TenNhom) AS TenLop,
        mhl.LopNhomID AS LopID
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments asm
        ON atc.ResourceID = asm.AssignmentID
       AND atc.ResourceType = 'ASSIGNMENT'
       AND asm.IsDeleted = 0
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    JOIN dbo.tblMonHoc mh ON mhl.MonHocID = mh.MonHocID
    LEFT JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID AND l.NienKhoa = mhl.NienKhoa
    LEFT JOIN dbo.tblNhom n ON mhl.LopNhomID = n.NhomID AND n.NienKhoa = mhl.NienKhoa
    LEFT JOIN dbo.tblEL_Submissions s
        ON s.SubmissionID = @SubmissionID
       AND s.IsDeleted = 0
    WHERE atc.AssignToClassID = @AssignToClassID
      AND atc.IsDeleted = 0;

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
