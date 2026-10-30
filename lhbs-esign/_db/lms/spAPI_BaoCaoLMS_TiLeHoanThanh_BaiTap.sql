CREATE PROCEDURE [dbo].[spAPI_BaoCaoLMS_TiLeHoanThanh_BaiTap] 

 @MonHocID INT ,
 @CapID INT ,
 @NienKhoa INT 
 AS
 BEGIN
    IF(@MonHocID = 76)
    BEGIN
    -- Tạo temp table để cache submissions (nếu data lớn)
SELECT DISTINCT
    HocSinhID,
    AssignToClassID
INTO #Submissions
FROM tblEL_Submissions
WHERE IsDeleted = 0;

CREATE INDEX IX_Temp ON #Submissions(HocSinhID, AssignToClassID);

-- Query chính đơn giản hơn
SELECT 
    n.NhomID as LopID,
    n.TenNhom as TenLop, 
    n.KhoiID,
    COUNT(*) AS TongBaiTapPhaiNop,
    SUM(CASE WHEN sub.HocSinhID IS NOT NULL THEN 1 ELSE 0 END) AS DaNop,
    SUM(CASE WHEN sub.HocSinhID IS NULL THEN 1 ELSE 0 END) AS ChuaNop,
    CAST(
        SUM(CASE WHEN sub.HocSinhID IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
    AS DECIMAL(5,2)) AS TiLeHoanThanh
FROM tblNhom n
JOIN tblKhoi k 
    ON k.KhoiID = n.KhoiID 
    AND k.CapID = @CapID
JOIN tblHocSinhNhom hsn 
    ON hsn.NhomID = n.NhomID 
    AND hsn.Enable = 1
JOIN tblHocSinh hs 
    ON hs.HocSinhID = hsn.HocSinhID 
    AND hs.TinhTrang = 0
JOIN tblMonHocLop mhl 
    ON mhl.LopNhomID = n.NhomID
   AND mhl.NienKhoa = @NienKhoa
   AND mhl.Enable = 1
JOIN tblEL_AssignToClass atc 
    ON atc.MonHocLopID = mhl.MonHocLopID 
    AND atc.IsDeleted = 0
JOIN tblEL_Assignments asm 
    ON asm.AssignmentID = atc.AssignmentID
    AND asm.MonHocID = @MonHocID
    AND asm.NienKhoa = @NienKhoa
    AND asm.KhoiID = k.KhoiID
    AND asm.IsDeleted = 0
    AND ISNULL(asm.IsDev, 0) = 0
LEFT JOIN #Submissions sub
    ON sub.HocSinhID = hsn.HocSinhID 
    AND sub.AssignToClassID = atc.AssignToClassID
WHERE n.Enable = 1
    AND n.NienKhoa = @NienKhoa
    AND n.MonHocID = @MonHocID
GROUP BY 
    n.NhomID,
    n.TenNhom,
    n.KhoiID
ORDER BY 
    n.TenNhom;

DROP TABLE #Submissions;

-- Pre-filter Submissions để giảm data scan
SELECT DISTINCT 
    s.HocSinhID, 
    s.AssignToClassID,
    1 AS HasSubmission
INTO #TempSub
FROM tblEL_Submissions s
WHERE s.IsDeleted = 0
    AND EXISTS (
        SELECT 1 
        FROM tblEL_AssignToClass atc
        JOIN tblEL_Assignments asm ON asm.AssignmentID = atc.AssignmentID
        WHERE atc.AssignToClassID = s.AssignToClassID
            AND asm.MonHocID = @MonHocID
            AND asm.NienKhoa = @NienKhoa
    );

CREATE CLUSTERED INDEX IX_TempSub ON #TempSub(HocSinhID, AssignToClassID);

-- Query chính
SELECT 
    n.KhoiID,
    k.TenKhoiHoc,
    COUNT(*) AS TongBaiTapPhaiNop,
    SUM(ISNULL(ts.HasSubmission, 0)) AS DaNop,
    COUNT(*) - SUM(ISNULL(ts.HasSubmission, 0)) AS ChuaNop,
    CAST(SUM(ISNULL(ts.HasSubmission, 0)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS TiLeHoanThanh
FROM tblNhom n
JOIN tblKhoi k 
    ON k.KhoiID = n.KhoiID
    AND k.CapID = @CapID
JOIN tblHocSinhNhom hsn 
    ON hsn.NhomID = n.NhomID 
    AND hsn.Enable = 1
JOIN tblHocSinh hs 
    ON hs.HocSinhID = hsn.HocSinhID 
    AND hs.TinhTrang = 0
JOIN tblMonHocLop mhl 
    ON mhl.LopNhomID = n.NhomID
   AND mhl.NienKhoa = @NienKhoa
   AND mhl.Enable = 1
JOIN tblEL_AssignToClass atc 
    ON atc.MonHocLopID = mhl.MonHocLopID 
    AND atc.IsDeleted = 0
JOIN tblEL_Assignments asm 
    ON asm.AssignmentID = atc.AssignmentID
    AND asm.MonHocID = @MonHocID
    AND asm.KhoiID = k.KhoiID
    AND asm.NienKhoa = @NienKhoa
    AND asm.IsDeleted = 0
    AND ISNULL(asm.IsDev, 0) = 0
LEFT JOIN #TempSub ts
    ON ts.HocSinhID = hsn.HocSinhID 
    AND ts.AssignToClassID = atc.AssignToClassID
WHERE n.Enable = 1
    AND n.NienKhoa = @NienKhoa
GROUP BY n.KhoiID, k.TenKhoiHoc
ORDER BY n.KhoiID;

DROP TABLE #TempSub;


    END
    ELSE
    BEGIN
        ;WITH HS AS (
    SELECT 
        hsl.LopID,
        hsl.HocSinhID
    FROM tblHocSinhLop hsl
    JOIN tblHocSinh hs 
        ON hs.HocSinhID = hsl.HocSinhID
       AND hs.TinhTrang = 0
    WHERE hsl.Enable = 1
      AND hsl.NienKhoa = @NienKhoa
), BaiGiao AS (
    SELECT 
        mhl.LopNhomID AS LopID,
        atc.AssignToClassID
    FROM tblEL_AssignToClass atc
    JOIN tblEL_Assignments asm 
        ON asm.AssignmentID = atc.AssignmentID
       AND asm.MonHocID = @MonHocID
       AND asm.KhoiID in (SELECT KhoiID FROM tblKhoi WHERE CapID =@CapID)
       AND asm.NienKhoa = @NienKhoa
       AND asm.IsDeleted = 0
       AND (asm.IsDev IS NULL OR asm.IsDev = 0)
    JOIN tblMonHocLop mhl 
        ON mhl.MonHocLopID = atc.MonHocLopID
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.Enable = 1
    WHERE atc.IsDeleted = 0
), BaiPhaiNop AS (
    SELECT 
        hs.LopID,
        hs.HocSinhID,
        bg.AssignToClassID
    FROM HS hs
    JOIN BaiGiao bg 
        ON bg.LopID = hs.LopID
)
SELECT 
    l.TenLop,
    l.LopID,
    l.KhoiID,
    COUNT(*) AS TongBaiTapPhaiNop,
    SUM(CASE WHEN s.AssignToClassID IS NOT NULL THEN 1 ELSE 0 END) AS DaNop,
    SUM(CASE WHEN s.AssignToClassID IS NULL THEN 1 ELSE 0 END) AS ChuaNop,
    CAST(
        SUM(CASE WHEN s.AssignToClassID IS NOT NULL THEN 1 ELSE 0 END) * 100.0
        / COUNT(*)
    AS DECIMAL(5,2)) AS TiLeHoanThanh
FROM BaiPhaiNop bpn
JOIN tblLop l 
    ON l.LopID = bpn.LopID
   AND l.Enable = 1
   AND l.NienKhoa = @NienKhoa
   AND l.KhoiID in (SELECT KhoiID FROM tblKhoi WHERE CapID =@CapID)
LEFT JOIN (
    SELECT DISTINCT HocSinhID, AssignToClassID
    FROM tblEL_Submissions
    WHERE IsDeleted = 0
) s
    ON s.HocSinhID = bpn.HocSinhID
   AND s.AssignToClassID = bpn.AssignToClassID
GROUP BY l.LopID, l.TenLop,l.KhoiID
ORDER BY l.TenLop;

;WITH HS AS (
    SELECT 
        hsl.LopID,
        hsl.HocSinhID
    FROM tblHocSinhLop hsl
    JOIN tblHocSinh hs 
        ON hs.HocSinhID = hsl.HocSinhID
       AND hs.TinhTrang = 0
    WHERE hsl.Enable = 1
      AND hsl.NienKhoa = @NienKhoa
),
BaiGiao AS (
    SELECT 
        mhl.LopNhomID AS LopID,
        atc.AssignToClassID
    FROM tblEL_AssignToClass atc
    JOIN tblEL_Assignments asm 
        ON asm.AssignmentID = atc.AssignmentID
       AND asm.MonHocID = @MonHocID
       AND asm.KhoiID in (SELECT KhoiID FROM tblKhoi WHERE CapID =@CapID)
       AND asm.NienKhoa = @NienKhoa
       AND asm.IsDeleted = 0
       AND (asm.IsDev IS NULL OR asm.IsDev = 0)
    JOIN tblMonHocLop mhl 
        ON mhl.MonHocLopID = atc.MonHocLopID
       AND mhl.NienKhoa = @NienKhoa
       AND mhl.Enable = 1
    WHERE atc.IsDeleted = 0
),
BaiPhaiNop AS (
    SELECT 
        hs.LopID,
        hs.HocSinhID,
        bg.AssignToClassID
    FROM HS hs
    JOIN BaiGiao bg 
        ON bg.LopID = hs.LopID
),
SubmissionDistinct AS (
    SELECT DISTINCT HocSinhID, AssignToClassID
    FROM tblEL_Submissions
    WHERE IsDeleted = 0
)

SELECT 
    l.KhoiID,
    k.TenKhoiHoc,
    COUNT(*) AS TongBaiTapPhaiNop,
    SUM(CASE WHEN sd.AssignToClassID IS NOT NULL THEN 1 ELSE 0 END) AS DaNop,
    SUM(CASE WHEN sd.AssignToClassID IS NULL THEN 1 ELSE 0 END) AS ChuaNop,
    CAST(
        SUM(CASE WHEN sd.AssignToClassID IS NOT NULL THEN 1 ELSE 0 END) * 100.0
        / COUNT(*)
    AS DECIMAL(5,2)) AS TiLeHoanThanh
FROM BaiPhaiNop bpn
JOIN tblLop l 
    ON l.LopID = bpn.LopID
   AND l.Enable = 1
   AND l.NienKhoa = @NienKhoa
JOIN tblKhoi k 
    ON k.KhoiID = l.KhoiID
LEFT JOIN SubmissionDistinct sd
    ON sd.HocSinhID = bpn.HocSinhID
   AND sd.AssignToClassID = bpn.AssignToClassID
GROUP BY l.KhoiID, k.TenKhoiHoc
ORDER BY l.KhoiID;
    END


END