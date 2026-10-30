CREATE PROC [dbo].[spAPI_BaoCao_2_ThongKe_BaiTap_BaiHoc_LMS_ByCapID]
    @CapID       INT
  , @NienKhoa    INT
  , @NgayBatDau  DATE
  , @NgayKetThuc DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- ================================================================
    -- ARRAY [0]: TỔNG BÀI ĐÃ TẠO / ĐÃ GIAO THEO MÔN
    -- ================================================================
    ;WITH ClassStudents AS
    (
        SELECT mhl.MonHocLopID, hsl.HocSinhID
        FROM dbo.tblMonHocLop mhl
        JOIN dbo.tblHocSinhLop hsl
          ON hsl.LopID = mhl.LopNhomID AND hsl.Enable = 1
        JOIN dbo.tblHocSinh hs
          ON hs.HocSinhID = hsl.HocSinhID AND hs.TinhTrang = 0
        WHERE mhl.Enable = 1
          AND (@NienKhoa IS NULL OR mhl.NienKhoa = @NienKhoa)
        UNION
        SELECT mhl.MonHocLopID, hsn.HocSinhID
        FROM dbo.tblMonHocLop mhl
        JOIN dbo.tblHocSinhNhom hsn
          ON hsn.NhomID = mhl.LopNhomID AND hsn.Enable = 1
        JOIN dbo.tblHocSinh hs
          ON hs.HocSinhID = hsn.HocSinhID AND hs.TinhTrang = 0
        WHERE mhl.Enable = 1
          AND (@NienKhoa IS NULL OR mhl.NienKhoa = @NienKhoa)
    )
    , AssignedLessons AS
    (
        -- Lesson dùng chung bảng target với assignment, nên phải lọc ResourceType.
        -- Chỉ lesson có target giao hợp lệ mới được tính tiến độ.
        SELECT DISTINCT atc.ResourceID AS LessonID
        FROM dbo.tblEL_AssignToClass atc
        JOIN ClassStudents cs ON cs.MonHocLopID = atc.MonHocLopID
        WHERE atc.IsDeleted = 0
          AND atc.ResourceType = 'LESSON'
          AND atc.ResourceID IS NOT NULL
          AND (@NienKhoa IS NULL OR atc.NienKhoa IS NULL OR atc.NienKhoa = @NienKhoa)
        UNION
        SELECT DISTINCT ats.ResourceID AS LessonID
        FROM dbo.tblEL_AssignToStudent ats
        JOIN dbo.tblHocSinh hs
          ON hs.HocSinhID = ats.HocSinhID AND hs.TinhTrang = 0
        WHERE ats.IsDeleted = 0
          AND ats.ResourceType = 'LESSON'
          AND ats.ResourceID IS NOT NULL
          AND (@NienKhoa IS NULL OR ats.NienKhoa IS NULL OR ats.NienKhoa = @NienKhoa)
    )
    , AssignedAssignments AS
    (
        -- Một assignment có thể vừa giao theo lớp vừa giao riêng; chỉ giữ một lần.
        -- Lọc ResourceType để target của lesson không bị nhầm là assignment.
        SELECT DISTINCT atc.AssignmentID
        FROM dbo.tblEL_AssignToClass atc
        JOIN ClassStudents cs ON cs.MonHocLopID = atc.MonHocLopID
        WHERE atc.IsDeleted = 0
          AND atc.ResourceType = 'ASSIGNMENT'
          AND (@NienKhoa IS NULL OR atc.NienKhoa IS NULL OR atc.NienKhoa = @NienKhoa)
        UNION
        SELECT DISTINCT ats.AssignmentID
        FROM dbo.tblEL_AssignToStudent ats
        JOIN dbo.tblHocSinh hs
          ON hs.HocSinhID = ats.HocSinhID AND hs.TinhTrang = 0
        WHERE ats.IsDeleted = 0
          AND ats.ResourceType = 'ASSIGNMENT'
          AND (@NienKhoa IS NULL OR ats.NienKhoa IS NULL OR ats.NienKhoa = @NienKhoa)
    )
    , BaiHoc AS
    (
        SELECT mh.MonHocID
             , mh.TenMonHoc_HienThi
             , mh.Sort
             , COUNT(DISTINCT l.LessonID) AS TotalLessons
             , COUNT(DISTINCT CASE WHEN al.LessonID IS NOT NULL THEN l.LessonID END) AS AssignedLessons
             , COUNT(DISTINCT l.LessonID)
               - COUNT(DISTINCT CASE WHEN al.LessonID IS NOT NULL THEN l.LessonID END) AS UnassignedLessons
             , 0 AS TotalAssignments
             , 0 AS AssignedAssignments
             , 0 AS UnassignedAssignments
        FROM dbo.tblMonHoc mh
        JOIN dbo.tblEL_Lessons l
          ON l.MonHocID = mh.MonHocID
         AND ISNULL(l.IsDev, 0) = 0
         AND l.IsDeleted = 0
         AND (@NienKhoa IS NULL OR l.NienKhoa = @NienKhoa)
         AND (@NgayBatDau IS NULL OR CAST(l.CreateTime AS DATE) >= @NgayBatDau)
         AND (@NgayKetThuc IS NULL OR CAST(l.CreateTime AS DATE) <= @NgayKetThuc)
        LEFT JOIN AssignedLessons al ON al.LessonID = l.LessonID
        WHERE mh.Enable = 1 AND mh.CapID = @CapID
        GROUP BY mh.MonHocID, mh.TenMonHoc_HienThi, mh.Sort
    )
    , BaiTap AS
    (
        SELECT mh.MonHocID
             , mh.TenMonHoc_HienThi
             , mh.Sort
             , 0 AS TotalLessons
             , 0 AS AssignedLessons
             , 0 AS UnassignedLessons
             , COUNT(DISTINCT a.AssignmentID) AS TotalAssignments
             , COUNT(DISTINCT CASE WHEN aa.AssignmentID IS NOT NULL THEN a.AssignmentID END) AS AssignedAssignments
             , COUNT(DISTINCT a.AssignmentID)
               - COUNT(DISTINCT CASE WHEN aa.AssignmentID IS NOT NULL THEN a.AssignmentID END) AS UnassignedAssignments
        FROM dbo.tblMonHoc mh
        JOIN dbo.tblEL_Assignments a
          ON a.MonHocID = mh.MonHocID
         AND ISNULL(a.IsDev, 0) = 0
         AND a.IsDeleted = 0
         AND (@NienKhoa IS NULL OR a.NienKhoa = @NienKhoa)
         AND (@NgayBatDau IS NULL OR CAST(a.CreateTime AS DATE) >= @NgayBatDau)
         AND (@NgayKetThuc IS NULL OR CAST(a.CreateTime AS DATE) <= @NgayKetThuc)
        LEFT JOIN AssignedAssignments aa ON aa.AssignmentID = a.AssignmentID
        WHERE mh.Enable = 1 AND mh.CapID = @CapID
        GROUP BY mh.MonHocID, mh.TenMonHoc_HienThi, mh.Sort
    )
    SELECT MonHocID
         , TenMonHoc_HienThi
         , SUM(TotalLessons) AS TotalLessons
         , SUM(AssignedLessons) AS AssignedLessons
         , SUM(UnassignedLessons) AS UnassignedLessons
         , SUM(TotalAssignments) AS TotalAssignments
         , SUM(AssignedAssignments) AS AssignedAssignments
         , SUM(UnassignedAssignments) AS UnassignedAssignments
    FROM (
        SELECT * FROM BaiHoc
        UNION ALL
        SELECT * FROM BaiTap
    ) Combined
    GROUP BY MonHocID, TenMonHoc_HienThi, Sort
    ORDER BY Sort;

    -- ================================================================
    -- ARRAY [1]: CHI TIẾT BÀI HỌC
    -- ================================================================
    ;WITH ClassStudents AS
    (
        SELECT mhl.MonHocLopID, hsl.HocSinhID
        FROM dbo.tblMonHocLop mhl
        JOIN dbo.tblHocSinhLop hsl
          ON hsl.LopID = mhl.LopNhomID AND hsl.Enable = 1
        JOIN dbo.tblHocSinh hs
          ON hs.HocSinhID = hsl.HocSinhID AND hs.TinhTrang = 0
        WHERE mhl.Enable = 1
          AND (@NienKhoa IS NULL OR mhl.NienKhoa = @NienKhoa)
        UNION
        SELECT mhl.MonHocLopID, hsn.HocSinhID
        FROM dbo.tblMonHocLop mhl
        JOIN dbo.tblHocSinhNhom hsn
          ON hsn.NhomID = mhl.LopNhomID AND hsn.Enable = 1
        JOIN dbo.tblHocSinh hs
          ON hs.HocSinhID = hsn.HocSinhID AND hs.TinhTrang = 0
        WHERE mhl.Enable = 1
          AND (@NienKhoa IS NULL OR mhl.NienKhoa = @NienKhoa)
    )
    , AssignedLessons AS
    (
        SELECT DISTINCT atc.ResourceID AS LessonID
        FROM dbo.tblEL_AssignToClass atc
        JOIN ClassStudents cs ON cs.MonHocLopID = atc.MonHocLopID
        WHERE atc.IsDeleted = 0
          AND atc.ResourceType = 'LESSON'
          AND atc.ResourceID IS NOT NULL
          AND (@NienKhoa IS NULL OR atc.NienKhoa IS NULL OR atc.NienKhoa = @NienKhoa)
        UNION
        SELECT DISTINCT ats.ResourceID AS LessonID
        FROM dbo.tblEL_AssignToStudent ats
        JOIN dbo.tblHocSinh hs
          ON hs.HocSinhID = ats.HocSinhID AND hs.TinhTrang = 0
        WHERE ats.IsDeleted = 0
          AND ats.ResourceType = 'LESSON'
          AND ats.ResourceID IS NOT NULL
          AND (@NienKhoa IS NULL OR ats.NienKhoa IS NULL OR ats.NienKhoa = @NienKhoa)
    )
    SELECT mh.MonHocID
         , mh.TenMonHoc_HienThi
         , COUNT(DISTINCT l.LessonID) AS TotalLessons
         , COUNT(DISTINCT CASE WHEN al.LessonID IS NOT NULL THEN l.LessonID END) AS AssignedLessons
         , COUNT(DISTINCT l.LessonID)
           - COUNT(DISTINCT CASE WHEN al.LessonID IS NOT NULL THEN l.LessonID END) AS UnassignedLessons
         , COUNT(lp.ProgressID) AS TotalProgress
         , SUM(CASE WHEN lp.IsCompleted = 1 THEN 1 ELSE 0 END) AS TotalCompleted
         , CASE
               WHEN COUNT(lp.ProgressID) = 0 THEN 0
               ELSE ROUND(
                    SUM(CASE WHEN lp.IsCompleted = 1 THEN 1.0 ELSE 0 END)
                    / COUNT(lp.ProgressID) * 100, 1)
           END AS CompletionRate_Lessons
    FROM dbo.tblMonHoc mh
    JOIN dbo.tblEL_Lessons l
      ON l.MonHocID = mh.MonHocID
     AND ISNULL(l.IsDev, 0) = 0
     AND l.IsDeleted = 0
     AND (@NienKhoa IS NULL OR l.NienKhoa = @NienKhoa)
     AND (@NgayBatDau IS NULL OR CAST(l.CreateTime AS DATE) >= @NgayBatDau)
     AND (@NgayKetThuc IS NULL OR CAST(l.CreateTime AS DATE) <= @NgayKetThuc)
    LEFT JOIN AssignedLessons al ON al.LessonID = l.LessonID
    LEFT JOIN dbo.tblEL_Learning_Progress lp
      ON lp.LessonID = l.LessonID
     AND al.LessonID IS NOT NULL
     AND ISNULL(lp.IsDeleted, 0) = 0
    WHERE mh.CapID = @CapID AND mh.Enable = 1
    GROUP BY mh.MonHocID, mh.TenMonHoc_HienThi, mh.Sort
    ORDER BY mh.Sort;

    -- ================================================================
    -- ARRAY [2]: CHI TIẾT BÀI TẬP
    -- ================================================================
    ;WITH ClassStudents AS
    (
        -- Roster là cơ sở để tính học sinh được giao, kể cả chưa nộp bài.
        SELECT mhl.MonHocLopID, hsl.HocSinhID
        FROM dbo.tblMonHocLop mhl
        JOIN dbo.tblHocSinhLop hsl
          ON hsl.LopID = mhl.LopNhomID AND hsl.Enable = 1
        JOIN dbo.tblHocSinh hs
          ON hs.HocSinhID = hsl.HocSinhID AND hs.TinhTrang = 0
        WHERE mhl.Enable = 1
          AND (@NienKhoa IS NULL OR mhl.NienKhoa = @NienKhoa)
        UNION
        SELECT mhl.MonHocLopID, hsn.HocSinhID
        FROM dbo.tblMonHocLop mhl
        JOIN dbo.tblHocSinhNhom hsn
          ON hsn.NhomID = mhl.LopNhomID AND hsn.Enable = 1
        JOIN dbo.tblHocSinh hs
          ON hs.HocSinhID = hsn.HocSinhID AND hs.TinhTrang = 0
        WHERE mhl.Enable = 1
          AND (@NienKhoa IS NULL OR mhl.NienKhoa = @NienKhoa)
    )
    , AllAssignedRaw AS
    (
        SELECT atc.AssignmentID
             , atc.AssignToClassID
             , CAST(NULL AS BIGINT) AS AssignToStudentID
             , cs.HocSinhID
        FROM dbo.tblEL_AssignToClass atc
        JOIN ClassStudents cs ON cs.MonHocLopID = atc.MonHocLopID
        WHERE atc.IsDeleted = 0
          AND atc.ResourceType = 'ASSIGNMENT'
          AND (@NienKhoa IS NULL OR atc.NienKhoa IS NULL OR atc.NienKhoa = @NienKhoa)
        UNION
        SELECT ats.AssignmentID
             , CAST(NULL AS BIGINT) AS AssignToClassID
             , ats.AssignToStudentID
             , ats.HocSinhID
        FROM dbo.tblEL_AssignToStudent ats
        JOIN dbo.tblHocSinh hs
          ON hs.HocSinhID = ats.HocSinhID AND hs.TinhTrang = 0
        WHERE ats.IsDeleted = 0
          AND ats.ResourceType = 'ASSIGNMENT'
          AND (@NienKhoa IS NULL OR ats.NienKhoa IS NULL OR ats.NienKhoa = @NienKhoa)
    )
    , AssignedPairs AS
    (
        -- Một học sinh có thể nằm trong cả giao theo lớp và giao riêng; chỉ tính một lần.
        SELECT AssignmentID, HocSinhID
        FROM AllAssignedRaw
        GROUP BY AssignmentID, HocSinhID
    )
    , LatestSubmission AS
    (
        -- Lấy lần nộp mới nhất của cùng một assignment-học sinh trên mọi target.
        SELECT x.AssignmentID, x.HocSinhID, x.SubmissionStatus
        FROM (
            SELECT aa.AssignmentID
                 , aa.HocSinhID
                 , s.SubmissionStatus
                 , ROW_NUMBER() OVER (
                       PARTITION BY aa.AssignmentID, aa.HocSinhID
                       ORDER BY s.LanNop DESC, s.SubmissionID DESC
                   ) AS rn
            FROM AllAssignedRaw aa
            JOIN dbo.tblEL_Submissions s
              ON s.HocSinhID = aa.HocSinhID
             AND (
                    (aa.AssignToClassID IS NOT NULL AND s.AssignToClassID = aa.AssignToClassID)
                 OR (aa.AssignToStudentID IS NOT NULL AND s.AssignToStudentID = aa.AssignToStudentID)
                 )
            WHERE s.IsDeleted = 0
        ) x
        WHERE x.rn = 1
    )
    , CreatedAssignments AS
    (
        SELECT mh.MonHocID
             , mh.TenMonHoc_HienThi
             , mh.Sort
             , COUNT(DISTINCT a.AssignmentID) AS TotalAssignments
        FROM dbo.tblMonHoc mh
        JOIN dbo.tblEL_Assignments a
          ON a.MonHocID = mh.MonHocID
         AND ISNULL(a.IsDev, 0) = 0
         AND a.IsDeleted = 0
         AND (@NienKhoa IS NULL OR a.NienKhoa = @NienKhoa)
         AND (@NgayBatDau IS NULL OR CAST(a.CreateTime AS DATE) >= @NgayBatDau)
         AND (@NgayKetThuc IS NULL OR CAST(a.CreateTime AS DATE) <= @NgayKetThuc)
        WHERE mh.CapID = @CapID AND mh.Enable = 1
        GROUP BY mh.MonHocID, mh.TenMonHoc_HienThi, mh.Sort
    )
    , AssignmentStatus AS
    (
        SELECT mh.MonHocID
             , COUNT(DISTINCT a.AssignmentID) AS AssignedAssignments
             , COUNT(*) AS TotalAssigned
             , SUM(CASE WHEN ls.SubmissionStatus IS NULL OR ls.SubmissionStatus = 0 THEN 1 ELSE 0 END) AS Total_ChuaLam
             , SUM(CASE WHEN ls.SubmissionStatus = 1 THEN 1 ELSE 0 END) AS Total_DangLam
             -- Trạng thái 3 là đã chấm nháp nhưng học sinh đã nộp.
             , SUM(CASE WHEN ls.SubmissionStatus IN (2, 3) THEN 1 ELSE 0 END) AS Total_DaNop
             , SUM(CASE WHEN ls.SubmissionStatus = 4 THEN 1 ELSE 0 END) AS Total_DaCham
             , CASE
                   WHEN COUNT(*) = 0 THEN 0
                   ELSE ROUND(
                        SUM(CASE WHEN ls.SubmissionStatus IN (2, 3, 4) THEN 1.0 ELSE 0 END)
                        / COUNT(*) * 100, 1)
               END AS CompletionRate_Assignments
             , CASE
                   WHEN COUNT(*) = 0 THEN 0
                   ELSE ROUND(
                        SUM(CASE WHEN ls.SubmissionStatus = 4 THEN 1.0 ELSE 0 END)
                        / COUNT(*) * 100, 1)
               END AS CompletionRate_Graded
        FROM dbo.tblMonHoc mh
        JOIN dbo.tblEL_Assignments a
          ON a.MonHocID = mh.MonHocID
         AND ISNULL(a.IsDev, 0) = 0
         AND a.IsDeleted = 0
         AND (@NienKhoa IS NULL OR a.NienKhoa = @NienKhoa)
         AND (@NgayBatDau IS NULL OR CAST(a.CreateTime AS DATE) >= @NgayBatDau)
         AND (@NgayKetThuc IS NULL OR CAST(a.CreateTime AS DATE) <= @NgayKetThuc)
        JOIN AssignedPairs aa ON aa.AssignmentID = a.AssignmentID
        LEFT JOIN LatestSubmission ls
          ON ls.AssignmentID = aa.AssignmentID
         AND ls.HocSinhID = aa.HocSinhID
        WHERE mh.CapID = @CapID AND mh.Enable = 1
        GROUP BY mh.MonHocID
    )
    SELECT ca.MonHocID
         , ca.TenMonHoc_HienThi
         , ca.TotalAssignments
         , COALESCE(st.AssignedAssignments, 0) AS AssignedAssignments
         , ca.TotalAssignments - COALESCE(st.AssignedAssignments, 0) AS UnassignedAssignments
         , COALESCE(st.TotalAssigned, 0) AS TotalAssigned
         , COALESCE(st.Total_ChuaLam, 0) AS Total_ChuaLam
         , COALESCE(st.Total_DangLam, 0) AS Total_DangLam
         , COALESCE(st.Total_DaNop, 0) AS Total_DaNop
         , COALESCE(st.Total_DaCham, 0) AS Total_DaCham
         , COALESCE(st.CompletionRate_Assignments, 0) AS CompletionRate_Assignments
         , COALESCE(st.CompletionRate_Graded, 0) AS CompletionRate_Graded
    FROM CreatedAssignments ca
    LEFT JOIN AssignmentStatus st ON st.MonHocID = ca.MonHocID
    ORDER BY ca.Sort;
END;
