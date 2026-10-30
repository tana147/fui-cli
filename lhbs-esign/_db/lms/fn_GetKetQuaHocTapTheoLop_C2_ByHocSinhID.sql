CREATE   PROCEDURE [dbo].[fn_GetKetQuaHocTapTheoLop_C2_ByHocSinhID]
    @HocSinhID INT
  , @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    -- BƯỚC 1: Khai báo bảng kết quả
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

    -- BƯỚC 2A: Môn học thường (không phải môn 46)
    INSERT INTO @Result
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        kqht.HocSinhID,
        mh.MonHocCode,
        CASE
            WHEN ct.MaCotDiem LIKE 'TX_%'               THEN 'TX'
            WHEN ct.MaCotDiem LIKE 'DiemGK%'            THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE 'DiemCD1%'           THEN 'DiemGK'
            WHEN ct.MaCotDiem LIKE 'DiemCD2%'           THEN 'DiemCK'
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
    FROM dbo.tblKetQuaHocTap kqht
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable = 1
        -- ← BỎ filter Semester
        AND (
            ct.MaCotDiem LIKE 'TX_%'
            OR ct.MaCotDiem LIKE 'DiemCD1%'
            OR ct.MaCotDiem LIKE 'DiemCD2%'
            OR ct.MaCotDiem LIKE 'DiemGK%'
            OR ct.MaCotDiem LIKE 'DiemCK%'
            OR ct.MaCotDiem LIKE 'DiemTB%'
        )
    INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.TemplateBangDiemID = ct.TemplateBangDiemID
        AND mhl.NienKhoa = @NienKhoa
        AND mhl.MonHocLopID = kqht.MonHocLopID
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
        AND l.Enable = 1
    AND hsl.NienKhoa = l.NienKhoa
        WHERE kqht.NienKhoa = @NienKhoa
      AND kqht.Enable = 1
      AND kqht.HocSinhID = @HocSinhID

    UNION ALL

    -- BƯỚC 2B: Môn học đặc biệt (môn 46)
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
    FROM dbo.tblKetQuaHocTap kqht
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable = 1
        -- ← BỎ filter Semester
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
        AND l.Enable = 1
    AND hsl.NienKhoa = l.NienKhoa
        WHERE kqht.NienKhoa = @NienKhoa
      AND kqht.Enable = 1
      AND kqht.HocSinhID = @HocSinhID;

    -- BƯỚC 3: Trả về kết quả
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
        MaCotDiem;
END;