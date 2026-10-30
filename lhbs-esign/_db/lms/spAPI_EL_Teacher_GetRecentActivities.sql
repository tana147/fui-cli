CREATE   PROCEDURE [dbo].[spAPI_EL_Teacher_GetRecentActivities] --''
    @sys_UserID VARCHAR(9),
    @LopID VARCHAR(10),
    @MonHocID INT,
    @PageSize INT,
	@HocKi INT,
	@NienKhoa INT
AS
BEGIN
	IF @NienKhoa IS NULL
	BEGIN
		RAISERROR(N'Niên khóa là bắt buộc để xác định đúng lớp.', 16, 1)
		RETURN
	END
	SET @PageSize = COALESCE(NULLIF(@PageSize, 0), 15)
	SET @sys_UserID =  dbo.fn_GetUser_LMS(@sys_UserID)
	DECLARE @NienKhoa_HienTai INT = @NienKhoa;

    -- Bước 1: Lấy ID của TẤT CẢ học sinh mà giáo viên này dạy vào một bảng tạm.
    DECLARE @MyStudentIDs TABLE (HocSinhID INT);
    INSERT INTO @MyStudentIDs (HocSinhID)
    SELECT DISTINCT hsl.HocSinhID
    FROM dbo.tblGiaoVienLop gvl
    INNER JOIN dbo.tblHocSinhLop hsl ON gvl.LopID = hsl.LopID AND gvl.NienKhoa = hsl.NienKhoa
    INNER JOIN dbo.tblLop l ON l.LopID = hsl.LopID AND l.NienKhoa = hsl.NienKhoa
    WHERE gvl.GiaoVienID = @sys_UserID
      AND gvl.NienKhoa = @NienKhoa_HienTai
      AND gvl.Enable = 1
      AND gvl.HocKy = @HocKi
      AND hsl.Enable = 1
    UNION
    SELECT DISTINCT hsn.HocSinhID
    FROM dbo.tblGiaoVienLop gvl
    INNER JOIN dbo.tblHocSinhNhom hsn ON gvl.LopID = hsn.NhomID
    INNER JOIN dbo.tblNhom n ON n.NhomID = hsn.NhomID AND n.NienKhoa = gvl.NienKhoa
    WHERE gvl.GiaoVienID = @sys_UserID
      AND gvl.NienKhoa = @NienKhoa_HienTai
      AND gvl.Enable = 1
      AND gvl.HocKy = @HocKi
      AND hsn.Enable = 1;

    -- Bước 2: Dùng CTE để lấy và làm giàu dữ liệu hoạt động từ các học sinh ở trên
    ;WITH RecentActivities AS (
        SELECT TOP (100) -- Lấy một lượng lớn hơn để lọc sau, tránh lấy toàn bộ bảng log
            al.ActivityID,
            al.CreateTime,
            al.HocSinhID,
            al.ActivityType,
            al.ResourceType,
            al.ResourceID
        FROM dbo.tblEL_Activity_Logs al
		INNER JOIN dbo.tblEL_Assignments ass on ass.AssignmentID = al.ResourceID and ass.CreateUser = @sys_UserID and ass.IsDeleted = 0 --Mẫn thêm join ngày 09/09/2025
        WHERE al.HocSinhID IN (SELECT HocSinhID FROM @MyStudentIDs) and al.IsDeleted = 0
        ORDER BY al.CreateTime DESC
    )
    -- Bước 3: Join và lọc để lấy ra N kết quả cuối cùng
    SELECT TOP (@PageSize)
        ra.ActivityID,
        ra.CreateTime AS Timestamp,
        hs.Ho + ' ' + hs.Ten AS StudentName,
        
        -- Dùng subquery để lấy Tên Lớp/Nhóm của học sinh tại thời điểm hoạt động
        COALESCE(
            (SELECT TOP 1 l.TenLop
             FROM dbo.tblHocSinhLop hsl
             INNER JOIN dbo.tblLop l ON l.LopID = hsl.LopID AND l.NienKhoa = hsl.NienKhoa
             WHERE hsl.HocSinhID = ra.HocSinhID AND hsl.Enable = 1 AND hsl.NienKhoa = @NienKhoa_HienTai),
            (SELECT TOP 1 n.TenNhom
             FROM dbo.tblHocSinhNhom hsn
             INNER JOIN dbo.tblNhom n ON n.NhomID = hsn.NhomID
             WHERE hsn.HocSinhID = ra.HocSinhID AND hsn.Enable = 1 AND n.NienKhoa = @NienKhoa_HienTai)
        ) AS ClassName,
        
        ra.ActivityType,
        
        -- Dùng subquery để lấy Tên tài nguyên
        CASE 
            WHEN ra.ResourceType = 'ASSIGNMENT' THEN (SELECT Title FROM dbo.tblEL_Assignments WHERE AssignmentID = ra.ResourceID)
            WHEN ra.ResourceType = 'LESSON' THEN (SELECT Title FROM dbo.tblEL_Lessons WHERE LessonID = ra.ResourceID)
            WHEN ra.ResourceType = 'SUBMISSION' THEN (
                SELECT a.Title 
                FROM dbo.tblEL_Submissions s
                JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID and atc.IsDeleted = 0
                JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
                WHERE s.SubmissionID = ra.ResourceID and s.IsDeleted = 0
            )
            ELSE NULL
        END AS ResourceTitle,
        
        -- Dùng subquery để lấy Tên Môn học
        (SELECT TOP 1 mh.MonHocName 
         FROM tblEL_AssignToClass atc 
         JOIN tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
         JOIN tblMonHoc mh ON mhl.MonHocID = mh.MonHocID
         WHERE (atc.ResourceID = ra.ResourceID AND atc.ResourceType = ra.ResourceType and atc.IsDeleted = 0)
            OR atc.AssignToClassID = (SELECT AssignToClassID FROM tblEL_Submissions WHERE IsDeleted = 0 and  SubmissionID = ra.ResourceID AND ra.ResourceType = 'SUBMISSION')
        )  AS MonHocName,
        
        -- Lấy các ID để lọc
        (SELECT TOP 1 mhl.LopNhomID 
         FROM tblEL_AssignToClass atc 
         JOIN tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
         WHERE (atc.ResourceID = ra.ResourceID AND atc.ResourceType = ra.ResourceType and atc.IsDeleted = 0)
            OR atc.AssignToClassID = (SELECT AssignToClassID FROM tblEL_Submissions WHERE IsDeleted = 0 and  SubmissionID = ra.ResourceID AND ra.ResourceType = 'SUBMISSION')
        ) AS LopNhomID_Filter,
        (SELECT TOP 1 mhl.MonHocID 
         FROM tblEL_AssignToClass atc 
         JOIN tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
         WHERE (atc.ResourceID = ra.ResourceID AND atc.ResourceType = ra.ResourceType and atc.IsDeleted = 0)
            OR atc.AssignToClassID = (SELECT AssignToClassID FROM tblEL_Submissions WHERE IsDeleted = 0 and SubmissionID = ra.ResourceID AND ra.ResourceType = 'SUBMISSION')
        ) AS MonHocID_Filter,
        
        NULL AS AvatarURL

    FROM RecentActivities ra
    JOIN dbo.tblHocSinh hs ON ra.HocSinhID = hs.HocSinhID
    WHERE
        -- Áp dụng bộ lọc
        (@LopID IS NULL OR (
            SELECT TOP 1 mhl.LopNhomID 
            FROM tblEL_AssignToClass atc JOIN tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
            WHERE (atc.ResourceID = ra.ResourceID AND atc.ResourceType = ra.ResourceType and atc.IsDeleted = 0)
               OR atc.AssignToClassID = (SELECT AssignToClassID FROM tblEL_Submissions WHERE IsDeleted = 0 and SubmissionID = ra.ResourceID AND ra.ResourceType = 'SUBMISSION')
        ) = @LopID)
        AND
        (@MonHocID IS NULL OR (
            SELECT TOP 1 mhl.MonHocID 
            FROM tblEL_AssignToClass atc JOIN tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
            WHERE (atc.ResourceID = ra.ResourceID AND atc.ResourceType = ra.ResourceType and atc.IsDeleted = 0)
               OR atc.AssignToClassID = (SELECT AssignToClassID FROM tblEL_Submissions WHERE IsDeleted = 0 and SubmissionID = ra.ResourceID AND ra.ResourceType = 'SUBMISSION')
        ) = @MonHocID)
    ORDER BY
        ra.CreateTime DESC;

END

