-- ===================================================================================
-- STORED PROCEDURE: spAPI_KPI_GetOperationalFacts (QUERY ROUTING ENGINE)
-- Mô tả: Cung cấp danh mục giao dịch chi tiết phục vụ Slide Drawer đối soát 1-1
-- Định tuyến truy vấn trực tiếp vào các bảng Snapshot chuyên biệt theo từng nguồn
-- Database: eSignature
-- ===================================================================================

CREATE   PROCEDURE spAPI_KPI_GetOperationalFacts
    @DomainCode VARCHAR(50),
    @PeriodKey VARCHAR(20),
    @ScopeID VARCHAR(50),
    @Status VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF @DomainCode IS NULL OR @DomainCode = ''
        SET @DomainCode = 'LEAVE';

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    IF @ScopeID IS NULL OR @ScopeID = ''
        SET @ScopeID = 'ALL';

    IF @Status IS NULL OR @Status = '' OR @Status = 'ALL'
        SET @Status = NULL;

    -- 1. ĐỊNH TUYẾN 1: NGHỈ PHÉP NHÂN SỰ (LEAVE)
    IF @DomainCode = 'LEAVE'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_HRM_Leave')
        BEGIN
            SELECT 
                RecordID AS FactID,
                PeriodKey,
                ScopeID,
                EmployeeCode AS EntityCode,
                EmployeeName AS EntityName,
                Department AS Dim1,
                LeaveType AS Dim2,
                Reason AS Dim3,
                NULL AS Dim4,
                LeaveDays AS MetricCount,
                NULL AS MetricAmount,
                Status,
                FromDate AS OccurredDate,
                'HRM' AS SourceSystem
            FROM tblKPI_Snap_HRM_Leave
            WHERE PeriodKey = @PeriodKey
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
              AND (@Status IS NULL OR Status = @Status)
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 2. ĐỊNH TUYẾN 2: Y TẾ HỌC ĐƯỜNG (HEALTH)
    ELSE IF @DomainCode = 'HEALTH'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_Healthcare')
        BEGIN
            SELECT 
                RecordID AS FactID,
                PeriodKey,
                ScopeID,
                StudentCode AS EntityCode,
                StudentName AS EntityName,
                ClassName AS Dim1,
                DiseaseGroup AS Dim2,
                DiseaseType AS Dim3,
                Diagnosis AS Dim4,
                1.0 AS MetricCount,
                NULL AS MetricAmount,
                Status,
                OccurredDate,
                'YTE' AS SourceSystem
            FROM tblKPI_Snap_Healthcare
            WHERE PeriodKey = @PeriodKey
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
              AND (@Status IS NULL OR Status = @Status)
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 3. ĐỊNH TUYẾN 3: BẢO TRÌ CƠ SỞ VẬT CHẤT (MAINTENANCE)
    ELSE IF @DomainCode = 'MAINTENANCE'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_Maintenance')
        BEGIN
            SELECT 
                RecordID AS FactID,
                PeriodKey,
                ScopeID,
                TicketCode AS EntityCode,
                Category AS EntityName,
                Location AS Dim1,
                IssueDescription AS Dim2,
                Category AS Dim3,
                CASE WHEN IsOverdue = 1 THEN N'Quá hạn 24h' ELSE N'Trong hạn' END AS Dim4,
                1.0 AS MetricCount,
                NULL AS MetricAmount,
                Status,
                ReportedDate AS OccurredDate,
                'CSVC' AS SourceSystem
            FROM tblKPI_Snap_Maintenance
            WHERE PeriodKey = @PeriodKey
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
              AND (@Status IS NULL OR Status = @Status)
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 4. ĐỊNH TUYẾN 4: BIẾN ĐỘNG NHÂN SỰ (HR_TURNOVER)
    ELSE IF @DomainCode = 'HR_TURNOVER'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_HRM_Turnover')
        BEGIN
            SELECT 
                RecordID AS FactID,
                PeriodKey,
                ScopeID,
                EmployeeCode AS EntityCode,
                EmployeeName AS EntityName,
                Department AS Dim1,
                JobTitle AS Dim2,
                ChangeType AS Dim3,
                Reason AS Dim4,
                1.0 AS MetricCount,
                NULL AS MetricAmount,
                'APPROVED' AS Status,
                EffectiveDate AS OccurredDate,
                'HRM' AS SourceSystem
            FROM tblKPI_Snap_HRM_Turnover
            WHERE PeriodKey = @PeriodKey
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 5. ĐỊNH TUYẾN 5: TIẾT DẠY THAY & CHUYÊN MÔN (TEACHING)
    ELSE IF @DomainCode = 'TEACHING'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_LMS_Academics')
        BEGIN
            SELECT 
                RecordID AS FactID,
                PeriodKey,
                ScopeID,
                TeacherName AS EntityCode,
                TeacherName AS EntityName,
                GradeName AS Dim1,
                SubjectName AS Dim2,
                SubstituteReason AS Dim3,
                NULL AS Dim4,
                SubstituteLessons AS MetricCount,
                NULL AS MetricAmount,
                'COMPLETED' AS Status,
                @PeriodKey AS OccurredDate,
                'LMS' AS SourceSystem
            FROM tblKPI_Snap_LMS_Academics
            WHERE PeriodKey = @PeriodKey
              AND RecordType = 'DAY_THAY'
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 6. ĐỊNH TUYẾN 6: DỊCH VỤ CÂU LẠC BỘ (CLUB)
    ELSE IF @DomainCode = 'CLUB'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_Finance_Services')
        BEGIN
            SELECT 
                RecordID AS FactID,
                PeriodKey,
                ScopeID,
                ItemCode AS EntityCode,
                ItemName AS EntityName,
                CategoryType AS Dim1,
                CAST(StudentCount AS NVARCHAR(50)) + N' học sinh' AS Dim2,
                N'Doanh thu KH: ' + FORMAT(PlanTargetRevenue, 'N0') + N' đ' AS Dim3,
                N'Đạt: ' + CAST(PlanAchievedPct AS NVARCHAR(50)) + '%' AS Dim4,
                StudentCount AS MetricCount,
                NetRevenue AS MetricAmount,
                CASE WHEN PlanAchievedPct >= 100 THEN 'COMPLETED' ELSE 'PENDING' END AS Status,
                @PeriodKey AS OccurredDate,
                'FTS' AS SourceSystem
            FROM tblKPI_Snap_Finance_Services
            WHERE PeriodKey = @PeriodKey
              AND CategoryType = 'CLUB'
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 6. FALLBACK AN TOÀN: NẾU BẢNG MỚI CHƯA ĐƯỢC CHẠY, TRUY VẤN TỪ BẢNG CŨ
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_OperationalFacts')
    BEGIN
        SELECT 
            FactID,
            PeriodKey,
            ScopeID,
            EntityCode,
            EntityName,
            Dim1,
            Dim2,
            Dim3,
            Dim4,
            MetricCount,
            MetricAmount,
            Status,
            OccurredDate,
            SourceSystem
        FROM tblKPI_OperationalFacts
        WHERE PeriodKey = @PeriodKey
          AND DomainCode = @DomainCode
          AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
          AND (@Status IS NULL OR Status = @Status)
        ORDER BY FactID;
    END
END;
