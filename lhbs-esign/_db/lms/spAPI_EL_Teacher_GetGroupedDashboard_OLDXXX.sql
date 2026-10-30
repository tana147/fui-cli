

CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetGroupedDashboard_OLDXXX] --'NV0001225'
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET @sys_UserID = 'NV0000244'
    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();
	set @NienKhoa_HienTai = 2025

    -- Bước 1: Khai báo và đổ dữ liệu vào các bảng tạm (logic này không đổi)
    DECLARE @TeacherClasses TABLE (LopID VARCHAR(10), KhoiID INT, MonHocID INT);
    DECLARE @TeacherAssignments TABLE (AssignToClassID BIGINT, TuanHocID INT, LopID VARCHAR(10), AssignmentID INT, AssignmentTitle NVARCHAR(255), DueDate DATETIME, KhoiID INT, MonHocID INT, ResourceType NVARCHAR(10));
    DECLARE @SubmissionCounts TABLE (AssignToClassID BIGINT, SubmittedCount INT, PendingGradingCount INT, GradedCount INT);

	DECLARE @TeacherLessons TABLE (AssignToClassID BIGINT,TuanHocID INT, LopID VARCHAR(10), AssignmentID INT, AssignmentTitle NVARCHAR(255), DueDate DATETIME, KhoiID INT, MonHocID INT, ResourceType NVARCHAR(10));
	DECLARE @LearnningCounts TABLE (AssignToClassID BIGINT, CompletedCount INT, LearningCount INT);

    DECLARE @ClassStudentCounts TABLE (LopID VARCHAR(10), StudentCount INT);

    INSERT INTO @TeacherClasses (LopID, KhoiID, MonHocID)
    SELECT DISTINCT gvl.LopID, l.KhoiID, gvl.MonHocID
		FROM dbo.tblGiaoVienLop gvl JOIN dbo.tblLop l ON gvl.LopID = l.LopID AND l.NienKhoa = @NienKhoa_HienTai
		WHERE gvl.GiaoVienID = @sys_UserID 
				AND gvl.NienKhoa = @NienKhoa_HienTai 
				AND gvl.Enable = 1;
	-- Nạp thêm dữ liệu từ NHÓM
	INSERT INTO @TeacherClasses (LopID, KhoiID, MonHocID)
	SELECT DISTINCT gvl.LopID, n.KhoiID, gvl.MonHocID
	FROM dbo.tblGiaoVienLop gvl JOIN dbo.tblNhom n ON gvl.LopID = n.NhomID AND n.NienKhoa = @NienKhoa_HienTai
	WHERE gvl.GiaoVienID = @sys_UserID 
		  AND gvl.NienKhoa = @NienKhoa_HienTai 
		  AND gvl.Enable = 1
		  -- Đảm bảo không nạp trùng lặp nếu đã có trong bảng tạm
		  AND gvl.LopID NOT IN (SELECT LopID FROM @TeacherClasses);

    INSERT INTO @TeacherAssignments (AssignToClassID, TuanHocID,LopID, AssignmentID, AssignmentTitle, DueDate, KhoiID, MonHocID, ResourceType)
    SELECT atc.AssignToClassID, a.TuanHocID , mhl.LopNhomID ,a.AssignmentID, a.Title, atc.DueDate, tc.KhoiID, tc.MonHocID, atc.ResourceType
    FROM dbo.tblEL_AssignToClass atc
		JOIN dbo.tblEL_Assignments a ON atc.AssignmentID = a.AssignmentID 
		JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID and mhl.Enable = 1
		JOIN @TeacherClasses tc ON mhl.LopNhomID = tc.LopID AND mhl.MonHocID = tc.MonHocID
    WHERE atc.IsDeleted = 0 AND a.IsDeleted = 0 and atc.ResourceType = 'ASSIGNMENT';

    INSERT INTO @SubmissionCounts (AssignToClassID, SubmittedCount, PendingGradingCount, GradedCount)
    SELECT s.AssignToClassID, 
			SUM(CASE WHEN s.SubmissionStatus >=2 THEN 1 ELSE 0 END),
			SUM(CASE WHEN s.SubmissionStatus = 2 THEN 1 ELSE 0 END), 
			SUM(CASE WHEN s.SubmissionStatus = 4 THEN 1 ELSE 0 END)
	FROM dbo.tblEL_Submissions s
		WHERE s.AssignToClassID IN (SELECT AssignToClassID FROM @TeacherAssignments) 
		GROUP BY s.AssignToClassID;

    INSERT INTO @ClassStudentCounts (LopID, StudentCount)
    SELECT ID, COUNT(HocSinhID) AS StudentCount
	FROM (
		-- Lấy học sinh từ Lớp
		SELECT LopID AS ID, HocSinhID 
		FROM dbo.tblHocSinhLop 
		WHERE Enable = 1 AND LopID IN (SELECT LopID FROM @TeacherClasses)
    
		UNION ALL
    
		-- Lấy học sinh từ Nhóm
		SELECT NhomID AS ID, HocSinhID 
		FROM dbo.tblHocSinhNhom 
		WHERE Enable = 1 AND NhomID IN (SELECT LopID FROM @TeacherClasses)
	) AS AllStudents
	GROUP BY ID;


	INSERT INTO @TeacherLessons (AssignToClassID, TuanHocID, LopID, AssignmentID, AssignmentTitle, DueDate, KhoiID, MonHocID,ResourceType)
    SELECT atc.AssignToClassID, a.TuanHocID , mhl.LopNhomID, a.LessonID AS AssignmentID, a.Title, atc.DueDate, tc.KhoiID, tc.MonHocID, atc.ResourceType
	FROM dbo.tblEL_AssignToClass atc
			JOIN dbo.tblEL_Lessons a ON atc.ResourceID = a.LessonID
			JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID and mhl.Enable = 1
			JOIN @TeacherClasses tc ON mhl.LopNhomID = tc.LopID AND mhl.MonHocID = tc.MonHocID
	WHERE atc.IsDeleted = 0 AND a.IsDeleted = 0 AND atc.ResourceType = 'LESSON'; ;

	INSERT INTO @LearnningCounts (AssignToClassID,  CompletedCount , LearningCount )
    SELECT a.AssignToClassID, 
		SUM(CASE WHEN s.IsCompleted = 1 THEN 1 ELSE 0 END),
		SUM(CASE WHEN s.IsCompleted = 0 THEN 1 ELSE 0 END)
    FROM [dbo].[tblEL_Learning_Progress] s
		INNER JOIN [dbo].[tblEL_AssignToClass] a ON s.LessonID = a.AssignmentID
    WHERE a.AssignToClassID IN (SELECT AssignToClassID FROM @TeacherLessons) 
    GROUP BY a.AssignToClassID;

    -- === BẢNG 1: TRẢ VỀ DỮ LIỆU TỔNG HỢP  ===
    -- Bắt đầu từ danh sách tất cả các nhóm được phân công, sau đó LEFT JOIN để lấy số liệu
    SELECT
        Groups.KhoiID,
        k.TenKhoiHoc AS TenKhoi,
        Groups.MonHocID,
        mh.MonHocName,
        SUM(ISNULL(sc.PendingGradingCount, 0)) AS TotalPendingGradingCount
    FROM (SELECT DISTINCT KhoiID, MonHocID FROM @TeacherClasses) AS Groups -- Lấy danh sách nhóm duy nhất từ phân công
		LEFT JOIN  @TeacherAssignments ta ON Groups.KhoiID = ta.KhoiID AND Groups.MonHocID = ta.MonHocID
		LEFT JOIN  @SubmissionCounts sc ON ta.AssignToClassID = sc.AssignToClassID
		JOIN  dbo.tblMonHoc mh ON Groups.MonHocID = mh.MonHocID
		LEFT JOIN dbo.tblKhoi k ON Groups.KhoiID = k.KhoiID
    GROUP BY 
        Groups.KhoiID, k.TenKhoiHoc, Groups.MonHocID, mh.MonHocName
    ORDER BY 
        Groups.KhoiID, mh.MonHocName;


    -- === BẢNG 2: TRẢ VỀ DỮ LIỆU CHI TIẾT CỦA TỪNG LỚP (logic này đã đúng) ===
    SELECT
		tc.LopID,
		COALESCE(l.TenLop, n.TenNhom) AS TenLop, 
		tc.KhoiID,
		tc.MonHocID,
		ISNULL(SUM(sc.PendingGradingCount), 0) AS PendingGradingCountInClass,
		ISNULL(csc.StudentCount, 0) AS StudentCount
	FROM @TeacherClasses tc
	LEFT JOIN @TeacherAssignments ta ON tc.LopID = ta.LopID AND tc.MonHocID = ta.MonHocID
	LEFT JOIN @SubmissionCounts sc ON ta.AssignToClassID = sc.AssignToClassID
	LEFT JOIN @ClassStudentCounts csc ON tc.LopID = csc.LopID
	LEFT JOIN dbo.tblLop l ON tc.LopID = l.LopID AND l.NienKhoa = @NienKhoa_HienTai
	LEFT JOIN dbo.tblNhom n ON tc.LopID = n.NhomID AND n.NienKhoa = @NienKhoa_HienTai
	GROUP BY tc.LopID, COALESCE(l.TenLop, n.TenNhom), tc.KhoiID, tc.MonHocID, csc.StudentCount
	ORDER BY TenLop;

    -- === BẢNG 3: TRẢ VỀ DỮ LIỆU CHI TIẾT CỦA TỪNG BÀI TẬP ĐÃ GIAO (logic này đã đúng) ===
    SELECT
        ta.LopID,
        ta.AssignmentID,
        ta.AssignToClassID,
        ta.AssignmentTitle,
        ta.DueDate,
        ta.TuanHocID,
         N'Tuần ' + CAST(th.TuanTrongNam AS NVARCHAR(10)) 
        + N' - Tháng ' + CAST(th.ThangHoc AS NVARCHAR(10)) 
        + N' - Năm ' + CAST(th.NienKhoa AS NVARCHAR(10)) AS Tuan_HienThi,
        ta.ResourceType,
        ISNULL(sc.SubmittedCount, 0) AS SubmittedCount,
        ISNULL(sc.PendingGradingCount, 0) AS PendingGradingCount,
        ISNULL(sc.GradedCount, 0) AS GradedCount,
        ISNULL(csc.StudentCount, 0) AS TotalStudentsInClass
    FROM @TeacherAssignments ta
    LEFT JOIN @SubmissionCounts sc ON ta.AssignToClassID = sc.AssignToClassID
    LEFT JOIN @ClassStudentCounts csc ON ta.LopID = csc.LopID
    LEFT JOIN tblTuanHocTap th on th.TuanHocID = ta.TuanHocID

    ORDER BY ta.LopID, ta.DueDate DESC;

	-- === BẢNG 4: LÂY DATA LESSON DA GIAO ===

	  SELECT
        ta.LopID,
        ta.AssignmentID,
        ta.AssignToClassID,
        ta.AssignmentTitle,
        ta.DueDate,
        ta.TuanHocID,
        N'Tuần ' + CAST(th.TuanTrongNam AS NVARCHAR(10)) 
        + N' - Tháng ' + CAST(th.ThangHoc AS NVARCHAR(10)) 
        + N' - Năm ' + CAST(th.NienKhoa AS NVARCHAR(10)) AS Tuan_HienThi,
        ta.ResourceType,
        ISNULL(sc.CompletedCount, 0) AS CompletedCount,
        ISNULL(sc.LearningCount, 0) AS LearningCount,
        ISNULL(csc.StudentCount, 0) AS TotalStudentsInClass
    FROM @TeacherLessons ta
    LEFT JOIN @LearnningCounts sc ON ta.AssignToClassID = sc.AssignToClassID
    LEFT JOIN @ClassStudentCounts csc ON ta.LopID = csc.LopID
    LEFT JOIN tblTuanHocTap th on th.TuanHocID = ta.TuanHocID
    ORDER BY  ta.LopID, ta.DueDate DESC;
	
END
