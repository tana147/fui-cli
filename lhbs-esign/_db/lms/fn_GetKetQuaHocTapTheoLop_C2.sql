-- [dbo].[fn_GetKetQuaHocTapTheoLop_C2] '2546', 2025, 'HK2'
CREATE PROCEDURE [dbo].[fn_GetKetQuaHocTapTheoLop_C2]
    @LopID    NVARCHAR(20)
  , @NienKhoa INT
  , @HocKy    NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- BƯỚC 1: Tách danh sách học kỳ
    DECLARE @HocKyTable TABLE (HocKy NVARCHAR(10));
    INSERT INTO @HocKyTable (HocKy)
    SELECT LTRIM(RTRIM(value))
    FROM STRING_SPLIT(@HocKy, ',');

    -- BƯỚC 2: Lấy danh sách cột điểm bị khóa
    DECLARE @LockedColumns TABLE
    (
        MonHocLopID INT,
        MaCotDiem   NVARCHAR(100),
        PRIMARY KEY (MonHocLopID, MaCotDiem)
    );
    INSERT INTO @LockedColumns (MonHocLopID, MaCotDiem)
    SELECT DISTINCT MonHocLopID, MaCotDiem
    FROM dbo.tblKhoaCotDiem
    WHERE LopID   = @LopID
      AND Enable  = 1
      AND TinhTrang = 1; -- 1: Khóa, 0: Chưa khóa

    -- BƯỚC 3: Khai báo bảng kết quả
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
    -- BƯỚC 4A: Môn học thường (không phải môn 46)
    -- =============================================
    INSERT INTO @Result
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        hsl.HocSinhID,
        mh.MonHocCode,
        CASE
            WHEN ct.MaCotDiem LIKE 'TX_%'              THEN 'TX'
            WHEN ct.MaCotDiem LIKE 'DiemGK%'           THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE 'DiemCD1%'          THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE 'DiemCD2%'          THEN 'DiemCK'
            WHEN ct.MaCotDiem LIKE 'DiemCK%'           THEN 'DiemCK'
            WHEN ct.MaCotDiem LIKE 'DiemTB%'           THEN 'DiemTB'
            WHEN ct.MaCotDiem LIKE '%Total'             THEN 'TX'
            WHEN ct.MaCotDiem LIKE '%Mid_Total_Point'   THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE '%Final_Total_Point' THEN 'DiemCK'
            ELSE 'Unknown'
        END AS LoaiDiem,
        ct.ThuTuNhom,
        ct.ThuTuCotDiem,
        ct.MaCotDiem,
        -- Nếu chưa có bản ghi điểm, LEFT JOIN giữ dòng này và KetQua sẽ là NULL.
        ISNULL(kqht.KetQuaDanhGia_VI, kqht.KetQuaDanhGia_EN) AS KetQua,
        ct.Semester AS HocKy,
        mh.Sort,
        mhl.MonHocLopID
    FROM dbo.tblMonHocLop mhl
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.TemplateBangDiemID = mhl.TemplateBangDiemID
        AND ct.Enable   = 1
        AND ct.Semester IN (SELECT HocKy FROM @HocKyTable)
        AND (
            ct.MaCotDiem LIKE 'TX_%'
            OR ct.MaCotDiem LIKE '%Total'
            OR ct.MaCotDiem LIKE 'DiemCD1%'
            OR ct.MaCotDiem LIKE 'DiemCD2%'
            OR ct.MaCotDiem LIKE 'DiemGK%'
            OR ct.MaCotDiem LIKE 'DiemCK%'
            OR ct.MaCotDiem LIKE 'DiemTB%'
        )
    INNER JOIN dbo.tblMonHoc mh 
        ON mh.MonHocID = mhl.MonHocID AND mh.Enable = 1
    INNER JOIN dbo.tblHocSinhLop hsl 
        ON hsl.LopID      = mhl.LopNhomID
        AND hsl.Enable    = 1
    INNER JOIN dbo.tblHocSinh hs 
        ON hs.HocSinhID  = hsl.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblLop l 
        ON l.LopID     = mhl.LopNhomID
        AND l.NienKhoa = @NienKhoa
        AND hsl.LopID  = l.LopID
        AND l.LopID    = @LopID
        AND l.Enable   = 1
        AND hsl.NienKhoa = l.NienKhoa
    -- Dùng học sinh + cột template làm nền để cột TX bị khuyết vẫn có KetQua = NULL.
    LEFT JOIN dbo.tblKetQuaHocTap kqht
        ON kqht.CotDiemID    = ct.CotDiemID
        AND kqht.MonHocLopID = mhl.MonHocLopID
        AND kqht.LopID       = hsl.LopID
        AND kqht.HocSinhID   = hsl.HocSinhID
        AND kqht.NienKhoa    = @NienKhoa
        AND kqht.Enable      = 1
    LEFT JOIN @LockedColumns lc
        ON lc.MonHocLopID = mhl.MonHocLopID
        AND lc.MaCotDiem  = ct.MaCotDiem
    WHERE mhl.NienKhoa  = @NienKhoa
      AND mhl.LopNhomID = @LopID
      AND mhl.Enable    = 1
      AND mhl.MonHocID NOT IN (
          SELECT DISTINCT MonHocID
          FROM dbo.tblNhom
          WHERE Enable = 1 AND IsNhomLMS_GiaoBai = 0
      )
      AND mhl.MonHocID NOT IN (46)
      AND hsl.NienKhoa = @NienKhoa
      -- Các cột TX, kể cả tên dạng Theme*_Total, luôn hiện; loại điểm khác chỉ hiện khi khóa.
      AND (
          ct.MaCotDiem LIKE 'TX_%'
          OR ct.MaCotDiem LIKE '%Total'
          OR lc.MaCotDiem IS NOT NULL
      )

    UNION ALL

    -- =============================================
    -- BƯỚC 4B: Môn học đặc biệt (môn 46)
    -- =============================================
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        hsl.HocSinhID,
        mh.MonHocCode,
        CASE
            WHEN ct.MaCotDiem LIKE 'TX_%'              THEN 'TX'
            WHEN ct.MaCotDiem LIKE 'DiemGK%'           THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE 'DiemCK%'           THEN 'DiemCK'
            WHEN ct.MaCotDiem LIKE 'DiemTB%'           THEN 'DiemTB'
            WHEN ct.MaCotDiem LIKE '%Total'             THEN 'TX'
            WHEN ct.MaCotDiem LIKE '%Mid_Total_Point'   THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE '%Final_Total_Point' THEN 'DiemCK'
            ELSE 'Unknown'
        END AS LoaiDiem,
        ct.ThuTuNhom,
        ct.ThuTuCotDiem,
        ct.MaCotDiem,
        -- Nếu chưa có bản ghi điểm, LEFT JOIN giữ dòng này và KetQua sẽ là NULL.
        ISNULL(kqht.KetQuaDanhGia_VI, kqht.KetQuaDanhGia_EN) AS KetQua,
        ct.Semester AS HocKy,
        mh.Sort,
        mhl.MonHocLopID
    FROM dbo.tblMonHocLop mhl
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.TemplateBangDiemID = mhl.TemplateBangDiemID
        AND ct.Enable   = 1
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
    INNER JOIN dbo.tblMonHoc mh 
        ON mh.MonHocID = mhl.MonHocID AND mh.Enable = 1
    INNER JOIN dbo.tblHocSinhLop hsl 
        ON hsl.LopID      = mhl.LopNhomID
        AND hsl.Enable    = 1
    INNER JOIN dbo.tblHocSinh hs 
        ON hs.HocSinhID  = hsl.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblLop l 
        ON l.LopID    = mhl.LopNhomID
        AND l.NienKhoa = @NienKhoa
        AND hsl.LopID = l.LopID
        AND l.LopID   = @LopID
        AND l.Enable  = 1
        AND hsl.NienKhoa = l.NienKhoa
    -- Dùng học sinh + cột template làm nền để cột TX bị khuyết vẫn có KetQua = NULL.
    LEFT JOIN dbo.tblKetQuaHocTap kqht
        ON kqht.CotDiemID    = ct.CotDiemID
        AND kqht.MonHocLopID = mhl.MonHocLopID
        AND kqht.LopID       = hsl.LopID
        AND kqht.HocSinhID   = hsl.HocSinhID
        AND kqht.NienKhoa    = @NienKhoa
        AND kqht.Enable      = 1
    LEFT JOIN @LockedColumns lc
        ON lc.MonHocLopID = mhl.MonHocLopID
        AND lc.MaCotDiem  = ct.MaCotDiem
    WHERE mhl.NienKhoa  = @NienKhoa
      AND mhl.LopNhomID = @LopID
      AND mhl.Enable    = 1
      AND mhl.MonHocID  = 46
      AND hsl.NienKhoa  = @NienKhoa
      -- Các cột TX, kể cả Theme*_Total, luôn hiện; loại điểm khác chỉ hiện khi khóa.
      AND (
          ct.MaCotDiem LIKE 'TX_%'
          OR ct.MaCotDiem LIKE '%Total'
          OR lc.MaCotDiem IS NOT NULL
      );

    -- =============================================
    -- BƯỚC 5: Trả về kết quả
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
                    WHEN 'TX'     THEN 1
                    WHEN 'DiemGK' THEN 2
                    WHEN 'DiemCK' THEN 3
                    WHEN 'DiemTB' THEN 4
                    ELSE 5
                END,
                ThuTuNhom,
                ThuTuCotDiem,
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
            WHEN 'TX'     THEN 1
            WHEN 'DiemGK' THEN 2
            WHEN 'DiemCK' THEN 3
            WHEN 'DiemTB' THEN 4
            ELSE 5
        END,
        ThuTuNhom,
        ThuTuCotDiem,
        MaCotDiem;
END;
