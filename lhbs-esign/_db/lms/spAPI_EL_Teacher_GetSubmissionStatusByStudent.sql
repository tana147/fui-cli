CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetSubmissionStatusByStudent]
    @AssignToClassID BIGINT
  , @sys_UserID      VARCHAR(9)
  , @SYS_SystemRight INT
AS
BEGIN
    -- Chỉ trả result set cần thiết về tAPI, không trả row-count message trung gian.
    SET NOCOUNT ON;

    SELECT @sys_UserID      = SYS_USERID
         , @SYS_SystemRight = SYS_SystemRight
    FROM Table_GetUser_LMS(@sys_UserID, @SYS_SystemRight);

    DECLARE @LopHoacNhomID VARCHAR(20);
    DECLARE @AssignmentID_Check INT;
    DECLARE @NienKhoa INT;

    -- Bước 1: Lấy ID của Lớp/Nhóm, Niên khóa và kiểm tra quyền 
    SELECT @AssignmentID_Check = atc.ResourceID
         , @LopHoacNhomID      = mhl.LopNhomID
         , @NienKhoa           = COALESCE(atc.NienKhoa, dbo.fn_GetNienKhoa_HienTai())
    FROM
           dbo.tblEL_AssignToClass atc
           JOIN dbo.tblMonHocLop   mhl ON atc.MonHocLopID = mhl.MonHocLopID
           LEFT JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID = atc.ResourceID
                                               AND atc.ResourceType = 'ASSIGNMENT'
    WHERE
           atc.AssignToClassID = @AssignToClassID
      AND
           (
               atc.CreateUser       = @sys_UserID
          OR   atc.CreateUser IN
               (
                   SELECT GiaoVienID
                   FROM
                       dbo.fn_GetGiaoVienTheoMonLop(mhl.MonHocID, mhl.LopNhomID, COALESCE(atc.NienKhoa, dbo.fn_GetNienKhoa_HienTai()), @sys_UserID, @SYS_SystemRight)
               )
          OR   @SYS_SystemRight IN (3, 5, 9)
          OR   atc.AssignToClassID IN
               (
                   SELECT AssignToClassID
                   FROM dbo.tblEL_Resoucre_TeacherPermissions
                   WHERE Enable = 1 AND GiaoVienID = @sys_UserID
               )
          OR EXISTS (
              -- Quyền SUBJECT cho phép xem tiến độ của bài thuộc môn được cấp quyền.
              SELECT 1
              FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
              WHERE rtp.Enable = 1
                AND rtp.GiaoVienID = @sys_UserID
                AND rtp.PermissionScope = 'SUBJECT'
                AND rtp.MonHocID = ISNULL(asm.MonHocID, mhl.MonHocID)
                AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa)
          )
           )
      AND  atc.IsDeleted        = 0;

    IF @AssignmentID_Check IS NULL
    BEGIN
        RAISERROR(N'[Unauthorized] Không tìm thấy lần giao bài hoặc bạn không có quyền xem.', 16, 1);
        RETURN;
    END

    -- Bước 2: Dùng CTE để lấy danh sách học sinh từ cả Lớp và Nhóm theo Niên Khóa
    ;
    WITH UnitStudents AS
    (
        -- Lấy học sinh từ LỚP thuộc niên khóa giao bài (ràng buộc cả hsl.NienKhoa và l.NienKhoa)
        SELECT hsl.HocSinhID
             , hsl.SoDanhBo
             , NULL as SoTT
        FROM
               dbo.tblHocSinhLop hsl
               INNER JOIN dbo.tblLop l ON hsl.LopID = l.LopID
                                      AND l.NienKhoa = @NienKhoa
        AND hsl.NienKhoa = l.NienKhoa
        WHERE
               hsl.LopID = @LopHoacNhomID
          AND  (hsl.NienKhoa = @NienKhoa OR hsl.NienKhoa IS NULL)
          AND  hsl.Enable = 1
        UNION -- Dùng UNION để loại bỏ trùng lặp nếu học sinh vừa ở trong lớp, vừa ở trong nhóm

        -- Lấy học sinh từ NHÓM thuộc niên khóa giao bài
        SELECT hsn.HocSinhID
             , NULL  AS SoDanhBo
             , hsn.SoTT
        FROM
               dbo.tblHocSinhNhom hsn
               INNER JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID
                                       AND n.NienKhoa = @NienKhoa
        WHERE
               hsn.NhomID = @LopHoacNhomID
          AND  hsn.Enable  = 1
    )

    -- Bước 3: Join danh sách học sinh đã chuẩn hóa với kết quả nộp bài
    SELECT us.HocSinhID
         , us.SoDanhBo
         , us.SoTT
         , hs.Ho + ' ' + hs.Ten AS HoTen
         , atc.MaxScore
         -- Bài RANDOM có mẫu số riêng theo snapshot của từng lần nộp.
         , s.AttemptMaxScore
         , s.SubmissionID
         , s.SubmissionTime
         , s.SubmissionStatus
         , s.SubmissionContent
         , s.AssignmentConfig AS SubmissionAssignmentConfig
         , s.Score
         , s.GradedDate
         , lcb.Reason
         , s.LanNop
         , CONCAT(gv.HoGV,' ',gv.TenGV) as TeacherGraded
         , CASE
                WHEN s.SubmissionStatus = 4 AND s.Score IS NOT NULL THEN 'GRADED'
                -- Status 4 nhưng chưa có Score là dữ liệu chưa hoàn tất chấm,
                -- không nên hiển thị là "Đã chấm".
                WHEN s.SubmissionStatus = 4 AND s.Score IS NULL THEN 'SUBMITTED'
                WHEN s.SubmissionStatus = 3 THEN 'SAVE_DRAFT'  -- Giáo viên đang lưu bản nháp
                WHEN s.SubmissionStatus = 2 THEN 'SUBMITTED'   -- Đã nộp
                WHEN s.SubmissionStatus = 1 THEN 'IN_PROGRESS' -- Đang làm nháp
                WHEN s.SubmissionStatus = 0
                 AND (ISNULL(lcb.Reason, '') <> '') THEN 'RESUBMIT'
                ELSE 'NOT_SUBMITTED'                           -- Chưa làm
           END                  AS Status
         , (
               SELECT ar.QuestionID_InJSON
               FROM
                      dbo.tblEL_Analytics_QuestionResults ar
               WHERE
                      ar.SubmissionID = s.SubmissionID
                 AND  ar.IsCorrect     = 0
                 -- Không đưa các câu ngoài snapshot random vào báo cáo của
                 -- submission (ví dụ pool 25 nhưng lượt này chỉ làm 20).
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
           )                    AS IncorrectQuestionsJSON
         , s.GradedByTeacherID
         , s.AccessTime
         , s.DurationTime
    FROM
           UnitStudents                      us
           JOIN dbo.tblHocSinh               hs ON us.HocSinhID          = hs.HocSinhID
                                               AND hs.TinhTrang          = 0 -- Đang học
           LEFT JOIN dbo.tblEL_Submissions   s ON us.HocSinhID           = s.HocSinhID
                                              AND s.AssignToClassID      = @AssignToClassID
                                              AND s.IsDeleted            = 0
           LEFT JOIN dbo.tblEL_AssignToClass atc ON atc.AssignToClassID  = s.AssignToClassID
                                                AND atc.IsDeleted        = 0
           LEFT JOIN dbo.tblEL_Log_ChamBai   AS lcb ON lcb.Log_ChamBaiID = s.Log_ChamBaiID
           LEFT JOIN dbo.tblGiaoVien gv on gv.GiaoVienID  = s.GradedByTeacherID
    ORDER BY
           us.SoDanhBo
        ,  us.SoTT 
        ,  hs.Ten;
END;
