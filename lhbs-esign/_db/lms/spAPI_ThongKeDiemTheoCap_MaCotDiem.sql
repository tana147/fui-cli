
CREATE PROCEDURE [dbo].[spAPI_ThongKeDiemTheoCap_MaCotDiem]
    @CapID INT,
    @MonHocID INT,
    @MaCotDiem NVARCHAR(50),
    @HocKi NVARCHAR(10),
    @NhomHocKi NVARCHAR(50),
    @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@NienKhoa IS NULL OR @NienKhoa = 0)
        SET @NienKhoa = dbo.fn_GetNienKhoa_HienTai();

    IF @MonHocID IN (106, 43, 42, 41, 40, 38, 37, 36)
    BEGIN
        SET @MaCotDiem = 'Sao' + @NhomHocKi

        ;WITH DiemTheoKhoi AS (
            SELECT 
                k.TenKhoiHoc,
                tbdct.Semester,
                COUNT(DISTINCT kq.HocSinhID) AS TongSoHocSinh,

                COUNT(CASE WHEN TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) < 3  THEN 1 END) AS SaoDuoi3,
                COUNT(CASE WHEN FLOOR(TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT)) = 3 THEN 1 END) AS Sao3,
                COUNT(CASE WHEN FLOOR(TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT)) = 4 THEN 1 END) AS Sao4,
                COUNT(CASE WHEN FLOOR(TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT)) = 5 THEN 1 END) AS Sao5

            FROM tblKetQuaHocTap kq
                INNER JOIN TemplateBangDiemChiTiet tbdct 
                    ON kq.CotDiemID = tbdct.CotDiemID AND tbdct.Enable = 1
                INNER JOIN tblHocSinh hs 
                    ON hs.HocSinhID = kq.HocSinhID AND hs.TinhTrang = 0
                INNER JOIN tblMonHocLop mhl 
                    ON mhl.MonHocLopID = kq.MonHocLopID AND mhl.Enable = 1 AND mhl.NienKhoa = @NienKhoa
                INNER JOIN tblMonHoc mh 
                    ON mh.MonHocID = mhl.MonHocID AND mh.Enable = 1
                INNER JOIN tblHocSinhLop hsl 
                    ON hsl.HocSinhID = kq.HocSinhID AND hsl.Enable = 1
                INNER JOIN tblLop l 
                    ON hsl.LopID = l.LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
                AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN tblKhoi k 
                    ON l.KhoiID = k.KhoiID AND k.Enable = 1
            WHERE  
                mh.CapID = @CapID
                AND mh.MonHocID = @MonHocID
                AND tbdct.MaCotDiem = @MaCotDiem
                AND tbdct.Semester = @HocKi
                AND kq.Enable = 1
                AND kq.NienKhoa = @NienKhoa
                AND kq.KetQuaDanhGia_VI <> ''
                AND kq.KetQuaDanhGia_VI IS NOT NULL
                AND TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) IS NOT NULL
            GROUP BY 
                k.TenKhoiHoc,
                tbdct.Semester
        )

        SELECT 
            TenKhoiHoc,
            Semester,
            TongSoHocSinh,

            SaoDuoi3,
            FORMAT(SaoDuoi3 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeSaoDuoi3,

            Sao3,
            FORMAT(Sao3 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeSao3,

            Sao4,
            FORMAT(Sao4 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeSao4,

            Sao5,
            FORMAT(Sao5 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeSao5

        FROM DiemTheoKhoi
    END
    ELSE 
    BEGIN
        ;WITH DiemTheoKhoi AS (
            SELECT 
                k.TenKhoiHoc,
                tbdct.Semester,
                COUNT(DISTINCT kq.HocSinhID) AS TongSoHocSinh,

                COUNT(CASE WHEN TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) < 5 THEN 1 END) AS DiemDuoi5,
                COUNT(CASE WHEN FLOOR(TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT)) = 5 AND TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) < 5.5 THEN 1 END) AS Diem5,
                COUNT(CASE WHEN FLOOR(TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT)) = 6 AND TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) < 6.5 THEN 1 END) AS Diem6,
                COUNT(CASE WHEN FLOOR(TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT)) = 7 AND TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) < 7.5 THEN 1 END) AS Diem7,
                COUNT(CASE WHEN FLOOR(TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT)) = 8 AND TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) < 8.5 THEN 1 END) AS Diem8,
                COUNT(CASE WHEN TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) >= 8.5 AND TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) < 9.5 THEN 1 END) AS Diem9,
                COUNT(CASE WHEN TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) >= 9.5 THEN 1 END) AS Diem10

            FROM tblKetQuaHocTap kq
                INNER JOIN TemplateBangDiemChiTiet tbdct 
                    ON kq.CotDiemID = tbdct.CotDiemID AND tbdct.Enable = 1
                INNER JOIN tblHocSinh hs 
                    ON hs.HocSinhID = kq.HocSinhID AND hs.TinhTrang = 0 
                INNER JOIN tblMonHocLop mhl 
                    ON mhl.MonHocLopID = kq.MonHocLopID AND mhl.Enable = 1 AND mhl.NienKhoa = @NienKhoa
                INNER JOIN tblMonHoc mh 
                    ON mh.MonHocID = mhl.MonHocID AND mh.Enable = 1
                INNER JOIN tblHocSinhLop hsl 
                    ON hsl.HocSinhID = kq.HocSinhID AND hsl.Enable = 1 
                INNER JOIN tblLop l 
                    ON hsl.LopID = l.LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
                AND hsl.NienKhoa = l.NienKhoa
        INNER JOIN tblKhoi k 
                    ON l.KhoiID = k.KhoiID AND k.Enable = 1
            WHERE  
                mh.CapID = @CapID
                AND mh.MonHocID = @MonHocID
                AND tbdct.MaCotDiem = @MaCotDiem
                AND tbdct.Semester = @HocKi
                AND kq.Enable = 1
                AND kq.NienKhoa = @NienKhoa
                AND kq.KetQuaDanhGia_VI <> ''
                AND kq.KetQuaDanhGia_VI IS NOT NULL
                AND TRY_CAST(kq.KetQuaDanhGia_VI AS FLOAT) IS NOT NULL
            GROUP BY 
                k.TenKhoiHoc,
                tbdct.Semester
        )

        SELECT 
            TenKhoiHoc,
            Semester,
            TongSoHocSinh,

            DiemDuoi5,
            FORMAT(DiemDuoi5 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeDiemDuoi5,

            Diem5,
            FORMAT(Diem5 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeDiem5,

            Diem6,
            FORMAT(Diem6 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeDiem6,

            Diem7,
            FORMAT(Diem7 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeDiem7,

            Diem8,
            FORMAT(Diem8 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeDiem8,

            Diem9,
            FORMAT(Diem9 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeDiem9,

            Diem10,
            FORMAT(Diem10 * 100.0 / NULLIF(TongSoHocSinh, 0), 'N2') + '%' AS TiLeDiem10

        FROM DiemTheoKhoi
    END

END