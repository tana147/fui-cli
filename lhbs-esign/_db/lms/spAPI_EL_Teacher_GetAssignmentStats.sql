-- EXEC  [dbo].[spAPI_EL_Teacher_GetAssignmentStats] 'NV0000786',1,1302,2
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentStats]
    @sys_UserID      VARCHAR(9)
  , @SYS_SystemRight INT
  , @AssignToClassID BIGINT
  , @HocKi           INT
AS
BEGIN
    -- Không trả các row-count message trung gian về tAPI, giảm nhiễu response.
    SET NOCOUNT ON;

    SELECT @sys_UserID      = SYS_USERID
         , @SYS_SystemRight = SYS_SystemRight
    FROM
           Table_GetUser_LMS(@sys_UserID, @SYS_SystemRight);
    DECLARE @LopHoacNhomID VARCHAR(100);
    DECLARE @NienKhoa INT;
    DECLARE @AssignmentMaxScore DECIMAL(18, 2);

    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();
    -- CTE 1: Các môn học của giáo viên dạy
    DECLARE @MonHocLopIDs TABLE
    (
        MonHocLopID INT
    );
    INSERT INTO @MonHocLopIDs
    (
        MonHocLopID
    )
    SELECT MonHocLopID
    FROM
           tblGiaoVienLop          gvl
           INNER JOIN tblMonHocLop mhl ON mhl.MonHocID  = gvl.MonHocID
                                      AND mhl.LopNhomID = gvl.LopID
                                      AND gvl.NienKhoa  = @NienKhoa_HienTai
    WHERE
           gvl.GiaoVienID = @sys_UserID
      AND  gvl.Enable      = 1
      -- HocKy đang lưu dạng nvarchar; ép kiểu biến thay vì ép kiểu cả cột.
      AND  gvl.HocKy       = CONVERT(NVARCHAR(50), @HocKi);

    -- Lấy LopHoacNhomID, NienKhoa và kiểm tra quyền
    SELECT @LopHoacNhomID = mhl.LopNhomID
         , @NienKhoa      = COALESCE(atc.NienKhoa, @NienKhoa_HienTai)
         , @AssignmentMaxScore = atc.MaxScore
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
          OR   @SYS_SystemRight IN (3, 5, 9)
          -- GV dạy lơp thây được bài được giao cho lớp từ GV khác
          OR   atc.MonHocLopID IN
               (
                   SELECT *
                   FROM
                       @MonHocLopIDs
               )
          OR   atc.AssignToClassID  in
          (
              SELECT 
                     AssignToClassID
              FROM
                     tblEL_Resoucre_TeacherPermissions
              WHERE
                     Enable    = 1
                AND  GiaoVienID = @sys_UserID
          )
          OR EXISTS (
              -- Quyền SUBJECT cho phép xem thống kê của bài thuộc môn được cấp quyền.
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

    IF @LopHoacNhomID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin giao bài hoặc bạn không có quyền truy cập.', 16, 1);
        RETURN;
    END;
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
         -- Submission mới đã lưu sẵn AttemptMaxScore; chỉ parse JSON cho dữ liệu cũ
         -- chưa có giá trị persisted để tránh parse AssignmentConfig nhiều lần mỗi request.
         , COALESCE(s.AttemptMaxScore, json_stats.AttemptMaxScore, @AssignmentMaxScore) AS AttemptMaxScore
         , s.LanNop
    FROM
           dbo.tblEL_Submissions s
           OUTER APPLY
           (
               SELECT AttemptMaxScore = NULLIF(
                   COALESCE((
                       SELECT SUM(COALESCE(TRY_CONVERT(DECIMAL(18, 2), JSON_VALUE(q.Value, '$.points')), 1.00))
                       FROM OPENJSON(CASE WHEN ISJSON(s.AssignmentConfig) = 1 THEN s.AssignmentConfig ELSE N'{}' END, '$.groups') g
                       CROSS APPLY OPENJSON(g.Value, '$.questions') q
                   ), 0)
                   + COALESCE((
                       SELECT SUM(COALESCE(TRY_CONVERT(DECIMAL(18, 2), JSON_VALUE(q.Value, '$.points')), 1.00))
                       FROM OPENJSON(CASE WHEN ISJSON(s.AssignmentConfig) = 1 THEN s.AssignmentConfig ELSE N'{}' END, '$.questions') q
                   ), 0), 0)
               WHERE s.AttemptMaxScore IS NULL
           ) AS json_stats
    WHERE
           s.AssignToClassID = @AssignToClassID
      AND  s.SubmissionStatus >= 2
      AND  s.IsDeleted        = 0;
    -- === Tính toán và trả về các số liệu ===
    SELECT
        --  Đếm sĩ số từ cả Lớp và Nhóm theo Niên khóa
        (
            SELECT COUNT(ID)
            FROM
                   (
                       SELECT hsl.HocSinhID AS ID
                       FROM
                              dbo.tblHocSinhLop         hsl
                              INNER JOIN dbo.tblLop     l  ON hsl.LopID = l.LopID
                                                          AND l.NienKhoa = @NienKhoa
                              AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID
                                                          AND hs.TinhTrang = 0
                       WHERE
                              hsl.LopID = @LopHoacNhomID
                         AND  (hsl.NienKhoa = @NienKhoa OR hsl.NienKhoa IS NULL)
                         AND  hsl.Enable = 1
                       UNION
                       SELECT hsn.HocSinhID AS ID
                       FROM
                              dbo.tblHocSinhNhom        hsn
                              INNER JOIN dbo.tblNhom    n  ON hsn.NhomID = n.NhomID
                                                          AND n.NienKhoa = @NienKhoa
                              INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsn.HocSinhID
                                                          AND hs.TinhTrang = 0
                       WHERE
                              hsn.NhomID    = @LopHoacNhomID
                         AND  hsn.Enable = 1
                   ) AS TotalStudents
        ) AS TotalStudents
      -- Số lượng đã nộp (status >= 2)
      , (
            SELECT COUNT(DISTINCT HocSinhID)
            FROM
                   @TempTable
        ) AS SubmittedCount
      -- Điểm trung bình của các bài đã chấm 
      , (
            -- Các lượt random có mẫu số riêng. Chọn lượt tốt nhất theo tỷ lệ
            -- Score/AttemptMaxScore rồi quy đổi về thang điểm của bài giao,
            -- không so sánh Score thô giữa các lượt 20/25 câu.
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
      , @AssignmentMaxScore AS MaxScore;
END;
