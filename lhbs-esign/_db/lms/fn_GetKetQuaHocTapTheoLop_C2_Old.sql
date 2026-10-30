-- [dbo].[fn_GetKetQuaHocTapTheoLop_C2] 2464, 2025, 'HK2'
CREATE PROCEDURE [dbo].[fn_GetKetQuaHocTapTheoLop_C2_Old]
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
        MaCotDiem NVARCHAR(100),
        PRIMARY KEY (MonHocLopID, MaCotDiem)
    );

    INSERT INTO @LockedColumns (MonHocLopID, MaCotDiem)
    SELECT DISTINCT 
           MonHocLopID, 
           MaCotDiem
    FROM dbo.tblKhoaCotDiem
    WHERE LopID = @LopID
      AND Enable = 1
      AND TinhTrang = 1; --1: Khóa điểm, 0: Chưa khóa điểm
 
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
    -- BƯỚC 4A: Lấy dữ liệu môn học thường (không phải môn 46)
    -- =============================================
    INSERT INTO @Result
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        kqht.HocSinhID,
        mh.MonHocCode,
        -- Xác định loại điểm
        CASE
            WHEN ct.MaCotDiem LIKE 'TX_%' THEN 'TX'
            WHEN ct.MaCotDiem LIKE 'DiemGK%' THEN 'DiemGK'
            -- Dành cho các môn AI
            WHEN ct.MaCotDiem LIKE 'DiemCD1%' THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE 'DiemCD2%' THEN 'DiemCK'
            WHEN ct.MaCotDiem LIKE 'DiemCK%' THEN 'DiemCK'
            WHEN ct.MaCotDiem LIKE 'DiemTB%' THEN 'DiemTB'
            WHEN ct.MaCotDiem LIKE '%Total' THEN 'TX'
            WHEN ct.MaCotDiem LIKE '%Mid_Total_Point' THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE '%Final_Total_Point' THEN 'DiemCK'
            ELSE 'Unknown'
        END AS LoaiDiem,
        ct.ThuTuNhom,
        ct.ThuTuCotDiem,
        ct.MaCotDiem, 
        CASE 
            WHEN lc.MaCotDiem IS NULL THEN NULL
            ELSE ISNULL(kqht.KetQuaDanhGia_VI, kqht.KetQuaDanhGia_EN)
        END AS KetQua,
        ct.Semester AS HocKy,
        mh.Sort,
        kqht.MonHocLopID
    FROM dbo.tblKetQuaHocTap kqht
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable = 1
        AND ct.Semester IN (SELECT HocKy FROM @HocKyTable)
        AND (
            ct.MaCotDiem LIKE 'TX_%'
            OR ct.MaCotDiem LIKE 'DiemCD1%'  -- Dành cho các môn AI
            OR ct.MaCotDiem LIKE 'DiemCD2%'  -- Dành cho các môn AI
            OR ct.MaCotDiem LIKE 'DiemGK%'
            OR ct.MaCotDiem LIKE 'DiemCK%'
            OR ct.MaCotDiem LIKE 'DiemTB%'
        )
    INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.TemplateBangDiemID = ct.TemplateBangDiemID
        AND mhl.NienKhoa = @NienKhoa
        AND mhl.MonHocLopID = kqht.MonHocLopID
        AND mhl.LopNhomID = @LopID
        AND mhl.Enable = 1
        AND mhl.MonHocID NOT IN (
            SELECT DISTINCT MonHocID
            FROM dbo.tblNhom
            WHERE Enable = 1 
              AND IsNhomLMS_GiaoBai = 0
        )
        AND mhl.MonHocID NOT IN (46)
    INNER JOIN dbo.tblMonHoc mh 
        ON mh.MonHocID = mhl.MonHocID
        AND mh.Enable = 1
    INNER JOIN dbo.tblHocSinhLop hsl 
        ON hsl.LopID = mhl.LopNhomID
        AND hsl.LopID = kqht.LopID
        AND hsl.HocSinhID = kqht.HocSinhID
        AND hsl.Enable = 1
    INNER JOIN dbo.tblHocSinh hs 
        ON hs.HocSinhID = hsl.HocSinhID
        AND hs.HocSinhID = kqht.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblLop l 
        ON l.LopID = mhl.LopNhomID
        AND l.NienKhoa = @NienKhoa
        AND hsl.LopID = l.LopID
        AND l.LopID = @LopID
        AND l.Enable = 1
    -- Join với danh sách cột bị khóa
    LEFT JOIN @LockedColumns lc
        ON lc.MonHocLopID = kqht.MonHocLopID
        AND lc.MaCotDiem = ct.MaCotDiem
    WHERE kqht.NienKhoa = @NienKhoa
      AND kqht.Enable = 1
      AND kqht.LopID = @LopID

    UNION ALL

    -- =============================================
    -- BƯỚC 4B: Lấy dữ liệu môn học đặc biệt (môn 46)
    -- =============================================
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        kqht.HocSinhID,
        mh.MonHocCode,
        -- Xác định loại điểm
        CASE
            WHEN ct.MaCotDiem LIKE 'TX_%' THEN 'TX'
            WHEN ct.MaCotDiem LIKE 'DiemGK%' THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE 'DiemCK%' THEN 'DiemCK'
            WHEN ct.MaCotDiem LIKE 'DiemTB%' THEN 'DiemTB'
            WHEN ct.MaCotDiem LIKE '%Total' THEN 'TX'
            WHEN ct.MaCotDiem LIKE '%Mid_Total_Point' THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE '%Final_Total_Point' THEN 'DiemCK'
            ELSE 'Unknown'
        END AS LoaiDiem,
        ct.ThuTuNhom,
        ct.ThuTuCotDiem,
        ct.MaCotDiem,
        -- Kiểm tra khóa cột điểm: nếu bị khóa thì NULL
        CASE 
            WHEN lc.MaCotDiem IS  NULL THEN NULL
            ELSE ISNULL(kqht.KetQuaDanhGia_VI, kqht.KetQuaDanhGia_EN)
        END AS KetQua,
        ct.Semester AS HocKy,
        mh.Sort,
        kqht.MonHocLopID
    FROM dbo.tblKetQuaHocTap kqht
    INNER JOIN dbo.tblLop_TinhTrang l_tt 
        ON l_tt.Lop_TinhTrangID = kqht.Lop_TinhTrangID
        AND l_tt.TinhTrang = 4
        AND l_tt.Enable = 1
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable = 1
        AND ct.Semester IN (SELECT HocKy FROM @HocKyTable)
        AND (
            ct.MaCotDiem LIKE '%Total'
            OR ct.MaCotDiem LIKE '%Mid_Total_Point'
            OR ct.MaCotDiem LIKE '%Final_Total_Point'
            OR ct.MaCotDiem LIKE 'TX_%'
            OR ct.MaCotDiem LIKE 'DiemGK%'
            OR ct.MaCotDiem LIKE 'DiemCK%'
            OR ct.MaCotDiem LIKE 'DiemTB%'
        )
    INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.TemplateBangDiemID = ct.TemplateBangDiemID
        AND mhl.NienKhoa = @NienKhoa
        AND mhl.MonHocLopID = kqht.MonHocLopID
        AND mhl.LopNhomID = @LopID
        AND mhl.Enable = 1
        AND mhl.MonHocID = 46
    INNER JOIN dbo.tblMonHoc mh 
        ON mh.MonHocID = mhl.MonHocID
        AND mh.Enable = 1
    INNER JOIN dbo.tblHocSinhLop hsl 
        ON hsl.LopID = mhl.LopNhomID
        AND hsl.LopID = kqht.LopID
        AND hsl.HocSinhID = kqht.HocSinhID
        AND hsl.Enable = 1
    INNER JOIN dbo.tblHocSinh hs 
        ON hs.HocSinhID = hsl.HocSinhID
        AND hs.HocSinhID = kqht.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblLop l 
        ON l.LopID = mhl.LopNhomID
        AND l.NienKhoa = @NienKhoa
        AND hsl.LopID = l.LopID
        AND l.LopID = @LopID
        AND l.Enable = 1
    -- Join với danh sách cột bị khóa
    LEFT JOIN @LockedColumns lc
        ON lc.MonHocLopID = kqht.MonHocLopID
        AND lc.MaCotDiem = ct.MaCotDiem
    WHERE kqht.NienKhoa = @NienKhoa
      AND kqht.Enable = 1
      AND kqht.LopID = @LopID;

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
        -- Đánh lại thứ tự cột điểm theo LoaiDiem
        ROW_NUMBER() OVER (
            PARTITION BY HocSinhID, MonHocCode, HocKy 
            ORDER BY 
                CASE LoaiDiem
                    WHEN 'TX' THEN 1
                    WHEN 'DiemGK' THEN 2
                    WHEN 'DiemCK' THEN 3
                    WHEN 'DiemTB' THEN 4
                    ELSE 5
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
            WHEN 'TX' THEN 1
            WHEN 'DiemGK' THEN 2
            WHEN 'DiemCK' THEN 3
            WHEN 'DiemTB' THEN 4
            ELSE 5
        END,
        MaCotDiem;
END;
