CREATE PROC [dbo].[spAPI_HocSinhBangDiem_Get_ByLopID_Semester]
    @Semester  NVARCHAR(20),
    @NienKhoa  INT,
    @LopID     NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Dùng CTE thay vì table variable để optimizer thấy được cardinality
     WITH ValidCot AS (
    -- Phần cố định theo semester
    SELECT 'TX_L1_' + @Semester AS MaCotDiem UNION ALL
    SELECT 'TX_L2_' + @Semester UNION ALL
    SELECT 'TX_L3_' + @Semester UNION ALL
    SELECT 'TX_L4_' + @Semester UNION ALL
    SELECT 'TX_L5_' + @Semester UNION ALL
    SELECT 'DiemGK_' + @Semester UNION ALL
    SELECT 'DiemCK_' + @Semester UNION ALL
    SELECT 'DiemTB_' + @Semester UNION ALL
    SELECT 'DiemCD1_' + @Semester UNION ALL
    SELECT 'DiemCD2_' + @Semester UNION ALL
    SELECT 'DiemCD3_' + @Semester UNION ALL
    -- Phần riêng HK1
    SELECT 'Theme1_Total'         WHERE @Semester = 'HK1' UNION ALL
    SELECT 'Theme2_Total'         WHERE @Semester = 'HK1' UNION ALL
    SELECT 'Theme3_Total'         WHERE @Semester = 'HK1' UNION ALL
    SELECT 'Theme4_Total'         WHERE @Semester = 'HK1' UNION ALL
    SELECT 'S1_Mid_Total_Point'   WHERE @Semester = 'HK1' UNION ALL
    SELECT 'S1_Final_Total_Point' WHERE @Semester = 'HK1' UNION ALL
    -- Phần riêng HK2
    SELECT 'Theme5_Total'         WHERE @Semester = 'HK2' UNION ALL
    SELECT 'Theme6_Total'         WHERE @Semester = 'HK2' UNION ALL
    SELECT 'Theme7_Total'         WHERE @Semester = 'HK2' UNION ALL
    SELECT 'Theme8_Total'         WHERE @Semester = 'HK2' UNION ALL
    SELECT 'S2_Mid_Total_Point'   WHERE @Semester = 'HK2' UNION ALL
    SELECT 'S2_Final_Total_Point' WHERE @Semester = 'HK2' UNION ALL
	-- Phần riêng Cả năm
	SELECT 'DiemTB_CaNam' WHERE @Semester = 'CaNam' 
),
    -- Nhánh 1: học sinh theo lớp
    KQ_Lop AS (
        SELECT hsl.SoDanhBo
             , kqht.HocSinhID
             , mh.MonHocCode
             , ct.MaCotDiem
             , kqht.KetQuaDanhGia_VI
             , mh.Sort         AS mhSort
             , ct.ThuTuNhom    AS ctThuTuNhom
             , ct.ThuTuCotDiem AS ctThuTuCotDiem
             , CASE
                   WHEN ct.MaCotDiem LIKE 'TX[_]%'   THEN 1
                   WHEN kcd.KhoaCotDiemID IS NOT NULL THEN 1
                   ELSE 0
               END AS IsLock
        FROM dbo.tblKetQuaHocTap AS kqht
            INNER JOIN dbo.tblLop AS l
                ON  l.LopID    = kqht.LopID
                AND l.Enable   = 1
                AND l.NienKhoa = @NienKhoa
            INNER JOIN dbo.TemplateBangDiemChiTiet AS ct
                ON  ct.CotDiemID = kqht.CotDiemID
                AND ct.Enable    = 1
                AND ct.Semester  = @Semester
                AND ct.MaCotDiem IN (SELECT MaCotDiem FROM ValidCot)  -- thống nhất dùng IN
            INNER JOIN dbo.tblMonHocLop AS mhl
                ON  mhl.MonHocLopID = kqht.MonHocLopID
                AND mhl.Enable      = 1
                AND mhl.NienKhoa    = @NienKhoa
            INNER JOIN dbo.tblMonHoc AS mh
                ON  mh.MonHocID = mhl.MonHocID
                AND mh.Enable   = 1
            INNER JOIN dbo.tblHocSinhLop AS hsl
                ON  hsl.HocSinhID = kqht.HocSinhID
                AND hsl.LopID     = l.LopID
                AND hsl.Enable    = 1
            LEFT JOIN dbo.tblKhoaCotDiem AS kcd
                ON  kcd.MonHocLopID = kqht.MonHocLopID
                AND kcd.LopID       = kqht.LopID
                AND kcd.MaCotDiem   = ct.MaCotDiem
                AND kcd.Enable      = 1
                AND kcd.TinhTrang   = 1
        WHERE kqht.Enable   = 1
          AND kqht.NienKhoa = @NienKhoa
          AND kqht.LopID    = @LopID
    ),
    -- Nhánh 2: học sinh theo nhóm
    KQ_Nhom AS (
        SELECT CAST(hsn.SoTT AS VARCHAR(2)) AS SoDanhBo
             , kqht.HocSinhID
             , mh.MonHocCode
             , ct.MaCotDiem
             , kqht.KetQuaDanhGia_VI
             , mh.Sort         AS mhSort
             , ct.ThuTuNhom    AS ctThuTuNhom
             , ct.ThuTuCotDiem AS ctThuTuCotDiem
             , CASE
                   WHEN ct.MaCotDiem LIKE 'TX[_]%'   THEN 1
                   WHEN kcd.KhoaCotDiemID IS NOT NULL THEN 1
                   ELSE 0
               END AS IsLock
        FROM dbo.tblHocSinhLop AS hsl
            INNER JOIN dbo.tblHocSinhNhom AS hsn
                ON  hsn.HocSinhID = hsl.HocSinhID
                AND hsn.Enable    = 1
            INNER JOIN dbo.tblKetQuaHocTap AS kqht
                ON  kqht.LopID     = hsn.NhomID
                AND kqht.HocSinhID = hsl.HocSinhID
                AND kqht.NienKhoa  = @NienKhoa
                AND kqht.Enable    = 1
            INNER JOIN dbo.TemplateBangDiemChiTiet AS ct
                ON  ct.CotDiemID = kqht.CotDiemID
                AND ct.Enable    = 1
                AND ct.MaCotDiem IN (SELECT MaCotDiem FROM ValidCot)
            INNER JOIN dbo.tblMonHocLop AS mhl
                ON  mhl.MonHocLopID = kqht.MonHocLopID
                AND mhl.Enable      = 1
                AND mhl.NienKhoa    = @NienKhoa
            INNER JOIN dbo.tblMonHoc AS mh
                ON  mh.MonHocID = mhl.MonHocID
                AND mh.Enable   = 1
            LEFT JOIN dbo.tblKhoaCotDiem AS kcd
                ON  kcd.MonHocLopID = kqht.MonHocLopID
                AND kcd.LopID       = kqht.LopID      -- ✅ fix: dùng hsl.LopID thay kqht.LopID
                AND kcd.MaCotDiem   = ct.MaCotDiem
                AND kcd.Enable      = 1
                AND kcd.TinhTrang   = 1
        WHERE hsl.Enable = 1
          AND hsl.LopID  = @LopID
    )
    SELECT SoDanhBo, HocSinhID, MonHocCode, MaCotDiem,
           KetQuaDanhGia_VI, mhSort, ctThuTuNhom, ctThuTuCotDiem, IsLock
    FROM (
        SELECT * FROM KQ_Lop
        UNION ALL
        SELECT * FROM KQ_Nhom
    ) AS kq
    ORDER BY SoDanhBo, mhSort, ctThuTuNhom, ctThuTuCotDiem;
END;