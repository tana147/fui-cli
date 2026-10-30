-- FILE: spAPI_EL_Teacher_GetMostIncorrectQuestions.sql
-- =================================================================================
-- Description:    Phân tích và trả về danh sách (top 5) các câu hỏi
--                 có nhiều học sinh trả lời sai nhất cho một lần giao bài.
-- API Endpoint:   POST lms/el_teacher_getmostincorrectquestions
-- Ví dụ Body:     { "AssignToClassID": 123 }
-- =================================================================================

-- [dbo].[spAPI_EL_Teacher_GetMostIncorrectQuestions] 'NV0000888', 5, 199
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetMostIncorrectQuestions]
    @sys_UserID VARCHAR(9),
	@sys_SystemRight INT,
    @AssignToClassID BIGINT,
	@HocKi INT
AS
BEGIN
    SELECT 
		@sys_UserID			= SYS_USERID,
		@sys_SystemRight	= SYS_SystemRight 
	FROM Table_GetUser_LMS(@sys_UserID, @sys_SystemRight);

    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();
    -- CTE 1: Các môn học của giáo viên dạy
    DECLARE @MonHocLopIDs TABLE (MonHocLopID INT);
    INSERT INTO @MonHocLopIDs (MonHocLopID)
    SELECT MonHocLopID FROM tblGiaoVienLop gvl 
		INNER JOIN tblMonHocLop mhl ON mhl.MonHocID = gvl.MonHocID AND mhl.LopNhomID = gvl.LopID AND gvl.NienKhoa = @NienKhoa_HienTai
    WHERE GiaoVienID = @sys_UserID AND gvl.Enable = 1 AND gvl.HocKy = @HocKi;

    -- === Kiểm tra quyền sở hữu bài tập ===
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.tblEL_AssignToClass atc
        INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = atc.MonHocLopID
        LEFT JOIN dbo.tblEL_Assignments asm ON asm.AssignmentID = atc.ResourceID
                                            AND atc.ResourceType = 'ASSIGNMENT'
        WHERE atc.AssignToClassID = @AssignToClassID
          AND (
              atc.CreateUser = @sys_UserID
              OR @SYS_SystemRight IN (3, 5, 9)
              OR atc.MonHocLopID IN (SELECT * FROM @MonHocLopIDs)
              OR atc.AssignToClassID IN (
                  SELECT AssignToClassID 
                  FROM tblEL_Resoucre_TeacherPermissions 
                  WHERE Enable = 1 AND GiaoVienID = @sys_UserID
              )
              OR EXISTS (
                  -- Quyền SUBJECT cho phép xem phân tích của môn được cấp quyền.
                  SELECT 1
                  FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                  WHERE rtp.Enable = 1
                    AND rtp.GiaoVienID = @sys_UserID
                    AND rtp.PermissionScope = 'SUBJECT'
                    AND rtp.MonHocID = ISNULL(asm.MonHocID, mhl.MonHocID)
                    AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa_HienTai)
              )
          )
          AND atc.IsDeleted = 0
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền xem phân tích cho bài tập này.', 16, 1);
        RETURN;
    END

    -- === Phân tích dữ liệu từ bảng Analytics ===
    SELECT TOP 5
        ar.QuestionID_InJSON,
        -- Đếm số lần trả lời sai
        SUM(CASE WHEN ar.IsCorrect = 0 THEN 1 ELSE 0 END) AS IncorrectCount,
        -- Tính tỉ lệ % sai
        CAST(
            SUM(CASE WHEN ar.IsCorrect = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(ar.ResultID) 
            AS DECIMAL(5, 2)
        ) AS IncorrectPercentage
    FROM 
        dbo.tblEL_Analytics_QuestionResults ar
        INNER JOIN dbo.tblEL_Submissions submission
            ON submission.SubmissionID = ar.SubmissionID
           AND submission.IsDeleted = 0
    WHERE 
        ar.AssignToClassID = @AssignToClassID
        AND ar.IsDeleted = 0
        -- Analytics cũ có thể từng ghi cả pool. Với submission đã có snapshot,
        -- chỉ tính câu thật sự xuất hiện trong lượt làm đó.
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
        IncorrectCount DESC, IncorrectPercentage DESC; -- Ưu tiên theo số lượng, sau đó là tỉ lệ

END;
