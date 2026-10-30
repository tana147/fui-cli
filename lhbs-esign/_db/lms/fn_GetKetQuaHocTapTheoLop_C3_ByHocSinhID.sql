-- [dbo].[fn_GetKetQuaHocTapTheoLop_C3_ByHocSinhID] 23100152, 2025
CREATE   PROCEDURE [dbo].[fn_GetKetQuaHocTapTheoLop_C3_ByHocSinhID]
    @HocSinhID INT
  , @NienKhoa  INT
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

    -- BƯỚC 2A: Môn học thường (không phải môn 76 và không phải nhóm)
    INSERT INTO @Result
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        hsl.HocSinhID,
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
        mhl.MonHocLopID
    FROM dbo.tblMonHocLop mhl
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.TemplateBangDiemID = mhl.TemplateBangDiemID
        AND ct.Enable = 1
        AND (
            ct.MaCotDiem LIKE 'TX_%'
            OR ct.MaCotDiem LIKE 'DiemGK%'
            OR ct.MaCotDiem LIKE 'DiemCK%'
            OR ct.MaCotDiem LIKE 'DiemTB%'
        )
    INNER JOIN dbo.tblMonHoc mh 
        ON mh.MonHocID = mhl.MonHocID
        AND mh.Enable = 1
    INNER JOIN dbo.tblHocSinhLop hsl 
        ON hsl.LopID = mhl.LopNhomID
        AND hsl.Enable = 1
        AND hsl.NienKhoa = @NienKhoa
    INNER JOIN dbo.tblHocSinh hs 
        ON hs.HocSinhID = hsl.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblLop l 
        ON l.LopID = mhl.LopNhomID
        AND l.NienKhoa = @NienKhoa
        AND hsl.LopID = l.LopID
        AND l.Enable = 1
    AND hsl.NienKhoa = l.NienKhoa
    -- Lấy cột TX từ template để vẫn trả dòng bị khuyết với KetQua = NULL.
    LEFT JOIN dbo.tblKetQuaHocTap kqht
        ON kqht.CotDiemID    = ct.CotDiemID
        AND kqht.MonHocLopID = mhl.MonHocLopID
        AND kqht.LopID       = hsl.LopID
        AND kqht.HocSinhID   = hsl.HocSinhID
        AND kqht.NienKhoa    = @NienKhoa
        AND kqht.Enable      = 1
    WHERE mhl.NienKhoa = @NienKhoa
      AND mhl.Enable = 1
      AND mhl.MonHocID NOT IN (
          SELECT DISTINCT MonHocID
          FROM dbo.tblNhom
          WHERE Enable = 1 AND IsNhomLMS_GiaoBai = 0
      )
      AND hsl.HocSinhID = @HocSinhID

    UNION ALL

    -- BƯỚC 2B: Môn 76 - lấy cột tổng từ template để giữ TX thiếu với KetQua = NULL.
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        hsl.HocSinhID,
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
        mhl.MonHocLopID
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN dbo.tblHocSinh hs 
        ON hs.HocSinhID = hsl.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblHocSinhNhom hsn 
        ON hsn.HocSinhID = hsl.HocSinhID
        AND hsn.Enable = 1
        AND hsn.NhomID IN (
            SELECT NhomID
            FROM dbo.tblNhom
            WHERE MonHocID = 76
              AND Enable = 1
              AND NienKhoa = @NienKhoa
        )
    INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.LopNhomID = hsn.NhomID
        AND mhl.NienKhoa = @NienKhoa
        AND mhl.Enable = 1
        AND mhl.MonHocID = 76
    INNER JOIN dbo.tblLop l 
        ON l.LopID = hsl.LopID
        AND l.Enable = 1
        AND l.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.tblMonHoc mh 
        ON mh.MonHocID = mhl.MonHocID
        AND mh.Enable = 1
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.TemplateBangDiemID = mhl.TemplateBangDiemID
        AND ct.Enable = 1
        AND (
            ct.MaCotDiem LIKE '%Total'
            OR ct.MaCotDiem LIKE '%Mid_Total_Point'
            OR ct.MaCotDiem LIKE '%Final_Total_Point'
            OR ct.MaCotDiem LIKE 'DiemGK%'
            OR ct.MaCotDiem LIKE 'DiemCK%'
            OR ct.MaCotDiem LIKE 'DiemTB%'
        )
    LEFT JOIN dbo.tblKetQuaHocTap kqht
        ON kqht.CotDiemID    = ct.CotDiemID
        AND kqht.MonHocLopID = mhl.MonHocLopID
        AND kqht.LopID       = hsl.LopID
        AND kqht.HocSinhID   = hsl.HocSinhID
        AND kqht.NienKhoa    = @NienKhoa
        AND kqht.Enable      = 1
    WHERE hsl.HocSinhID = @HocSinhID

    UNION ALL

    -- BƯỚC 2C: Môn 76 - Điểm chi tiết TA2
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        kqht.HocSinhID,
        mh.MonHocCode,
        CASE
            WHEN ct.MaCotDiem LIKE '%Mid_TA2_Listening_Point'  THEN 'DiemGK_TA'
            WHEN ct.MaCotDiem LIKE '%Mid_TA2_Reading_Point'    THEN 'DiemGK_TA'
            WHEN ct.MaCotDiem LIKE '%Mid_TA2_Writing_Point'    THEN 'DiemGK_TA'
            WHEN ct.MaCotDiem LIKE '%Mid_TA2_Speaking_Point'   THEN 'DiemGK_TA'
            WHEN ct.MaCotDiem LIKE '%Mid_TA2_Avg_Point'        THEN 'DiemGK_TA'
            WHEN ct.MaCotDiem LIKE '%Final_TA2_Listening_Point' THEN 'DiemCK_TA'
            WHEN ct.MaCotDiem LIKE '%Final_TA2_Reading_Point'  THEN 'DiemCK_TA'
            WHEN ct.MaCotDiem LIKE '%Final_TA2_Writing_Point'  THEN 'DiemCK_TA'
            WHEN ct.MaCotDiem LIKE '%Final_TA2_Speaking_Point' THEN 'DiemCK_TA'
            WHEN ct.MaCotDiem LIKE '%Final_TA2_Avg_Point'      THEN 'DiemCK_TA'
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
        ON hs.HocSinhID = hsl.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblHocSinhNhom hsn 
        ON hsn.HocSinhID = hsl.HocSinhID
        AND hsn.NhomID IN (
            SELECT NhomID
            FROM dbo.tblNhom
            WHERE MonHocID = 76
              AND Enable = 1
              AND NienKhoa = @NienKhoa
        )
    INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.LopNhomID = hsn.NhomID
        AND mhl.NienKhoa = @NienKhoa
        AND mhl.Enable = 1
        AND mhl.MonHocID = 76
    INNER JOIN dbo.tblLop l 
        ON l.LopID = hsl.LopID
        AND l.Enable = 1
        AND l.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.tblMonHoc mh 
        ON mh.MonHocID = mhl.MonHocID
        AND mh.Enable = 1
    INNER JOIN dbo.tblKetQuaHocTap kqht 
        ON kqht.MonHocLopID = mhl.MonHocLopID
        AND hsn.HocSinhID = kqht.HocSinhID
        AND hsl.HocSinhID = kqht.HocSinhID
        AND kqht.Enable = 1
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable = 1
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
    WHERE hsl.HocSinhID = @HocSinhID
      AND ct.MaCotDiem NOT LIKE '%Conv%'

    UNION ALL

    -- BƯỚC 2D: Các môn nhóm khác (không phải môn 76); TX thiếu vẫn trả KetQua = NULL.
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        hsl.HocSinhID,
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
        mhl.MonHocLopID
    FROM dbo.tblHocSinhLop hsl
    INNER JOIN dbo.tblHocSinh hs 
        ON hs.HocSinhID = hsl.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblHocSinhNhom hsn 
        ON hsn.HocSinhID = hsl.HocSinhID
        AND hsn.NhomID IN (
            SELECT NhomID
            FROM dbo.tblNhom
            WHERE MonHocID IN (
                SELECT DISTINCT MonHocID
                FROM dbo.tblNhom
                WHERE Enable = 1
                  AND MonHocID <> 76
            )
            AND Enable = 1
            AND NienKhoa = @NienKhoa
        )
    INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.LopNhomID = hsn.NhomID
        AND mhl.NienKhoa = @NienKhoa
        AND mhl.Enable = 1
        AND mhl.MonHocID <> 76
    INNER JOIN dbo.tblLop l 
        ON l.LopID = hsl.LopID
        AND l.Enable = 1
        AND l.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN dbo.tblMonHoc mh 
        ON mh.MonHocID = mhl.MonHocID
        AND mh.Enable = 1
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.TemplateBangDiemID = mhl.TemplateBangDiemID
        AND ct.Enable = 1
        AND (
            ct.MaCotDiem LIKE 'TX_%'
            OR ct.MaCotDiem LIKE 'DiemGK%'
            OR ct.MaCotDiem LIKE 'DiemCK%'
            OR ct.MaCotDiem LIKE 'DiemTB%'
        )
    LEFT JOIN dbo.tblKetQuaHocTap kqht
        ON kqht.CotDiemID    = ct.CotDiemID
        AND kqht.MonHocLopID = mhl.MonHocLopID
        AND kqht.LopID       = hsl.LopID
        AND kqht.HocSinhID   = hsl.HocSinhID
        AND kqht.NienKhoa    = @NienKhoa
        AND kqht.Enable      = 1
    WHERE hsl.HocSinhID = @HocSinhID;

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
                    WHEN 'TX'        THEN 1
                    WHEN 'DiemGK_TA' THEN 2
                    WHEN 'DiemGK'    THEN 3
                    WHEN 'DiemCK_TA' THEN 4
                    WHEN 'DiemCK'    THEN 5
                    WHEN 'DiemTB'    THEN 6
                    ELSE 7
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
            WHEN 'TX'        THEN 1
            WHEN 'DiemGK_TA' THEN 2
            WHEN 'DiemGK'    THEN 3
            WHEN 'DiemCK_TA' THEN 4
            WHEN 'DiemCK'    THEN 5
            WHEN 'DiemTB'    THEN 6
            ELSE 7
        END,
        ThuTuNhom,
        ThuTuCotDiem,
        MaCotDiem;
END;
