-- ==============================================================================
-- MIGRATION: ĐỒNG BỘ ĐẦY ĐỦ 60 CHỈ TIÊU VẬN HÀNH VÀO KHO SNAPSHOT CHỐT KỲ
-- Căn cứ: docs/2026.10.19_Phương án xây dựng Dashboard vận hành.docx & docs/KPI_DASHBOARD_CHECKLIST.md
-- Database: eSignature (esign)
-- ==============================================================================

INSERT INTO tblKPI_PeriodSnapshots (
    PeriodKey, DonViID, KpiCode, KpiName, KpiGroup, 
    FrameworkLevel, FrameworkRef, ActualValue, TargetValue, Unit, 
    Rate, Status, DataSourceType, SpecCode, FinancialImpact, OperationalInsight, IsFrozen
)
SELECT 
    '2026-09' AS PeriodKey,
    'ALL' AS DonViID,
    d.KpiCode,
    d.KpiName,
    d.KpiGroup,
    CASE 
        WHEN d.FrameworkRef IS NOT NULL THEN 'Level 1'
        WHEN d.KpiCode IN ('CM09', 'CM10', 'CM13', 'CM14', 'DV31', 'DV33', 'DV34', 'TC53', 'TC54') THEN 'Level 2'
        ELSE 'Level 3'
    END AS FrameworkLevel,
    d.FrameworkRef,
    0.0 AS ActualValue,
    ISNULL(d.DefaultTarget, 0.0) AS TargetValue,
    d.Unit,
    0.0 AS Rate,
    'PENDING' AS Status,
    'API_PENDING' AS DataSourceType,
    CASE 
        WHEN d.KpiGroup = N'Giáo dục & Học thuật' THEN 'SPEC_LMS'
        WHEN d.KpiCode IN ('DV41', 'DV38', 'DV39', 'DV40') THEN 'SPEC_YTE'
        WHEN d.KpiCode IN ('DV44', 'DV50', 'DV51') THEN 'SPEC_QA'
        WHEN d.KpiGroup = N'Dịch vụ & An toàn' THEN 'SPEC_HOCPHI'
        WHEN d.KpiGroup = N'Tài chính & CSVC' THEN 'SPEC_EXCEL_INTERNAL'
        ELSE 'SPEC_BASICDATA'
    END AS SpecCode,
    N'Lộ trình tích hợp kết nối API trước ngày 02/11/2026' AS FinancialImpact,
    N'Chờ kết nối API từ ' + d.SourceSystem + N' theo biên bản họp BĐH ngày 19/10/2026' AS OperationalInsight,
    1 AS IsFrozen
FROM tblKPI_Definitions d
WHERE NOT EXISTS (
    SELECT 1 FROM tblKPI_PeriodSnapshots s 
    WHERE s.PeriodKey = '2026-09' AND s.DonViID = 'ALL' 
      AND (s.KpiCode = d.KpiCode 
           OR (d.KpiCode = 'DV28' AND s.KpiCode = 'VH28')
           OR (d.KpiCode = 'DV29' AND s.KpiCode = 'VH29')
           OR (d.KpiCode = 'DV35' AND s.KpiCode = 'VH35')
           OR (d.KpiCode = 'DV36' AND s.KpiCode = 'VH36')
           OR (d.KpiCode = 'DV38' AND s.KpiCode = 'VH38')
           OR (d.KpiCode = 'DV39' AND s.KpiCode = 'SK01')
           OR (d.KpiCode = 'DV40' AND s.KpiCode = 'SK02')
           OR (d.KpiCode = 'DV50' AND s.KpiCode = 'QA50')
           OR (d.KpiCode = 'TC52' AND s.KpiCode = 'HR01')
           OR (d.KpiCode = 'TC59' AND s.KpiCode = 'CSVC01')
           OR (d.KpiCode = 'TC60' AND s.KpiCode = 'CSVC02')
           OR (d.KpiCode = 'CM11' AND s.KpiCode = 'CM04')
           OR (d.KpiCode = 'CM15' AND s.KpiCode = 'CM08')
           OR (d.KpiCode = 'CM23' AND s.KpiCode = 'QA23'))
);
