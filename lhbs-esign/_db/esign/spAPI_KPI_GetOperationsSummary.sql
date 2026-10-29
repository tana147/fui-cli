-- ===================================================================================
-- STORED PROCEDURE: spAPI_KPI_GetOperationsSummary
-- Mô tả: Dynamic Operations Summary & CRM Pipeline Data
-- Trả về dữ liệu An toàn ME School, Phễu CRM, Kênh tiếp cận và Prospects
-- 100% ĐỘNG: Đọc trực tiếp từ kho snapshot đóng băng theo PeriodKey & ScopeID
-- KHÔNG CÒN BẤT KỲ MỆNH ĐỀ VALUES HARDCODE NÀO
-- Database: eSignature
-- ===================================================================================

CREATE   PROCEDURE spAPI_KPI_GetOperationsSummary
    @PeriodKey VARCHAR(20),
    @ScopeID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    IF @ScopeID IS NULL OR @ScopeID = ''
        SET @ScopeID = 'ALL';

    -- 1. RESULT SET 0: AN TOÀN HỌC ĐƯỜNG & ME SCHOOL
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_Safety_Me')
    BEGIN
        SELECT TOP 1
            FoodPoisoningCases,
            AccidentCases,
            BoardingRate,
            BoardingStudents,
            MeAppInstallRate,
            MeAppInstallParents,
            NewsInteractions,
            FaceIdCheckins,
            SatisfactionRate
        FROM tblKPI_Snap_Safety_Me
        WHERE PeriodKey = @PeriodKey
          AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
        ORDER BY CASE WHEN ScopeID = @ScopeID THEN 0 ELSE 1 END;
    END
    ELSE
    BEGIN
        SELECT 
            CAST(0 AS INT) AS FoodPoisoningCases,
            CAST(0 AS INT) AS AccidentCases,
            CAST(NULL AS DECIMAL(9,2)) AS BoardingRate,
            CAST(0 AS INT) AS BoardingStudents,
            CAST(NULL AS DECIMAL(9,2)) AS MeAppInstallRate,
            CAST(0 AS INT) AS MeAppInstallParents,
            CAST(NULL AS INT) AS NewsInteractions,
            CAST(NULL AS INT) AS FaceIdCheckins,
            CAST(NULL AS DECIMAL(9,2)) AS SatisfactionRate
        WHERE 1 = 0;
    END;

    -- 2. RESULT SET 1: DIỄN BIẾN LEADS CRM 3 THÁNG
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_Pipeline')
    BEGIN
        SELECT 
            ReportMonth AS [month],
            PtlcLeads AS ptlcLeads,
            MnbhLeads AS mnbhLeads,
            MnlkLeads AS mnlkLeads,
            TotalLeads AS totalLeads,
            EnrolledStudents AS totalEnrolled,
            FORMAT(ConversionRatePct, 'N1') + '%' AS [rate]
        FROM tblKPI_Snap_CRM_Pipeline
        WHERE PeriodKey = @PeriodKey
        ORDER BY RecordID;
    END
    ELSE
    BEGIN
        SELECT 
            CAST(NULL AS NVARCHAR(50)) AS [month],
            CAST(0 AS INT) AS ptlcLeads,
            CAST(0 AS INT) AS mnbhLeads,
            CAST(0 AS INT) AS mnlkLeads,
            CAST(0 AS INT) AS totalLeads,
            CAST(0 AS INT) AS totalEnrolled,
            CAST(NULL AS NVARCHAR(50)) AS [rate]
        WHERE 1 = 0;
    END;

    -- 3. RESULT SET 2: HIỆU QUẢ KÊNH TIẾP CẬN (CHANNELS)
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_Channels')
    BEGIN
        SELECT 
            ChannelName AS [channel],
            LeadsCount AS leads,
            FORMAT(LeadsPct, 'N1') + '%' AS pct,
            EnrolledCount AS enrolled,
            FORMAT(ConvRatePct, 'N1') + '%' AS convRate
        FROM tblKPI_Snap_CRM_Channels
        WHERE PeriodKey = @PeriodKey
          AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
        ORDER BY RankOrder, RecordID;
    END
    ELSE
    BEGIN
        SELECT 
            CAST(NULL AS NVARCHAR(250)) AS [channel],
            CAST(0 AS INT) AS leads,
            CAST(NULL AS NVARCHAR(50)) AS pct,
            CAST(0 AS INT) AS enrolled,
            CAST(NULL AS NVARCHAR(50)) AS convRate
        WHERE 1 = 0;
    END;

    -- 4. RESULT SET 3: PIPELINE PROSPECTS / HẸN KỲ SAU (KITTY & CÁC CẤP)
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_Prospects')
    BEGIN
        SELECT 
            Stt AS stt,
            MonthLabel AS [thang],
            ParentName AS [tenPH],
            ClassOrTarget AS [lop],
            StudentName AS [tenHS],
            StatusDescription AS [tinhTrang],
            AppointmentNote AS [hen]
        FROM tblKPI_Snap_CRM_Prospects
        WHERE PeriodKey = @PeriodKey
          AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
        ORDER BY RankOrder, RecordID;
    END
    ELSE
    BEGIN
        SELECT 
            CAST(0 AS INT) AS stt,
            CAST(NULL AS NVARCHAR(50)) AS [thang],
            CAST(NULL AS NVARCHAR(200)) AS [tenPH],
            CAST(NULL AS NVARCHAR(100)) AS [lop],
            CAST(NULL AS NVARCHAR(200)) AS [tenHS],
            CAST(NULL AS NVARCHAR(500)) AS [tinhTrang],
            CAST(NULL AS NVARCHAR(500)) AS [hen]
        WHERE 1 = 0;
    END;

    -- 5. RESULT SET 4: NGUYÊN NHÂN RỚT HỒ SƠ
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_DropReasons')
    BEGIN
        SELECT 
            ReasonText AS [reason],
            ReasonCount AS [count],
            FORMAT(ReasonPct, 'N1') + '%' AS pct,
            SolutionAction AS [solution]
        FROM tblKPI_Snap_CRM_DropReasons
        WHERE PeriodKey = @PeriodKey
          AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
        ORDER BY RankOrder, RecordID;
    END
    ELSE
    BEGIN
        SELECT 
            CAST(NULL AS NVARCHAR(500)) AS [reason],
            CAST(0 AS INT) AS [count],
            CAST(NULL AS NVARCHAR(50)) AS pct,
            CAST(NULL AS NVARCHAR(500)) AS [solution]
        WHERE 1 = 0;
    END;
END;
