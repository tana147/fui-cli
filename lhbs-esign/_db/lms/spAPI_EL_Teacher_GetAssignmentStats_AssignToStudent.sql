CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentStats_AssignToStudent]
    @sys_UserID        VARCHAR(9)
  , @AssignToStudentID BIGINT
  , @HocKi             INT
  , @sys_SystemRight   INT
AS
BEGIN
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    DECLARE @LopHoacNhomID VARCHAR(100);
    DECLARE @AssignmentID INT;
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

    -- Lấy LopHoacNhomID và kiểm tra quyền
    SELECT TOP 1
           @AssignmentID = atc.AssignmentID
    FROM
           dbo.tblEL_AssignToStudent atc
    WHERE
           atc.AssignToStudentID = @AssignToStudentID
      AND (
          atc.CreateUser = @sys_UserID
          OR @sys_SystemRight IN (3, 5, 9)
          OR atc.CreateUser IN
          (
              SELECT DISTINCT
                    GiaoVienID
              FROM
                    dbo.tblGiaoVienLop
              WHERE
                    LopID   = @LopHoacNhomID
                AND  HocKy    = @HocKi
                AND  Enable   = 1
              UNION
              SELECT DISTINCT
                    GiaoVienID
              FROM
                    dbo.tblEL_GiaoVienLop
              WHERE
                    LopID   = @LopHoacNhomID
                AND  HocKy    = @HocKi
                AND  Enable   = 1
          )
      )
      AND  atc.IsDeleted          = 0;

    IF @AssignmentID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin giao bài hoặc bạn không có quyền truy cập.', 16, 1);
        RETURN;
    END;
    DECLARE @AssignmentMaxScore DECIMAL(18, 2);
    SELECT @AssignmentMaxScore = MAX(MaxScore)
    FROM dbo.tblEL_AssignToStudent
    WHERE AssignToStudentID = @AssignToStudentID
      AND CreateUser = @sys_UserID;

    DECLARE @TempTable AS TABLE
    (
        HocSinhID        INT
      , Score            DECIMAL(18, 2)
      , AttemptMaxScore  DECIMAL(18, 2)
      , LanNop           INT
    );
    INSERT @TempTable (HocSinhID, Score, AttemptMaxScore, LanNop)
    SELECT s.HocSinhID
         , s.Score
         , COALESCE(
               NULLIF(
                   COALESCE((
                       SELECT SUM(COALESCE(TRY_CONVERT(DECIMAL(18, 2), JSON_VALUE(q.Value, '$.points')), 1.00))
                       FROM OPENJSON(CASE WHEN ISJSON(s.AssignmentConfig) = 1 THEN s.AssignmentConfig ELSE N'{}' END, '$.groups') g
                       CROSS APPLY OPENJSON(g.Value, '$.questions') q
                   ), 0)
                   + COALESCE((
                       SELECT SUM(COALESCE(TRY_CONVERT(DECIMAL(18, 2), JSON_VALUE(q.Value, '$.points')), 1.00))
                       FROM OPENJSON(CASE WHEN ISJSON(s.AssignmentConfig) = 1 THEN s.AssignmentConfig ELSE N'{}' END, '$.questions') q
                   ), 0), 0
               ),
               @AssignmentMaxScore
           ) AS AttemptMaxScore
         , s.LanNop
    FROM
           dbo.tblEL_Submissions s
    WHERE
           s.AssignToStudentID IN
           (
               SELECT AssignToStudentID
               FROM
                      tblEL_AssignToStudent
               WHERE
                      AssignmentID = @AssignmentID
                 AND  CreateUser    = @sys_UserID
           )
      AND  s.SubmissionStatus >= 2
      AND  s.IsDeleted        = 0;
    -- === Tính toán và trả về các số liệu ===
    SELECT
        --  Đếm sĩ số từ cả Lớp và Nhóm
        (
            SELECT COUNT(AssignToStudentID)
            FROM
                   tblEL_AssignToStudent
            WHERE
                   AssignmentID = @AssignmentID
              AND  CreateUser    = @sys_UserID
        ) AS TotalStudents
      -- Số lượng đã nộp (status >= 2)
      , (
            SELECT COUNT(DISTINCT HocSinhID)
            FROM
                   @TempTable
        ) AS SubmittedCount
      -- Điểm trung bình của các bài đã chấm 
      , (
            -- Tính lượt tốt nhất theo tỷ lệ điểm trên mẫu số của chính lượt
            -- làm; sau đó quy đổi về MaxScore của bài giao để thống kê cùng thang.
            SELECT ROUND(AVG(
                       CASE
                           WHEN t.AttemptMaxScore > 0 AND @AssignmentMaxScore > 0
                               THEN t.Score / t.AttemptMaxScore * @AssignmentMaxScore
                           ELSE t.Score
                       END
                   ), 2)
            FROM
                   (
                       SELECT HocSinhID
                            , Score
                            , AttemptMaxScore
                            , ROW_NUMBER() OVER (
                                  PARTITION BY HocSinhID
                                  ORDER BY CASE WHEN AttemptMaxScore > 0 THEN Score / AttemptMaxScore ELSE Score END DESC
                                         , LanNop DESC
                              ) AS RowNo
                       FROM @TempTable
                   ) AS t
            WHERE t.RowNo = 1
        ) AS AverageScore
      -- Điểm tối đa của bài tập
      , (
            SELECT MAX(MaxScore)
            FROM
                   [dbo].[tblEL_AssignToStudent]
            WHERE
                   AssignToStudentID = @AssignToStudentID
              AND  CreateUser         = @sys_UserID
        ) AS MaxScore;
END;
