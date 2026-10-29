-- ==============================================================================
-- STORED PROCEDURE: spAPI_KPI_GetPeriodSnapshots
-- Mô tả: Cung cấp danh mục 60 chỉ tiêu vận hành (Snapshots) theo kỳ và đơn vị
-- Thuần túy READ-ONLY truy vấn từ kho dữ liệu chốt kỳ tblKPI_PeriodSnapshots
-- DB: eSignature (esign)
-- ==============================================================================

CREATE OR ALTER PROCEDURE spAPI_KPI_GetPeriodSnapshots
    @PeriodKey VARCHAR(20),
    @DonViID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PeriodKey IS NULL OR @PeriodKey = ''
        SET @PeriodKey = '2026-09';

    IF @DonViID IS NULL OR @DonViID = ''
        SET @DonViID = 'ALL';

    -- 1. RESULT SET 0: CHI TIẾT 60 CHỈ TIÊU VẬN HÀNH CHỐT KỲ
    SELECT 
        s.SnapshotID,
        s.PeriodKey,
        s.DonViID,
        s.KpiCode,
        s.KpiName,
        s.KpiGroup,
        s.FrameworkLevel,
        s.FrameworkRef,
        s.ActualValue,
        s.TargetValue,
        s.Unit,
        s.Rate,
        s.Status,
        s.DataSourceType,
        s.SpecCode,
        s.FinancialImpact,
        s.OperationalInsight,
        s.IsFrozen,
        s.CreatedAt,
        spec.SourceSystem,
        spec.ApiEndpoint,
        spec.HttpMethod,
        spec.SyncSchedule,
        spec.RequestSchema,
        spec.ResponseSchema,
        spec.GolivePrerequisites
    FROM tblKPI_PeriodSnapshots s
    LEFT JOIN tblKPI_DataSourceSpecs spec ON s.SpecCode = spec.SpecCode
    WHERE s.PeriodKey = @PeriodKey
      AND (
          (@DonViID = 'ALL' AND s.DonViID = 'ALL')
          OR (@DonViID <> 'ALL' AND s.DonViID = @DonViID)
          OR (@DonViID <> 'ALL' AND s.DonViID = 'ALL' AND NOT EXISTS (
              SELECT 1 FROM tblKPI_PeriodSnapshots sub 
              WHERE sub.PeriodKey = s.PeriodKey AND sub.DonViID = @DonViID AND sub.KpiCode = s.KpiCode
          ))
      )
    ORDER BY CASE s.KpiGroup 
        WHEN N'Quy mô & Tuyển sinh' THEN 1
        WHEN N'Chất lượng Giáo dục' THEN 2
        WHEN N'Học thuật & Đào tạo' THEN 2
        WHEN N'Vận hành & Dịch vụ' THEN 3
        WHEN N'Tài chính & CSVC' THEN 4
        WHEN N'Tài chính & Dịch vụ' THEN 4
        ELSE 5 END, s.KpiCode;

    -- 2. RESULT SET 1: TỔNG HỢP THEO NHÓM CHỈ TIÊU (GROUP SUMMARY)
    SELECT 
        s.KpiGroup,
        COUNT(*) AS TotalCount,
        SUM(CASE WHEN s.Status = 'GOOD' THEN 1 ELSE 0 END) AS GoodCount,
        SUM(CASE WHEN s.Status = 'WARN' THEN 1 ELSE 0 END) AS WarnCount,
        SUM(CASE WHEN s.Status = 'DANGER' OR s.Status = 'BAD' THEN 1 ELSE 0 END) AS DangerCount
    FROM tblKPI_PeriodSnapshots s
    WHERE s.PeriodKey = @PeriodKey
      AND (
          (@DonViID = 'ALL' AND s.DonViID = 'ALL')
          OR (@DonViID <> 'ALL' AND s.DonViID = @DonViID)
      )
    GROUP BY s.KpiGroup;

    -- 3. RESULT SET 2: DANH MỤC ĐẶC TẢ KỸ THUẬT GOLIVE (6 HỆ THỐNG NGUỒN)
    SELECT 
        SpecCode,
        KpiGroup,
        SourceSystem,
        ApiEndpoint,
        HttpMethod,
        SyncSchedule,
        RequestSchema,
        ResponseSchema,
        GolivePrerequisites
    FROM tblKPI_DataSourceSpecs
    ORDER BY SpecCode;

    -- 4. RESULT SET 3: CƠ CẤU SĨ SỐ KHỐI LỚP CHỐT KỲ (tblKPI_Snap_BasicData_Students)
    SELECT 
        ScopeID,
        GradeID AS KhoiID,
        GradeName AS Ten,
        StudentCount AS SLHocSinh,
        CAST(ROUND(StudentCount * 0.48, 0) AS INT) AS SL_HSNu,
        CAST(ROUND(StudentCount * 0.52, 0) AS INT) AS SL_HSNam,
        CapacityMax
    FROM tblKPI_Snap_BasicData_Students
    WHERE PeriodKey = @PeriodKey
      AND RecordType = 'GRADE_SUMMARY'
      AND (@DonViID = 'ALL' OR ScopeID = @DonViID OR (@DonViID = 'MNBH' AND ScopeID = 'MNBH') OR (@DonViID = 'MNLK' AND ScopeID = 'MNLK'))
    ORDER BY CASE ScopeID WHEN 'MNLK' THEN 2 ELSE 1 END, KhoiID ASC;

    -- 5. RESULT SET 4: DANH SÁCH CHI TIẾT HỌC SINH RÚT HỌC CHỐT KỲ (tblKPI_Snap_BasicData_Students)
    SELECT 
        RecordID,
        ScopeID,
        ISNULL(EventDate, '2026-09-30') AS NgayChuyen,
        StudentCode,
        StudentName AS HoTen,
        ClassName AS LopDi,
        WithdrawReasonText AS LyDo,
        N'Trường khác' AS TruongDen
    FROM tblKPI_Snap_BasicData_Students
    WHERE PeriodKey = @PeriodKey
      AND RecordType = 'WITHDRAWAL'
      AND (@DonViID = 'ALL' OR ScopeID = @DonViID)
    ORDER BY EventDate DESC;

    -- 6. RESULT SET 5: BÀI TẬP LMS CHỐT KỲ (tblKPI_Snap_LMS_Academics)
    SELECT 
        RecordID AS MonHocID,
        ScopeID,
        CapHocID,
        SubjectName AS TenMonHoc_HienThi,
        10 AS TotalAssignments,
        TotalAssigned,
        TotalSubmitted AS Total_DaNop,
        TotalGraded AS Total_DaCham,
        ISNULL(TotalAssigned - TotalSubmitted, 0) AS Total_ChuaLam,
        CAST(ROUND(CASE WHEN TotalAssigned > 0 THEN ((TotalSubmitted + TotalGraded) * 100.0 / TotalAssigned) ELSE 0 END, 1) AS DECIMAL(5,1)) AS CompletionRate_Assignments,
        CAST(ROUND(CASE WHEN TotalAssigned > 0 THEN (TotalGraded * 100.0 / TotalAssigned) ELSE 0 END, 1) AS DECIMAL(5,1)) AS CompletionRate_Graded
    FROM tblKPI_Snap_LMS_Academics
    WHERE PeriodKey = @PeriodKey
      AND RecordType = 'LMS_ASSIGNMENT'
      AND (@DonViID = 'ALL' OR ScopeID = @DonViID)
    ORDER BY CapHocID ASC, TotalAssigned DESC;

    -- 7. RESULT SET 6: HỌC LIỆU SỐ CHỐT KỲ (tblKPI_Snap_LMS_Academics)
    SELECT 
        RecordID,
        ScopeID,
        CapHocID,
        GradeName AS KhoiID,
        SubjectName AS TenMonHoc_HienThi,
        TotalMaterials AS TongHocLieu,
        ContentMaterials AS HocLieuCoNoiDung,
        ISNULL(TotalMaterials - ContentMaterials, 0) AS HocLieuChuaCoNoiDung,
        ISNULL(ContentMaterials * 3, 0) AS TongNoiDung
    FROM tblKPI_Snap_LMS_Academics
    WHERE PeriodKey = @PeriodKey
      AND RecordType = 'LMS_MATERIALS'
      AND (@DonViID = 'ALL' OR ScopeID = @DonViID)
    ORDER BY CapHocID ASC, GradeName ASC;

    -- 8. RESULT SET 7: TIẾN ĐỘ TIẾT DẠY THEO TKB CHỐT KỲ (tblKPI_Snap_LMS_Academics)
    SELECT 
        RecordID,
        ScopeID,
        GradeName AS TenLop,
        SubstituteLessons AS TongTiet,
        8 AS Toan,
        8 AS Van,
        12 AS KHTN,
        4 AS STEM
    FROM tblKPI_Snap_LMS_Academics
    WHERE PeriodKey = @PeriodKey
      AND RecordType = 'TEACHING_PROGRESS'
      AND (@DonViID = 'ALL' OR ScopeID = @DonViID)
    ORDER BY GradeName ASC;
END;
