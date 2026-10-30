CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetMyResources]
    @sys_UserID VARCHAR(9),
    @MonHocID INT,
    @StatusFilter VARCHAR(20) -- 'ALL', 'COMPLETED', 'INCOMPLETE'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HocSinhID INT = CAST(RIGHT(@sys_UserID, 8) AS INT);
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();

    -- =================================================================================
    -- == BƯỚC CHUẨN BỊ: Lấy tất cả LỚP và NHÓM của học sinh vào bảng tạm           ==
    -- =================================================================================
    DECLARE @MyUnits TABLE (UnitID VARCHAR(10));
    INSERT INTO @MyUnits (UnitID)
    SELECT hsl.LopID FROM dbo.tblHocSinhLop hsl JOIN dbo.tblLop l
        ON hsl.LopID = l.LopID AND hsl.NienKhoa = l.NienKhoa
    WHERE hsl.HocSinhID = @HocSinhID AND hsl.Enable = 1
      AND hsl.NienKhoa = @NienKhoa AND l.NienKhoa = @NienKhoa
    UNION
    SELECT hsn.NhomID FROM dbo.tblHocSinhNhom hsn JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID
    WHERE hsn.HocSinhID = @HocSinhID AND hsn.Enable = 1 AND n.NienKhoa = @NienKhoa;

    -- CTE: Lấy danh sách tất cả các tài nguyên đã được giao cho học sinh
    WITH AssignedResources AS (
        SELECT 
            atc.AssignToClassID,
            atc.ResourceType,
            atc.ResourceID,
            mhl.MonHocID
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
        WHERE mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits)
          AND mhl.NienKhoa = @NienKhoa AND atc.NienKhoa = @NienKhoa
          AND atc.IsDeleted = 0
    )

    SELECT * FROM (
        -- Lấy danh sách BÀI GIẢNG (Lessons)
        SELECT
            ar.AssignToClassID, ar.ResourceType, ar.ResourceID,
            l.Title, l.Description, l.ThumbnailURL,
            mh.MonHocName, mh.MonHocID,
            CAST(ISNULL(lp.IsCompleted, 0) AS BIT) AS IsCompleted,
            lp.LastAccessed
        FROM AssignedResources ar
        JOIN dbo.tblEL_Lessons l ON ar.ResourceID = l.LessonID AND ar.ResourceType = 'LESSON'
        JOIN dbo.tblMonHoc mh ON ar.MonHocID = mh.MonHocID
        LEFT JOIN dbo.tblEL_Learning_Progress lp ON ar.ResourceID = lp.LessonID AND lp.HocSinhID = @HocSinhID
        WHERE l.IsDeleted = 0 AND l.Status = 2

        UNION ALL

        -- Lấy danh sách BÀI TẬP (Assignments)
        SELECT
            ar.AssignToClassID, ar.ResourceType, ar.ResourceID,
            a.Title, a.Instructions AS Description, NULL AS ThumbnailURL,
            mh.MonHocName, mh.MonHocID,
            CAST(CASE WHEN s.SubmissionStatus >= 2 THEN 1 ELSE 0 END AS BIT) AS IsCompleted,
            s.SubmissionTime
        FROM AssignedResources ar
        JOIN dbo.tblEL_Assignments a ON ar.ResourceID = a.AssignmentID AND ar.ResourceType = 'ASSIGNMENT'
        JOIN dbo.tblMonHoc mh ON ar.MonHocID = mh.MonHocID
        LEFT JOIN dbo.tblEL_Submissions s ON ar.AssignToClassID = s.AssignToClassID AND s.HocSinhID = @HocSinhID
        WHERE a.IsDeleted = 0
    ) AS FinalResults
    WHERE
        (@MonHocID = 0 OR FinalResults.MonHocID = @MonHocID)
        AND (@StatusFilter = 'ALL' 
             OR (@StatusFilter = 'COMPLETED' AND IsCompleted = 1)
             OR (@StatusFilter = 'INCOMPLETE' AND IsCompleted = 0)
            )
    ORDER BY 
        LastAccessed DESC;

END
