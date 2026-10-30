-- [dbo].[fn_GetKetQuaHocTapTheoLop_C3] '2257', 2025, 'HK2'
CREATE PROCEDURE [dbo].[fn_GetKetQuaHocTapTheoLop_C3_Old]
    @LopID    NVARCHAR(20)
  , @NienKhoa INT
  , @HocKy    NVARCHAR(50) -- VD: 'HK1' hoặc 'HK1,HK2'
AS
BEGIN

SET NOCOUNT ON;

    -- =============================================
    -- BƯỚC 1: Tách danh sách học kỳ
    -- =============================================
    DECLARE @HocKyTable TABLE (HocKy NVARCHAR(10));

    INSERT INTO @HocKyTable (HocKy)
    SELECT LTRIM(RTRIM(value))
    FROM STRING_SPLIT(@HocKy, ',');

    -- =============================================
    -- BƯỚC 2: Lấy danh sách cột điểm bị khóa
    -- =============================================
    DECLARE @LockedColumns TABLE
    (
        MonHocLopID INT,
        MaCotDiem   NVARCHAR(100),
        TinhTrang   BIT,
        PRIMARY KEY (MonHocLopID, MaCotDiem)
    );

    -- Lấy danh sách NhomID của học sinh trong lớp
    DECLARE @HocSinhLop TABLE (NhomID VARCHAR(50));

    INSERT INTO @HocSinhLop
    SELECT hsn.NhomID
    FROM tblHocSinhNhom hsn
    INNER JOIN tblNhom n
        ON  n.NhomID            = hsn.NhomID
        AND n.Enable            = 1
        AND n.NienKhoa          = @NienKhoa
        AND n.IsNhomLMS_GiaoBai = 0
    WHERE hsn.LopID = @LopID;

    -- Lấy danh sách MonHocLopID theo nhóm
    DECLARE @MonHocLopID_Nhom TABLE (MonHocLopID INT);

    INSERT INTO @MonHocLopID_Nhom
    SELECT mhl.MonHocLopID
    FROM @HocSinhLop hsl
    INNER JOIN tblMonHocLop mhl
        ON  mhl.LopNhomID = hsl.NhomID
        AND mhl.Enable    = 1
        AND mhl.NienKhoa  = @NienKhoa;

    -- Gộp khóa cột điểm: theo LopID + theo nhóm
    INSERT INTO @LockedColumns (MonHocLopID, MaCotDiem, TinhTrang)
    SELECT DISTINCT
           MonHocLopID,
           MaCotDiem,
           TinhTrang
    FROM dbo.tblKhoaCotDiem
    WHERE LopID     = @LopID
      AND Enable    = 1
      AND TinhTrang = 1

    UNION

    SELECT DISTINCT
           kcd.MonHocLopID,
           kcd.MaCotDiem,
           kcd.TinhTrang
    FROM tblKhoaCotDiem kcd
    INNER JOIN @MonHocLopID_Nhom mhl
        ON  mhl.MonHocLopID = kcd.MonHocLopID
    WHERE kcd.Enable    = 1
      AND kcd.TinhTrang = 1;

    -- =============================================
    -- BƯỚC 3: Khai báo bảng kết quả
    -- =============================================
    DECLARE @Result TABLE
    (
        LopID        VARCHAR(40),
        TenLop       NVARCHAR(50),
        SoDanhBo     NVARCHAR(100),
        HocSinhID    INT,
        MonHocCode   NVARCHAR(50),
        LoaiDiem     NVARCHAR(20),
        ThuTuNhom    INT,
        ThuTuCotDiem INT,
        MaCotDiem    NVARCHAR(100),
        KetQua       NVARCHAR(MAX),
        HocKy        NVARCHAR(100),
        Sort         INT,
        MonHocLopID  INT
    );

    -- =============================================
    -- BƯỚC 4A: Môn học thường (không phải môn 76 và không phải nhóm)
    -- =============================================
    INSERT INTO @Result
    SELECT
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        kqht.HocSinhID,
        mh.MonHocCode,
        CASE
            WHEN ct.MaCotDiem LIKE 'TX_%'    THEN 'TX'
            WHEN ct.MaCotDiem LIKE 'DiemGK%' THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE 'DiemCK%' THEN 'DiemCK'
            WHEN ct.MaCotDiem LIKE 'DiemTB%' THEN 'DiemTB'
            ELSE 'Unknown'
        END AS LoaiDiem,
        ct.ThuTuNhom,
        ct.ThuTuCotDiem,
        ct.MaCotDiem,
        ISNULL(kqht.KetQuaDanhGia_VI, kqht.KetQuaDanhGia_EN) AS KetQua,
        ct.Semester AS HocKy,
        mh.Sort,
        kqht.MonHocLopID
    FROM dbo.tblKetQuaHocTap kqht
    INNER JOIN dbo.TemplateBangDiemChiTiet ct
        ON  ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable    = 1
        AND ct.Semester IN (SELECT HocKy FROM @HocKyTable)
        AND (
               ct.MaCotDiem LIKE 'TX_%'
            OR ct.MaCotDiem LIKE 'DiemGK%'
            OR ct.MaCotDiem LIKE 'DiemCK%'
            OR ct.MaCotDiem LIKE 'DiemTB%'
        )
    INNER JOIN dbo.tblMonHocLop mhl
        ON  mhl.TemplateBangDiemID = ct.TemplateBangDiemID
        AND mhl.NienKhoa           = @NienKhoa
        AND mhl.MonHocLopID        = kqht.MonHocLopID
        AND mhl.LopNhomID          = @LopID
        AND mhl.Enable             = 1
        AND mhl.MonHocID NOT IN (
            SELECT DISTINCT MonHocID
            FROM dbo.tblNhom
            WHERE Enable = 1 AND IsNhomLMS_GiaoBai = 0
        )
    INNER JOIN dbo.tblMonHoc mh
        ON  mh.MonHocID = mhl.MonHocID
        AND mh.Enable   = 1
    INNER JOIN dbo.tblHocSinhLop hsl
        ON  hsl.LopID     = mhl.LopNhomID
        AND hsl.LopID     = kqht.LopID
        AND hsl.HocSinhID = kqht.HocSinhID
        AND hsl.Enable    = 1
    INNER JOIN dbo.tblHocSinh hs
        ON  hs.HocSinhID = hsl.HocSinhID
        AND hs.HocSinhID = kqht.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblLop l
        ON  l.LopID   = mhl.LopNhomID
        AND hsl.LopID = l.LopID
        AND l.LopID   = @LopID
        AND l.Enable  = 1
    INNER JOIN @LockedColumns lc
        ON  lc.MonHocLopID = kqht.MonHocLopID
        AND lc.MaCotDiem   = ct.MaCotDiem
    WHERE kqht.NienKhoa = @NienKhoa
      AND kqht.Enable   = 1
      AND kqht.LopID    = @LopID

    UNION ALL

    -- =============================================
    -- BƯỚC 4B: Môn 76 - Điểm tổng (Total, Mid_Total_Point, Final_Total_Point)
    -- =============================================
    SELECT
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        kqht.HocSinhID,
        mh.MonHocCode,
        CASE
            WHEN ct.MaCotDiem LIKE 'TX_%'               THEN 'TX'
            WHEN ct.MaCotDiem LIKE 'DiemGK%'            THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE 'DiemCK%'            THEN 'DiemCK'
            WHEN ct.MaCotDiem LIKE 'DiemTB%'            THEN 'DiemTB'
            WHEN ct.MaCotDiem LIKE '%Total'             THEN 'TX'
            WHEN ct.MaCotDiem LIKE '%Mid_Total_Point'   THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE '%Final_Total_Point' THEN 'DiemCK'
            ELSE 'Unknown'
        END AS LoaiDiem,
        ct.ThuTuNhom,
        ct.ThuTuCotDiem,
        ct.MaCotDiem,
        ISNULL(kqht.KetQuaDanhGia_VI, kqht.KetQuaDanhGia_EN) AS KetQua,
        ct.Semester AS HocKy,
        mh.Sort,
        kqht.MonHocLopID
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN dbo.tblHocSinh hs
        ON  hs.HocSinhID = hsl.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblHocSinhNhom hsn
        ON  hsn.HocSinhID = hsl.HocSinhID
        AND hsn.Enable    = 1
        AND hsn.NhomID IN (
            SELECT NhomID
            FROM dbo.tblNhom
            WHERE MonHocID = 76
              AND Enable   = 1
              AND NienKhoa = @NienKhoa
        )
    INNER JOIN dbo.tblMonHocLop mhl
        ON  mhl.LopNhomID = hsn.NhomID
        AND mhl.NienKhoa  = @NienKhoa
        AND mhl.Enable    = 1
        AND mhl.MonHocID  = 76
    INNER JOIN dbo.tblLop l
        ON  l.LopID    = hsl.LopID
        AND l.Enable   = 1
        AND l.NienKhoa = @NienKhoa
    INNER JOIN dbo.tblMonHoc mh
        ON  mh.MonHocID = mhl.MonHocID
        AND mh.Enable   = 1
    INNER JOIN dbo.tblKetQuaHocTap kqht
        ON  kqht.MonHocLopID = mhl.MonHocLopID
        AND hsn.HocSinhID    = kqht.HocSinhID
        AND hsl.HocSinhID    = kqht.HocSinhID
        AND kqht.Enable      = 1
    INNER JOIN dbo.TemplateBangDiemChiTiet ct
        ON  ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable    = 1
        AND ct.Semester IN (SELECT HocKy FROM @HocKyTable)
        AND (
               ct.MaCotDiem LIKE '%Total'
            OR ct.MaCotDiem LIKE '%Mid_Total_Point'
            OR ct.MaCotDiem LIKE '%Final_Total_Point'
            OR ct.MaCotDiem LIKE 'DiemGK%'
            OR ct.MaCotDiem LIKE 'DiemCK%'
            OR ct.MaCotDiem LIKE 'DiemTB%'
        )
    INNER JOIN @LockedColumns lc
        ON  lc.MonHocLopID = kqht.MonHocLopID
        AND lc.MaCotDiem   = ct.MaCotDiem
    WHERE hsl.LopID = @LopID

    UNION ALL

    -- =============================================
    -- BƯỚC 4C: Môn 76 - Điểm chi tiết TA2 (Listening, Reading, Writing, Speaking)
    -- =============================================
    SELECT
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        kqht.HocSinhID,
        mh.MonHocCode,
        CASE
            WHEN ct.MaCotDiem LIKE '%Mid_TA2_Listening_Point'   THEN 'DiemGK_TA'
            WHEN ct.MaCotDiem LIKE '%Mid_TA2_Reading_Point'     THEN 'DiemGK_TA'
            WHEN ct.MaCotDiem LIKE '%Mid_TA2_Writing_Point'     THEN 'DiemGK_TA'
            WHEN ct.MaCotDiem LIKE '%Mid_TA2_Speaking_Point'    THEN 'DiemGK_TA'
            WHEN ct.MaCotDiem LIKE '%Mid_TA2_Avg_Point'         THEN 'DiemGK_TA'
            WHEN ct.MaCotDiem LIKE '%Final_TA2_Listening_Point' THEN 'DiemCK_TA'
            WHEN ct.MaCotDiem LIKE '%Final_TA2_Reading_Point'   THEN 'DiemCK_TA'
            WHEN ct.MaCotDiem LIKE '%Final_TA2_Writing_Point'   THEN 'DiemCK_TA'
            WHEN ct.MaCotDiem LIKE '%Final_TA2_Speaking_Point'  THEN 'DiemCK_TA'
            WHEN ct.MaCotDiem LIKE '%Final_TA2_Avg_Point'       THEN 'DiemCK_TA'
            ELSE 'Unknown'
        END AS LoaiDiem,
        ct.ThuTuNhom,
        ct.ThuTuCotDiem,
        ct.MaCotDiem,
        ISNULL(kqht.KetQuaDanhGia_VI, kqht.KetQuaDanhGia_EN) AS KetQua,
        ct.Semester AS HocKy,
        mh.Sort,
        kqht.MonHocLopID
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN dbo.tblHocSinh hs
        ON  hs.HocSinhID = hsl.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblHocSinhNhom hsn
        ON  hsn.HocSinhID = hsl.HocSinhID
        AND hsn.NhomID IN (
            SELECT NhomID
            FROM dbo.tblNhom
            WHERE MonHocID = 76
              AND Enable   = 1
              AND NienKhoa = @NienKhoa
        )
    INNER JOIN dbo.tblMonHocLop mhl
        ON  mhl.LopNhomID = hsn.NhomID
        AND mhl.NienKhoa  = @NienKhoa
        AND mhl.Enable    = 1
        AND mhl.MonHocID  = 76
    INNER JOIN dbo.tblLop l
        ON  l.LopID    = hsl.LopID
        AND l.Enable   = 1
        AND l.NienKhoa = @NienKhoa
    INNER JOIN dbo.tblMonHoc mh
        ON  mh.MonHocID = mhl.MonHocID
        AND mh.Enable   = 1
    INNER JOIN dbo.tblKetQuaHocTap kqht
        ON  kqht.MonHocLopID = mhl.MonHocLopID
        AND hsn.HocSinhID    = kqht.HocSinhID
        AND hsl.HocSinhID    = kqht.HocSinhID
        AND kqht.Enable      = 1
    INNER JOIN dbo.TemplateBangDiemChiTiet ct
        ON  ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable    = 1
        AND ct.Semester IN (SELECT HocKy FROM @HocKyTable)
        AND (
               ct.MaCotDiem LIKE '%Mid_TA2_Listening_Point'
            OR ct.MaCotDiem LIKE '%Mid_TA2_Reading_Point'
            OR ct.MaCotDiem LIKE '%Mid_TA2_Writing_Point'
            OR ct.MaCotDiem LIKE '%Mid_TA2_Speaking_Point'
            OR ct.MaCotDiem LIKE '%Mid_TA2_Avg_Point'
            OR ct.MaCotDiem LIKE '%Final_TA2_Listening_Point'
            OR ct.MaCotDiem LIKE '%Final_TA2_Reading_Point'
            OR ct.MaCotDiem LIKE '%Final_TA2_Writing_Point'
            OR ct.MaCotDiem LIKE '%Final_TA2_Speaking_Point'
            OR ct.MaCotDiem LIKE '%Final_TA2_Avg_Point'
        )
    INNER JOIN @LockedColumns lc
        ON  lc.MonHocLopID = kqht.MonHocLopID
        AND lc.MaCotDiem   = ct.MaCotDiem
    WHERE hsl.LopID        = @LopID
      AND ct.MaCotDiem NOT LIKE '%Conv%'

    UNION ALL

    -- =============================================
    -- BƯỚC 4D: Các môn nhóm khác (không phải môn 76)
    -- =============================================
    SELECT
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        kqht.HocSinhID,
        mh.MonHocCode,
        CASE
            WHEN ct.MaCotDiem LIKE 'TX_%'    THEN 'TX'
            WHEN ct.MaCotDiem LIKE 'DiemGK%' THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE 'DiemCK%' THEN 'DiemCK'
            WHEN ct.MaCotDiem LIKE 'DiemTB%' THEN 'DiemTB'
            ELSE 'Unknown'
        END AS LoaiDiem,
        ct.ThuTuNhom,
        ct.ThuTuCotDiem,
        ct.MaCotDiem,
        ISNULL(kqht.KetQuaDanhGia_VI, kqht.KetQuaDanhGia_EN) AS KetQua,
        ct.Semester AS HocKy,
        mh.Sort,
        kqht.MonHocLopID
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN dbo.tblHocSinh hs
        ON  hs.HocSinhID = hsl.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblHocSinhNhom hsn
        ON  hsn.HocSinhID = hsl.HocSinhID
        AND hsn.NhomID IN (
            SELECT NhomID
            FROM dbo.tblNhom
            WHERE MonHocID IN (
                SELECT DISTINCT MonHocID
                FROM dbo.tblNhom
                WHERE Enable   = 1
                  AND MonHocID <> 76
            )
            AND Enable   = 1
            AND NienKhoa = @NienKhoa
        )
    INNER JOIN dbo.tblMonHocLop mhl
        ON  mhl.LopNhomID = hsn.NhomID
        AND mhl.NienKhoa  = @NienKhoa
        AND mhl.Enable    = 1
        AND mhl.MonHocID  <> 76
    INNER JOIN dbo.tblLop l
        ON  l.LopID    = hsl.LopID
        AND l.Enable   = 1
        AND l.NienKhoa = @NienKhoa
    INNER JOIN dbo.tblMonHoc mh
        ON  mh.MonHocID = mhl.MonHocID
        AND mh.Enable   = 1
    INNER JOIN dbo.tblKetQuaHocTap kqht
        ON  kqht.MonHocLopID = mhl.MonHocLopID
        AND hsn.HocSinhID    = kqht.HocSinhID
        AND hsl.HocSinhID    = kqht.HocSinhID
        AND kqht.Enable      = 1
    INNER JOIN dbo.TemplateBangDiemChiTiet ct
        ON  ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable    = 1
        AND ct.Semester IN (SELECT HocKy FROM @HocKyTable)
        AND (
               ct.MaCotDiem LIKE 'TX_%'
            OR ct.MaCotDiem LIKE 'DiemGK%'
            OR ct.MaCotDiem LIKE 'DiemCK%'
            OR ct.MaCotDiem LIKE 'DiemTB%'
        )
    INNER JOIN @LockedColumns lc
        ON  lc.MonHocLopID = kqht.MonHocLopID
        AND lc.MaCotDiem   = ct.MaCotDiem
    WHERE hsl.LopID = @LopID;

    -- =============================================
    -- BƯỚC 5: Trả về kết quả với thứ tự đã sắp xếp
    -- =============================================
    SELECT
        LopID,
        TenLop,
        SoDanhBo,
        HocSinhID,
        MonHocCode AS MonHocID,
        LoaiDiem,
        ThuTuNhom,
        ROW_NUMBER() OVER (
            PARTITION BY HocSinhID, MonHocCode, HocKy
            ORDER BY
                CASE LoaiDiem
                    WHEN 'TX'        THEN 1
                    WHEN 'DiemGK_TA' THEN 2
                    WHEN 'DiemGK'    THEN 3
                    WHEN 'DiemCK_TA' THEN 4
                    WHEN 'DiemCK'    THEN 5
                    WHEN 'DiemTB'    THEN 6
                    ELSE 7
                END,
                MaCotDiem
        ) AS ThuTuCotDiem,
        MaCotDiem,
        KetQua,
        HocKy,
        Sort
    FROM @Result
    ORDER BY
        SoDanhBo,
        MonHocCode,
        HocKy,
        CASE LoaiDiem
            WHEN 'TX'        THEN 1
            WHEN 'DiemGK_TA' THEN 2
            WHEN 'DiemGK'    THEN 3
            WHEN 'DiemCK_TA' THEN 4
            WHEN 'DiemCK'    THEN 5
            WHEN 'DiemTB'    THEN 6
            ELSE 7
        END,
        MaCotDiem;

END;
