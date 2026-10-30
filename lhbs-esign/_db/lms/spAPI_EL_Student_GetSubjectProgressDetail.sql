CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetSubjectProgressDetail]
    @MonHocID   INT
  , @HocSinhID  INT
  , @NienKhoa  INT
  , @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
	 
    -- =================================================================================
    -- == BƯỚC CHUẨN BỊ: Lấy tất cả LỚP và NHÓM của học sinh vào bảng tạm           ==
    -- =================================================================================
    DECLARE @MyUnits TABLE
    (
        UnitID VARCHAR(100)
    );
    INSERT INTO @MyUnits
    (
        UnitID
    )
    SELECT hsl.LopID
    FROM
           dbo.tblHocSinhLop hsl
           JOIN dbo.tblLop   l ON hsl.LopID = l.LopID AND l.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        WHERE
           hsl.HocSinhID = @HocSinhID
      AND  hsl.Enable     = 1
      AND  hsl.NienKhoa   = @NienKhoa
    UNION
    SELECT hsn.NhomID
    FROM
           dbo.tblHocSinhNhom hsn
           JOIN dbo.tblNhom   n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa
    WHERE
           hsn.HocSinhID = @HocSinhID
      AND  hsn.Enable     = 1;

    -- Kiểm tra xem học sinh có thuộc lớp/nhóm nào không
    IF NOT EXISTS
    (
        SELECT 1
        FROM
               @MyUnits
    )
    BEGIN
        -- Trả về tập rỗng nếu không tìm thấy
        SELECT 0    AS TotalResources
             , 0    AS CompletedResources
             , NULL AS TeacherName
             , NULL AS MonHocName;
        SELECT *
        FROM
               (
                   VALUES
                       (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
               ) AS Empty (ResourceType, ResourceID, Title, TuanHocID, Tuan_HienThi, Chuong, StudentStatus, StudentScore, DueDate)
        WHERE
               1 = 0;
        RETURN;
    END;

    -- Sử dụng bảng tạm để chứa danh sách tất cả tài nguyên (giữ nguyên)
    IF OBJECT_ID('tempdb..#AssignedResources') IS NOT NULL
        DROP TABLE #AssignedResources;
    CREATE TABLE #AssignedResources
    (
        ResourceType    VARCHAR(20)
      , ResourceID      INT
      , AssignToClassID BIGINT
      , Title           NVARCHAR(255)
      , TuanHocID       INT
      , Tuan_HienThi    NVARCHAR(500)
      , Chuong          NVARCHAR(2000)
      , DueDate         DATETIME
      , TeacherName     NVARCHAR(100)
      , MonHocName      NVARCHAR(200)
      , Icon            VARCHAR(100)
      , Color           VARCHAR(10)
      , LimitAssigned   INT
      , MaxScore        DECIMAL
      , Is_SendToClass  BIT
    );

    -- Lấy danh sách BÀI TẬP đã giao
    INSERT INTO #AssignedResources
    SELECT 'ASSIGNMENT'   AS ResourceType
         , a.AssignmentID
         , atc.AssignToClassID
         , a.Title
         , a.TuanHocID
         , N'Tuần ' + CAST(TuanTrongNam AS VARCHAR(2)) + N' - Tháng ' + CAST(ThangHoc AS VARCHAR(2)) + N' - Năm ' + CAST(YEAR(NgayBatDau) AS VARCHAR(4))
         , a.Chuong
         , atc.DueDate
         , gv.HoGV + ' ' + gv.TenGV
         , mh.MonHocName
         , mh.Icon
         , mh.Color
         , atc.LimitAssigned
         , atc.MaxScore
         , CAST(1 AS BIT) AS Is_SendToClass
    FROM
           dbo.tblEL_AssignToClass     atc
           JOIN dbo.tblEL_Assignments  a ON atc.ResourceID    = a.AssignmentID
                                        AND atc.ResourceType  = 'ASSIGNMENT'
                                        AND a.IsDeleted       = 0
           JOIN dbo.tblMonHocLop       mhl ON atc.MonHocLopID = mhl.MonHocLopID
                                          AND mhl.Enable      = 1
                                          AND mhl.NienKhoa    = @NienKhoa
           JOIN dbo.tblMonHoc          mh ON mh.MonHocID      = mhl.MonHocID
                                         AND mh.Enable        = 1
           LEFT JOIN dbo.tblTuanHocTap AS tht ON a.TuanHocID  = tht.TuanHocID
           LEFT JOIN dbo.tblGiaoVien   gv ON a.CreateUser     = gv.GiaoVienID
    WHERE
           mhl.LopNhomID IN
           (
               SELECT UnitID
               FROM
                      @MyUnits
           )
      AND  mhl.MonHocID  = @MonHocID
      AND  atc.IsDeleted = 0
    UNION ALL
    SELECT 'ASSIGNMENT'          AS ResourceType
         , a.AssignmentID
         , ats.AssignToStudentID AS AssignToClassID
         , a.Title
         , a.TuanHocID
         , N'Tuần ' + CAST(TuanTrongNam AS VARCHAR(2)) + N' - Tháng ' + CAST(ThangHoc AS VARCHAR(2)) + N' - Năm ' + CAST(YEAR(NgayBatDau) AS VARCHAR(4))
         , a.Chuong
         , ats.DueDate
         , gv.HoGV + ' ' + gv.TenGV
         , mh.MonHocName
         , mh.Icon
         , mh.Color
         , ats.LimitAssigned
         , ats.MaxScore
         , CAST(0 AS BIT)        AS Is_SendToClass
    FROM
           dbo.tblEL_AssignToStudent   ats
           JOIN dbo.tblEL_Assignments  a ON ats.ResourceID    = a.AssignmentID
                                        AND ats.ResourceType  = 'ASSIGNMENT'
                                        AND a.IsDeleted       = 0
           JOIN dbo.tblMonHocLop       mhl ON ats.MonHocLopID = mhl.MonHocLopID
                                          AND mhl.NienKhoa    = @NienKhoa
                                          AND mhl.Enable      = 1
           JOIN dbo.tblMonHoc          mh ON mh.MonHocID      = mhl.MonHocID
                                         AND mh.Enable        = 1
           LEFT JOIN dbo.tblTuanHocTap AS tht ON a.TuanHocID  = tht.TuanHocID
           LEFT JOIN dbo.tblGiaoVien   gv ON a.CreateUser     = gv.GiaoVienID
    WHERE
           mhl.LopNhomID IN
           (
               SELECT UnitID
               FROM
                      @MyUnits
           )
      AND  mhl.MonHocID  = @MonHocID
      AND  ats.IsDeleted = 0
      AND  ats.HocSinhID = @HocSinhID;

    -- Lấy danh sách BÀI HỌC đã giao
    INSERT INTO #AssignedResources
    SELECT 'LESSON'       AS ResourceType
         , l.LessonID
         , atc.AssignToClassID
         , l.Title
         , l.TuanHocID
         , N'Tuần ' + CAST(TuanTrongNam AS VARCHAR(2)) + N' - Tháng ' + CAST(ThangHoc AS VARCHAR(2)) + N' - Năm ' + CAST(YEAR(NgayBatDau) AS VARCHAR(4))
         , l.Chuong
         , NULL
         , gv.HoGV + ' ' + gv.TenGV
         , mh.MonHocName
         , mh.Icon
         , mh.Color
         , atc.LimitAssigned
         , atc.MaxScore
         , CAST(1 AS BIT) AS Is_SendToClass
    FROM
           dbo.tblEL_AssignToClass     atc
           JOIN dbo.tblEL_Lessons      l ON atc.ResourceID     = l.LessonID
                                        AND atc.ResourceType   = 'LESSON'
           JOIN dbo.tblMonHocLop       mhl ON atc.MonHocLopID  = mhl.MonHocLopID
                                          AND mhl.Enable       = 1
                                          AND mhl.NienKhoa     = @NienKhoa
           LEFT JOIN dbo.tblTuanHocTap AS tht ON tht.TuanHocID = l.TuanHocID
           LEFT JOIN dbo.tblMonHoc     mh ON mh.MonHocID       = mhl.MonHocID
                                         AND mh.Enable         = 1
           LEFT JOIN dbo.tblGiaoVien   gv ON l.CreateUser      = gv.GiaoVienID
    WHERE
           mhl.LopNhomID IN
           (
               SELECT UnitID
               FROM
                      @MyUnits
           )
      AND  mhl.MonHocID  = @MonHocID
      AND  atc.IsDeleted = 0
      AND  l.IsDeleted   = 0;

    -- === BẢNG 2: TRẢ VỀ DANH SÁCH TÀI NGUYÊN CHI TIẾT===
    SELECT t.*
    FROM
           (
               SELECT ar.ResourceType
                    , ar.ResourceID
                    , ar.Title
                    , ar.TuanHocID
                    , ar.Tuan_HienThi
                    , ar.Chuong
                    , ar.DueDate
                    , CASE
                           WHEN ar.ResourceType = 'ASSIGNMENT' THEN CASE s.SubmissionStatus
                                                                         WHEN 4 THEN 'GRADED'
                                                                         WHEN 3 THEN 'SUBMITTED' -- Coi 3 là đã nộp
                                                                         WHEN 2 THEN 'SUBMITTED'
                                                                         WHEN 1 THEN 'IN_PROGRESS'
                                                                         ELSE 'NOT_STARTED'
                                                                    END
                           WHEN ar.ResourceType = 'LESSON' THEN CASE
                                                                     WHEN lp.IsCompleted = 1 THEN 'COMPLETED'
                                                                     WHEN lp.ProgressID IS NOT NULL THEN 'IN_PROGRESS'
                                                                     ELSE 'NOT_STARTED'
                                                                END
                    END     AS StudentStatus
                    , s.Score AS StudentScore
                    , ar.AssignToClassID
                    , s.LanNop
                    , ar.LimitAssigned
                    -- Bài random có thể lưu mẫu số riêng theo từng lượt làm.
                    -- Ưu tiên mẫu số của lượt đó, fallback về mẫu số lúc giao bài.
                    , COALESCE(s.AttemptMaxScore, ar.MaxScore) AS MaxScore
                    , ar.Is_SendToClass
               FROM
                      #AssignedResources                    ar
                      LEFT JOIN dbo.tblEL_Submissions       s ON ar.AssignToClassID = s.AssignToClassID
                                                             AND s.HocSinhID        = @HocSinhID
                                                             AND s.IsDeleted        = 0
                      LEFT JOIN dbo.tblEL_Learning_Progress lp ON ar.ResourceID     = lp.LessonID
                                                             AND ar.ResourceType   = 'LESSON'
                                                             AND lp.HocSinhID      = @HocSinhID
               WHERE
                      ar.AssignToClassID > 0
               UNION ALL
               SELECT ar.ResourceType
                    , ar.ResourceID
                    , ar.Title
                    , ar.TuanHocID
                    , ar.Tuan_HienThi
                    , ar.Chuong
                    , ar.DueDate
                    , CASE
                           WHEN ar.ResourceType = 'ASSIGNMENT' THEN CASE s.SubmissionStatus
                                                                         WHEN 4 THEN 'GRADED'
                                                                         WHEN 3 THEN 'SUBMITTED' -- Coi 3 là đã nộp
                                                                         WHEN 2 THEN 'SUBMITTED'
                                                                         WHEN 1 THEN 'IN_PROGRESS'
                                                                         ELSE 'NOT_STARTED'
                                                                    END
                           WHEN ar.ResourceType = 'LESSON' THEN CASE
                                                                     WHEN lp.IsCompleted = 1 THEN 'COMPLETED'
                                                                     WHEN lp.ProgressID IS NOT NULL THEN 'IN_PROGRESS'
                                                                     ELSE 'NOT_STARTED'
                                                                END
                      END     AS StudentStatus
                    , s.Score AS StudentScore
                    , ar.AssignToClassID
                    , s.LanNop
                    , ar.LimitAssigned
                    -- Đồng nhất mẫu số với lượt làm thực tế cho cả bài giao riêng.
                    , COALESCE(s.AttemptMaxScore, ar.MaxScore) AS MaxScore
                    , ar.Is_SendToClass
               FROM
                      #AssignedResources                    ar
                      LEFT JOIN dbo.tblEL_Submissions       s ON ar.AssignToClassID = s.AssignToStudentID
                                                             AND s.HocSinhID        = @HocSinhID
                                                             AND s.IsDeleted        = 0
                      LEFT JOIN dbo.tblEL_Learning_Progress lp ON ar.ResourceID     = lp.LessonID
                                                             AND ar.ResourceType   = 'LESSON'
                                                             AND lp.HocSinhID      = @HocSinhID
               WHERE
                      s.AssignToStudentID > 0
           ) AS t
    ORDER BY
           TuanHocID
         , Chuong
         , Title;

    -- === BẢNG 1: TRẢ VỀ THỐNG KÊ TỔNG QUAN ===
    SELECT
        (
            SELECT COUNT(*)
            FROM
                   #AssignedResources
        ) AS TotalResources
      , ((
             SELECT COUNT(DISTINCT s.AssignToClassID)
             FROM
                    dbo.tblEL_Submissions   s
                    JOIN #AssignedResources ar ON s.AssignToClassID = ar.AssignToClassID
             WHERE
                    s.HocSinhID       = @HocSinhID
               AND  s.SubmissionStatus >= 2
         ) +
         (
             SELECT COUNT(DISTINCT lp.LessonID)
             FROM
                    dbo.tblEL_Learning_Progress lp
                    JOIN #AssignedResources     ar ON lp.LessonID     = ar.ResourceID
                                                  AND ar.ResourceType = 'LESSON'
             WHERE
                    lp.HocSinhID  = @HocSinhID
               AND  lp.IsCompleted = 1
         )
        ) AS CompletedResources
      , (
             SELECT TOP 1
                    TeacherName
             FROM
                    #AssignedResources
             WHERE
                    TeacherName IS NOT NULL
         ) AS TeacherName
      , (
             SELECT TOP 1
                    MonHocName
             FROM
                    #AssignedResources
             WHERE
                    MonHocName IS NOT NULL
         ) AS MonHocName
      , (
             SELECT TOP 1
                    Icon
             FROM
                    #AssignedResources
             WHERE
                    Icon IS NOT NULL
         ) AS Icon
      , (
             SELECT TOP 1
                    Color
             FROM
                    #AssignedResources
             WHERE
                    Color IS NOT NULL
         ) AS Color;
    DROP TABLE #AssignedResources;
END;
