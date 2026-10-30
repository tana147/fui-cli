CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_PublishGrade_AssignToStudent]
    @SubmissionID      BIGINT
  , @Score             DECIMAL(5, 2)
  , @TeacherComment    NVARCHAR(MAX)
  , @SubmissionContent NVARCHAR(MAX)
  , @sys_UserID        VARCHAR(9)
AS
BEGIN
    BEGIN TRY
    -- Trạng thái 4 luôn phải đi kèm điểm tổng; tránh tạo dữ liệu status=4/Score=NULL.
    IF @Score IS NULL
    BEGIN
        RAISERROR(N'Không thể trả bài khi Score bị thiếu.', 16, 1);
        RETURN;
    END;

    IF ISNULL(ISJSON(@SubmissionContent), 0) <> 1
        THROW 51002, N'Không thể trả bài khi SubmissionContent không phải JSON hợp lệ; analytics chưa thể đồng bộ.', 1;

    -- Cùng một SubmissionID phải tuần tự hóa cập nhật submission và analytics.
    DECLARE @AnalyticsLockResult INT
          , @AnalyticsLockResource NVARCHAR(255);
    SET @AnalyticsLockResource = N'EL_Analytics_QuestionResults:' + CONVERT(NVARCHAR(20), @SubmissionID);
    BEGIN TRANSACTION;
    EXEC @AnalyticsLockResult = sys.sp_getapplock
         @Resource = @AnalyticsLockResource,
         @LockMode = 'Exclusive',
         @LockOwner = 'Transaction',
         @LockTimeout = 15000;
    IF @AnalyticsLockResult < 0
        THROW 51001, N'Không lấy được khóa đồng bộ analytics theo SubmissionID.', 1;

    -- === BƯỚC 1: CẬP NHẬT BẢNG SUBMISSIONS (Không đổi) ===
    UPDATE dbo.tblEL_Submissions
    SET    Score = @Score
         , TeacherComment = @TeacherComment
         , SubmissionContent = @SubmissionContent
         , SubmissionStatus = 4
         , GradedByTeacherID = @sys_UserID
         , GradedDate = GETDATE()
         , UpdateUser = @sys_UserID
         , UpdateTime = GETDATE()
    WHERE
           SubmissionID = @SubmissionID;

    -- === BƯỚC 2: ĐỒNG BỘ DỮ LIỆU SANG BẢNG ANALYTICS ===
    DELETE FROM
    dbo.tblEL_Analytics_QuestionResults
    WHERE
        SubmissionID = @SubmissionID;

    DECLARE @AssignToStudentID INT
          , @HocSinhID         INT
          , @AssignmentConfig  NVARCHAR(MAX)
          , @AssignmentID      INT
          , @LopID             VARCHAR(10)
          , @NienKhoa          INT
          , @MonHocLopID       INT
          , @MonHocID          INT
          , @SubmissionTime    DATETIME;

    SELECT @AssignToStudentID = s.AssignToStudentID
         , @HocSinhID         = s.HocSinhID
         , @SubmissionContent = s.SubmissionContent -- Read the persisted payload while holding the analytics lock.
         , @SubmissionTime    = ISNULL(s.SubmissionTime, s.CreateTime)
         -- Snapshot của submission là nguồn chuẩn để đồng bộ analytics:
         -- bài random chỉ có các câu học sinh thực sự nhận, còn ats/a là pool gốc.
         , @AssignmentConfig = CASE
             WHEN ISJSON(s.AssignmentConfig)=1 AND (JSON_QUERY(CASE WHEN ISJSON(s.AssignmentConfig)=1 THEN s.AssignmentConfig ELSE N'{}' END, '$.groups') IS NOT NULL OR JSON_QUERY(CASE WHEN ISJSON(s.AssignmentConfig)=1 THEN s.AssignmentConfig ELSE N'{}' END, '$.questions') IS NOT NULL) THEN s.AssignmentConfig
             WHEN ISJSON(ats.AssignmentConfig)=1 AND (JSON_QUERY(CASE WHEN ISJSON(ats.AssignmentConfig)=1 THEN ats.AssignmentConfig ELSE N'{}' END, '$.groups') IS NOT NULL OR JSON_QUERY(CASE WHEN ISJSON(ats.AssignmentConfig)=1 THEN ats.AssignmentConfig ELSE N'{}' END, '$.questions') IS NOT NULL) THEN ats.AssignmentConfig
             WHEN ISJSON(a.AssignmentConfig)=1 AND (JSON_QUERY(CASE WHEN ISJSON(a.AssignmentConfig)=1 THEN a.AssignmentConfig ELSE N'{}' END, '$.groups') IS NOT NULL OR JSON_QUERY(CASE WHEN ISJSON(a.AssignmentConfig)=1 THEN a.AssignmentConfig ELSE N'{}' END, '$.questions') IS NOT NULL) THEN a.AssignmentConfig
             ELSE NULL
         END
         , @AssignmentID      = a.AssignmentID
         , @LopID             = mhl.LopNhomID
         , @NienKhoa          = a.NienKhoa
         , @MonHocLopID       = ats.MonHocLopID
         , @MonHocID          = a.MonHocID
    FROM
           dbo.tblEL_Submissions          s
           JOIN dbo.tblEL_AssignToStudent ats ON s.AssignToStudentID = ats.AssignToStudentID
           JOIN dbo.tblEL_Assignments     a ON ats.ResourceID        = a.AssignmentID
                                           AND ats.ResourceType      = 'ASSIGNMENT'
           JOIN dbo.tblMonHocLop          mhl ON ats.MonHocLopID     = mhl.MonHocLopID
    WHERE
           s.SubmissionID = @SubmissionID;

    DECLARE @Questions TABLE
    (
        QuestionID_InJSON VARCHAR(50) NOT NULL CHECK (LEN(LTRIM(RTRIM(QuestionID_InJSON))) > 0)
      , QuestionType      VARCHAR(50) NOT NULL CHECK (LEN(LTRIM(RTRIM(QuestionType))) > 0)
      , MaxScore          DECIMAL(5, 2) NOT NULL
      , Skills            NVARCHAR(MAX)
    );
    INSERT INTO @Questions
    (
        QuestionID_InJSON
      , QuestionType
      , MaxScore
      , Skills
    )
    SELECT JSON_VALUE(q.Value, '$.id')
         , JSON_VALUE(q.Value, '$.type')
         , COALESCE(TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE(q.Value, '$.points')), 1.00)
         , JSON_QUERY(q.Value, '$.skills')
    FROM
           OPENJSON(@AssignmentConfig, '$.groups')           AS groups
           CROSS APPLY OPENJSON(groups.Value, '$.questions') AS q
    UNION ALL
    -- Giữ tương thích với assignment JSON cũ có questions ở root.
    SELECT JSON_VALUE(q.Value, '$.id')
         , JSON_VALUE(q.Value, '$.type')
         , COALESCE(TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE(q.Value, '$.points')), 1.00)
         , JSON_QUERY(q.Value, '$.skills')
    FROM OPENJSON(@AssignmentConfig, '$.questions') AS q;
    -- Chèn dữ liệu mới vào bảng Analytics
    INSERT INTO dbo.tblEL_Analytics_QuestionResults
    (
        SubmissionID
      , AssignmentID
      , AssignToStudentID
      , HocSinhID
      , LopID
      , NienKhoa
      , MonHocLopID
      , MonHocID
      , QuestionID_InJSON
      , QuestionType
      , Score
      , MaxScore
      , IsCorrect
      , SubmissionTime
      , Skills
    )
    SELECT @SubmissionID
         , @AssignmentID
         , @AssignToStudentID
         , @HocSinhID
         , @LopID
         , @NienKhoa
         , @MonHocLopID
         , @MonHocID
         , q_info.QuestionID_InJSON
         , q_info.QuestionType
         -- manualScore là điểm giáo viên chốt; autoScore chỉ là fallback khi
         -- câu chưa có điểm thủ công. Không cộng hai field vì flow auto-grade
         -- hiện lưu cùng một điểm vào cả hai field.
         , COALESCE(
               TRY_CAST(JSON_VALUE(answers.Value, '$.grading.manualScore') AS DECIMAL(5, 2)),
               TRY_CAST(JSON_VALUE(answers.Value, '$.grading.autoScore') AS DECIMAL(5, 2)),
               0
           ) AS QuestionScore
         , q_info.MaxScore
         -- =================================================================
         -- == LOGIC TÍNH IsCorrect ĐÃ ĐƯỢC VIẾT LẠI HOÀN TOÀN            ==
         -- =================================================================
         , CASE
                -- Trường hợp 1: Có trường isCorrect và nó là 'true'
                WHEN JSON_VALUE(answers.Value, '$.grading.isCorrect') = 'true' THEN 1

                -- Trường hợp 2: Điểm đạt được bằng điểm tối đa (và > 0)
                WHEN q_info.MaxScore > 0
                 AND COALESCE(
                       TRY_CAST(JSON_VALUE(answers.Value, '$.grading.manualScore') AS DECIMAL(5, 2)),
                       TRY_CAST(JSON_VALUE(answers.Value, '$.grading.autoScore') AS DECIMAL(5, 2)),
                       0
                     ) = q_info.MaxScore THEN 1

                -- Trường hợp 3: Có trường isCorrect và nó là 'false'
                WHEN JSON_VALUE(answers.Value, '$.grading.isCorrect') = 'false' THEN 0

                -- Trường hợp 4: Điểm số là 0
                WHEN COALESCE(
                       TRY_CAST(JSON_VALUE(answers.Value, '$.grading.manualScore') AS DECIMAL(5, 2)),
                       TRY_CAST(JSON_VALUE(answers.Value, '$.grading.autoScore') AS DECIMAL(5, 2)),
                       0
                     ) = 0 THEN 0

                -- Các trường hợp còn lại (ví dụ: đúng một phần)
                ELSE NULL
           END                                                                                                                                                                       AS IsCorrect
         , @SubmissionTime
         , q_info.Skills
    -- Lấy danh sách câu từ snapshot làm nguồn chuẩn để mỗi câu luôn có một dòng
    -- analytics; đáp án cũ có question-id ngoài snapshot sẽ không tạo dòng rác.
    FROM
           @Questions AS q_info
           LEFT JOIN OPENJSON(@SubmissionContent, '$.answers') AS answers
             ON answers.[Key] COLLATE DATABASE_DEFAULT = q_info.QuestionID_InJSON COLLATE DATABASE_DEFAULT;

    COMMIT TRANSACTION;

    --Insert log Chấm bài
    EXEC spAPI_EL_Log_ChamBai_Ins_AssignToStudent @SubmissionID = @SubmissionID
                                                , @AssignToStudentID = @AssignToStudentID
                                                , @AssignmentConfig = @AssignmentConfig
                                                , @SubmissionContent = @SubmissionContent
                                                , @SubmissionStatus = 4 -- Do API là này trả bài
                                                , @SYS_USERID = @sys_UserID;


    --Gắn thêm thông báo
    EXEC [dbo].[spAPI_ThongBao_Ins] @ResourceID = @SubmissionID
                                  , @ResourceType = 'SUBMISSION'
                                  , @ThongBao_TemplateID = 8
                                  , @NguoiNhan = @HocSinhID
                                  , @SYS_USERID = @sys_UserID;

    --Gắn thêm Achievement
    EXEC spAPI_EL_Achievement_Submit_ByHocSinhID @HocSinhID = @HocSinhID;
    -- === BƯỚC 3: TRẢ VỀ KẾT QUẢ THÀNH CÔNG ===
    SELECT Success = 1
         , Message = N'Đã trả bài và đồng bộ báo cáo thành công.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
