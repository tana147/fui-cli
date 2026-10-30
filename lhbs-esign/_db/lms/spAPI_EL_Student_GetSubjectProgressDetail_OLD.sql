-- FILE: spAPI_EL_Student_GetSubjectProgressDetail.sql
-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Create date:    2025-08-16
-- Description:    Lấy dữ liệu chi tiết tiến độ của một học sinh cho một môn học cụ thể.
--                 Trả về 2 bảng: Thống kê tổng quan và Danh sách tài nguyên chi tiết.
-- API Endpoint:   POST lms/el_student_getsubjectprogressdetail
-- Ví dụ Body:     { "MonHocID": 1 }
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetSubjectProgressDetail_OLD] -- 74, ''
    @MonHocID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HocSinhID INT = CAST(RIGHT(@sys_UserID,8) AS INT);
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
    DECLARE @LopID VARCHAR(10);

    -- Xác định LopID hiện tại của học sinh
    SELECT TOP 1 @LopID = hsl.LopID 
	FROM dbo.tblHocSinhLop hsl 
	inner join tblLop l on hsl.LopID = l.LopID
    WHERE HocSinhID = @HocSinhID AND l.NienKhoa = @NienKhoa AND hsl.Enable = 1;


    IF @LopID IS NULL
    BEGIN
        -- Trả về tập rỗng nếu không tìm thấy lớp của học sinh
        SELECT 0 AS TotalResources, 0 AS CompletedResources, NULL AS TeacherName, NULL AS MonHocName;
        SELECT * FROM (VALUES (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)) AS Empty(ResourceType, ResourceID, Title, Tuan, Chuong, StudentStatus, StudentScore, DueDate) WHERE 1 = 0;
        RETURN;
    END

    -- Sử dụng bảng tạm để chứa danh sách tất cả tài nguyên được giao cho lớp của học sinh
    IF OBJECT_ID('tempdb..#AssignedResources') IS NOT NULL DROP TABLE #AssignedResources;

    CREATE TABLE #AssignedResources (
        ResourceType VARCHAR(20),
        ResourceID INT,
        AssignToClassID BIGINT,
        Title NVARCHAR(255),
        TuanHocID INT,
		Tuan_HienThi NVARCHAR(500),
        Chuong NVARCHAR(2000),
        DueDate DATETIME,
        TeacherName NVARCHAR(100),
		MonHocName NVARCHAR(200),
		Icon VARCHAR(100),
		Color VARCHAR(10)
    );
    -- Lấy danh sách BÀI TẬP đã giao
    INSERT INTO #AssignedResources
    SELECT
        'ASSIGNMENT' AS ResourceType,
        a.AssignmentID,
        atc.AssignToClassID,
        a.Title,
        a.TuanHocID,
			N'Tuần ' + CAST(TuanTrongNam AS VARCHAR(2)) 
			+ N' - Tháng ' + CAST(ThangHoc AS VARCHAR(2)) 
			+ N' - Năm ' + CAST(YEAR(NgayBatDau) AS VARCHAR(4)) AS Tuan_HienThi,
        a.Chuong,
        atc.DueDate,
        gv.HoGV + ' '+ gv.TenGV  AS TeacherName,
		mh.MonHocName,
		mh.Icon,
		mh.Color
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments a ON atc.AssignmentID = a.AssignmentID
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
	JOIN dbo.tblMonHoc mh ON mh.MonHocID = mhl.MonHocID
	LEFT JOIN dbo.tblTuanHocTap AS tht ON a.TuanHocID = tht.TuanHocID
    LEFT JOIN dbo.tblGiaoVien gv ON a.CreateUser = gv.GiaoVienID 
    WHERE mhl.LopNhomID = @LopID
      AND mhl.MonHocID = @MonHocID
      AND atc.IsDeleted = 0 AND a.IsDeleted = 0;


    -- Lấy danh sách BÀI HỌC đã giao
    INSERT INTO #AssignedResources
    SELECT

		    'LESSON' AS ResourceType,		--ResourceType VARCHAR(20),
			   l.LessonID,	--ResourceID INT,
				     atc.AssignToClassID,--AssignToClassID BIGINT,
				    l.Title,--Title NVARCHAR(255),
			     l.TuanHocID,	--TuanHocID INT,
					 	N'Tuần ' + CAST(TuanTrongNam AS VARCHAR(2)) 
			+ N' - Tháng ' + CAST(ThangHoc AS VARCHAR(2)) 
			+ N' - Năm ' + CAST(YEAR(NgayBatDau) AS VARCHAR(4)) AS Tuan_HienThi,--Tuan_HienThi NVARCHAR(500),
				NULL,	--Chuong NVARCHAR(2000),
				  NULL,--DueDate DATETIME,
			    gv.HoGV + ' ' + gv.TenGV AS TeacherName,	--TeacherName NVARCHAR(100),
				mh.MonHocName,	--MonHocName NVARCHAR(200),
				mh.Icon,	--Icon VARCHAR(100),
				mh.Color	--Color VARCHAR(10)
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Lessons l ON atc.ResourceID = l.LessonID AND atc.ResourceType = 'LESSON'
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
	LEFT JOIN dbo.tblTuanHocTap AS tht ON tht.TuanHocID = l.TuanHocID
	LEFT JOIN dbo.tblMonHoc mh ON mh.MonHocID = mhl.MonHocID
    LEFT JOIN dbo.tblGiaoVien gv ON l.CreateUser = gv.GiaoVienID
    WHERE mhl.LopNhomID = @LopID
      AND mhl.MonHocID = @MonHocID
      AND atc.IsDeleted = 0 AND l.IsDeleted = 0;

    -- === BẢNG 2: TRẢ VỀ DANH SÁCH TÀI NGUYÊN CHI TIẾT ===
    -- Join bảng tài nguyên với bảng tiến độ của học sinh
    SELECT
        ar.ResourceType,
        ar.ResourceID,
        ar.Title,
        ar.TuanHocID,
		ar.Tuan_HienThi,
        ar.Chuong,
        ar.DueDate,
        -- Logic tính toán trạng thái
        CASE
            WHEN ar.ResourceType = 'ASSIGNMENT' THEN
                CASE s.SubmissionStatus
					WHEN 4 THEN 'GRADED'
                    WHEN 3 THEN 'SUBMITTED'
                    WHEN 2 THEN 'SUBMITTED'
                    WHEN 1 THEN 'IN_PROGRESS'
                    ELSE 'NOT_STARTED'
                END
            WHEN ar.ResourceType = 'LESSON' THEN
                CASE
                    WHEN lp.IsCompleted = 1 THEN 'COMPLETED'
                    WHEN lp.ProgressID IS NOT NULL THEN 'IN_PROGRESS'
                    ELSE 'NOT_STARTED'
                END
        END AS StudentStatus,
        s.Score AS StudentScore,
		ar.AssignToClassID
    FROM #AssignedResources ar
    LEFT JOIN dbo.tblEL_Submissions s ON ar.AssignToClassID = s.AssignToClassID AND s.HocSinhID = @HocSinhID
    LEFT JOIN dbo.tblEL_Learning_Progress lp ON ar.ResourceID = lp.LessonID AND ar.ResourceType = 'LESSON' AND lp.HocSinhID = @HocSinhID
    ORDER BY ar.TuanHocID, ar.Chuong, ar.Title;

    -- === BẢNG 1: TRẢ VỀ THỐNG KÊ TỔNG QUAN ===
    SELECT
        (SELECT COUNT(*) FROM #AssignedResources) AS TotalResources,
        (
            -- Đếm số bài tập đã nộp hoặc đã chấm
            (SELECT COUNT(DISTINCT s.AssignToClassID) FROM dbo.tblEL_Submissions s JOIN #AssignedResources ar ON s.AssignToClassID = ar.AssignToClassID WHERE s.HocSinhID = @HocSinhID AND s.SubmissionStatus >= 2) +
            -- Đếm số bài học đã hoàn thành
            (SELECT COUNT(DISTINCT lp.LessonID) FROM dbo.tblEL_Learning_Progress lp JOIN #AssignedResources ar ON lp.LessonID = ar.ResourceID AND ar.ResourceType = 'LESSON' WHERE lp.HocSinhID = @HocSinhID AND lp.IsCompleted = 1)
        ) AS CompletedResources,
        -- Lấy tên giáo viên (lấy 1 người đại diện)
        (SELECT TOP 1 TeacherName FROM #AssignedResources WHERE TeacherName IS NOT NULL) AS TeacherName,
		(SELECT TOP 1 MonHocName FROM #AssignedResources WHERE MonHocName IS NOT NULL) AS MonHocName,
		(SELECT TOP 1 Icon FROM #AssignedResources WHERE Icon IS NOT NULL) AS Icon,
		(SELECT TOP 1 Color FROM #AssignedResources WHERE Color IS NOT NULL) AS Color;
    -- Dọn dẹp bảng tạm
    DROP TABLE #AssignedResources; 
END
