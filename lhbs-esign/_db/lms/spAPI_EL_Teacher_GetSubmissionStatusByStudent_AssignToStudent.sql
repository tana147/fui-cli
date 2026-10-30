CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetSubmissionStatusByStudent_AssignToStudent]
    @AssignToStudentID BIGINT,
    @sys_UserID        VARCHAR(9),
    @HocKi             INT,
    @sys_SystemRight   INT
AS
BEGIN
    -- Chỉ trả result set cần thiết về tAPI, không trả row-count message trung gian.
    SET NOCOUNT ON;

    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);
    DECLARE @AssignmentID_Check INT;
    DECLARE @LopHoacNhomID VARCHAR(100);
    DECLARE @MonHocLopID INT;
    DECLARE @MonHocID INT;

    -- Lấy thông tin MonHocLopID
    SELECT TOP 1
           @MonHocLopID = MonHocLopID
    FROM dbo.tblEL_AssignToStudent
    WHERE AssignToStudentID = @AssignToStudentID;

    -- Lấy thông tin Lớp/Nhóm và Môn học
    SELECT TOP 1
           @LopHoacNhomID = LopNhomID,
           @MonHocID      = MonHocID
    FROM dbo.tblMonHocLop
    WHERE MonHocLopID = @MonHocLopID;

    -- Kiểm tra quyền 
    SELECT TOP 1
           @AssignmentID_Check = ats.AssignmentID
    FROM dbo.tblEL_AssignToStudent ats
    WHERE ats.AssignToStudentID = @AssignToStudentID
      AND (
          ats.CreateUser = @sys_UserID
          OR @sys_SystemRight IN (3, 5, 9)
          OR ats.CreateUser IN
          (
              SELECT DISTINCT GiaoVienID
              FROM dbo.tblGiaoVienLop
              WHERE LopID   = @LopHoacNhomID
                AND Enable   = 1 
                AND HocKy    = @HocKi
              UNION
              SELECT DISTINCT GiaoVienID
              FROM dbo.tblEL_GiaoVienLop
              WHERE LopID   = @LopHoacNhomID
                AND Enable   = 1 
                AND HocKy    = @HocKi
          )
      )
      AND ats.IsDeleted = 0;

    IF @AssignmentID_Check IS NULL
    BEGIN
        RAISERROR(N'[Unauthorized] Không tìm thấy lần giao bài hoặc bạn không có quyền xem.', 16, 1);
        RETURN;
    END;

    -- Lấy danh sách submissions với TenLop của từng học sinh
    SELECT hs.HocSinhID,
           hs.Ho + ' ' + hs.Ten AS HoTen,
           s.SubmissionID,
           s.SubmissionTime,
           s.SubmissionStatus,
           s.SubmissionContent,
           s.AssignmentConfig AS SubmissionAssignmentConfig,
           s.Score,
           -- Bài RANDOM có mẫu số riêng theo snapshot của từng lần nộp.
           s.AttemptMaxScore,
           s.GradedDate,
           lcb.Reason,
           s.LanNop,
           CASE
                WHEN s.SubmissionStatus = 4 AND s.Score IS NOT NULL THEN 'GRADED'
                -- Status 4 nhưng chưa có Score là dữ liệu chưa hoàn tất chấm.
                WHEN s.SubmissionStatus = 4 AND s.Score IS NULL THEN 'SUBMITTED'
                WHEN s.SubmissionStatus = 3 THEN 'SAVE_DRAFT'
                WHEN s.SubmissionStatus = 2 THEN 'SUBMITTED'
                WHEN s.SubmissionStatus = 1 THEN 'IN_PROGRESS'
                WHEN s.SubmissionStatus = 0 AND (ISNULL(lcb.Reason, '') <> '') THEN 'RESUBMIT'
                ELSE 'NOT_SUBMITTED'
           END AS Status,
           (
               SELECT ar.QuestionID_InJSON
               FROM dbo.tblEL_Analytics_QuestionResults ar
               WHERE ar.SubmissionID = s.SubmissionID
                 AND ar.IsCorrect = 0
                 -- Chỉ báo cáo câu thuộc snapshot của lượt làm hiện tại.
                 AND (
                     NULLIF(LTRIM(RTRIM(s.AssignmentConfig)), '') IS NULL
                     OR ISJSON(s.AssignmentConfig) <> 1
                     OR EXISTS (
                         SELECT 1
                         FROM OPENJSON(CASE WHEN ISJSON(s.AssignmentConfig) = 1 THEN s.AssignmentConfig ELSE N'{}' END, '$.groups') group_json
                         CROSS APPLY OPENJSON(group_json.Value, '$.questions') question_json
                         WHERE JSON_VALUE(question_json.Value, '$.id') = ar.QuestionID_InJSON
                     )
                     OR EXISTS (
                         SELECT 1
                         FROM OPENJSON(CASE WHEN ISJSON(s.AssignmentConfig) = 1 THEN s.AssignmentConfig ELSE N'{}' END, '$.questions') question_json
                         WHERE JSON_VALUE(question_json.Value, '$.id') = ar.QuestionID_InJSON
                     )
                 )
               FOR JSON PATH
           ) AS IncorrectQuestionsJSON,
           s.AccessTime,
           s.DurationTime,
           s.GradedByTeacherID,
           -- Lấy TenLop từ AssignToStudent của từng học sinh
           ISNULL(n_hs.TenNhom, l_hs.TenLop) AS TenLop
    FROM
           (
               SELECT HocSinhID, Ho, Ten, TinhTrang
               FROM dbo.tblHocSinh
               WHERE HocSinhID IN
                     (
                         SELECT HocSinhID
                         FROM tblEL_AssignToStudent
                         WHERE AssignmentID = @AssignmentID_Check
                     )
           ) hs
           -- JOIN để lấy AssignToStudent của TỪNG học sinh
           LEFT JOIN dbo.tblEL_AssignToStudent ats_hs
                ON ats_hs.AssignmentID = @AssignmentID_Check
               AND ats_hs.HocSinhID = hs.HocSinhID
               AND ats_hs.IsDeleted = 0
           -- JOIN để lấy thông tin lớp của TỪNG học sinh
           LEFT JOIN dbo.tblMonHocLop mhl_hs
                ON mhl_hs.MonHocLopID = ats_hs.MonHocLopID
               AND mhl_hs.Enable = 1
           LEFT JOIN dbo.tblLop l_hs
                ON l_hs.LopID = mhl_hs.LopNhomID
                AND l_hs.NienKhoa = mhl_hs.NienKhoa
               AND l_hs.Enable = 1
           LEFT JOIN dbo.tblNhom n_hs
                ON n_hs.NhomID = mhl_hs.LopNhomID
               AND n_hs.Enable = 1
           -- JOIN submissions
           LEFT JOIN dbo.tblEL_Submissions s 
                ON hs.HocSinhID = s.HocSinhID
               AND s.AssignToStudentID IN
                   (
                       SELECT AssignToStudentID
                       FROM tblEL_AssignToStudent
                       WHERE AssignmentID = @AssignmentID_Check
                         AND CreateUser = @sys_UserID
                   )
               AND s.IsDeleted = 0
           LEFT JOIN dbo.tblEL_Log_ChamBai lcb 
                ON lcb.Log_ChamBaiID = s.Log_ChamBaiID
    WHERE hs.TinhTrang = 0;
END;
