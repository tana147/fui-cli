CREATE PROC [dbo].[spAPI_EL_Student_Get_HoatDong_ByHocSinhID]
    @HocSinhID INT,
    @NienKhoa  INT
AS
BEGIN
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

    /***********************
     * CTE_Submissions
     ***********************/
    ;WITH CTE_Submissions_Raw AS
    (
        SELECT
            s.SubmissionID, s.HocSinhID, s.SubmissionStatus,
            s.SubmissionTime, s.GradedDate, s.Score, s.AttemptMaxScore, s.LanNop,
            s.IsDeleted, s.CreateTime,
            atc.AssignToClassID AS AssignID, 'CLASS' AS ScopeType,
            atc.MaxScore AS AtcMaxScore,
            atc.LimitAssigned, a.Title, a.MonHocID, atc.ResourceType,
            CASE 
                WHEN ISJSON(s.AssignmentConfig) = 1 AND s.AssignmentConfig NOT IN ('null', '') THEN s.AssignmentConfig
                WHEN ISJSON(atc.AssignmentConfig) = 1 AND atc.AssignmentConfig NOT IN ('null', '') THEN atc.AssignmentConfig
                ELSE NULL 
            END AS ValidConfig
        FROM dbo.tblEL_Submissions s
        JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID AND atc.IsDeleted = 0
        JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND a.IsDeleted = 0
        WHERE s.HocSinhID = @HocSinhID
          AND atc.MonHocLopID IN (
              SELECT mhl.MonHocLopID
              FROM dbo.tblMonHocLop mhl
              WHERE mhl.NienKhoa = @NienKhoa
                AND mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits)
          )

        UNION ALL

        SELECT
            s.SubmissionID, s.HocSinhID, s.SubmissionStatus,
            s.SubmissionTime, s.GradedDate, s.Score, s.AttemptMaxScore, s.LanNop,
            s.IsDeleted, s.CreateTime,
            ats.AssignToStudentID AS AssignID, 'STUDENT' AS ScopeType,
            ats.MaxScore AS AtcMaxScore,
            ats.LimitAssigned, a.Title, a.MonHocID, ats.ResourceType,
            CASE 
                WHEN ISJSON(s.AssignmentConfig) = 1 AND s.AssignmentConfig NOT IN ('null', '') THEN s.AssignmentConfig
                WHEN ISJSON(ats.AssignmentConfig) = 1 AND ats.AssignmentConfig NOT IN ('null', '') THEN ats.AssignmentConfig
                ELSE NULL 
            END AS ValidConfig
        FROM dbo.tblEL_Submissions s
        JOIN dbo.tblEL_AssignToStudent ats ON s.AssignToStudentID = ats.AssignToStudentID AND ats.IsDeleted = 0
        JOIN dbo.tblEL_Assignments a ON ats.ResourceID = a.AssignmentID AND a.IsDeleted = 0
        WHERE s.HocSinhID = @HocSinhID
          AND ats.HocSinhID = @HocSinhID
          AND ats.MonHocLopID IN (
              SELECT mhl.MonHocLopID
              FROM dbo.tblMonHocLop mhl
              WHERE mhl.NienKhoa = @NienKhoa
                AND mhl.LopNhomID IN (SELECT UnitID FROM @MyUnits)
          )
    ),
    CTE_Submissions AS
    (
        SELECT
            r.SubmissionID, r.HocSinhID, r.SubmissionStatus,
            r.SubmissionTime, r.GradedDate, r.Score, r.LanNop,
            r.IsDeleted, r.CreateTime,
            r.AssignID, r.ScopeType,
            COALESCE(
                r.AttemptMaxScore,
                CASE 
                    WHEN r.ValidConfig IS NOT NULL THEN
                        (SELECT SUM(q.Points)
                         FROM (
                             SELECT ISNULL(Points, 1.00) AS Points
                             FROM OPENJSON(
                                 CASE
                                     WHEN JSON_QUERY(r.ValidConfig, '$.groups') IS NOT NULL
                                         THEN r.ValidConfig
                                     ELSE N'{}'
                                 END,
                                 '$.groups'
                             )
                                 WITH (questions NVARCHAR(MAX) '$.questions' AS JSON) AS Groups
                             CROSS APPLY OPENJSON(
                                 CASE
                                     WHEN ISJSON(Groups.questions) = 1
                                         AND LEFT(LTRIM(RTRIM(Groups.questions)), 1) = '['
                                         THEN Groups.questions
                                     ELSE N'[]'
                                 END
                             )
                                 WITH (Points DECIMAL(10,2) '$.points')
                             UNION ALL
                             SELECT ISNULL(Points, 1.00) AS Points
                             FROM OPENJSON(
                                 CASE
                                     WHEN JSON_QUERY(r.ValidConfig, '$.questions') IS NOT NULL
                                         THEN r.ValidConfig
                                     ELSE N'{}'
                                 END,
                                 '$.questions'
                             )
                                 WITH (Points DECIMAL(10,2) '$.points')
                         ) q)
                    ELSE NULL
                END,
                r.AtcMaxScore
            ) AS MaxScore,
            r.LimitAssigned, r.Title, r.MonHocID, r.ResourceType
        FROM CTE_Submissions_Raw r
    ),

    /***********************
     * CTE_SubmitInfo — thêm TotalSubmits + DSLanNop
     ***********************/
    CTE_SubmitInfo AS
    (
        SELECT
            c.*,
            (SELECT COUNT(*)
             FROM dbo.tblEL_Submissions s2
             WHERE s2.HocSinhID = @HocSinhID
               AND (  (c.ScopeType = 'CLASS'   AND s2.AssignToClassID   = c.AssignID)
                   OR (c.ScopeType = 'STUDENT' AND s2.AssignToStudentID = c.AssignID))
            ) AS TotalSubmits,

            (SELECT '[' +
                STUFF((
                    SELECT ',' + CAST(s2.LanNop AS VARCHAR(10))
                    FROM dbo.tblEL_Submissions s2
                    WHERE s2.HocSinhID = @HocSinhID
                      AND (  (c.ScopeType = 'CLASS'   AND s2.AssignToClassID   = c.AssignID)
                          OR (c.ScopeType = 'STUDENT' AND s2.AssignToStudentID = c.AssignID))
                    FOR XML PATH('')
                ), 1, 1, '')
             + ']'
            ) AS DSLanNop
        FROM CTE_Submissions c
        WHERE c.IsDeleted = 0
    ),

    /***********************
     * CTE_Assignment_Flat — gán FeedType + EventTime cho từng lần
     ***********************/
    CTE_Assignment_Flat AS
    (
        SELECT
            SubmissionID, AssignID, ScopeType, Title, MonHocID,
            LanNop, SubmissionStatus, Score, MaxScore,
            TotalSubmits, LimitAssigned, DSLanNop,
            CASE
                -- Phase 1 của bài trắc nghiệm có thể tạm ghi status = 4 để lấy answer key,
                -- nhưng chỉ được hiển thị "Đã chấm" khi tổng điểm đã tồn tại.
                WHEN SubmissionStatus = 4 AND Score IS NOT NULL THEN 'GRADED'
                WHEN SubmissionStatus = 4 THEN 'SUBMITTED'
                WHEN SubmissionStatus = 3 THEN 'SAVE_DRAFT'
                WHEN SubmissionStatus = 2 THEN 'SUBMITTED'
                ELSE                           'IN_PROGRESS'
            END AS FeedType,
            CASE
                WHEN SubmissionStatus = 4 AND Score IS NOT NULL THEN GradedDate
                WHEN SubmissionStatus = 4 THEN SubmissionTime
                WHEN SubmissionStatus IN (2, 3) THEN SubmissionTime
                ELSE CreateTime
            END AS EventTime,
            CASE WHEN ScopeType = 'CLASS' THEN 1 ELSE 0 END AS Is_SendToClass,
            CASE WHEN TotalSubmits < LimitAssigned THEN 0 ELSE 1 END AS Is_MaxAssigned
        FROM CTE_SubmitInfo
    ),

    /***********************
     * CTE_Assignment_Ranked
     * — Chọn lượt đã chấm có tỷ lệ Score/MaxScore cao nhất; hòa thì lượt nộp mới hơn.
     ***********************/
    CTE_Assignment_Ranked AS
    (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY AssignID
                ORDER BY
                    -- Khi đã hoàn thành một lượt rồi làm lại, Nhiệm vụ không còn
                    -- hiển thị. Hoạt động phải ưu tiên lượt đang dở để học sinh có
                    -- đúng nút "Tiếp tục làm", thay vì trỏ ngược về lượt đã chấm.
                    CASE WHEN SubmissionStatus NOT IN (2, 4) THEN 0 ELSE 1 END,
                    CASE WHEN SubmissionStatus = 4 AND Score IS NOT NULL THEN 0 ELSE 1 END,
                    CASE WHEN SubmissionStatus = 4 AND Score IS NOT NULL AND MaxScore > 0
                         THEN Score / MaxScore ELSE -1 END DESC,
                    LanNop DESC,
                    SubmissionID DESC
            ) AS rn
        FROM CTE_Assignment_Flat
    )

    SELECT *
    FROM
    (
        /************************************************************
         * A. ASSIGNMENT — 1 row / bài tập (đại diện = lần mới nhất)
         *    Kèm DSBaiLam: JSON array tất cả các lần
         ************************************************************/
        SELECT
            r.FeedType,
            r.SubmissionID                                              AS ObjectID,
            r.Title,
            r.EventTime,
            CASE
                WHEN r.SubmissionStatus = 4 AND r.Score IS NOT NULL
                    THEN N'Điểm: ' + CAST(r.Score AS VARCHAR(10)) + ' / ' + CAST(r.MaxScore AS VARCHAR(10))
                WHEN r.SubmissionStatus IN (2, 4)
                    THEN (SELECT mh.MonHocName FROM dbo.tblMonHoc mh WHERE mh.MonHocID = r.MonHocID)
                ELSE NULL
            END                                                         AS Details,
            r.AssignID,
            'ASSIGNMENT'                                                AS ResourceType,
            r.Is_MaxAssigned,
            r.DSLanNop,
            r.LanNop,
            r.Is_SendToClass,
            -- SubmissionID của lần mới nhất — dùng khi "Tiếp tục làm"
            r.SubmissionID                                              AS LastSubmissionID,
            -- 1 = lần mới nhất đang dở (IN_PROGRESS / SAVE_DRAFT) → hiện nút "Tiếp tục làm"
            -- 0 = lần mới nhất đã xong (SUBMITTED / GRADED)        → hiện nút "Làm lại" / "Chi tiết"
            CASE
                WHEN r.SubmissionStatus NOT IN (2, 4) THEN 1
                ELSE 0
            END                                                         AS Is_HasInProgress,
            -- JSON array tất cả các lần, sắp xếp LanNop giảm dần
            (
                SELECT '[' +
                    STUFF((
                        SELECT ',' +
                            '{"SubmissionID":'   + CAST(f.SubmissionID AS VARCHAR)  +
                            ',"LanNop":'         + CAST(f.LanNop AS VARCHAR)        +
                            ',"AssignID":'       + CAST(f.AssignID AS VARCHAR)      +
                            ',"Title":"'         + REPLACE(r.Title, '"', '\"') + '"' +
                            ',"FeedType":"'      + f.FeedType + '"'                 +
                            ',"EventTime":"'     + ISNULL(CONVERT(VARCHAR(23), f.EventTime, 126), '') + '"' +
                            ',"Details":'        +
                                CASE WHEN f.SubmissionStatus = 4 AND f.Score IS NOT NULL
                                     THEN '"' + N'Điểm: ' + CAST(f.Score AS VARCHAR) + '/' + CAST(f.MaxScore AS VARCHAR) + '"'
                                     ELSE 'null'
                                END              +
                            ',"Is_SendToClass":' + CAST(f.Is_SendToClass AS VARCHAR) +
                            '}'
                        FROM CTE_Assignment_Flat f
                        WHERE f.AssignID = r.AssignID
                        ORDER BY f.LanNop DESC
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')
                + ']'
            )                                                           AS DSBaiLam
        FROM CTE_Assignment_Ranked r
        WHERE r.rn = 1


        UNION ALL

        /************************************
         * B. LESSON_COMPLETED
         ************************************/
        SELECT
            'LESSON_COMPLETED'  AS FeedType,
            lp.ProgressID       AS ObjectID,
            l.Title,
            lp.CompletedDate    AS EventTime,
            mh.MonHocName       AS Details,
            atc.AssignToClassID AS AssignID,
            'LESSON'            AS ResourceType,
            NULL                AS Is_MaxAssigned,
            NULL                AS DSLanNop,
            NULL                AS LanNop,
            0                   AS Is_SendToClass,
            NULL                AS LastSubmissionID,
            0                   AS Is_HasInProgress,
            NULL                AS DSBaiLam
        FROM dbo.tblEL_Learning_Progress lp
        JOIN dbo.tblEL_Lessons l ON lp.LessonID = l.LessonID AND l.IsDeleted = 0
        JOIN dbo.tblMonHoc mh ON l.MonHocID = mh.MonHocID
        JOIN dbo.tblEL_AssignToClass atc
            ON l.LessonID = atc.ResourceID
            AND atc.ResourceType = 'LESSON' AND atc.IsDeleted = 0
            AND atc.MonHocLopID IN (
                SELECT MonHocLopID FROM tblMonHocLop
                WHERE LopNhomID IN (SELECT UnitID FROM @MyUnits)
            )
        WHERE lp.HocSinhID = @HocSinhID AND lp.IsCompleted = 1 AND lp.IsDeleted = 0


        UNION ALL

        /************************************
         * C. ACHIEVEMENT
         ************************************/
        SELECT
            'ACHIEVEMENT'                                       AS FeedType,
            ach.AchievementID                                   AS ObjectID,
            ad.Title,
            ach.CreateTime                                      AS EventTime,
            '+' + CAST(ach.PointsEarned AS VARCHAR(10)) + ' XP' AS Details,
            NULL                                                AS AssignID,
            NULL                                                AS ResourceType,
            NULL                                                AS Is_MaxAssigned,
            NULL                                                AS DSLanNop,
            NULL                                                AS LanNop,
            0                   AS Is_SendToClass,
            NULL                AS LastSubmissionID,
            0                   AS Is_HasInProgress,
            NULL                AS DSBaiLam
        FROM dbo.tblEL_Achievements ach
        JOIN dbo.tblEL_Achievement_Definitions ad ON ach.AchievementCode = ad.AchievementCode
        WHERE ach.HocSinhID = @HocSinhID
          AND ach.NienKhoa = @NienKhoa
          AND ach.IsDeleted = 0

    ) AS AllFeeds
    ORDER BY EventTime DESC;

END
