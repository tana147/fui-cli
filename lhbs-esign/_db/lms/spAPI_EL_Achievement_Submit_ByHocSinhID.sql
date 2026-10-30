CREATE PROC spAPI_EL_Achievement_Submit_ByHocSinhID
	@HocSinhID INT
AS
BEGIN
-------------------------------------------------------
-- 1. TÍNH TỔNG SỐ BÀI ĐÃ HOÀN THÀNH (FOREVER)
-------------------------------------------------------
;WITH CountTotal AS (
    SELECT 
        @HocSinhID AS HocSinhID,
        'ASSIGNMENT' AS ResourceType,
        COUNT(*) AS TotalCompleted
    FROM dbo.tblEL_Submissions s
    INNER JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID
    WHERE s.HocSinhID = @HocSinhID
      AND s.SubmissionStatus = 4
      AND s.Score IS NOT NULL
      AND s.IsDeleted = 0
      AND atc.IsDeleted = 0
    
    UNION ALL
    
    SELECT 
        @HocSinhID AS HocSinhID,
        'LESSON' AS ResourceType,
        COUNT(*) AS TotalCompleted
    FROM dbo.tblEL_Learning_Progress lp
    WHERE lp.HocSinhID = @HocSinhID
      AND lp.IsCompleted = 1
      AND lp.IsDeleted = 0
),

-------------------------------------------------------
-- 2. TÍNH SỐ BÀI HOÀN THÀNH TRONG TUẦN (WEEKLY)
-------------------------------------------------------
CountWeekly AS (
    SELECT 
        @HocSinhID AS HocSinhID,
        'ASSIGNMENT' AS ResourceType,
        COUNT(*) AS WeeklyCompleted
    FROM dbo.tblEL_Submissions s
    INNER JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID
    WHERE s.HocSinhID = @HocSinhID
      AND s.SubmissionStatus = 4
      AND s.Score IS NOT NULL
      AND s.IsDeleted = 0
      AND atc.IsDeleted = 0
      AND DATEPART(YEAR, s.SubmissionTime) = DATEPART(YEAR, GETDATE())
      AND DATEPART(WEEK, s.SubmissionTime) = DATEPART(WEEK, GETDATE())
    
    UNION ALL
    
    SELECT 
        @HocSinhID AS HocSinhID,
        'LESSON' AS ResourceType,
        COUNT(*) AS WeeklyCompleted
    FROM dbo.tblEL_Learning_Progress lp
    WHERE lp.HocSinhID = @HocSinhID
      AND lp.IsCompleted = 1
      AND lp.IsDeleted = 0
      AND DATEPART(YEAR, lp.CompletedDate) = DATEPART(YEAR, GETDATE())
      AND DATEPART(WEEK, lp.CompletedDate) = DATEPART(WEEK, GETDATE())
),

-------------------------------------------------------
-- 3. LẤY TẤT CẢ CÁC BÀI ĐẠT ĐIỂM CAO (DAILY SCORE)
-------------------------------------------------------
DailyScores AS (
    SELECT 
        s.SubmissionID,
        s.HocSinhID,
        s.AssignToClassID AS ResourceID,
        'ASSIGNMENT' AS ResourceType,
        (s.Score * 100.0 / atc.MaxScore) AS ScorePercentage,
        CASE 
            WHEN (s.Score * 100.0 / atc.MaxScore) = 100 THEN 'PERFECT_SCORE'
            WHEN (s.Score * 100.0 / atc.MaxScore) >= 90 THEN 'SCORE_90'
            WHEN (s.Score * 100.0 / atc.MaxScore) >= 80 THEN 'SCORE_80'
            WHEN (s.Score * 100.0 / atc.MaxScore) >= 70 THEN 'SCORE_70'
            ELSE NULL
        END AS AchievementCode
    FROM dbo.tblEL_Submissions s
    INNER JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID
    WHERE s.HocSinhID = @HocSinhID
      AND s.SubmissionStatus = 4
      AND s.Score IS NOT NULL
      AND s.IsDeleted = 0
      AND atc.IsDeleted = 0
      AND atc.MaxScore > 0
),

-------------------------------------------------------
-- 4. GHÉP VỚI ACHIEVEMENT DEFINITIONS
-------------------------------------------------------
ForeverAchievements AS (
    -- FOREVER Achievements (DONE_X)
    SELECT DISTINCT
        ad.AchievementCode,
        ad.Title,
        ad.Description,
        ad.Points,
        ad.AchievementType AS ResourceType,
        @HocSinhID AS HocSinhID,
        NULL AS ResourceID,
        'FOREVER' AS AchievementPeriod
    FROM dbo.tblEL_Achievement_Definitions ad
    INNER JOIN CountTotal ct ON ad.AchievementType = ct.ResourceType
    WHERE ad.IsDeleted = 0
      AND ad.PeriodType = 'FOREVER'
      AND (
          (ad.AchievementCode LIKE '%_1'   AND ct.TotalCompleted >= 1) OR
          (ad.AchievementCode LIKE '%_5'   AND ct.TotalCompleted >= 5) OR
          (ad.AchievementCode LIKE '%_10'  AND ct.TotalCompleted >= 10) OR
          (ad.AchievementCode LIKE '%_25'  AND ct.TotalCompleted >= 25) OR
          (ad.AchievementCode LIKE '%_50'  AND ct.TotalCompleted >= 50) OR
          (ad.AchievementCode LIKE '%_100' AND ct.TotalCompleted >= 100)
      )
),

WeeklyAchievements AS (
    -- WEEKLY Achievements (WEEKLY_X)
    SELECT DISTINCT
        ad.AchievementCode,
        ad.Title,
        ad.Description,
        ad.Points,
        ad.AchievementType AS ResourceType,
        @HocSinhID AS HocSinhID,
        NULL AS ResourceID,
        'WEEKLY' AS AchievementPeriod
    FROM dbo.tblEL_Achievement_Definitions ad
    INNER JOIN CountWeekly cw ON ad.AchievementType = cw.ResourceType
    WHERE ad.IsDeleted = 0
      AND ad.PeriodType = 'WEEKLY'
      AND (
          (ad.AchievementCode LIKE '%_1' AND cw.WeeklyCompleted >= 1) OR
          (ad.AchievementCode LIKE '%_3' AND cw.WeeklyCompleted >= 3) OR
          (ad.AchievementCode LIKE '%_5' AND cw.WeeklyCompleted >= 5)
      )
),

DailyAchievements AS (
    -- DAILY SCORE Achievements
    SELECT DISTINCT
        ad.AchievementCode,
        ad.Title,
        ad.Description,
        ad.Points,
        'ASSIGNMENT' AS ResourceType,
        ds.HocSinhID,
        ds.ResourceID,
        'DAILY' AS AchievementPeriod
    FROM DailyScores ds
    INNER JOIN dbo.tblEL_Achievement_Definitions ad 
        ON ad.AchievementCode = ds.AchievementCode
    WHERE ad.IsDeleted = 0
      AND ad.PeriodType = 'DAILY'
      AND ds.AchievementCode IS NOT NULL
)
,
-------------------------------------------------------
-- KẾT QUẢ CUỐI CÙNG - CHUẨN BỊ INSERT VÀO tblEL_Achievements
-------------------------------------------------------
AllAchievements AS (
    SELECT 
        AchievementCode,
        Title,
        Description,
        Points,
        ResourceType,
        HocSinhID,
        ResourceID,
        AchievementPeriod
    FROM ForeverAchievements

    UNION ALL

    SELECT 
        AchievementCode,
        Title,
        Description,
        Points,
        ResourceType,
        HocSinhID,
        ResourceID,
        AchievementPeriod
    FROM WeeklyAchievements

    UNION ALL

    SELECT 
        AchievementCode,
        Title,
        Description,
        Points,
        ResourceType,
        HocSinhID,
        ResourceID,
        AchievementPeriod
    FROM DailyAchievements
),

-------------------------------------------------------
-- LỌC BỎ ACHIEVEMENTS ĐÃ TỒN TẠI (Tránh duplicate)
-------------------------------------------------------
NewAchievements AS (
    SELECT 
        a.HocSinhID,
        a.AchievementCode,
        a.Points AS PointsEarned,
        a.ResourceID AS ContextResourceID,
        a.ResourceType AS ContextResourceType,
        a.AchievementPeriod,
        CAST(GETDATE() AS DATE) AS EarnedDate
    FROM AllAchievements a
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.tblEL_Achievements ea
        WHERE ea.HocSinhID = a.HocSinhID
          AND ea.AchievementCode = a.AchievementCode
          AND ea.IsDeleted = 0
          AND (
              -- FOREVER: Chỉ check đã có chưa (không quan tâm ngày)
              (a.AchievementPeriod = 'FOREVER')
              
              -- WEEKLY: Check đã nhận trong tuần này chưa
              OR (a.AchievementPeriod = 'WEEKLY' 
                  AND DATEPART(YEAR, ea.EarnedDate) = DATEPART(YEAR, GETDATE())
                  AND DATEPART(WEEK, ea.EarnedDate) = DATEPART(WEEK, GETDATE()))
              
              -- DAILY: Check đã nhận cho bài này chưa (cùng ContextResourceID)
              OR (a.AchievementPeriod = 'DAILY' 
                  AND ea.ContextResourceID = a.ResourceID
                  AND CAST(ea.EarnedDate AS DATE) = CAST(GETDATE() AS DATE))
          )
    )
)

-------------------------------------------------------
-- INSERT VÀO BẢNG tblEL_Achievements
-------------------------------------------------------
INSERT INTO dbo.tblEL_Achievements (
    HocSinhID,
    AchievementCode,
    PointsEarned,
    ContextResourceID,
    ContextResourceType,
    EarnedDate,
    NienKhoa,
    IsDeleted,
    CreateTime,
    CreateUser
)
SELECT 
    HocSinhID,
    AchievementCode,
    PointsEarned,
    ContextResourceID,
    ContextResourceType,
    EarnedDate,
    YEAR(GETDATE()) AS NienKhoa,
    0 AS IsDeleted,
    GETDATE() AS CreateTime,
    @HocSinhID AS CreateUser
FROM NewAchievements
ORDER BY PointsEarned DESC;

-------------------------------------------------------
-- TRẢ VỀ KẾT QUẢ ĐÃ INSERT
-------------------------------------------------------
SELECT 
    ea.AchievementID,
    ea.HocSinhID,
    ea.AchievementCode,
    ad.Title,
    ad.Description,
    ea.PointsEarned,
    ea.ContextResourceID,
    ea.ContextResourceType,
    ea.EarnedDate,
    ad.PeriodType AS AchievementPeriod,
    ea.CreateTime
FROM dbo.tblEL_Achievements ea
INNER JOIN dbo.tblEL_Achievement_Definitions ad 
    ON ea.AchievementCode = ad.AchievementCode
WHERE ea.HocSinhID = @HocSinhID
  AND ea.IsDeleted = 0
  AND ea.CreateTime >= DATEADD(SECOND, -5, GETDATE())  -- Chỉ lấy achievements vừa insert
ORDER BY ea.CreateTime DESC;
END 
 