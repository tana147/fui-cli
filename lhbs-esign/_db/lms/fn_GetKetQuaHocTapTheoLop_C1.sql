-- [dbo].[fn_GetKetQuaHocTapTheoLop_C1] '2535' , 2025, 'HK2'
CREATE PROCEDURE [dbo].[fn_GetKetQuaHocTapTheoLop_C1]
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
      AND TinhTrang = 0;

    -- =============================================
    -- BƯỚC 3: Lấy danh sách môn học loại trừ
    -- =============================================
    DECLARE @ExcludedMonHoc TABLE (MonHocID INT PRIMARY KEY);

    INSERT INTO @ExcludedMonHoc (MonHocID)
    SELECT DISTINCT MonHocID
    FROM dbo.tblNhom
    WHERE Enable = 1 
      AND IsNhomLMS_GiaoBai = 0;

    -- =============================================
    -- BƯỚC 4: Lấy dữ liệu kết quả học tập
    -- =============================================
    DECLARE @Result TABLE
    (
        LopID          VARCHAR(40),
        TenLop         NVARCHAR(50),
        SoDanhBo       NVARCHAR(100),
        HocSinhID      INT,
        MonHocCode     NVARCHAR(50),
        LoaiDiem       NVARCHAR(20),
        ThuTuNhom      INT,
        ThuTuCotDiem   INT,
        MaCotDiem      NVARCHAR(100),
        KetQua         NVARCHAR(MAX),
        HocKy          NVARCHAR(100),
        Sort           INT
    );

    INSERT INTO @Result
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        kqht.HocSinhID,
        mh.MonHocCode,
        -- Xác định loại điểm
        CASE
            WHEN ct.MaCotDiem LIKE 'NhanXet%' THEN 'NhanXet'
            WHEN ct.MaCotDiem LIKE 'Diem%' THEN 'Diem'
            WHEN ct.MaCotDiem LIKE 'MucDoDanhGia%' THEN 'MucDoDanhGia'
            ELSE 'Unknown'
        END AS LoaiDiem,
        ct.ThuTuNhom,
        ct.ThuTuCotDiem,
        ct.MaCotDiem,
        -- Kiểm tra khóa cột điểm: nếu bị khóa thì NULL
        CASE 
            WHEN lc.MaCotDiem IS NULL THEN NULL
            ELSE ISNULL(kqht.KetQuaDanhGia_VI, kqht.KetQuaDanhGia_EN)
        END AS KetQua,
        ct.Semester AS HocKy,
        mh.Sort
    FROM dbo.tblKetQuaHocTap kqht
    -- Join với template cột điểm
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable = 1
        AND ct.Semester IN (SELECT HocKy FROM @HocKyTable)
        AND (
            ct.MaCotDiem LIKE 'NhanXet%'
            OR ct.MaCotDiem LIKE 'Diem%'
            OR ct.MaCotDiem LIKE 'MucDoDanhGia%'
        )
        AND ct.MaCotDiem NOT LIKE 'DiemTB%'
    -- Join với môn học lớp
    INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.TemplateBangDiemID = ct.TemplateBangDiemID
        AND mhl.NienKhoa = @NienKhoa
        AND mhl.MonHocLopID = kqht.MonHocLopID
        AND mhl.LopNhomID = @LopID
        AND mhl.Enable = 1
        AND mhl.MonHocID NOT IN (SELECT MonHocID FROM @ExcludedMonHoc)
    -- Join với môn học
    INNER JOIN dbo.tblMonHoc mh 
        ON mh.MonHocID = mhl.MonHocID
        AND mh.Enable = 1
    -- Join với học sinh lớp
    INNER JOIN dbo.tblHocSinhLop hsl 
        ON hsl.LopID = @LopID
        AND hsl.HocSinhID = kqht.HocSinhID
        AND hsl.Enable = 1
    -- Join với học sinh
    INNER JOIN dbo.tblHocSinh hs 
        ON hs.HocSinhID = kqht.HocSinhID
        AND hs.TinhTrang = 0
    -- Join với lớp
    INNER JOIN dbo.tblLop l 
        ON l.LopID = @LopID
        AND l.NienKhoa = @NienKhoa
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
        -- Đánh lại thứ tự cột điểm cho mỗi học sinh/môn học/học kỳ
        ROW_NUMBER() OVER (
            PARTITION BY HocSinhID, MonHocCode, HocKy 
            ORDER BY ThuTuNhom, ThuTuCotDiem
        ) AS ThuTuCotDiem,
        MaCotDiem,
        KetQua,
        HocKy,
        Sort
    FROM @Result
    ORDER BY 
        SoDanhBo,
        Sort,
        HocKy,
        ThuTuNhom,
        ThuTuCotDiem;
END;
