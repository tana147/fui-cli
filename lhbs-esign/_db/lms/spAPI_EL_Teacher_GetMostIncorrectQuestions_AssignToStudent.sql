-- FILE: spAPI_EL_Teacher_GetMostIncorrectQuestions.sql
-- =================================================================================
-- Description:    Phân tích và trả về danh sách (top 5) các câu hỏi
--                 có nhiều học sinh trả lời sai nhất cho một lần giao bài.
-- API Endpoint:   POST lms/el_teacher_getmostincorrectquestions
-- Ví dụ Body:     { "AssignToClassID": 123 }
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetMostIncorrectQuestions_AssignToStudent]
    @sys_UserID        VARCHAR(9)
  , @AssignToStudentID BIGINT
  , @HocKi             INT
  , @sys_SystemRight   INT
AS
BEGIN
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    DECLARE @LopHoacNhomID VARCHAR(100);
    DECLARE @MonHocLopID INT;
    DECLARE @MonHocID INT;

    SELECT TOP 1
           @MonHocLopID = MonHocLopID
    FROM
           dbo.tblEL_AssignToStudent
    WHERE
           AssignToStudentID = @AssignToStudentID;

    SELECT TOP 1
           @LopHoacNhomID = LopNhomID
         , @MonHocID      = MonHocID
    FROM
           dbo.tblMonHocLop
    WHERE
           MonHocLopID = @MonHocLopID;

    -- === Kiểm tra quyền sở hữu bài tập ===
    IF NOT EXISTS
    (
        SELECT 1
        FROM
               dbo.tblEL_AssignToStudent
        WHERE
               AssignToStudentID = @AssignToStudentID
          AND (
              CreateUser = @sys_UserID
              OR @sys_SystemRight IN (3, 5, 9)
              OR CreateUser IN
              (
                  SELECT DISTINCT
                         GiaoVienID
                  FROM
                         dbo.tblGiaoVienLop
                  WHERE
                         LopID   = @LopHoacNhomID
                    AND  Enable   = 1
                    AND  HocKy    = @HocKi
                  UNION
                  SELECT DISTINCT
                         GiaoVienID
                  FROM
                         dbo.tblEL_GiaoVienLop
                  WHERE
                         LopID   = @LopHoacNhomID
                    AND  Enable   = 1
                    AND  HocKy    = @HocKi
              )
          )
          AND  IsDeleted          = 0
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền xem phân tích cho bài tập này.', 16, 1);
        RETURN;
    END;

    -- === Phân tích dữ liệu từ bảng Analytics ===
    SELECT TOP 5
           ar.QuestionID_InJSON
         -- Đếm số lần trả lời sai
         , SUM(CASE WHEN ar.IsCorrect = 0 THEN 1 ELSE 0 END)                                                     AS IncorrectCount
         -- Tính tỉ lệ % sai
         , CAST(SUM(CASE WHEN ar.IsCorrect = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(ar.ResultID) AS DECIMAL(5, 2)) AS IncorrectPercentage
    FROM
           dbo.tblEL_Analytics_QuestionResults ar
           INNER JOIN dbo.tblEL_Submissions submission
               ON submission.SubmissionID = ar.SubmissionID
              AND submission.IsDeleted = 0
    WHERE
           ar.AssignToStudentID = @AssignToStudentID
      AND  ar.IsDeleted          = 0
      -- Chỉ giữ câu có trong snapshot của submission; câu ngoài 20/25
      -- không được tham gia báo cáo dù analytics cũ từng ghi cả pool.
      AND (
          NULLIF(LTRIM(RTRIM(submission.AssignmentConfig)), '') IS NULL
          OR ISJSON(submission.AssignmentConfig) <> 1
          OR EXISTS (
              SELECT 1
              FROM OPENJSON(CASE WHEN ISJSON(submission.AssignmentConfig) = 1 THEN submission.AssignmentConfig ELSE N'{}' END, '$.groups') group_json
              CROSS APPLY OPENJSON(group_json.Value, '$.questions') question_json
              WHERE JSON_VALUE(question_json.Value, '$.id') = ar.QuestionID_InJSON
          )
          OR EXISTS (
              SELECT 1
              FROM OPENJSON(CASE WHEN ISJSON(submission.AssignmentConfig) = 1 THEN submission.AssignmentConfig ELSE N'{}' END, '$.questions') question_json
              WHERE JSON_VALUE(question_json.Value, '$.id') = ar.QuestionID_InJSON
          )
      )
    GROUP BY
           ar.QuestionID_InJSON
    -- Chỉ lấy những câu có ít nhất 1 lần trả lời sai
    HAVING
           SUM(CASE WHEN ar.IsCorrect = 0 THEN 1 ELSE 0 END) > 0
    ORDER BY
           IncorrectCount DESC
         , IncorrectPercentage DESC; -- Ưu tiên theo số lượng, sau đó là tỉ lệ

END;
