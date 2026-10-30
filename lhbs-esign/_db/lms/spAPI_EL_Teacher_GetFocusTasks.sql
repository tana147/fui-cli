-- =============================================
-- [dbo].[spAPI_EL_Teacher_GetFocusTasks] 'NV0001181', 1, 1
--
-- OPTIMIZATION LOG v3:
--   Fix 1: Inline TVF Table_GetUser_LMS → bỏ multi-statement TVF, giảm compile time
--   Fix 2: Local variables → tránh parameter sniffing
--   Fix 3: OUTER APPLY → CTE StudentCount (tính 1 lần thay vì N lần)
--   Fix 4: Materialize các CTE nặng ra Temp Table có index
--           CTE AllTeacher/AllowedCreator/CurrentTeacher/StudentCount khi để inline
--           bị SQL Server re-evaluate mỗi row → scan count 1,772 lần
--           tblGiaoVienLop: 178,972 logical reads → sau fix kỳ vọng < 200
-- =============================================
CREATE   PROCEDURE [dbo].[spAPI_EL_Teacher_GetFocusTasks]
    @sys_UserID      VARCHAR(9)
  , @sys_SystemRight INT
  , @HocKi           INT
  , @NienKhoa        INT
AS
BEGIN
    SET NOCOUNT ON;

    -- ============================================================
    -- [FIX 1+2] Chuẩn hóa identity một lần rồi dùng local variables để tránh
    -- parameter sniffing. Table_GetUser_LMS là nguồn ánh xạ duy nhất cho các
    -- tài khoản proxy; không lặp lại mapping riêng trong từng API.
    -- ============================================================
    DECLARE @UserID VARCHAR(50) = @sys_UserID;
    DECLARE @SystemRight INT = @sys_SystemRight;

    SELECT @UserID = SYS_USERID, @SystemRight = SYS_SystemRight
    FROM dbo.Table_GetUser_LMS(@UserID, @SystemRight);

    DECLARE @NienKhoa_HienTai INT = COALESCE(@NienKhoa, dbo.fn_GetNienKhoa_HienTai());

    -- ============================================================
    -- [FIX 4] Temp table: MonHocLopIDs
    -- Các lớp GV đang dạy → dùng để xem bài GV khác giao cho lớp mình
    -- ============================================================
    CREATE TABLE #MonHocLopIDs
    (
        MonHocLopID INT PRIMARY KEY
    );

    INSERT INTO #MonHocLopIDs
    (
        MonHocLopID
    )
    SELECT DISTINCT mhl.MonHocLopID   -- ← thêm DISTINCT vào đây
    FROM
           dbo.tblGiaoVienLop    gvl
           JOIN dbo.tblMonHocLop mhl ON mhl.MonHocID  = gvl.MonHocID
                                    AND mhl.LopNhomID = gvl.LopID
                                    AND gvl.NienKhoa  = @NienKhoa_HienTai
    WHERE
           gvl.GiaoVienID = @UserID
      AND  gvl.Enable      = 1
      AND  gvl.HocKy       = @HocKi;

    -- ============================================================
    -- [FIX 4] Temp table: AllTeacher (union 2 nguồn GV)
    -- Materialized 1 lần, tránh re-evaluate trong các CTE phụ thuộc
    -- ============================================================
    CREATE TABLE #AllTeacher
    (
        GiaoVienID VARCHAR(50) NOT NULL
      , MonHocID   INT         NOT NULL
    );
    CREATE INDEX IX_AllTeacher_MonHoc ON #AllTeacher (MonHocID);
    CREATE INDEX IX_AllTeacher_GiaoVienID ON #AllTeacher (GiaoVienID);

    INSERT INTO #AllTeacher
    (
        GiaoVienID
      , MonHocID
    )
    SELECT DISTINCT
           GiaoVienID
         , MonHocID
    FROM
           dbo.tblEL_GiaoVienLop
    WHERE
           Enable  = 1
      AND  NienKhoa = @NienKhoa_HienTai
      AND  HocKy    = @HocKi
      AND  MonHocID IS NOT NULL
    UNION ALL
    SELECT DISTINCT
           GiaoVienID
         , MonHocID
    FROM
           dbo.tblGiaoVienLop
    WHERE
           Enable  = 1
      AND  NienKhoa = @NienKhoa_HienTai
      AND  HocKy    = @HocKi
      AND  MonHocID IS NOT NULL;
    -- ============================================================
    -- [FIX 4] Temp table: CurrentTeacher
    -- Các môn GV hiện tại đang dạy
    -- ============================================================
    CREATE TABLE #CurrentTeacher
    (
        MonHocID INT PRIMARY KEY
    );

    INSERT INTO #CurrentTeacher
    (
        MonHocID
    )
    SELECT DISTINCT
           MonHocID
    FROM
           #AllTeacher
    WHERE
           GiaoVienID = @UserID;

    -- ============================================================
    -- [FIX 4] Temp table: AllowedCreator
    -- Tất cả GV cùng dạy môn với GV hiện tại (dùng cho quyền xem bài)
    -- Đây là thủ phạm chính: khi là CTE bị scan 1,772 lần
    -- ============================================================
    CREATE TABLE #AllowedCreator
    (
        GiaoVienID VARCHAR(50) PRIMARY KEY
    );

    INSERT INTO #AllowedCreator
    (
        GiaoVienID
    )
    SELECT DISTINCT
           a.GiaoVienID
    FROM
           #AllTeacher          a
           JOIN #CurrentTeacher b ON b.MonHocID = a.MonHocID;


    -- ============================================================
    -- [FIX 3+4] Temp table: StudentCount
    -- Số học sinh mỗi lớp/nhóm — tính 1 lần thay vì OUTER APPLY N lần
    -- ============================================================
    CREATE TABLE #StudentCount
    (
        LopNhomID     NVARCHAR(100) PRIMARY KEY
      , TotalStudents INT           NOT NULL
    );

    INSERT INTO #StudentCount
    (
        LopNhomID
      , TotalStudents
    )
    SELECT LopNhomID
         , SUM(cnt)
    FROM
           (
               SELECT hsl.LopID AS LopNhomID
                    , COUNT(*)  AS cnt
               FROM
                      dbo.tblHocSinhLop   hsl
                      JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID
                                            AND hs.TinhTrang = 0
               WHERE
                      hsl.Enable = 1
               GROUP BY
                      hsl.LopID
               UNION ALL
               SELECT hsn.NhomID
                    , COUNT(*)
               FROM
                      dbo.tblHocSinhNhom  hsn
                      JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsn.HocSinhID
                                            AND hs.TinhTrang = 0
               WHERE
                      hsn.Enable = 1
               GROUP BY
                      hsn.NhomID
           ) x
    GROUP BY
           LopNhomID;


    -- ============================================================
    -- Main query — tất cả lookup đều từ temp table có index
    -- ============================================================
    SELECT atc.AssignToClassID
         , mhl.MonHocID
         , mhl.LopNhomID                                                               AS LopID
         , a.Title
         , m.MonHocName
         , COALESCE(l.TenLop, n.TenNhom)                                               AS TenLopHoacNhom
         , atc.DueDate
         , a.Chuong
         , SUM(CASE WHEN s.SubmissionStatus >= 2 THEN 1 ELSE 0 END)                    AS SubmittedCount
         , SUM(CASE WHEN s.SubmissionStatus = 2 AND s.Score IS NULL THEN 1 ELSE 0 END) AS PendingGradingCount
         , SUM(CASE WHEN s.SubmissionStatus = 4 THEN 1 ELSE 0 END)                     AS GradedCount
         , COALESCE(sc.TotalStudents, 0)                                               AS TotalStudents
         , 'CLASS'                                                                     AS AssignType
         , CASE
                WHEN SUM(CASE WHEN s.SubmissionStatus = 2 AND s.Score IS NULL THEN 1 ELSE 0 END) > 0
                 AND atc.DueDate > GETDATE() THEN 'PENDING_GRADING'
                WHEN atc.DueDate < GETDATE() THEN 'OVERDUE'
                ELSE 'UPCOMING'
           END                                                                         AS Status
         , COALESCE(l.CapID, n.CapID)                                                  AS CapID
         , COALESCE(l.KhoiID, n.KhoiID)                                                AS KhoiID
    FROM
           dbo.tblEL_AssignToClass         atc
           JOIN dbo.tblEL_Assignments      a ON a.AssignmentID    = atc.ResourceID
                                            AND a.IsDeleted       = 0
           JOIN dbo.tblMonHocLop           mhl ON mhl.MonHocLopID = atc.MonHocLopID
           JOIN #CurrentTeacher            ct ON ct.MonHocID      = mhl.MonHocID -- chỉ môn GV đang dạy
           JOIN dbo.tblMonHoc              m ON m.MonHocID        = mhl.MonHocID
           LEFT JOIN dbo.tblLop            l ON l.LopID           = mhl.LopNhomID
                                            AND l.NienKhoa        = @NienKhoa_HienTai
           LEFT JOIN dbo.tblNhom           n ON n.NhomID          = mhl.LopNhomID
                                            AND n.NienKhoa        = @NienKhoa_HienTai
           LEFT JOIN dbo.tblEL_Submissions s ON s.AssignToClassID = atc.AssignToClassID
                                            AND s.IsDeleted       = 0
           LEFT JOIN #StudentCount         sc ON sc.LopNhomID     = mhl.LopNhomID -- [FIX 3]
    WHERE
           (
               -- Admin/trưởng nhóm: xem bài của tất cả GV cùng môn
               (
                   @SystemRight IN (3, 5, 9)
             AND   atc.CreateUser IN
                   (
                       SELECT GiaoVienID
                       FROM
                              #AllowedCreator
                   ) -- [FIX 4] temp table
               )
          OR
          -- GV thường: chỉ xem bài do mình tạo
               (
                   @SystemRight NOT IN (3, 5, 9)
             AND   atc.CreateUser = @UserID
               )
          -- GV dạy lớp thấy bài được giao cho lớp mình từ GV khác
          OR   atc.MonHocLopID IN
               (
                   SELECT MonHocLopID
                   FROM
                          #MonHocLopIDs
               ) -- [FIX 4] temp table
           )
      AND  atc.IsDeleted      = 0
      AND  atc.ResourceType   = 'ASSIGNMENT'
      AND  COALESCE(l.LopID, n.NhomID) IS NOT NULL
    GROUP BY
           atc.AssignToClassID
         , mhl.MonHocID
         , mhl.LopNhomID
         , a.Title
         , m.MonHocName
         , COALESCE(l.TenLop, n.TenNhom)
         , atc.DueDate
         , a.Chuong
         , COALESCE(sc.TotalStudents, 0)
         , COALESCE(l.CapID, n.CapID)
         , COALESCE(l.KhoiID, n.KhoiID)
    HAVING
        -- Lọc bài chưa chấm xong toàn bộ học sinh
           SUM(CASE WHEN s.SubmissionStatus = 4 THEN 1 ELSE 0 END) <> COALESCE(sc.TotalStudents, 0)
    ORDER BY
           CASE
                WHEN SUM(CASE WHEN s.SubmissionStatus = 2 AND s.Score IS NULL THEN 1 ELSE 0 END) > 0 THEN 0
                ELSE 1
           END
         , atc.DueDate ASC;

    -- ============================================================
    -- Cleanup temp tables
    -- ============================================================
    DROP TABLE IF EXISTS #MonHocLopIDs;
    DROP TABLE IF EXISTS #AllTeacher;
    DROP TABLE IF EXISTS #CurrentTeacher;
    DROP TABLE IF EXISTS #AllowedCreator;
    DROP TABLE IF EXISTS #StudentCount;

END;

