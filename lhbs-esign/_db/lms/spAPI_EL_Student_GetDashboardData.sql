CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetDashboardData] --'H23300061'
	--@TuanHocID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @HocSinhID_INT INT = CAST(RIGHT(@sys_UserID,8) AS INT);
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();

    -- =================================================================================
    -- == BƯỚC CHUẨN BỊ: Lấy tất cả LỚP và NHÓM của học sinh vào bảng tạm           ==
    -- =================================================================================
    DECLARE @MyUnits TABLE (UnitID VARCHAR(10));
    INSERT INTO @MyUnits (UnitID)
    -- Lấy Lớp chính thức
    SELECT hsl.LopID FROM dbo.tblHocSinhLop hsl 
    JOIN dbo.tblLop l ON hsl.LopID = l.LopID AND l.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = @HocSinhID_INT AND hsl.Enable = 1 AND hsl.NienKhoa = @NienKhoa
    UNION 
    -- Lấy các Nhóm học tập
    SELECT hsn.NhomID FROM dbo.tblHocSinhNhom hsn 
    JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa
    WHERE hsn.HocSinhID = @HocSinhID_INT AND hsn.Enable = 1;

    DECLARE @MyMonHocLopIDs TABLE (MonHocLopID INT);
    INSERT INTO @MyMonHocLopIDs (MonHocLopID)
    SELECT MonHocLopID
    FROM dbo.tblMonHocLop
    WHERE LopNhomID IN (SELECT UnitID FROM @MyUnits)
      AND NienKhoa = @NienKhoa
      AND Enable = 1;


    -- === Bảng 1: Today's Focus (Nhiệm vụ cần làm ngay) ===
    SELECT  *
    FROM (
        -- ===== PHẦN 1: LẤY BÀI TẬP (ASSIGNMENTS) CHƯA NỘP =====
        SELECT 
            'ASSIGNMENT' AS ResourceType, atc.AssignToClassID AS ResourceID, a.Title, mh.MonHocName,
			CAST(atc.DueDate AS DATETIME) AS DueDate, 
			a.MonHocID,
			lcb.Reason,
            CASE 
                WHEN s.SubmissionStatus = 1 THEN 'IN_PROGRESS'
				WHEN s.SubmissionStatus = 0 AND (ISNULL(lcb.Reason, '' ) <> '') THEN 'RESUBMIT'
                WHEN atc.DueDate < GETDATE() THEN 'OVERDUE'
                ELSE 'NOT_STARTED'
            END AS Status,
            1 AS Priority,
			a.TuanHocID,
		   CAST(1 AS bit) 	AS Is_SendToClass 
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
        JOIN dbo.tblMonHoc mh ON a.MonHocID = mh.MonHocID
        LEFT JOIN dbo.tblEL_Submissions s ON atc.AssignToClassID = s.AssignToClassID AND s.HocSinhID = @HocSinhID_INT and s.IsDeleted = 0
		LEFT JOIN dbo. tblEL_Log_ChamBai lcb ON lcb.Log_ChamBaiID = s.Log_ChamBaiID
        WHERE atc.MonHocLopID IN (SELECT MonHocLopID FROM @MyMonHocLopIDs)
          AND atc.IsDeleted = 0 AND a.IsDeleted = 0 AND (s.SubmissionID IS NULL OR s.SubmissionStatus < 2)
		  AND atc.Status IN (1, 2) -- Show public asm
		  --AND a.TuanHocID = @TuanHocID

        UNION ALL

        -- ===== PHẦN 2: LẤY BÀI HỌC (LESSONS) CHƯA HOÀN THÀNH =====
        SELECT 
            'LESSON' AS ResourceType, atc.AssignToClassID AS ResourceID, l.Title, mh.MonHocName, 
			CAST(atc.DueDate AS DATETIME) AS DueDate,
			l.MonHocID,
			NULL AS Reason,
            CASE
                WHEN lp.ProgressID IS NOT NULL AND lp.IsCompleted = 0 THEN 'IN_PROGRESS'
                ELSE 'NOT_STARTED'
            END AS Status,
            2 AS Priority,
			l.TuanHocID,
			CAST(1 AS bit) 	AS Is_SendToClass 
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblEL_Lessons l ON atc.ResourceID = l.LessonID AND atc.ResourceType = 'LESSON' 
        JOIN dbo.tblMonHoc mh ON l.MonHocID = mh.MonHocID
        LEFT JOIN dbo.tblEL_Learning_Progress lp ON l.LessonID = lp.LessonID AND lp.HocSinhID = @HocSinhID_INT and lp.IsDeleted = 0
        WHERE atc.MonHocLopID IN (SELECT MonHocLopID FROM @MyMonHocLopIDs)
          AND atc.IsDeleted = 0 AND l.IsDeleted = 0 AND (lp.ProgressID IS NULL OR lp.IsCompleted = 0)
		 -- AND l.TuanHocID = @TuanHocID
		 UNION ALL
          -- ===== PHẦN 3: LẤY BÀI TẬP CỦA HỌC SINH CHƯA HOÀN THÀNH =====
        SELECT 
            'ASSIGNMENT' AS ResourceType, ats.AssignToStudentID AS ResourceID, a.Title, mh.MonHocName,
			CAST(ats.DueDate AS DATETIME) AS DueDate, 
			a.MonHocID,
			lcb.Reason,
            CASE 
                WHEN s.SubmissionStatus = 1 THEN 'IN_PROGRESS'
				WHEN s.SubmissionStatus = 0 AND (ISNULL(lcb.Reason, '' ) <> '') THEN 'RESUBMIT'
                WHEN ats.DueDate < GETDATE() THEN 'OVERDUE'
                ELSE 'NOT_STARTED'
            END AS Status,
            1 AS Priority,
			a.TuanHocID,
		 CAST(0 AS bit) 	AS Is_SendToClass 
        FROM dbo.tblEL_AssignToStudent ats
        JOIN dbo.tblEL_Assignments a ON ats.ResourceID = a.AssignmentID AND ats.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
        JOIN dbo.tblMonHoc mh ON a.MonHocID = mh.MonHocID
        LEFT JOIN dbo.tblEL_Submissions s ON ats.AssignToStudentID = s.AssignToStudentID AND s.HocSinhID = @HocSinhID_INT and s.IsDeleted = 0
		LEFT JOIN dbo. tblEL_Log_ChamBai lcb ON lcb.Log_ChamBaiID = s.Log_ChamBaiID
        WHERE ats.MonHocLopID IN (SELECT MonHocLopID FROM @MyMonHocLopIDs)
          AND ats.IsDeleted = 0 AND a.IsDeleted = 0 AND (s.SubmissionID IS NULL OR s.SubmissionStatus < 2)
		  AND ats.Status IN (1, 2) -- Show public asm
			AND ats.HocSinhID = @HocSinhID_INT
    ) AS Tasks
    ORDER BY 
        Priority ASC,
        CASE WHEN Status = 'OVERDUE' THEN 0 ELSE 1 END,
        DueDate ASC;

    -- === Bảng 2: Week Ahead (Lịch trong tuần) ===

	SELECT t.* FROM (
		SELECT 
			CAST(atc.DueDate AS DATE) AS DueDate,
			COUNT(atc.AssignToClassID) AS TaskCount,
			(
				SELECT 
					atc_inner.ResourceType, atc_inner.ResourceID,
					CASE 
						WHEN atc_inner.ResourceType = 'ASSIGNMENT' THEN (SELECT ass.Title FROM tblEL_Assignments ass WHERE ass.AssignmentID = atc_inner.ResourceID and ass.IsDeleted = 0)
						WHEN atc_inner.ResourceType = 'LESSON' THEN (SELECT lsn.Title FROM tblEL_Lessons lsn WHERE lsn.LessonID = atc_inner.ResourceID and lsn.IsDeleted = 0)
						ELSE N'Nhiệm vụ không xác định'
					END AS Title
				FROM dbo.tblEL_AssignToClass atc_inner
				WHERE atc_inner.IsDeleted = 0
				  AND CAST(atc_inner.DueDate AS DATE) = CAST(atc.DueDate AS DATE)
				  AND atc_inner.MonHocLopID IN (SELECT MonHocLopID FROM @MyMonHocLopIDs)
				FOR JSON PATH
			) AS TasksJSON
		FROM dbo.tblEL_AssignToClass atc
		WHERE atc.IsDeleted = 0
		  AND atc.DueDate BETWEEN GETDATE() AND DATEADD(day, 7, GETDATE())
		  AND atc.MonHocLopID IN (SELECT MonHocLopID FROM @MyMonHocLopIDs)
		GROUP BY CAST(atc.DueDate AS DATE)

		UNION ALL

		SELECT 
			CAST(ats.DueDate AS DATE) AS DueDate,
			COUNT(ats.AssignToStudentID) AS TaskCount,
			(
				SELECT 
					ats_inner.ResourceType, ats_inner.ResourceID,
					CASE 
						WHEN ats_inner.ResourceType = 'ASSIGNMENT' THEN (SELECT ass.Title FROM dbo.tblEL_Assignments ass WHERE ass.AssignmentID = ats_inner.ResourceID and ass.IsDeleted = 0)
						WHEN ats_inner.ResourceType = 'LESSON' THEN (SELECT lsn.Title FROM dbo.tblEL_Lessons lsn WHERE lsn.LessonID = ats_inner.ResourceID and lsn.IsDeleted = 0)
						ELSE N'Nhiệm vụ không xác định'
					END AS Title
				FROM dbo.tblEL_AssignToStudent ats_inner
				WHERE ats_inner.IsDeleted = 0
				  AND CAST(ats_inner.DueDate AS DATE) = CAST(ats_inner.DueDate AS DATE)
				  AND ats_inner.MonHocLopID IN (SELECT MonHocLopID FROM @MyMonHocLopIDs)
				FOR JSON PATH
			) AS TasksJSON
		FROM dbo.tblEL_AssignToStudent ats
		WHERE ats.IsDeleted = 0
		  AND ats.DueDate BETWEEN GETDATE() AND DATEADD(day, 7, GETDATE())
		  AND ats.MonHocLopID IN (SELECT MonHocLopID FROM @MyMonHocLopIDs)
		  AND ats.HocSinhID = @HocSinhID_INT
		GROUP BY CAST(ats.DueDate AS DATE)
	) AS t
    ORDER BY t.DueDate;

    -- === Bảng 3: Semester Progress (Tiến độ môn học) ===
	WITH AllTasks AS (
		SELECT MonHocID, SUM(TotalCount) AS TotalCount FROM (
			-- Đếm số BÀI TẬP (Assignments) duy nhất
			SELECT a.MonHocID, COUNT(DISTINCT atc.ResourceID) AS TotalCount 
			FROM dbo.tblEL_AssignToClass atc 
			JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID
			WHERE atc.MonHocLopID IN (SELECT MonHocLopID FROM @MyMonHocLopIDs)
			  AND atc.IsDeleted = 0 and a.IsDeleted = 0 AND atc.ResourceType = 'ASSIGNMENT' 
			GROUP BY a.MonHocID
        
			UNION ALL

			SELECT a.MonHocID, COUNT(DISTINCT ats.ResourceID) AS TotalCount 
			FROM dbo.tblEL_AssignToStudent ats
			JOIN dbo.tblEL_Assignments a ON ats.ResourceID = a.AssignmentID
			WHERE ats.MonHocLopID IN (SELECT MonHocLopID FROM @MyMonHocLopIDs)
			AND ats.IsDeleted = 0 and a.IsDeleted = 0 AND ats.ResourceType = 'ASSIGNMENT' AND ats.HocSinhID = @HocSinhID_INT
			GROUP BY a.MonHocID

			UNION ALL
        
			-- Đếm số BÀI HỌC (Lessons) duy nhất
			SELECT l.MonHocID, COUNT(DISTINCT atc.ResourceID) AS TotalCount 
			FROM dbo.tblEL_AssignToClass atc 
			JOIN dbo.tblEL_Lessons l ON atc.ResourceID = l.LessonID
			WHERE atc.MonHocLopID IN (SELECT MonHocLopID FROM @MyMonHocLopIDs)
			  AND atc.IsDeleted = 0 and l.IsDeleted = 0 AND atc.ResourceType = 'LESSON'
			GROUP BY l.MonHocID
		) t GROUP BY MonHocID 
	),
	CompletedTasks AS (
		-- CTE này đã đúng vì nó đếm theo kết quả của học sinh, vốn đã là duy nhất
		-- nên không cần sửa.
		SELECT MonHocID, SUM(CompletedCount) AS CompletedCount FROM (
			SELECT a.MonHocID, COUNT(DISTINCT atc.ResourceID) AS CompletedCount
			FROM dbo.tblEL_Submissions s
			JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID and atc.IsDeleted = 0
			JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
			WHERE s.HocSinhID = @HocSinhID_INT AND s.SubmissionStatus >= 2 and s.IsDeleted = 0
			GROUP BY a.MonHocID

			UNION ALL
            
			SELECT a.MonHocID, COUNT(DISTINCT ats.ResourceID) AS CompletedCount
			FROM dbo.tblEL_Submissions s
			JOIN dbo.tblEL_AssignToStudent ats ON s.AssignToStudentID = ats.AssignToStudentID and ats.IsDeleted = 0
			JOIN dbo.tblEL_Assignments a ON ats.ResourceID = a.AssignmentID AND ats.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
			WHERE s.HocSinhID = @HocSinhID_INT AND s.SubmissionStatus >= 2 and s.IsDeleted = 0 AND ats.HocSinhID = @HocSinhID_INT
			GROUP BY a.MonHocID

			UNION ALL

			SELECT l.MonHocID, COUNT(DISTINCT lp.LessonID) AS CompletedCount
			FROM dbo.tblEL_Learning_Progress lp
			JOIN dbo.tblEL_Lessons l ON lp.LessonID = l.LessonID and l.IsDeleted = 0
			WHERE lp.HocSinhID = @HocSinhID_INT AND lp.IsCompleted = 1 and lp.IsDeleted = 0
			GROUP BY l.MonHocID  
		) t GROUP BY MonHocID
	)
    SELECT mh.MonHocID, mh.MonHocName, 
           ISNULL(at.TotalCount, 0) AS TotalTasks, 
           ISNULL(ct.CompletedCount, 0) AS CompletedTasks,
		    0 AS OverdueTasks
    FROM dbo.tblMonHoc mh
    LEFT JOIN AllTasks at ON mh.MonHocID = at.MonHocID
    LEFT JOIN CompletedTasks ct ON mh.MonHocID = ct.MonHocID
    WHERE ISNULL(at.TotalCount, 0) > 0
    ORDER BY mh.Sort;

    -- === Bảng 4: What's New (Bảng tin) ===
    SELECT TOP 5 * FROM (
        -- Hoạt động 1: Bài được chấm
        SELECT 
            CASE WHEN s.SubmissionStatus = 3 THEN 'SAVE_DRAFT' WHEN s.SubmissionStatus = 4 THEN 'GRADED' ELSE '' END AS FeedType, 
            s.SubmissionID AS ObjectID, a.Title, s.GradedDate AS EventTime,
            N'Điểm: ' + CAST(s.Score AS VARCHAR(10)) + ' / ' + CAST(atc.MaxScore AS VARCHAR(10)) AS Details,
            atc.AssignToClassID, 'ASSIGNMENT' AS ResourceType,
            CASE 
                    WHEN (SELECT COUNT(SubmissionID) FROM tblEL_Submissions WHERE HocSinhID = @HocSinhID_INT and AssignToClassID = atc.AssignToClassID) < atc.LimitAssigned THEN 0
                    ELSE 1
               END AS Is_MaxAssigned,
              ISNULL( (SELECT '[' + 
		   STUFF((
			   SELECT ',' + CAST(LanNop AS VARCHAR(10))
			   FROM tblEL_Submissions WHERE HocSinhID = @HocSinhID_INT and AssignToClassID = atc.AssignToClassID
			   FOR XML PATH('')
		   ), 1, 1, '') 
		   + ']'),'[]') AS DSLanNop,
        s.LanNop,
        CAST(1 AS bit) 	AS Is_SendToClass 
        FROM dbo.tblEL_Submissions s
        JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID and atc.IsDeleted = 0
        JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
        WHERE s.HocSinhID = @HocSinhID_INT AND s.SubmissionStatus IN (3, 4) and s.IsDeleted = 0
        UNION ALL
        -- Hoạt động 2: Nộp bài
        SELECT 'SUBMITTED' AS FeedType, s.SubmissionID AS ObjectID, a.Title, s.SubmissionTime AS EventTime,
               mh.MonHocName AS Details, atc.AssignToClassID, 'ASSIGNMENT' AS ResourceType,
               CASE 
                    WHEN (SELECT COUNT(SubmissionID) FROM tblEL_Submissions WHERE HocSinhID = @HocSinhID_INT and AssignToClassID = atc.AssignToClassID) < atc.LimitAssigned THEN 0
                    ELSE 1
               END AS Is_MaxAssigned,
              ISNULL( (SELECT '[' + 
       STUFF((
           SELECT ',' + CAST(LanNop AS VARCHAR(10))
           FROM tblEL_Submissions WHERE HocSinhID = @HocSinhID_INT and AssignToClassID = atc.AssignToClassID
           FOR XML PATH('')
       ), 1, 1, '') 
       + ']'),'[]') AS DSLanNop,
        s.LanNop,
        CAST(1 AS bit) 	AS Is_SendToClass
        FROM dbo.tblEL_Submissions s
        JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID and atc.IsDeleted = 0
        JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
        JOIN dbo.tblMonHoc mh ON a.MonHocID = mh.MonHocID
        WHERE s.HocSinhID = @HocSinhID_INT AND s.SubmissionStatus = 2 and s.IsDeleted = 0
		UNION ALL
		---- ATS
		 SELECT 
            CASE WHEN s.SubmissionStatus = 3 THEN 'SAVE_DRAFT' WHEN s.SubmissionStatus = 4 THEN 'GRADED' ELSE '' END AS FeedType, 
            s.SubmissionID AS ObjectID, a.Title, s.GradedDate AS EventTime,
            N'Điểm: ' + CAST(s.Score AS VARCHAR(10)) + ' / ' + CAST(ats.MaxScore AS VARCHAR(10)) AS Details,
            ats.AssignToStudentID, 'ASSIGNMENT' AS ResourceType,
            CASE 
                    WHEN (SELECT COUNT(SubmissionID) FROM dbo.tblEL_Submissions WHERE HocSinhID = @HocSinhID_INT and AssignToStudentID =   ats.AssignToStudentID) < ats.LimitAssigned THEN 0
                    ELSE 1
               END AS Is_MaxAssigned,
              ISNULL( (SELECT '[' + 
		   STUFF((
			   SELECT ',' + CAST(LanNop AS VARCHAR(10))
			   FROM dbo.tblEL_Submissions WHERE HocSinhID = @HocSinhID_INT and AssignToStudentID =   ats.AssignToStudentID
			   FOR XML PATH('')
		   ), 1, 1, '') 
		   + ']'),'[]') AS DSLanNop,
        s.LanNop,
        CAST(0 AS bit) 	AS Is_SendToClass
        FROM dbo.tblEL_Submissions s
        JOIN dbo.tblEL_AssignToStudent ats ON s.AssignToStudentID = ats.AssignToStudentID and ats.IsDeleted = 0
        JOIN dbo.tblEL_Assignments a ON ats.ResourceID = a.AssignmentID AND ats.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
        WHERE s.HocSinhID = @HocSinhID_INT AND s.SubmissionStatus IN (3, 4) and s.IsDeleted = 0 AND ats.HocSinhID = @HocSinhID_INT
        UNION ALL
        -- Hoạt động 2: Nộp bài
        SELECT 'SUBMITTED' AS FeedType, s.SubmissionID AS ObjectID, a.Title, s.SubmissionTime AS EventTime,
               mh.MonHocName AS Details, ats.AssignToStudentID, 'ASSIGNMENT' AS ResourceType,
               CASE 
                    WHEN (SELECT COUNT(SubmissionID) FROM dbo.tblEL_Submissions WHERE HocSinhID = @HocSinhID_INT and AssignToStudentID = ats.AssignToStudentID) < ats.LimitAssigned THEN 0
                    ELSE 1
               END AS Is_MaxAssigned,
              ISNULL( (SELECT '[' + 
       STUFF((
           SELECT ',' + CAST(LanNop AS VARCHAR(10))
           FROM dbo.tblEL_Submissions WHERE HocSinhID = @HocSinhID_INT and AssignToStudentID = ats.AssignToStudentID
           FOR XML PATH('')
       ), 1, 1, '') 
       + ']'),'[]') AS DSLanNop,
        s.LanNop,
        CAST(0 AS bit) 	AS Is_SendToClass
        FROM dbo.tblEL_Submissions s
        JOIN dbo.tblEL_AssignToStudent ats ON s.AssignToStudentID = ats.AssignToStudentID and ats.IsDeleted = 0
        JOIN dbo.tblEL_Assignments a ON ats.ResourceID = a.AssignmentID AND ats.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
        JOIN dbo.tblMonHoc mh ON a.MonHocID = mh.MonHocID
        WHERE s.HocSinhID = @HocSinhID_INT AND s.SubmissionStatus = 2 and s.IsDeleted = 0 AND ats.HocSinhID = @HocSinhID_INT
		----
        UNION ALL
        -- Hoạt động 3: Hoàn thành bài học
        SELECT 'LESSON_COMPLETED' AS FeedType, lp.ProgressID AS ObjectID, l.Title, lp.CompletedDate AS EventTime,
               mh.MonHocName AS Details, atc.AssignToClassID, 'LESSON' AS ResourceType,null as Is_MaxAssigned, null AS DSLanNop,
              null AS LanNop,
        CAST(0 AS bit) 	AS Is_SendToClass
        FROM dbo.tblEL_Learning_Progress lp
        JOIN dbo.tblEL_Lessons l ON lp.LessonID = l.LessonID and l.IsDeleted = 0
        JOIN dbo.tblMonHoc mh ON l.MonHocID = mh.MonHocID
        JOIN dbo.tblEL_AssignToClass atc ON l.LessonID = atc.ResourceID AND atc.ResourceType = 'LESSON' and atc.IsDeleted = 0
             -- SỬA ĐỔI: Lọc theo tất cả các Lớp/Nhóm của học sinh
             AND atc.MonHocLopID IN (SELECT MonHocLopID FROM tblMonHocLop WHERE LopNhomID IN (SELECT UnitID FROM @MyUnits))
        WHERE lp.HocSinhID = @HocSinhID_INT AND lp.IsCompleted = 1 and lp.IsDeleted = 0
        UNION ALL
        -- Hoạt động 4: Đạt thành tích
        SELECT 'ACHIEVEMENT' AS FeedType, ach.AchievementID AS ObjectID, ad.Title, ach.CreateTime AS EventTime,
               '+' + CAST(ach.PointsEarned AS VARCHAR(10)) + ' XP' AS Details, NULL AS AssignToClassID, NULL AS ResourceType,null as Is_MaxAssigned, null AS DSLanNop,
              null AS LanNop,
        CAST(0 AS bit) 	AS Is_SendToClass
        FROM dbo.tblEL_Achievements ach
        JOIN dbo.tblEL_Achievement_Definitions ad ON ach.AchievementCode = ad.AchievementCode
        WHERE ach.HocSinhID = @HocSinhID_INT AND ach.IsDeleted = 0
    ) AS Feeds
    ORDER BY EventTime DESC;

    -- === Bảng 5: Recent Achievements (Thành tích gần đây) ===
    SELECT TOP 6 ad.Title, ad.Description, ad.ImageUrl, ad.AchievementType, a.CreateTime
    FROM dbo.tblEL_Achievements a
    JOIN dbo.tblEL_Achievement_Definitions ad ON a.AchievementCode = ad.AchievementCode
    WHERE a.HocSinhID = @HocSinhID_INT AND a.IsDeleted = 0 
    ORDER BY a.CreateTime DESC;
END
