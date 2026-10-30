 -- [dbo].[spAPI_EL_Teacher_GetAssignmentStatusByClass]    29,'LESSON', 'NV0000244'
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentStatusByClass]   
    @AssignmentID INT,
    @ResourceType NVARCHAR(20),
    @sys_UserID VARCHAR(9),
	@sys_SystemRight int
AS
BEGIN
 
   select @sys_UserID  = SYS_USERID from 
    [dbo].[Table_GetUser_LMS](@sys_UserID, @sys_SystemRight)

    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();

    -- === LOGIC PHÂN QUYỀN ===
   IF @ResourceType = 'ASSIGNMENT'
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tblEL_Assignments
            WHERE AssignmentID = @AssignmentID
              AND CreateUser = @sys_UserID
        )
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.tblEL_AssignToClass atc
            INNER JOIN dbo.tblEL_Resoucre_TeacherPermissions tp
                ON tp.AssignToClassID = atc.AssignToClassID
               AND tp.GiaoVienID = @sys_UserID
               AND tp.Enable = 1
               AND (tp.IsEdit = 1 OR tp.IsGrade = 1)
            WHERE (atc.AssignmentID = @AssignmentID OR atc.ResourceID = @AssignmentID)
              AND atc.ResourceType = 'ASSIGNMENT'
              AND atc.IsDeleted = 0
        )
        BEGIN
            RAISERROR(N'[Unauthorized] Bạn không có quyền xem thông tin bài tập này.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @ResourceType = 'LESSON'
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tblEL_Lessons
            WHERE LessonID = @AssignmentID 
              AND CreateUser = @sys_UserID
        )
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.tblEL_AssignToClass atc
            INNER JOIN dbo.tblEL_Resoucre_TeacherPermissions tp
                ON tp.AssignToClassID = atc.AssignToClassID
               AND tp.GiaoVienID = @sys_UserID
               AND tp.Enable = 1
               AND (tp.IsEdit = 1 OR tp.IsGrade = 1)
            WHERE (atc.AssignmentID = @AssignmentID OR atc.ResourceID = @AssignmentID)
              AND atc.ResourceType = 'LESSON'
              AND atc.IsDeleted = 0
        )
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.tblEL_Lessons l
            INNER JOIN dbo.tblEL_Resoucre_TeacherPermissions tp
                ON tp.GiaoVienID = @sys_UserID
               AND tp.Enable = 1
               AND tp.PermissionScope = 'SUBJECT'
               AND tp.MonHocID = l.MonHocID
               AND (tp.NienKhoa IS NULL OR tp.NienKhoa = l.NienKhoa)
            WHERE l.LessonID = @AssignmentID
              AND l.IsDeleted = 0
        )
        BEGIN
            RAISERROR(N'[Unauthorized] Bạn không có quyền xem thông tin bài giảng này.', 16, 1);
            RETURN;
        END
    END
    ELSE
    BEGIN
        RAISERROR(N'ResourceType không hợp lệ.', 16, 1);
        RETURN;
    END

    -- === LOGIC TRẢ DỮ LIỆU ===
    IF @ResourceType = 'ASSIGNMENT'
    BEGIN
        WITH ClassSubmissions AS (
            SELECT 
                AssignToClassID,
                COUNT(SubmissionID) AS SubmittedCount
            FROM dbo.tblEL_Submissions
            WHERE IsDeleted = 0 AND SubmissionStatus >= 2
            GROUP BY AssignToClassID
        ),
        -- Dùng CTE để đếm sĩ số của cả Lớp và Nhóm
        UnitStudentCounts AS (
            SELECT ID, COUNT(HocSinhID) AS StudentCount FROM (
                SELECT LopID AS ID, HocSinhID FROM dbo.tblHocSinhLop WHERE Enable = 1 AND NienKhoa = @NienKhoa
                UNION ALL
                SELECT hsn.NhomID AS ID, hsn.HocSinhID 
                FROM dbo.tblHocSinhNhom hsn
                JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa
                WHERE hsn.Enable = 1
            ) AS AllStudents
            GROUP BY ID
        )
        -- Câu lệnh SELECT chính
        SELECT 
            atc.AssignToClassID,
            atc.MonHocLopID,
            COALESCE(l.TenLop, n.TenNhom) AS TenLop,
            atc.DueDate,
            ISNULL(usc.StudentCount, 0) AS TotalStudents, 
            ISNULL(cs.SubmittedCount, 0) AS SubmittedCount
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
        LEFT JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID AND l.NienKhoa = @NienKhoa
        LEFT JOIN dbo.tblNhom n ON mhl.LopNhomID = n.NhomID AND n.NienKhoa = @NienKhoa
        -- Join với các CTE đã tính toán
        LEFT JOIN ClassSubmissions cs ON atc.AssignToClassID = cs.AssignToClassID
        LEFT JOIN UnitStudentCounts usc ON mhl.LopNhomID = usc.ID
        WHERE 
            atc.ResourceID = @AssignmentID 
            AND atc.ResourceType = 'ASSIGNMENT'
            AND atc.IsDeleted = 0
            AND COALESCE(l.LopID, n.NhomID) IS NOT NULL 
        ORDER BY
            TenLop;
    END
    ELSE IF @ResourceType = 'LESSON'
BEGIN
    WITH UnitStudentCounts AS (
        SELECT ID, COUNT(HocSinhID) AS StudentCount
        FROM (
            SELECT LopID AS ID, HocSinhID 
            FROM dbo.tblHocSinhLop WHERE Enable = 1 AND NienKhoa = @NienKhoa
            UNION ALL
            SELECT hsn.NhomID AS ID, hsn.HocSinhID 
            FROM dbo.tblHocSinhNhom hsn
            JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa
            WHERE hsn.Enable = 1
        ) AS AllStudents
        GROUP BY ID
    ),
    LessonCompletions AS (
        SELECT 
            atc.AssignToClassID,
            COUNT(DISTINCT lp.HocSinhID) AS CompletedCount
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblEL_Learning_Progress lp 
            ON lp.LessonID = atc.ResourceID 
           AND lp.IsCompleted = 1
        WHERE atc.ResourceType = 'LESSON'
        GROUP BY atc.AssignToClassID
    )
    SELECT 
        atc.AssignToClassID,
        atc.MonHocLopID,
        COALESCE(l.TenLop, n.TenNhom) AS TenLop,
        atc.DueDate,
        ISNULL(usc.StudentCount, 0) AS TotalStudents, 
        ISNULL(lc.CompletedCount, 0) AS CompletedCount,
        ISNULL(usc.StudentCount-lc.CompletedCount , 0)  As NotSeen
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    LEFT JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID AND l.NienKhoa = @NienKhoa
    LEFT JOIN dbo.tblNhom n ON mhl.LopNhomID = n.NhomID AND n.NienKhoa = @NienKhoa
    LEFT JOIN UnitStudentCounts usc ON mhl.LopNhomID = usc.ID
    LEFT JOIN LessonCompletions lc ON atc.AssignToClassID = lc.AssignToClassID
    WHERE 
        atc.ResourceID = @AssignmentID
        AND atc.ResourceType = 'LESSON'
        AND atc.IsDeleted = 0
        AND COALESCE(l.LopID, n.NhomID) IS NOT NULL 
    ORDER BY TenLop;
END

END
