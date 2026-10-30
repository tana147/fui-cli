
-- ============================================================
-- BENCHMARK TRƯỚC KHI APPLY (chạy với SP cũ, ghi lại kết quả)
-- SET STATISTICS TIME ON; SET STATISTICS IO ON;
-- EXEC [dbo].[spAPI_EL_Teacher_GetGroupedDashboard]
--     @sys_UserID='NA0000022', @sys_SystemRight=9, @HocKi=2
-- SET STATISTICS TIME OFF; SET STATISTICS IO OFF;
-- ============================================================

CREATE   PROCEDURE [dbo].[spAPI_EL_Teacher_GetGroupedDashboard]
    @sys_UserID      VARCHAR(9),
    @sys_SystemRight INT,
    @HocKi           INT,
    @NienKhoa        INT
AS
BEGIN
    SET NOCOUNT ON;

    -- ============================================================
    -- BƯỚC 0: LẤY THÔNG TIN USER
    -- ============================================================
    SELECT
        @sys_UserID      = SYS_USERID,
        @sys_SystemRight = SYS_SystemRight
    FROM dbo.Table_GetUser_LMS(@sys_UserID, @sys_SystemRight);

    DECLARE @NienKhoa_HienTai INT = COALESCE(@NienKhoa, dbo.fn_GetNienKhoa_HienTai());

    -- Quyền SUBJECT dùng chung bảng phân quyền tài nguyên nhưng không gắn vào từng target.
    -- Một dòng theo giáo viên + môn + niên khóa sẽ mở quyền xem cả bài hiện tại và bài tạo sau này.
    CREATE TABLE #SubjectPermissions (MonHocID INT PRIMARY KEY);

    INSERT INTO #SubjectPermissions (MonHocID)
    SELECT DISTINCT rtp.MonHocID
    FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
    WHERE rtp.GiaoVienID = @sys_UserID
      AND rtp.Enable = 1
      AND rtp.PermissionScope = 'SUBJECT'
      AND rtp.MonHocID IS NOT NULL
      AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa_HienTai);

    -- ============================================================
    -- BƯỚC 1: XÁC ĐỊNH QUYỀN XEM DỮ LIỆU
    -- TỐI ƯU: Dùng #TempTable thay @TableVariable để có statistics
    --         và có thể tạo INDEX sau khi INSERT
    -- ============================================================

    -- Tất cả giáo viên trong năm học / học kỳ hiện tại
    CREATE TABLE #AllTeacher (GiaoVienID VARCHAR(20), MonHocID INT);

    INSERT INTO #AllTeacher (GiaoVienID, MonHocID)
    SELECT GiaoVienID, MonHocID
    FROM dbo.tblEL_GiaoVienLop
    WHERE Enable = 1 AND NienKhoa = @NienKhoa_HienTai AND HocKy = @HocKi
      AND MonHocID IS NOT NULL
    UNION
    SELECT GiaoVienID, MonHocID
    FROM dbo.tblGiaoVienLop
    WHERE Enable = 1 AND NienKhoa = @NienKhoa_HienTai AND HocKy = @HocKi
      AND MonHocID IS NOT NULL
    UNION
    SELECT GiaoVienID, MonHocID
    FROM dbo.tblEL_Resoucre_TeacherPermissions
    WHERE Enable = 1 AND GiaoVienID = @sys_UserID
      AND MonHocID IS NOT NULL;

    CREATE INDEX IX_AllTeacher_GV     ON #AllTeacher (GiaoVienID) INCLUDE (MonHocID);
    CREATE INDEX IX_AllTeacher_MonHoc ON #AllTeacher (MonHocID)   INCLUDE (GiaoVienID);

    -- Môn học của GV hiện tại
    CREATE TABLE #CurrentTeacher (MonHocID INT PRIMARY KEY);

    INSERT INTO #CurrentTeacher (MonHocID)
    SELECT DISTINCT MonHocID
    FROM #AllTeacher
    WHERE GiaoVienID = @sys_UserID;

    -- GV được phép xem (cùng môn học với GV hiện tại)
    CREATE TABLE #AllowedCreator (GiaoVienID VARCHAR(20) PRIMARY KEY);

    INSERT INTO #AllowedCreator (GiaoVienID)
    SELECT DISTINCT a.GiaoVienID
    FROM #AllTeacher a
    INNER JOIN #CurrentTeacher b ON a.MonHocID = b.MonHocID;

    -- MonHocLopID mà GV trực tiếp dạy (dùng để filter quyền xem)
    CREATE TABLE #MonHocLopIDs (MonHocLopID INT PRIMARY KEY);

    INSERT INTO #MonHocLopIDs (MonHocLopID)
    SELECT DISTINCT mhl.MonHocLopID   -- ← thêm DISTINCT vào đây
    FROM tblGiaoVienLop gvl
    INNER JOIN tblMonHocLop mhl
           ON  mhl.MonHocID  = gvl.MonHocID
           AND mhl.LopNhomID = gvl.LopID
           AND gvl.NienKhoa  = @NienKhoa_HienTai
    WHERE gvl.GiaoVienID = @sys_UserID
      AND gvl.Enable = 1
      AND gvl.HocKy  = @HocKi;

    -- ============================================================
    -- BƯỚC 2: LỚP / NHÓM MÀ GIÁO VIÊN DẠY
    -- TỐI ƯU: (l.LopID IS NOT NULL OR n.NhomID IS NOT NULL)
    --         rõ ràng hơn COALESCE IS NOT NULL, dễ dùng index hơn
    -- ============================================================

    CREATE TABLE #TeacherUnits (
        UnitID   VARCHAR(20),
        KhoiID   INT,
        MonHocID INT,
        IsDirectTeacher INT DEFAULT 0
    );

    INSERT INTO #TeacherUnits (UnitID, KhoiID, MonHocID, IsDirectTeacher)
    SELECT DISTINCT gvl.LopID, COALESCE(l.KhoiID, n.KhoiID), gvl.MonHocID, 1
    FROM dbo.tblGiaoVienLop gvl
    LEFT JOIN dbo.tblLop  l ON gvl.LopID = l.LopID  AND l.NienKhoa = @NienKhoa_HienTai
    LEFT JOIN dbo.tblNhom n ON gvl.LopID = n.NhomID AND n.NienKhoa = @NienKhoa_HienTai
    WHERE gvl.GiaoVienID = @sys_UserID
      AND gvl.MonHocID NOT IN (3,8,11,13,14,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,36,37)
      AND gvl.MonHocID IS NOT NULL
      AND gvl.NienKhoa = @NienKhoa_HienTai
      AND gvl.Enable   = 1
      AND gvl.HocKy    = @HocKi
      AND (l.LopID IS NOT NULL OR n.NhomID IS NOT NULL)

    UNION

    SELECT DISTINCT gvl.LopID, COALESCE(l.KhoiID, n.KhoiID), gvl.MonHocID, 1
    FROM dbo.tblEL_GiaoVienLop gvl
    LEFT JOIN dbo.tblLop  l ON gvl.LopID = l.LopID  AND l.NienKhoa = @NienKhoa_HienTai
    LEFT JOIN dbo.tblNhom n ON gvl.LopID = n.NhomID AND n.NienKhoa = @NienKhoa_HienTai
    WHERE gvl.GiaoVienID = @sys_UserID
      AND gvl.MonHocID NOT IN (3,8,11,13,14,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,36,37)
      AND gvl.MonHocID IS NOT NULL
      AND gvl.NienKhoa = @NienKhoa_HienTai
      AND gvl.Enable   = 1
      AND gvl.HocKy    = @HocKi
      AND (l.LopID IS NOT NULL OR n.NhomID IS NOT NULL)

    UNION

    SELECT mhl.LopNhomID, COALESCE(l.KhoiID, n.KhoiID), mhl.MonHocID, 0
    FROM tblEL_Resoucre_TeacherPermissions rtp
    INNER JOIN tblEL_AssignToClass atc ON atc.AssignToClassID = rtp.AssignToClassID AND atc.IsDeleted = 0
    INNER JOIN tblMonHocLop mhl        ON atc.MonHocLopID = mhl.MonHocLopID AND mhl.Enable = 1
    LEFT JOIN  dbo.tblLop  l ON mhl.LopNhomID = l.LopID  AND l.NienKhoa = @NienKhoa_HienTai
    LEFT JOIN  dbo.tblNhom n ON mhl.LopNhomID = n.NhomID AND n.NienKhoa = @NienKhoa_HienTai
    WHERE rtp.Enable = 1 AND rtp.GiaoVienID = @sys_UserID
      AND mhl.MonHocID IS NOT NULL

    UNION

    -- Quyền theo môn: mở rộng phạm vi tới toàn bộ lớp/nhóm của môn trong niên khóa.
    SELECT DISTINCT mhl.LopNhomID, COALESCE(l.KhoiID, n.KhoiID), mhl.MonHocID, 0
    FROM dbo.tblMonHocLop mhl
    INNER JOIN #SubjectPermissions sp ON sp.MonHocID = mhl.MonHocID
    LEFT JOIN dbo.tblLop  l ON mhl.LopNhomID = l.LopID  AND l.NienKhoa = @NienKhoa_HienTai
    LEFT JOIN dbo.tblNhom n ON mhl.LopNhomID = n.NhomID AND n.NienKhoa = @NienKhoa_HienTai
    WHERE mhl.NienKhoa = @NienKhoa_HienTai
      AND mhl.Enable = 1;

    CREATE INDEX IX_TeacherUnits_Unit    ON #TeacherUnits (UnitID)           INCLUDE (KhoiID, MonHocID);
    CREATE INDEX IX_TeacherUnits_KhoiMon ON #TeacherUnits (KhoiID, MonHocID);

    -- ============================================================
    -- BƯỚC 3: TẤT CẢ BÀI ĐÃ GIAO
    -- TỐI ƯU CHÍNH: Tách 5 OR thành nhiều INSERT riêng biệt
    --   → Mỗi nhánh SQL Server tối ưu plan độc lập
    --   → Dùng EXISTS thay IN(SELECT...) cho subquery lớn
    --   → NOT EXISTS để tránh duplicate giữa các nhánh
    -- ============================================================

    CREATE TABLE #AllAssignedContent (
        AssignToClassID   BIGINT,
        AssignToStudentID BIGINT,
        AssignType        VARCHAR(20),
        ResourceType      NVARCHAR(20),
        ResourceID        INT,
        TuanHocID         INT,
        DueDate           DATETIME,
        UnitID            VARCHAR(20),
        KhoiID            INT,
        MonHocID          INT,
        CreateUser        VARCHAR(20),
        CreateTime        DATETIME
    );

    -- ── NHÁNH CLASS ──────────────────────────────────────────────────────────

    -- [CLASS-1] Admin: xem tất cả GV cùng môn (trừ NA0000022 đặc biệt)
    IF @sys_SystemRight IN (3, 5, 9) AND @sys_UserID <> 'NA0000022'
    BEGIN
        INSERT INTO #AllAssignedContent (
            AssignToClassID, AssignToStudentID, AssignType,
            ResourceType, ResourceID, TuanHocID, DueDate,
            UnitID, KhoiID, MonHocID, CreateUser, CreateTime
        )
        SELECT DISTINCT
            atc.AssignToClassID, -1, 'CLASS',
            atc.ResourceType, atc.ResourceID,
            COALESCE(a.TuanHocID, l.TuanHocID),
            atc.DueDate,
            tu.UnitID, tu.KhoiID, tu.MonHocID,
            atc.CreateUser, atc.CreateTime
        FROM dbo.tblEL_AssignToClass atc
        INNER JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID AND mhl.Enable = 1
        LEFT  JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' AND a.IsDeleted = 0
        LEFT  JOIN dbo.tblEL_Lessons     l ON atc.ResourceID = l.LessonID     AND atc.ResourceType = 'LESSON'      AND l.IsDeleted = 0
        INNER JOIN #TeacherUnits    tu  ON mhl.LopNhomID = tu.UnitID AND tu.MonHocID = ISNULL(a.MonHocID, ISNULL(l.MonHocID, mhl.MonHocID))
        WHERE atc.IsDeleted = 0
          AND (a.AssignmentID IS NOT NULL OR l.LessonID IS NOT NULL)
          AND EXISTS (SELECT 1 FROM #AllowedCreator ac WHERE ac.GiaoVienID = atc.CreateUser);
    END;

    -- [CLASS-2] GV thường: bài của chính mình hoặc có quyền SUBJECT theo môn.
    INSERT INTO #AllAssignedContent (
        AssignToClassID, AssignToStudentID, AssignType,
        ResourceType, ResourceID, TuanHocID, DueDate,
        UnitID, KhoiID, MonHocID, CreateUser, CreateTime
    )
    SELECT DISTINCT
        atc.AssignToClassID, -1, 'CLASS',
        atc.ResourceType, atc.ResourceID,
        COALESCE(a.TuanHocID, l.TuanHocID),
        atc.DueDate,
        tu.UnitID, tu.KhoiID, tu.MonHocID,
        atc.CreateUser, atc.CreateTime
    FROM dbo.tblEL_AssignToClass atc
    INNER JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID AND mhl.Enable = 1
    LEFT  JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' AND a.IsDeleted = 0
    LEFT  JOIN dbo.tblEL_Lessons     l ON atc.ResourceID = l.LessonID     AND atc.ResourceType = 'LESSON'      AND l.IsDeleted = 0
    INNER JOIN #TeacherUnits    tu  ON mhl.LopNhomID = tu.UnitID AND tu.MonHocID = ISNULL(a.MonHocID, ISNULL(l.MonHocID, mhl.MonHocID))
    WHERE atc.IsDeleted = 0
      AND (a.AssignmentID IS NOT NULL OR l.LessonID IS NOT NULL)
      AND (
            atc.CreateUser = @sys_UserID
            OR EXISTS (
                SELECT 1
                FROM #SubjectPermissions sp
                WHERE sp.MonHocID = ISNULL(a.MonHocID, ISNULL(l.MonHocID, mhl.MonHocID))
            )
          )
      AND NOT EXISTS (
            SELECT 1 FROM #AllAssignedContent x
            WHERE x.AssignToClassID = atc.AssignToClassID AND x.UnitID = tu.UnitID
          );

    -- [CLASS-3] GV dạy lớp xem bài giao qua MonHocLopID (từ GV khác)
    INSERT INTO #AllAssignedContent (
        AssignToClassID, AssignToStudentID, AssignType,
        ResourceType, ResourceID, TuanHocID, DueDate,
        UnitID, KhoiID, MonHocID, CreateUser, CreateTime
    )
    SELECT DISTINCT
        atc.AssignToClassID, -1, 'CLASS',
        atc.ResourceType, atc.ResourceID,
        COALESCE(a.TuanHocID, l.TuanHocID),
        atc.DueDate,
        tu.UnitID, tu.KhoiID, tu.MonHocID,
        atc.CreateUser, atc.CreateTime
    FROM dbo.tblEL_AssignToClass atc
    INNER JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID AND mhl.Enable = 1
    LEFT  JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' AND a.IsDeleted = 0
    LEFT  JOIN dbo.tblEL_Lessons     l ON atc.ResourceID = l.LessonID     AND atc.ResourceType = 'LESSON'      AND l.IsDeleted = 0
    INNER JOIN #TeacherUnits    tu  ON mhl.LopNhomID = tu.UnitID AND tu.MonHocID = ISNULL(a.MonHocID, ISNULL(l.MonHocID, mhl.MonHocID))
    WHERE atc.IsDeleted = 0
      AND (a.AssignmentID IS NOT NULL OR l.LessonID IS NOT NULL)
      AND EXISTS (SELECT 1 FROM #MonHocLopIDs m WHERE m.MonHocLopID = atc.MonHocLopID)
      AND NOT EXISTS (
            SELECT 1 FROM #AllAssignedContent x
            WHERE x.AssignToClassID = atc.AssignToClassID AND x.UnitID = tu.UnitID
          );

    -- [CLASS-4] Quyền resource teacher (AssignToClassID được phân quyền riêng)
    INSERT INTO #AllAssignedContent (
        AssignToClassID, AssignToStudentID, AssignType,
        ResourceType, ResourceID, TuanHocID, DueDate,
        UnitID, KhoiID, MonHocID, CreateUser, CreateTime
    )
    SELECT DISTINCT
        atc.AssignToClassID, -1, 'CLASS',
        atc.ResourceType, atc.ResourceID,
        COALESCE(a.TuanHocID, l.TuanHocID),
        atc.DueDate,
        tu.UnitID, tu.KhoiID, tu.MonHocID,
        atc.CreateUser, atc.CreateTime
    FROM dbo.tblEL_AssignToClass atc
    INNER JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID AND mhl.Enable = 1
    LEFT  JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' AND a.IsDeleted = 0
    LEFT  JOIN dbo.tblEL_Lessons     l ON atc.ResourceID = l.LessonID     AND atc.ResourceType = 'LESSON'      AND l.IsDeleted = 0
    INNER JOIN #TeacherUnits    tu  ON mhl.LopNhomID = tu.UnitID AND tu.MonHocID = ISNULL(a.MonHocID, ISNULL(l.MonHocID, mhl.MonHocID))
    WHERE atc.IsDeleted = 0
      AND (a.AssignmentID IS NOT NULL OR l.LessonID IS NOT NULL)
      AND EXISTS (
            SELECT 1 FROM tblEL_Resoucre_TeacherPermissions rtp
            WHERE rtp.AssignToClassID = atc.AssignToClassID
              AND rtp.GiaoVienID = @sys_UserID
              AND rtp.Enable = 1
          )
      AND NOT EXISTS (
            SELECT 1 FROM #AllAssignedContent x
            WHERE x.AssignToClassID = atc.AssignToClassID AND x.UnitID = tu.UnitID
          );

    -- ── NHÁNH STUDENT ────────────────────────────────────────────────────────

    -- [STUDENT-1] Admin: xem tất cả GV cùng môn
    IF @sys_SystemRight = 5
    BEGIN
        INSERT INTO #AllAssignedContent (
            AssignToClassID, AssignToStudentID, AssignType,
            ResourceType, ResourceID, TuanHocID, DueDate,
            UnitID, KhoiID, MonHocID, CreateUser, CreateTime
        )
        SELECT DISTINCT
            -1, ats.AssignToStudentID, 'STUDENT',
            ats.ResourceType, ats.ResourceID,
            COALESCE(a.TuanHocID, l.TuanHocID),
            ats.DueDate,
            tu.UnitID, tu.KhoiID, tu.MonHocID,
            ats.CreateUser, ats.CreateTime
        FROM dbo.tblEL_AssignToStudent ats
        INNER JOIN dbo.tblMonHocLop mhl ON ats.MonHocLopID = mhl.MonHocLopID AND mhl.Enable = 1
        LEFT  JOIN dbo.tblEL_Assignments a ON ats.ResourceID = a.AssignmentID AND ats.ResourceType = 'ASSIGNMENT' AND a.IsDeleted = 0
        LEFT  JOIN dbo.tblEL_Lessons     l ON ats.ResourceID = l.LessonID     AND ats.ResourceType = 'LESSON'      AND l.IsDeleted = 0
        INNER JOIN #TeacherUnits    tu  ON mhl.LopNhomID = tu.UnitID AND tu.MonHocID = ISNULL(a.MonHocID, ISNULL(l.MonHocID, mhl.MonHocID))
        WHERE ats.IsDeleted = 0
          AND (a.AssignmentID IS NOT NULL OR l.LessonID IS NOT NULL)
          AND EXISTS (SELECT 1 FROM #AllowedCreator ac WHERE ac.GiaoVienID = ats.CreateUser);
    END;

    -- [STUDENT-2] GV thường: bài của mình, qua MonHocLopID hoặc có quyền SUBJECT theo môn.
    INSERT INTO #AllAssignedContent (
        AssignToClassID, AssignToStudentID, AssignType,
        ResourceType, ResourceID, TuanHocID, DueDate,
        UnitID, KhoiID, MonHocID, CreateUser, CreateTime
    )
    SELECT DISTINCT
        -1, ats.AssignToStudentID, 'STUDENT',
        ats.ResourceType, ats.ResourceID,
        COALESCE(a.TuanHocID, l.TuanHocID),
        ats.DueDate,
        tu.UnitID, tu.KhoiID, tu.MonHocID,
        ats.CreateUser, ats.CreateTime
    FROM dbo.tblEL_AssignToStudent ats
    INNER JOIN dbo.tblMonHocLop mhl ON ats.MonHocLopID = mhl.MonHocLopID AND mhl.Enable = 1
    LEFT  JOIN dbo.tblEL_Assignments a ON ats.ResourceID = a.AssignmentID AND ats.ResourceType = 'ASSIGNMENT' AND a.IsDeleted = 0
    LEFT  JOIN dbo.tblEL_Lessons     l ON ats.ResourceID = l.LessonID     AND ats.ResourceType = 'LESSON'      AND l.IsDeleted = 0
    INNER JOIN #TeacherUnits    tu  ON mhl.LopNhomID = tu.UnitID AND tu.MonHocID = ISNULL(a.MonHocID, ISNULL(l.MonHocID, mhl.MonHocID))
    WHERE ats.IsDeleted = 0
      AND (a.AssignmentID IS NOT NULL OR l.LessonID IS NOT NULL)
      AND (
            ats.CreateUser = @sys_UserID
            OR EXISTS (SELECT 1 FROM #MonHocLopIDs m WHERE m.MonHocLopID = ats.MonHocLopID)
            OR EXISTS (
                SELECT 1
                FROM #SubjectPermissions sp
                WHERE sp.MonHocID = ISNULL(a.MonHocID, ISNULL(l.MonHocID, mhl.MonHocID))
            )
          )
      AND NOT EXISTS (
            SELECT 1 FROM #AllAssignedContent x
            WHERE x.AssignToStudentID = ats.AssignToStudentID AND x.UnitID = tu.UnitID
          );

    -- INDEX sau khi INSERT xong toàn bộ (quan trọng với bảng lớn)
    CREATE INDEX IX_AAC_ClassID     ON #AllAssignedContent (AssignToClassID)
        INCLUDE (ResourceType, UnitID, MonHocID, KhoiID, AssignType, AssignToStudentID);
    CREATE INDEX IX_AAC_StudentID   ON #AllAssignedContent (AssignToStudentID)
        INCLUDE (ResourceType, UnitID, MonHocID, KhoiID, AssignType);
    CREATE INDEX IX_AAC_UnitMon     ON #AllAssignedContent (UnitID, MonHocID, ResourceType);
    CREATE INDEX IX_AAC_ResourceID  ON #AllAssignedContent (ResourceID, ResourceType);

    -- ============================================================
    -- BƯỚC 4: THỐNG KÊ
    -- ============================================================

    -- ── Submission count cho CLASS ────────────────────────────────
    CREATE TABLE #SubmissionCounts (
        AssignToClassID     BIGINT PRIMARY KEY,
        SubmittedCount      INT,
        PendingGradingCount INT,
        GradedCount         INT
    );

    INSERT INTO #SubmissionCounts (AssignToClassID, SubmittedCount, PendingGradingCount, GradedCount)
    SELECT
        s.AssignToClassID,
        SUM(CASE WHEN s.SubmissionStatus >= 2                          THEN 1 ELSE 0 END),
        SUM(CASE WHEN s.SubmissionStatus =  2 AND s.Score IS NULL      THEN 1 ELSE 0 END),
        SUM(CASE WHEN s.SubmissionStatus >= 3                          THEN 1 ELSE 0 END)
    FROM (
        SELECT DISTINCT HocSinhID, SubmissionStatus, AssignToClassID, Score
        FROM tblEL_Submissions
        WHERE AssignToClassID IN (
            SELECT AssignToClassID
            FROM #AllAssignedContent
            WHERE ResourceType = 'ASSIGNMENT' AND AssignToClassID > 0
        )
        AND IsDeleted = 0
    ) AS s
    GROUP BY s.AssignToClassID;

    -- ── FIX CHÍNH: Pre-aggregate submission cho STUDENT ──────────
    --   TRƯỚC: correlated subquery × 3 trong CASE WHEN → 10 triệu reads
    --   SAU:   1 lần INSERT → LEFT JOIN trong Bảng 3
    CREATE TABLE #SubmissionCountsStudent (
        AssignToStudentID   BIGINT PRIMARY KEY,
        SubmittedCount      INT,
        PendingGradingCount INT,
        GradedCount         INT
    );

    INSERT INTO #SubmissionCountsStudent (AssignToStudentID, SubmittedCount, PendingGradingCount, GradedCount)
    SELECT
        s.AssignToStudentID,
        SUM(CASE WHEN s.SubmissionStatus >= 2                          THEN 1 ELSE 0 END),
        SUM(CASE WHEN s.SubmissionStatus =  2 AND s.Score IS NULL      THEN 1 ELSE 0 END),
        SUM(CASE WHEN s.SubmissionStatus >= 3                          THEN 1 ELSE 0 END)
    FROM (
        SELECT DISTINCT HocSinhID, SubmissionStatus, AssignToStudentID, Score
        FROM tblEL_Submissions
        WHERE AssignToStudentID IN (
            SELECT AssignToStudentID
            FROM #AllAssignedContent
            WHERE AssignType = 'STUDENT' AND AssignToStudentID > 0
        )
        AND IsDeleted = 0
    ) AS s
    GROUP BY s.AssignToStudentID;

    -- ── Học sinh theo Unit ────────────────────────────────────────
    CREATE TABLE #UnitStudents (UnitID VARCHAR(20), HocSinhID INT);

    INSERT INTO #UnitStudents (UnitID, HocSinhID)
    SELECT hsl.LopID, hsl.HocSinhID
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsl.HocSinhID AND hs.TinhTrang = 0
    WHERE hsl.Enable = 1
      AND (hsl.NienKhoa = @NienKhoa_HienTai OR hsl.NienKhoa IS NULL)
      AND hsl.LopID IN (SELECT DISTINCT UnitID FROM #TeacherUnits)

    UNION ALL   -- TỐI ƯU: UNION ALL thay UNION (LopID ≠ NhomID namespace)

    SELECT hsn.NhomID, hsn.HocSinhID
    FROM dbo.tblHocSinhNhom hsn
    INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = hsn.HocSinhID AND hs.TinhTrang = 0
    INNER JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa_HienTai
    WHERE hsn.Enable = 1
      AND hsn.NhomID IN (SELECT DISTINCT UnitID FROM #TeacherUnits);

    CREATE INDEX IX_UnitStudents ON #UnitStudents (UnitID, HocSinhID);

    -- ── Learning progress (LESSON) ────────────────────────────────
    CREATE TABLE #LearningCounts (AssignToClassID BIGINT PRIMARY KEY, CompletedCount INT);

    INSERT INTO #LearningCounts (AssignToClassID, CompletedCount)
    SELECT aac.AssignToClassID, COUNT(DISTINCT lp.HocSinhID)
    FROM dbo.tblEL_Learning_Progress lp
    INNER JOIN #AllAssignedContent aac
           ON  lp.LessonID = aac.ResourceID
           AND aac.ResourceType = 'LESSON'
    INNER JOIN #UnitStudents us
           ON  us.UnitID    = aac.UnitID
           AND us.HocSinhID = lp.HocSinhID
    WHERE ISNULL(lp.IsDeleted,   0) = 0
      AND ISNULL(lp.IsCompleted, 0) = 1
    GROUP BY aac.AssignToClassID;

    -- ── Sĩ số lớp / nhóm ─────────────────────────────────────────
    --   TỐI ƯU: Tái dụng #UnitStudents đã có → không scan lại tblHocSinhLop/Nhom
    CREATE TABLE #StudentCounts (UnitID VARCHAR(20) PRIMARY KEY, StudentCount INT);

    INSERT INTO #StudentCounts (UnitID, StudentCount)
    SELECT UnitID, COUNT(HocSinhID)
    FROM #UnitStudents
    GROUP BY UnitID;

    -- ============================================================
    -- BẢNG 1: TỔNG HỢP THEO KHỐI / MÔN
    -- ============================================================
    SELECT
        tu.KhoiID,
        k.TenKhoiHoc,
        tu.MonHocID,
        mh.MonHocName,
        tu.IsDirectTeacher,
        SUM(ISNULL(sc.PendingGradingCount, 0)) AS TotalPendingGradingCount
    FROM (
        SELECT KhoiID, MonHocID, MAX(IsDirectTeacher) AS IsDirectTeacher
        FROM #TeacherUnits
        GROUP BY KhoiID, MonHocID
    ) tu
    JOIN  dbo.tblMonHoc mh ON tu.MonHocID = mh.MonHocID
    JOIN  dbo.tblKhoi   k  ON tu.KhoiID   = k.KhoiID
    LEFT JOIN #AllAssignedContent aac
          ON  tu.KhoiID   = aac.KhoiID
          AND tu.MonHocID = aac.MonHocID
          AND aac.ResourceType = 'ASSIGNMENT'
    LEFT JOIN #SubmissionCounts sc ON aac.AssignToClassID = sc.AssignToClassID
    GROUP BY tu.KhoiID, k.TenKhoiHoc, tu.MonHocID, mh.MonHocName, tu.IsDirectTeacher
    ORDER BY tu.KhoiID, mh.MonHocName;

    -- ============================================================
    -- BẢNG 2: CHI TIẾT TỪNG LỚP / NHÓM
    -- ============================================================
    SELECT
        tu.UnitID AS LopID,
        COALESCE(l.TenLop, n.TenNhom) AS TenLop,
        tu.KhoiID,
        tu.MonHocID,
        tu.IsDirectTeacher,
        ISNULL(SUM(sc.PendingGradingCount), 0) AS PendingGradingCountInClass,
        ISNULL(stc.StudentCount, 0)             AS StudentCount
    FROM (
        SELECT UnitID, KhoiID, MonHocID, MAX(IsDirectTeacher) AS IsDirectTeacher
        FROM #TeacherUnits
        GROUP BY UnitID, KhoiID, MonHocID
    ) tu
    LEFT JOIN #AllAssignedContent aac
          ON  tu.UnitID   = aac.UnitID
          AND tu.MonHocID = aac.MonHocID
          AND aac.ResourceType = 'ASSIGNMENT'
    LEFT JOIN #SubmissionCounts sc  ON aac.AssignToClassID = sc.AssignToClassID
    LEFT JOIN #StudentCounts    stc ON tu.UnitID = stc.UnitID
    LEFT JOIN dbo.tblLop  l ON tu.UnitID = l.LopID  AND l.NienKhoa = @NienKhoa_HienTai
    LEFT JOIN dbo.tblNhom n ON tu.UnitID = n.NhomID AND n.NienKhoa = @NienKhoa_HienTai
    GROUP BY tu.UnitID, COALESCE(l.TenLop, n.TenNhom), tu.KhoiID, tu.MonHocID, tu.IsDirectTeacher, stc.StudentCount
    ORDER BY TenLop;

    -- ============================================================
    -- BẢNG 3: CHI TIẾT BÀI TẬP ĐÃ GIAO
    -- FIX CHÍNH: Thay 3 × correlated subquery bằng LEFT JOIN
    --   → giảm từ 10,293,624 logical reads (~27s) xuống ~vài trăm reads
    -- ============================================================
    SELECT
        aac.UnitID          AS LopID,
        aac.ResourceID      AS AssignmentID,
        aac.AssignToClassID,
        a.Title             AS AssignmentTitle,
        aac.DueDate,
        aac.TuanHocID,
        N'Tuần '    + CAST(th.Tuan      AS VARCHAR(2))
        + N' - Tháng ' + CAST(th.ThangHoc  AS VARCHAR(2))
        + N' - ('   + FORMAT(th.NgayBatDau,  'dd/MM/yyyy')
        + N' - '    + FORMAT(th.NgayKetThuc, 'dd/MM/yyyy') + ')' AS Tuan_HienThi,
        aac.ResourceType,

        -- SubmittedCount: CLASS → #SubmissionCounts, STUDENT → #SubmissionCountsStudent
        CASE
            WHEN aac.AssignType = 'CLASS'   THEN ISNULL(sc.SubmittedCount,  0)
            WHEN aac.AssignType = 'STUDENT' THEN ISNULL(scs.SubmittedCount, 0)
            ELSE 0
        END AS SubmittedCount,

        -- PendingGradingCount
        CASE
            WHEN aac.AssignType = 'CLASS'   THEN ISNULL(sc.PendingGradingCount,  0)
            WHEN aac.AssignType = 'STUDENT' THEN ISNULL(scs.PendingGradingCount, 0)
            ELSE 0
        END AS PendingGradingCount,

        -- GradedCount
        CASE
            WHEN aac.AssignType = 'CLASS'   THEN ISNULL(sc.GradedCount,  0)
            WHEN aac.AssignType = 'STUDENT' THEN ISNULL(scs.GradedCount, 0)
            ELSE 0
        END AS GradedCount,

        -- TotalStudentsInClass: STUDENT thì luôn = 1
        CASE
            WHEN aac.AssignType = 'CLASS'   THEN ISNULL(stc.StudentCount, 0)
            WHEN aac.AssignType = 'STUDENT' THEN 1
            ELSE 0
        END AS TotalStudentsInClass,

        CASE
            WHEN th.TuanTrongNam = DATEPART(WEEK, GETDATE()) THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END AS Is_Tuan_Active,

        a.Chuong,
        aac.MonHocID,
        aac.AssignType,
        aac.AssignToStudentID,
        aac.KhoiID,
        aac.CreateUser,
        gv.HoGV + ' ' + gv.TenGV                                AS TenGiaoVien,
        CASE WHEN aac.CreateUser = @sys_UserID THEN 1 ELSE 0 END AS IsMyContent,
        -- Chỉ bật thao tác chấm/xem tiến độ khi là chủ bài, BGH hoặc có IsGrade.
        CASE
            WHEN @sys_SystemRight IN (3, 5, 9) OR aac.CreateUser = @sys_UserID THEN 1
            WHEN EXISTS (
                SELECT 1
                FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                WHERE rtp.GiaoVienID = @sys_UserID
                  AND rtp.Enable = 1
                  AND rtp.IsGrade = 1
                  AND (
                        (aac.AssignType = 'CLASS' AND rtp.AssignToClassID = aac.AssignToClassID)
                     OR (aac.AssignType = 'STUDENT' AND rtp.AssignToStudentID = aac.AssignToStudentID)
                     OR (rtp.PermissionScope = 'SUBJECT'
                         AND rtp.MonHocID = aac.MonHocID
                         AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa_HienTai))
                      )
            ) THEN 1
            ELSE 0
        END AS CanGrade

    FROM #AllAssignedContent aac
    JOIN  dbo.tblEL_Assignments   a   ON aac.ResourceID = a.AssignmentID
    -- CLASS submissions
    LEFT JOIN #SubmissionCounts        sc  ON aac.AssignToClassID   = sc.AssignToClassID
                                          AND aac.AssignType = 'CLASS'
    -- STUDENT submissions (thay thế 3 correlated subquery)
    LEFT JOIN #SubmissionCountsStudent scs ON aac.AssignToStudentID = scs.AssignToStudentID
                                          AND aac.AssignType = 'STUDENT'
    -- Sĩ số (chỉ cần cho CLASS)
    LEFT JOIN #StudentCounts           stc ON aac.UnitID = stc.UnitID
                                          AND aac.AssignType = 'CLASS'
    LEFT JOIN tblTuanHocTap            th  ON th.TuanHocID = aac.TuanHocID
    LEFT JOIN dbo.tblGiaoVien          gv  ON gv.GiaoVienID = aac.CreateUser
    WHERE aac.ResourceType = 'ASSIGNMENT'
    ORDER BY aac.UnitID, aac.DueDate DESC;

    -- ============================================================
    -- BẢNG 4: CHI TIẾT BÀI HỌC ĐÃ GIAO
    -- (Không đổi logic, đã JOIN tốt từ đầu)
    -- ============================================================
    SELECT
        aac.UnitID     AS LopID,
        aac.ResourceID AS LessonID,
        aac.AssignToClassID,
        l.Title        AS LessonTitle,
        aac.DueDate,
        aac.TuanHocID,
        N'Tuần '    + CAST(th.Tuan      AS VARCHAR(2))
        + N' - Tháng ' + CAST(th.ThangHoc  AS VARCHAR(2))
        + N' - ('   + FORMAT(th.NgayBatDau,  'dd/MM/yyyy')
        + N' - '    + FORMAT(th.NgayKetThuc, 'dd/MM/yyyy') + ')' AS Tuan_HienThi,
        aac.ResourceType,
        ISNULL(lc.CompletedCount, 0) AS CompletedCount,
        CASE
            WHEN ISNULL(stc.StudentCount, 0) - ISNULL(lc.CompletedCount, 0) < 0 THEN 0
            ELSE ISNULL(stc.StudentCount, 0) - ISNULL(lc.CompletedCount, 0)
        END AS RemainingToComplete,
        ISNULL(stc.StudentCount, 0) AS TotalStudentsInClass,
        CASE
            WHEN th.TuanTrongNam = DATEPART(WEEK, GETDATE()) THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END AS Is_Tuan_Active,
        l.Chuong,
        aac.MonHocID,
        aac.AssignType,
        aac.AssignToStudentID,
        aac.KhoiID,
        aac.CreateUser,
        gv.HoGV + ' ' + gv.TenGV                                AS TenGiaoVien,
        CASE WHEN aac.CreateUser = @sys_UserID THEN 1 ELSE 0 END AS IsMyContent,
        -- Quyền SUBJECT chỉ xem không được mở nút xem tiến độ/chấm bài.
        CASE
            WHEN @sys_SystemRight IN (3, 5, 9) OR aac.CreateUser = @sys_UserID THEN 1
            WHEN EXISTS (
                SELECT 1
                FROM dbo.tblEL_Resoucre_TeacherPermissions rtp
                WHERE rtp.GiaoVienID = @sys_UserID
                  AND rtp.Enable = 1
                  AND rtp.IsGrade = 1
                  AND (
                        (aac.AssignType = 'CLASS' AND rtp.AssignToClassID = aac.AssignToClassID)
                     OR (aac.AssignType = 'STUDENT' AND rtp.AssignToStudentID = aac.AssignToStudentID)
                     OR (rtp.PermissionScope = 'SUBJECT'
                         AND rtp.MonHocID = aac.MonHocID
                         AND (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa_HienTai))
                      )
            ) THEN 1
            ELSE 0
        END AS CanGrade

    FROM #AllAssignedContent aac
    JOIN  dbo.tblEL_Lessons    l   ON aac.ResourceID = l.LessonID
    LEFT JOIN #LearningCounts  lc  ON aac.AssignToClassID = lc.AssignToClassID
    LEFT JOIN #StudentCounts   stc ON aac.UnitID = stc.UnitID
    LEFT JOIN tblTuanHocTap    th  ON th.TuanHocID = aac.TuanHocID
    LEFT JOIN dbo.tblGiaoVien  gv  ON gv.GiaoVienID = aac.CreateUser
    WHERE aac.ResourceType = 'LESSON'
    ORDER BY aac.UnitID, aac.DueDate DESC;

    -- Output GiaoVienID (giữ nguyên như SP gốc)
    SELECT @sys_UserID AS GiaoVienID;

    -- ============================================================
    -- CLEANUP
    -- Explicit DROP giải phóng tempdb ngay, không chờ session kết thúc
    -- ============================================================
    DROP TABLE IF EXISTS #AllTeacher;
    DROP TABLE IF EXISTS #SubjectPermissions;
    DROP TABLE IF EXISTS #CurrentTeacher;
    DROP TABLE IF EXISTS #AllowedCreator;
    DROP TABLE IF EXISTS #MonHocLopIDs;
    DROP TABLE IF EXISTS #TeacherUnits;
    DROP TABLE IF EXISTS #AllAssignedContent;
    DROP TABLE IF EXISTS #SubmissionCounts;
    DROP TABLE IF EXISTS #SubmissionCountsStudent;
    DROP TABLE IF EXISTS #UnitStudents;
    DROP TABLE IF EXISTS #LearningCounts;
    DROP TABLE IF EXISTS #StudentCounts;

END
