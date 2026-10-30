CREATE PROC [dbo].[spAPI_EL_Student_Get_NhiemVu_ByHocSinhID]
    @HocSinhID INT,
    @NienKhoa  INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy tất cả Lớp + Nhóm của học sinh trong niên khóa
    DECLARE @MyUnits TABLE (UnitID VARCHAR(100));
    INSERT INTO @MyUnits (UnitID)
    SELECT hsl.LopID
    FROM dbo.tblHocSinhLop hsl
    JOIN dbo.tblLop l ON hsl.LopID = l.LopID AND l.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = @HocSinhID AND hsl.Enable = 1 AND hsl.NienKhoa = @NienKhoa
    UNION
    SELECT hsn.NhomID
    FROM dbo.tblHocSinhNhom hsn
    JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa
    WHERE hsn.HocSinhID = @HocSinhID AND hsn.Enable = 1;

    -- Kết quả
    SELECT *
    FROM (

        -- ===== 1. BÀI TẬP GIAO CHO LỚP (chưa hoàn thành) =====
        SELECT
            'ASSIGNMENT'                        AS ResourceType,
            atc.AssignToClassID                 AS ResourceID,
            asm.Title,
            CAST(atc.DueDate AS DATETIME)       AS DueDate,
            1                                   AS [Priority],
            CAST(1 AS BIT)                      AS Is_SendToClass,
            mh.MonHocID,
            mh.Icon                             AS MonHoc_Icon,
            mh.Color                            AS MonHoc_Color,
            mh.TenMonHoc_HienThi,
            lg.Reason,
            CASE
                WHEN s.SubmissionStatus = 1                                             THEN 'IN_PROGRESS'
                WHEN s.SubmissionStatus = 0 AND ISNULL(lg.Reason, '') <> ''            THEN 'RESUBMIT'
                WHEN atc.DueDate < GETDATE()                                            THEN 'OVERDUE'
                ELSE 'NOT_STARTED'
            END                                 AS [Status],
            asm.TuanHocID,
            'mdi-pencil-box-outline'            AS Icon,
            'blue'                              AS Color,
            ISNULL(s.LanNop, 1)                 AS LanNop,
            ISNULL(gv.HoGV + ' ' + gv.TenGV, N'Giáo viên') AS HoTenNguoiGiao
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblEL_Assignments asm
            ON asm.AssignmentID = atc.ResourceID
            AND atc.ResourceType = 'ASSIGNMENT'
            AND asm.IsDeleted = 0
            AND ISNULL(asm.IsDev, 0) <> 1
        JOIN dbo.tblMonHocLop mhl
            ON mhl.MonHocLopID = atc.MonHocLopID
            AND mhl.NienKhoa = @NienKhoa
        JOIN dbo.tblMonHoc mh
            ON mh.MonHocID = ISNULL(asm.MonHocID, mhl.MonHocID)
            AND mh.Enable = 1
        LEFT JOIN dbo.tblGiaoVien gv
            ON gv.GiaoVienID = atc.CreateUser
        OUTER APPLY (
            -- Một task chỉ đại diện lượt mới nhất; không join lẫn lượt đã chấm.
            SELECT TOP 1 SubmissionID, SubmissionStatus, Log_ChamBaiID, LanNop
            FROM dbo.tblEL_Submissions
            WHERE AssignToClassID = atc.AssignToClassID
              AND HocSinhID = @HocSinhID
              AND IsDeleted = 0
            ORDER BY ISNULL(LanNop, 1) DESC, SubmissionID DESC
        ) s
        LEFT JOIN dbo.tblEL_Log_ChamBai lg
            ON lg.Log_ChamBaiID = s.Log_ChamBaiID
        WHERE atc.IsDeleted = 0
          AND atc.Status IN (1, 2)
          AND atc.MonHocLopID IN (
              SELECT MonHocLopID FROM dbo.tblMonHocLop
              WHERE LopNhomID IN (SELECT UnitID FROM @MyUnits)
                AND NienKhoa = @NienKhoa
          )
          -- Nhiệm vụ chỉ phục vụ lượt hoàn thành đầu tiên. Khi đã nộp/chấm
          -- bất kỳ lượt nào, việc làm lại được mở từ Hoạt động, không hiện lại ở đây.
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.tblEL_Submissions completed_submission
              WHERE completed_submission.AssignToClassID = atc.AssignToClassID
                AND completed_submission.HocSinhID = @HocSinhID
                AND completed_submission.IsDeleted = 0
                AND completed_submission.SubmissionStatus >= 2
          )
          AND (s.SubmissionID IS NULL OR s.SubmissionStatus < 2)

        UNION ALL

        -- ===== 2. BÀI TẬP GIAO RIÊNG HỌC SINH (chưa hoàn thành) =====
        SELECT
            'ASSIGNMENT'                        AS ResourceType,
            ats.AssignToStudentID               AS ResourceID,
            asm.Title,
            CAST(ats.DueDate AS DATETIME)       AS DueDate,
            1                                   AS [Priority],
            CAST(0 AS BIT)                      AS Is_SendToClass,
            mh.MonHocID,
            mh.Icon                             AS MonHoc_Icon,
            mh.Color                            AS MonHoc_Color,
            mh.TenMonHoc_HienThi,
            lg.Reason,
            CASE
                WHEN s.SubmissionStatus = 1                                             THEN 'IN_PROGRESS'
                WHEN s.SubmissionStatus = 0 AND ISNULL(lg.Reason, '') <> ''            THEN 'RESUBMIT'
                WHEN ats.DueDate < GETDATE()                                            THEN 'OVERDUE'
                ELSE 'NOT_STARTED'
            END                                 AS [Status],
            asm.TuanHocID,
            'mdi-pencil-box-outline'            AS Icon,
            'blue'                              AS Color,
            ISNULL(s.LanNop, 1)                 AS LanNop,
            ISNULL(gv.HoGV + ' ' + gv.TenGV, N'Giáo viên') AS HoTenNguoiGiao
        FROM dbo.tblEL_AssignToStudent ats
        JOIN dbo.tblEL_Assignments asm
            ON asm.AssignmentID = ats.ResourceID
            AND ats.ResourceType = 'ASSIGNMENT'
            AND asm.IsDeleted = 0
            AND ISNULL(asm.IsDev, 0) <> 1
        JOIN dbo.tblMonHocLop mhl
            ON mhl.MonHocLopID = ats.MonHocLopID
            AND mhl.NienKhoa = @NienKhoa
        JOIN dbo.tblMonHoc mh
            ON mh.MonHocID = ISNULL(asm.MonHocID, mhl.MonHocID)
            AND mh.Enable = 1
        LEFT JOIN dbo.tblGiaoVien gv
            ON gv.GiaoVienID = ats.CreateUser
        OUTER APPLY (
            -- Một task chỉ đại diện lượt mới nhất; không join lẫn lượt đã chấm.
            SELECT TOP 1 SubmissionID, SubmissionStatus, Log_ChamBaiID, LanNop
            FROM dbo.tblEL_Submissions
            WHERE AssignToStudentID = ats.AssignToStudentID
              AND HocSinhID = @HocSinhID
              AND IsDeleted = 0
            ORDER BY ISNULL(LanNop, 1) DESC, SubmissionID DESC
        ) s
        LEFT JOIN dbo.tblEL_Log_ChamBai lg
            ON lg.Log_ChamBaiID = s.Log_ChamBaiID
        WHERE ats.IsDeleted = 0
          AND ats.Status IN (1, 2)
          AND ats.HocSinhID = @HocSinhID
          AND (ats.NienKhoa IS NULL OR ats.NienKhoa = @NienKhoa)
          -- Nhiệm vụ chỉ phục vụ lượt hoàn thành đầu tiên. Khi đã nộp/chấm
          -- bất kỳ lượt nào, việc làm lại được mở từ Hoạt động, không hiện lại ở đây.
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.tblEL_Submissions completed_submission
              WHERE completed_submission.AssignToStudentID = ats.AssignToStudentID
                AND completed_submission.HocSinhID = @HocSinhID
                AND completed_submission.IsDeleted = 0
                AND completed_submission.SubmissionStatus >= 2
          )
          AND (s.SubmissionID IS NULL OR s.SubmissionStatus < 2)

        UNION ALL

        -- ===== 3. BÀI HỌC (chưa hoàn thành) =====
        SELECT
            'LESSON'                            AS ResourceType,
            atc.AssignToClassID                 AS ResourceID,
            ls.Title,
            CAST(atc.DueDate AS DATETIME)       AS DueDate,
            2                                   AS [Priority],
            CAST(1 AS BIT)                      AS Is_SendToClass,
            mh.MonHocID,
            mh.Icon                             AS MonHoc_Icon,
            mh.Color                            AS MonHoc_Color,
            mh.TenMonHoc_HienThi,
            NULL                                AS Reason,
            CASE
                WHEN lp.ProgressID IS NOT NULL AND lp.IsCompleted = 0  THEN 'IN_PROGRESS'
                ELSE 'NOT_STARTED'
            END                                 AS [Status],
            ls.TuanHocID,
            'mdi-book-open-page-variant'        AS Icon,
            'green'                             AS Color,
            NULL                                AS LanNop,
            ISNULL(gv.HoGV + ' ' + gv.TenGV, N'Giáo viên') AS HoTenNguoiGiao
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblEL_Lessons ls
            ON ls.LessonID = atc.ResourceID
            AND atc.ResourceType = 'LESSON'
            AND ls.IsDeleted = 0
            AND ISNULL(ls.IsDev, 0) <> 1
        JOIN dbo.tblMonHoc mh
            ON mh.MonHocID = ls.MonHocID
            AND mh.Enable = 1
        LEFT JOIN dbo.tblGiaoVien gv
            ON gv.GiaoVienID = ls.CreateUser
        LEFT JOIN dbo.tblEL_Learning_Progress lp
            ON lp.LessonID = ls.LessonID
            AND lp.HocSinhID = @HocSinhID
            AND lp.IsDeleted = 0
        WHERE atc.IsDeleted = 0
          AND atc.Status IN (1, 2)
          AND atc.MonHocLopID IN (
              SELECT MonHocLopID FROM dbo.tblMonHocLop
              WHERE LopNhomID IN (SELECT UnitID FROM @MyUnits)
                AND NienKhoa = @NienKhoa
          )
          -- Loại trừ bài học đã hoàn thành
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.tblEL_Learning_Progress clp
              WHERE clp.LessonID = ls.LessonID
                AND clp.HocSinhID = @HocSinhID
                AND clp.IsCompleted = 1
                AND clp.IsDeleted = 0
          )
          AND (lp.ProgressID IS NULL OR lp.IsCompleted = 0)

    ) AS Tasks
    ORDER BY
        [Priority] ASC,
        CASE WHEN [Status] = 'OVERDUE' THEN 0 ELSE 1 END ASC,
        DueDate ASC;
END;
