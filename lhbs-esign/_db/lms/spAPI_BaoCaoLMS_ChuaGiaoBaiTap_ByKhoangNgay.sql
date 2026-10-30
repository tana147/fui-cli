CREATE PROCEDURE dbo.spAPI_BaoCaoLMS_ChuaGiaoBaiTap_ByKhoangNgay
    @CapID INT,
    @NienKhoa INT,
    @NgayBatDau DATE,
    @NgayKetThuc DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Dùng lịch tuần LMS làm chuẩn: range ngày chọn các tuần giao nhau,
    -- sau đó so lịch dạy từng lớp/môn với các bài tập đã giao cho lớp trong tuần.
    ;WITH ReportWeeks AS
    (
        SELECT
            t.TuanHocID,
            t.NienKhoa,
            t.Nam,
            t.ThangHoc,
            t.Tuan,
            t.NgayBatDau,
            t.NgayKetThuc
        FROM dbo.tblTuanHocTap t
        WHERE (@NienKhoa IS NULL OR t.NienKhoa = @NienKhoa)
          AND t.NgayBatDau IS NOT NULL
          AND t.NgayKetThuc IS NOT NULL
          AND (@NgayBatDau IS NULL OR t.NgayKetThuc >= @NgayBatDau)
          AND (@NgayKetThuc IS NULL OR t.NgayBatDau <= @NgayKetThuc)
    ),
    ExpectedHomework AS
    (
        SELECT DISTINCT
            w.NienKhoa,
            w.Nam,
            w.ThangHoc,
            w.TuanHocID,
            w.Tuan,
            w.NgayBatDau,
            w.NgayKetThuc,
            l.LopID,
            l.TenLop,
            mh.MonHocID,
            mh.TenMonHoc_HienThi,
            g.GiaoVienID,
            COALESCE(
                NULLIF(LTRIM(RTRIM(CONCAT(gv.HoGV, N' ', gv.TenGV))), N''),
                NULLIF(LTRIM(RTRIM(g.GiaoVienID)), '')
            ) AS TenGiaoVien,
            mhl.MonHocLopID
        FROM ReportWeeks w
        -- Dùng phân công giáo viên lớp/môn của LMS để lấy đúng lớp và giáo viên theo cấp học.
        -- tblTKB_Lich là nguồn thời khóa biểu ngoài, không khớp CapHoc/LopID với danh mục lớp LMS.
        JOIN dbo.tblEL_GiaoVienLop g
          ON g.NienKhoa = w.NienKhoa
         AND g.Enable = 1
         AND NULLIF(LTRIM(RTRIM(g.GiaoVienID)), '') IS NOT NULL
        JOIN dbo.tblLop l
          ON l.LopID = g.LopID
         AND l.NienKhoa = g.NienKhoa
         AND l.CapID = @CapID
         AND l.Enable = 1
        JOIN dbo.tblMonHoc mh
          ON mh.MonHocID = g.MonHocID
         AND mh.CapID = @CapID
         AND mh.Enable = 1
        JOIN dbo.tblMonHocLop mhl
          ON mhl.LopNhomID = l.LopID
         AND mhl.MonHocID = mh.MonHocID
         AND mhl.NienKhoa = w.NienKhoa
         AND mhl.Enable = 1
        LEFT JOIN dbo.tblGiaoVien gv
          ON gv.GiaoVienID = g.GiaoVienID
         AND gv.Enable = 1
        WHERE (@NienKhoa IS NULL OR g.NienKhoa = @NienKhoa)
    )
    SELECT
        e.Nam,
        e.ThangHoc,
        e.TuanHocID,
        e.Tuan,
        e.NgayBatDau,
        e.NgayKetThuc,
        e.LopID,
        e.TenLop,
        e.MonHocID,
        e.TenMonHoc_HienThi,
        e.GiaoVienID,
        e.TenGiaoVien
    FROM ExpectedHomework e
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblEL_Assignments a
          ON a.AssignmentID = atc.AssignmentID
         AND a.TuanHocID = e.TuanHocID
         AND a.NienKhoa = e.NienKhoa
         AND a.MonHocID = e.MonHocID
         AND a.IsDeleted = 0
         AND ISNULL(a.IsDev, 0) = 0
        WHERE atc.MonHocLopID = e.MonHocLopID
          AND atc.ResourceType = 'ASSIGNMENT'
          AND atc.IsDeleted = 0
          AND (atc.NienKhoa IS NULL OR atc.NienKhoa = e.NienKhoa)
    )
    ORDER BY
        e.Nam,
        e.ThangHoc,
        e.Tuan,
        e.TenLop,
        e.TenMonHoc_HienThi,
        e.TenGiaoVien;
END;
