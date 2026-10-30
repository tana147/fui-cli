-- [dbo].[fn_GetKetQuaHocTapTheoLop_C1_ByHocSinhID] 23100152, 2025
CREATE   PROCEDURE [dbo].[fn_GetKetQuaHocTapTheoLop_C1_ByHocSinhID]
    @HocSinhID INT
  , @NienKhoa  INT
AS
BEGIN
    SET NOCOUNT ON;

    -- BƯỚC 1: Lấy danh sách môn học loại trừ
    DECLARE @ExcludedMonHoc TABLE (MonHocID INT PRIMARY KEY);

    INSERT INTO @ExcludedMonHoc (MonHocID)
    SELECT DISTINCT MonHocID
    FROM dbo.tblNhom
    WHERE Enable = 1 
      AND IsNhomLMS_GiaoBai = 0;

    -- BƯỚC 2: Khai báo bảng kết quả
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
        Sort         INT
    );

    -- BƯỚC 3: Lấy dữ liệu kết quả học tập
    INSERT INTO @Result
    SELECT 
        l.LopID,
        l.TenLop,
        hsl.SoDanhBo,
        kqht.HocSinhID,
        mh.MonHocCode,
        CASE
            WHEN ct.MaCotDiem LIKE 'NhanXet%'      THEN 'NhanXet'
            WHEN ct.MaCotDiem LIKE 'Diem%'         THEN 'Diem'
            WHEN ct.MaCotDiem LIKE 'MucDoDanhGia%' THEN 'MucDoDanhGia'
            ELSE 'Unknown'
        END AS LoaiDiem,
        ct.ThuTuNhom,
        ct.ThuTuCotDiem,
        ct.MaCotDiem,
        ISNULL(kqht.KetQuaDanhGia_VI, kqht.KetQuaDanhGia_EN) AS KetQua,  -- ← BỎ CHECK KHÓA
        ct.Semester AS HocKy,
        mh.Sort
    FROM dbo.tblKetQuaHocTap kqht
    INNER JOIN dbo.TemplateBangDiemChiTiet ct 
        ON ct.CotDiemID = kqht.CotDiemID
        AND ct.Enable = 1
        -- ← BỎ filter Semester
        AND (
            ct.MaCotDiem LIKE 'NhanXet%'
            OR ct.MaCotDiem LIKE 'Diem%'
            OR ct.MaCotDiem LIKE 'MucDoDanhGia%'
        )
        AND ct.MaCotDiem NOT LIKE 'DiemTB%'
    INNER JOIN dbo.tblMonHocLop mhl 
        ON mhl.TemplateBangDiemID = ct.TemplateBangDiemID
        AND mhl.NienKhoa = @NienKhoa
        AND mhl.MonHocLopID = kqht.MonHocLopID
        AND mhl.Enable = 1
        AND mhl.MonHocID NOT IN (SELECT MonHocID FROM @ExcludedMonHoc)
    INNER JOIN dbo.tblMonHoc mh 
        ON mh.MonHocID = mhl.MonHocID
        AND mh.Enable = 1
    INNER JOIN dbo.tblHocSinhLop hsl 
        ON hsl.LopID = mhl.LopNhomID
        AND hsl.HocSinhID = kqht.HocSinhID
        AND hsl.Enable = 1
    INNER JOIN dbo.tblHocSinh hs 
        ON hs.HocSinhID = kqht.HocSinhID
        AND hs.TinhTrang = 0
    INNER JOIN dbo.tblLop l 
        ON l.LopID = mhl.LopNhomID
        AND l.NienKhoa = @NienKhoa
        AND hsl.LopID = l.LopID
        AND l.Enable = 1
    AND hsl.NienKhoa = l.NienKhoa
        WHERE kqht.NienKhoa = @NienKhoa
      AND kqht.Enable = 1
      AND kqht.HocSinhID = @HocSinhID;  -- ← LỌC THEO HỌC SINH

    -- BƯỚC 4: Trả về kết quả
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