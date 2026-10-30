CREATE PROCEDURE [dbo].[spAPI_BaoCao_ThongKe_XepLoai_Tin]
    @NienKhoa INT,
    @MaCotDiem NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@NienKhoa, 0) = 0
    BEGIN
        RAISERROR(N'Niên khóa là bắt buộc.', 16, 1);
        RETURN;
    END;

    IF @MaCotDiem NOT IN (N'DiemGK_HK1', N'DiemCK_HK1', N'DiemGK_HK2', N'DiemCK_HK2')
    BEGIN
        RAISERROR(N'Cột điểm không hợp lệ.', 16, 1);
        RETURN;
    END;

    DECLARE @Semester NVARCHAR(10) = CASE
        WHEN @MaCotDiem IN (N'DiemGK_HK1', N'DiemCK_HK1') THEN N'HK1'
        ELSE N'HK2'
    END;

    ;WITH Targets AS
    (
        SELECT 1 AS PhamViID, l.LopID AS DoiTuongID, l.TenLop AS TenDoiTuong, l.KhoiID, l.CapID
        FROM dbo.tblLop AS l
        WHERE l.Enable = 1 AND l.NienKhoa = @NienKhoa AND l.CapID = 2

        UNION ALL

        SELECT 2 AS PhamViID, l.LopID AS DoiTuongID, l.TenLop AS TenDoiTuong, l.KhoiID, l.CapID
        FROM dbo.tblLop AS l
        WHERE l.Enable = 1 AND l.NienKhoa = @NienKhoa AND l.CapID = 3

        UNION ALL

        SELECT 3 AS PhamViID, n.NhomID AS DoiTuongID, n.TenNhom AS TenDoiTuong, n.KhoiID, n.CapID
        FROM dbo.tblNhom AS n
        WHERE n.Enable = 1
          AND n.NienKhoa = @NienKhoa
          AND n.CapID = 3
          AND n.MonHocID IN (72, 102) -- Mã môn Tin THCS/THPT theo cấu hình LMS hiện tại.
          AND ISNULL(n.IsNhomLMS_GiaoBai, 0) = 0
    ),
    Roster AS
    (
        SELECT 1 AS PhamViID, l.LopID AS DoiTuongID, hsl.HocSinhID
        FROM dbo.tblLop AS l
        INNER JOIN dbo.tblHocSinhLop AS hsl
            ON hsl.LopID = l.LopID
           AND hsl.NienKhoa = l.NienKhoa
           AND hsl.Enable = 1
        INNER JOIN dbo.tblHocSinh AS hs
            ON hs.HocSinhID = hsl.HocSinhID
           AND hs.TinhTrang = 0
        WHERE l.Enable = 1 AND l.NienKhoa = @NienKhoa AND l.CapID = 2

        UNION ALL

        SELECT 2 AS PhamViID, l.LopID AS DoiTuongID, hsl.HocSinhID
        FROM dbo.tblLop AS l
        INNER JOIN dbo.tblHocSinhLop AS hsl
            ON hsl.LopID = l.LopID
           AND hsl.NienKhoa = l.NienKhoa
           AND hsl.Enable = 1
        INNER JOIN dbo.tblHocSinh AS hs
            ON hs.HocSinhID = hsl.HocSinhID
           AND hs.TinhTrang = 0
        WHERE l.Enable = 1 AND l.NienKhoa = @NienKhoa AND l.CapID = 3

        UNION ALL

        SELECT 3 AS PhamViID, n.NhomID AS DoiTuongID, hsn.HocSinhID
        FROM dbo.tblNhom AS n
        INNER JOIN dbo.tblHocSinhNhom AS hsn
            ON hsn.Enable = 1
           AND CASE WHEN @Semester = N'HK1' THEN NULLIF(hsn.NhomID_HK1, '') ELSE hsn.NhomID END = n.NhomID
        INNER JOIN dbo.tblHocSinh AS hs
            ON hs.HocSinhID = hsn.HocSinhID
           AND hs.TinhTrang = 0
        WHERE n.Enable = 1
          AND n.NienKhoa = @NienKhoa
          AND n.CapID = 3
          AND n.MonHocID IN (72, 102)
          AND ISNULL(n.IsNhomLMS_GiaoBai, 0) = 0
    ),
    DiemTin AS
    (
        SELECT kq.HocSinhID,
               mhl.LopNhomID AS DoiTuongID,
               MAX(TRY_CONVERT(DECIMAL(10, 2), NULLIF(LTRIM(RTRIM(kq.KetQuaDanhGia_VI)), N''))) AS Diem
        FROM dbo.tblKetQuaHocTap AS kq
        INNER JOIN dbo.TemplateBangDiemChiTiet AS ct
            ON ct.CotDiemID = kq.CotDiemID
           AND ct.Enable = 1
           AND ct.Semester = @Semester
           AND ct.MaCotDiem = @MaCotDiem
        INNER JOIN dbo.tblMonHocLop AS mhl
            ON mhl.MonHocLopID = kq.MonHocLopID
           AND mhl.Enable = 1
           AND mhl.NienKhoa = @NienKhoa
        INNER JOIN dbo.tblMonHoc AS mh
            ON mh.MonHocID = mhl.MonHocID
           AND mh.Enable = 1
           AND mh.MonHocID IN (72, 102)
        WHERE kq.Enable = 1
          AND kq.NienKhoa = @NienKhoa
          AND kq.LopID = mhl.LopNhomID
        GROUP BY kq.HocSinhID, mhl.LopNhomID
    ),
    DiemTheoDoiTuongRaw AS
    (
        -- THCS: Tin được mở theo lớp, vì vậy đối tượng điểm là chính LopNhomID của lớp.
        SELECT 1 AS PhamViID, r.DoiTuongID, r.HocSinhID, d.Diem
        FROM Roster AS r
        INNER JOIN DiemTin AS d
            ON d.HocSinhID = r.HocSinhID
           AND d.DoiTuongID = r.DoiTuongID
        WHERE r.PhamViID = 1

        UNION ALL

        -- THPT lớp gốc: gom điểm từ nhóm Tin của học sinh về lớp hành chính hiện tại.
        SELECT 2 AS PhamViID, r.DoiTuongID, r.HocSinhID, MAX(d.Diem) AS Diem
        FROM Roster AS r
        INNER JOIN DiemTin AS d ON d.HocSinhID = r.HocSinhID
        INNER JOIN Targets AS groupTarget
            ON groupTarget.PhamViID = 3
           AND groupTarget.DoiTuongID = d.DoiTuongID
        WHERE r.PhamViID = 2
        GROUP BY r.DoiTuongID, r.HocSinhID

        UNION ALL

        -- THPT nhóm Tin: HK1 dùng nhóm đã lưu riêng cho HK1; HK2 dùng nhóm hiện tại.
        SELECT 3 AS PhamViID, r.DoiTuongID, r.HocSinhID, d.Diem
        FROM Roster AS r
        INNER JOIN DiemTin AS d
            ON d.HocSinhID = r.HocSinhID
           AND d.DoiTuongID = r.DoiTuongID
        WHERE r.PhamViID = 3
    ),
    DiemTheoDoiTuong AS
    (
        SELECT PhamViID, DoiTuongID, HocSinhID, MAX(Diem) AS Diem
        FROM DiemTheoDoiTuongRaw
        GROUP BY PhamViID, DoiTuongID, HocSinhID
    ),
    TongDiem AS
    (
        SELECT PhamViID,
               DoiTuongID,
               COUNT(DISTINCT HocSinhID) AS DaCoDiem,
               AVG(Diem) AS DiemTrungBinh,
               COUNT(DISTINCT CASE WHEN Diem >= 8 THEN HocSinhID END) AS Gioi,
               COUNT(DISTINCT CASE WHEN Diem >= 6.5 AND Diem < 8 THEN HocSinhID END) AS Kha,
               COUNT(DISTINCT CASE WHEN Diem >= 5 AND Diem < 6.5 THEN HocSinhID END) AS TrungBinh,
               COUNT(DISTINCT CASE WHEN Diem >= 3.5 AND Diem < 5 THEN HocSinhID END) AS Yeu,
               COUNT(DISTINCT CASE WHEN Diem < 3.5 THEN HocSinhID END) AS Kem
        FROM DiemTheoDoiTuong
        WHERE Diem BETWEEN 0 AND 10
        GROUP BY PhamViID, DoiTuongID
    )
    SELECT t.PhamViID,
           t.DoiTuongID,
           t.TenDoiTuong,
           t.KhoiID,
           t.CapID,
           COUNT(DISTINCT r.HocSinhID) AS SiSo,
           ISNULL(td.DaCoDiem, 0) AS DaCoDiem,
           CAST(td.DiemTrungBinh AS DECIMAL(10, 2)) AS DiemTrungBinh,
           ISNULL(td.Gioi, 0) AS Gioi,
           ISNULL(td.Kha, 0) AS Kha,
           ISNULL(td.TrungBinh, 0) AS TrungBinh,
           ISNULL(td.Yeu, 0) AS Yeu,
           ISNULL(td.Kem, 0) AS Kem
    FROM Targets AS t
    LEFT JOIN Roster AS r
        ON r.PhamViID = t.PhamViID
       AND r.DoiTuongID = t.DoiTuongID
    LEFT JOIN TongDiem AS td
        ON td.PhamViID = t.PhamViID
       AND td.DoiTuongID = t.DoiTuongID
    GROUP BY t.PhamViID, t.DoiTuongID, t.TenDoiTuong, t.KhoiID, t.CapID,
             td.DaCoDiem, td.DiemTrungBinh, td.Gioi, td.Kha, td.TrungBinh, td.Yeu, td.Kem
    ORDER BY t.PhamViID, t.KhoiID, t.TenDoiTuong;
END;
