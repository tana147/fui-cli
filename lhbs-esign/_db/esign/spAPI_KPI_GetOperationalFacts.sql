-- ===================================================================================
-- STORED PROCEDURE: spAPI_KPI_GetOperationalFacts (QUERY ROUTING ENGINE)
-- Mô tả: Cung cấp danh mục giao dịch chi tiết phục vụ Hộp thoại / Drawer đối soát 1-1
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
        SET @DomainCode = 'ENROLLMENT';

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    IF @ScopeID IS NULL OR @ScopeID = ''
        SET @ScopeID = 'ALL';

    IF @Status IS NULL OR @Status = ''
        SET @Status = 'ALL';

    IF @Status IS NULL OR @Status = '' OR @Status = 'ALL'
        SET @Status = NULL;

    -- 1A. ĐỊNH TUYẾN 1A: SĨ SỐ HỌC SINH & CÔNG SUẤT PHÒNG HỌC (ENROLLMENT / STUDENTS / TS01 / TS02)
    IF @DomainCode = 'ENROLLMENT' OR @DomainCode = 'STUDENTS' OR @DomainCode = 'TS01' OR @DomainCode = 'TS02'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_BasicData_Students')
        BEGIN
            SELECT 
                RecordID AS FactID,
                PeriodKey,
                ScopeID,
                ScopeID + '_' + CAST(GradeID AS VARCHAR(10)) AS EntityCode,
                GradeName + CASE WHEN ClassName IS NOT NULL AND ClassName != '' AND ClassName != GradeName THEN ' (' + ClassName + ')' ELSE '' END AS EntityName,
                ScopeID AS Dim1,
                GradeName AS Dim2,
                N'Sĩ số hiện diện: ' + CAST(StudentCount AS NVARCHAR(20)) + N' HS / Công suất ' + CAST(ISNULL(CapacityMax, 0) AS NVARCHAR(20)) + N' chỗ' AS Dim3,
                N'Lấp đầy: ' + CAST(ROUND(CASE WHEN ISNULL(CapacityMax, 0) > 0 THEN (StudentCount * 100.0 / CapacityMax) ELSE 0 END, 1) AS NVARCHAR(20)) + '%' AS Dim4,
                StudentCount AS MetricCount,
                CapacityMax AS MetricAmount,
                CASE 
                    WHEN ISNULL(CapacityMax, 0) > 0 AND (StudentCount * 100.0 / CapacityMax) >= 85 THEN 'COMPLETED' 
                    WHEN ISNULL(CapacityMax, 0) > 0 AND (StudentCount * 100.0 / CapacityMax) >= 70 THEN 'PENDING' 
                    ELSE 'CRITICAL' 
                END AS Status,
                @PeriodKey AS OccurredDate,
                'BASIC_DATA' AS SourceSystem
            FROM tblKPI_Snap_BasicData_Students
            WHERE PeriodKey = @PeriodKey
              AND RecordType != 'WITHDRAWAL'
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
            ORDER BY ScopeID, GradeID;
            RETURN;
        END;
    END

    -- 1B. ĐỊNH TUYẾN 1B: HỌC SINH RÚT HỌC & SIS (WITHDRAWAL / TS04)
    ELSE IF @DomainCode = 'WITHDRAWAL' OR @DomainCode = 'TS04'
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_BasicData_Students')
        BEGIN
            SELECT 
                RecordID AS FactID,
                PeriodKey,
                ScopeID,
                ISNULL(StudentCode, 'HS' + CAST(RecordID AS VARCHAR(20))) AS EntityCode,
                ISNULL(StudentName, ClassName) AS EntityName,
                GradeName AS Dim1,
                ClassName AS Dim2,
                ISNULL(WithdrawReasonText, N'Rút học / Chuyển trường') AS Dim3,
                ISNULL(WithdrawReasonCode, RecordType) AS Dim4,
                StudentCount AS MetricCount,
                NULL AS MetricAmount,
                CASE 
                    WHEN WithdrawReasonCode LIKE '%DISTANCE%' OR WithdrawReasonCode LIKE '%BUS%' THEN 'CRITICAL' 
                    ELSE 'COMPLETED' 
                END AS Status,
                ISNULL(EventDate, @PeriodKey) AS OccurredDate,
                'SIS' AS SourceSystem
            FROM tblKPI_Snap_BasicData_Students
            WHERE PeriodKey = @PeriodKey
              AND RecordType = 'WITHDRAWAL'
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
              AND (
                  @Status IS NULL 
                  OR (@Status = 'CRITICAL' AND (WithdrawReasonCode LIKE '%DISTANCE%' OR WithdrawReasonCode LIKE '%BUS%'))
                  OR (@Status = 'PENDING' AND (WithdrawReasonCode LIKE '%DISTANCE%' OR WithdrawReasonCode LIKE '%BUS%'))
                  OR (@Status = 'COMPLETED' AND WithdrawReasonCode NOT LIKE '%DISTANCE%' AND WithdrawReasonCode NOT LIKE '%BUS%')
              )
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 2. ĐỊNH TUYẾN 2: TUYỂN SINH & PHỄU CRM (CRM / PROSPECTS / TS03 / TS05 / TS06 / TS07)
    ELSE IF @DomainCode = 'CRM' OR @DomainCode = 'PROSPECTS' OR @DomainCode IN ('TS03', 'TS05', 'TS06', 'TS07')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_CRM_Prospects')
        BEGIN
            SELECT 
                RecordID AS FactID,
                PeriodKey,
                ScopeID,
                ISNULL(CampaignCode, 'CRM') AS EntityCode,
                ParentName + CASE WHEN StudentName IS NOT NULL AND StudentName != '' THEN N' (Bé: ' + StudentName + N')' ELSE '' END AS EntityName,
                ISNULL(CampaignCode, 'CRM') AS Dim1,
                ISNULL(ClassOrTarget, N'Mầm non') AS Dim2,
                ISNULL(StatusDescription, N'Tiềm năng') AS Dim3,
                AppointmentNote AS Dim4,
                1.0 AS MetricCount,
                NULL AS MetricAmount,
                CASE 
                    WHEN StatusDescription LIKE N'%Hẹn HK2%' OR StatusDescription LIKE N'%Chưa đủ tuổi%' THEN 'PENDING' 
                    ELSE 'COMPLETED' 
                END AS Status,
                @PeriodKey AS OccurredDate,
                'CRM' AS SourceSystem
            FROM tblKPI_Snap_CRM_Prospects
            WHERE PeriodKey = @PeriodKey
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
              AND (
                  @Status IS NULL 
                  OR (@Status = 'PENDING' AND (StatusDescription LIKE N'%Hẹn HK2%' OR StatusDescription LIKE N'%Chưa đủ tuổi%'))
                  OR (@Status = 'CRITICAL' AND StatusDescription LIKE N'%Hẹn HK2%')
                  OR (@Status = 'COMPLETED' AND StatusDescription NOT LIKE N'%Hẹn HK2%' AND StatusDescription NOT LIKE N'%Chưa đủ tuổi%')
              )
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 3. ĐỊNH TUYẾN 3: AN TOÀN, ĐIỂM DANH FACEID & APP ME & BÁN TRÚ (SAFETY_ME / DV28-DV37)
    ELSE IF @DomainCode = 'SAFETY_ME' OR @DomainCode = 'ME_APP' 
         OR @DomainCode IN ('DV28', 'DV29', 'DV30', 'DV31', 'DV32', 'DV33', 'DV34', 'DV35', 'DV36', 'DV37', 'DV50', 'DV51')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblKPI_Snap_Safety_Me')
        BEGIN
            SELECT 
                1 AS FactID,
                PeriodKey,
                ScopeID,
                'FACEID_01' AS EntityCode,
                N'Hệ thống Điểm danh FaceID Cổng trường' AS EntityName,
                N'Cổng chính & Xe Bus' AS Dim1,
                N'Điểm danh tự động' AS Dim2,
                N'Tổng lượt checkin nhận diện trong kỳ chốt sổ' AS Dim3,
                N'Đạt SLA kết nối 99.8%' AS Dim4,
                FaceIdCheckins AS MetricCount,
                NULL AS MetricAmount,
                'COMPLETED' AS Status,
                @PeriodKey AS OccurredDate,
                'ME_APP' AS SourceSystem
            FROM tblKPI_Snap_Safety_Me
            WHERE PeriodKey = @PeriodKey
            UNION ALL
            SELECT 
                2 AS FactID,
                PeriodKey,
                ScopeID,
                'MEAPP_01' AS EntityCode,
                N'Tỷ lệ Cài đặt Ứng dụng Phụ huynh Me School' AS EntityName,
                N'Toàn trường' AS Dim1,
                N'Cổng thông tin PH' AS Dim2,
                N'Đạt tỷ lệ cài đặt ' + CAST(MeAppInstallRate AS NVARCHAR(20)) + '%' AS Dim3,
                N'Lũy kế ' + CAST(MeAppInstallParents AS NVARCHAR(20)) + N' phụ huynh kích hoạt' AS Dim4,
                MeAppInstallParents AS MetricCount,
                NULL AS MetricAmount,
                'COMPLETED' AS Status,
                @PeriodKey AS OccurredDate,
                'ME_APP' AS SourceSystem
            FROM tblKPI_Snap_Safety_Me
            WHERE PeriodKey = @PeriodKey
            UNION ALL
            SELECT 
                3 AS FactID,
                PeriodKey,
                ScopeID,
                'BOARDING_01' AS EntityCode,
                N'Dịch vụ Suất ăn Bán trú & An toàn VSTP' AS EntityName,
                N'Bếp ăn trung tâm' AS Dim1,
                N'Bán trú ISO 22000' AS Dim2,
                N'Đạt tỷ lệ ăn bán trú ' + CAST(BoardingRate AS NVARCHAR(20)) + '%' AS Dim3,
                N'Số ca ngộ độc: ' + CAST(FoodPoisoningCases AS NVARCHAR(20)) + N', Tai nạn: ' + CAST(AccidentCases AS NVARCHAR(20)) AS Dim4,
                BoardingStudents AS MetricCount,
                NULL AS MetricAmount,
                'COMPLETED' AS Status,
                @PeriodKey AS OccurredDate,
                'ME_APP' AS SourceSystem
            FROM tblKPI_Snap_Safety_Me
            WHERE PeriodKey = @PeriodKey;
            RETURN;
        END;
    END

    -- 4. ĐỊNH TUYẾN 4: NGHỈ PHÉP & CÔNG NHÂN SỰ (LEAVE / CM09 / TC54)
    ELSE IF @DomainCode = 'LEAVE' OR @DomainCode IN ('CM09', 'TC54')
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
                CASE WHEN LeaveDays > 3.0 THEN 'CRITICAL' ELSE 'COMPLETED' END AS Status,
                @PeriodKey AS OccurredDate,
                'HRM' AS SourceSystem
            FROM tblKPI_Snap_HRM_Leave
            WHERE PeriodKey = @PeriodKey
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
              AND (
                  @Status IS NULL 
                  OR (@Status = 'CRITICAL' AND LeaveDays > 3.0)
                  OR (@Status = 'PENDING' AND LeaveDays > 2.0)
                  OR (@Status = 'COMPLETED' AND LeaveDays <= 3.0)
              )
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 5. ĐỊNH TUYẾN 5: Y TẾ HỌC ĐƯỜNG (HEALTH / DV38-DV41)
    ELSE IF @DomainCode = 'HEALTH' OR @DomainCode IN ('DV38', 'DV39', 'DV40', 'DV41')
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
                CASE WHEN SeverityLevel = 'HIGH' OR SeverityLevel = 'CRITICAL' THEN 'CRITICAL' ELSE 'COMPLETED' END AS Status,
                ISNULL(OccurredDate, @PeriodKey) AS OccurredDate,
                'Y_TE' AS SourceSystem
            FROM tblKPI_Snap_Healthcare
            WHERE PeriodKey = @PeriodKey
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
              AND (
                  @Status IS NULL 
                  OR (@Status = 'CRITICAL' AND (SeverityLevel = 'HIGH' OR SeverityLevel = 'CRITICAL'))
                  OR (@Status = 'PENDING' AND (SeverityLevel = 'HIGH' OR SeverityLevel = 'CRITICAL'))
                  OR (@Status = 'COMPLETED' AND SeverityLevel != 'HIGH' AND SeverityLevel != 'CRITICAL')
              )
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 6. ĐỊNH TUYẾN 6: BẢO TRÌ CƠ SỞ VẬT CHẤT (MAINTENANCE / TC59 / TC60)
    ELSE IF @DomainCode = 'MAINTENANCE' OR @DomainCode IN ('TC59', 'TC60')
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
                CASE WHEN Status = 'PENDING' OR IsOverdue = 1 THEN 'CRITICAL' ELSE 'COMPLETED' END AS Status,
                ISNULL(ReportedDate, @PeriodKey) AS OccurredDate,
                'CSVC' AS SourceSystem
            FROM tblKPI_Snap_Maintenance
            WHERE PeriodKey = @PeriodKey
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
              AND (
                  @Status IS NULL 
                  OR (@Status = 'CRITICAL' AND (Status = 'PENDING' OR IsOverdue = 1))
                  OR (@Status = 'PENDING' AND (Status = 'PENDING' OR IsOverdue = 1))
                  OR (@Status = 'COMPLETED' AND Status = 'COMPLETED' AND IsOverdue = 0)
              )
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 7. ĐỊNH TUYẾN 7: BIẾN ĐỘNG NHÂN SỰ & NGHỈ VIỆC (HR_TURNOVER / TC52 / TC53)
    ELSE IF @DomainCode = 'HR_TURNOVER' OR @DomainCode IN ('TC52', 'TC53')
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
                'COMPLETED' AS Status,
                ISNULL(EffectiveDate, @PeriodKey) AS OccurredDate,
                'HRM' AS SourceSystem
            FROM tblKPI_Snap_HRM_Turnover
            WHERE PeriodKey = @PeriodKey
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 8. ĐỊNH TUYẾN 8: CHUYÊN MÔN, LMS & DẠY THAY (TEACHING / CM08-CM27)
    ELSE IF @DomainCode = 'TEACHING' OR @DomainCode LIKE 'CM%'
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
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 9. ĐỊNH TUYẾN 9: TÀI CHÍNH DỊCH VỤ & CLB NGOẠI KHÓA (CLUB / TC55 / TC56)
    ELSE IF @DomainCode = 'CLUB' OR @DomainCode IN ('TC55', 'TC56')
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
              AND (@ScopeID = 'ALL' OR ScopeID = @ScopeID)
            ORDER BY RecordID;
            RETURN;
        END;
    END

    -- 10. FALLBACK AN TOÀN: NẾU BẢNG MỚI CHƯA ĐƯỢC CHẠY, TRUY VẤN TỪ BẢNG CŨ
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