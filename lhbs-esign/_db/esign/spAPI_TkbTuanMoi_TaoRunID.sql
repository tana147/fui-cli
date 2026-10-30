CREATE PROCEDURE spAPI_TkbTuanMoi_TaoRunID
    @RunIDCu INT,
    @TuanMoi INT,
    @MaxSecs INT = 60,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET @MaxSecs = ISNULL(@MaxSecs, 60);

    DECLARE @Khoi VARCHAR(50);
    SELECT @Khoi = STRING_AGG(x.Khoi, ',') FROM (
        SELECT DISTINCT l.Khoi FROM tblTKB_KetQuaXep k INNER JOIN tblTKB_Lop l ON l.MaLop = k.MaLop WHERE k.RunID = @RunIDCu
    ) x;

    IF @Khoi IS NULL OR @Khoi = ''
    BEGIN
        SELECT 0 AS RunID, N'KhongCoDuLieu' AS TrangThai, 0 AS SoTietGiuNguyen,
               N'RunID cũ chưa có tiết nào để xác định khối' AS ThongBao;
        RETURN;
    END

    -- Buoc 1: tao RunID moi + copy TOAN BO tiet tuan cu lam baseline, khoa het.
    INSERT INTO tblTKB_ChayAutoLog (Khoi, MaxSecs, TrangThai, NguoiChay, SoNhuCau, TuanHienTai)
    VALUES (CASE WHEN CHARINDEX(',', @Khoi) > 0 THEN LEFT(@Khoi, 1) + '+' ELSE @Khoi END,
            @MaxSecs, N'DaTaoBaseline', @sys_UserID, 0, @TuanMoi);
    DECLARE @RunIDMoi INT = SCOPE_IDENTITY();

    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
    SELECT @RunIDMoi, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong
    FROM tblTKB_KetQuaXep WHERE RunID = @RunIDCu;

    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime)
    SELECT ID, @sys_UserID, GETDATE() FROM tblTKB_KetQuaXep WHERE RunID = @RunIDMoi;

    -- Buoc 2: xoa dung phan bi anh huong (dung lai cong thuc R18 y het spAPI_TkbTuanMoi_XacDinhAnhHuong).
    DECLARE @TuanCu INT, @HocKy VARCHAR(4) = 'HK1';
    SELECT @TuanCu = TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunIDCu;

    ;WITH PCGDCu AS (
        SELECT pc.MaLop, pc.MaMon, pc.MaGV, pc.SoTietChuanTuan,
               ROW_NUMBER() OVER (PARTITION BY pc.MaLop, pc.MaMon, pc.HocKy
                   ORDER BY CASE WHEN pc.MaMon IN ('ENG1', 'TANN', 'SU') THEN pc.PhanCongID END) AS rn
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE pc.Enable = 1
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@TuanCu IS NULL OR pc.TuanApDungTu IS NULL OR @TuanCu >= pc.TuanApDungTu)
          AND (@TuanCu IS NULL OR pc.TuanApDungDen IS NULL OR @TuanCu <= pc.TuanApDungDen)
          AND (@TuanCu IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanCu % 2 = 0 THEN 1 ELSE 0 END)
    ),
    Cu AS (
        SELECT MaLop, MaMon, MaGV, SoTietChuanTuan AS SoTiet FROM PCGDCu
        WHERE (MaMon NOT IN ('ENG1', 'TANN', 'SU') OR rn = 1) AND MaMon <> 'SH'
    ),
    PCGDMoi AS (
        SELECT pc.MaLop, pc.MaMon, pc.MaGV, pc.SoTietChuanTuan,
               ROW_NUMBER() OVER (PARTITION BY pc.MaLop, pc.MaMon, pc.HocKy
                   ORDER BY CASE WHEN pc.MaMon IN ('ENG1', 'TANN', 'SU') THEN pc.PhanCongID END) AS rn
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE pc.Enable = 1
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@TuanMoi IS NULL OR pc.TuanApDungTu IS NULL OR @TuanMoi >= pc.TuanApDungTu)
          AND (@TuanMoi IS NULL OR pc.TuanApDungDen IS NULL OR @TuanMoi <= pc.TuanApDungDen)
          AND (@TuanMoi IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanMoi % 2 = 0 THEN 1 ELSE 0 END)
    ),
    Moi AS (
        SELECT MaLop, MaMon, MaGV, SoTietChuanTuan AS SoTiet FROM PCGDMoi
        WHERE (MaMon NOT IN ('ENG1', 'TANN', 'SU') OR rn = 1) AND MaMon <> 'SH'
    ),
    AnhHuong AS (
        SELECT COALESCE(c.MaLop, m.MaLop) AS MaLop, COALESCE(c.MaMon, m.MaMon) AS MaMon
        FROM Cu c
        FULL OUTER JOIN Moi m ON m.MaLop = c.MaLop AND m.MaMon = c.MaMon
        WHERE NOT (c.MaLop IS NOT NULL AND m.MaLop IS NOT NULL AND c.MaGV = m.MaGV AND c.SoTiet = m.SoTiet)
    )
    DELETE k FROM tblTKB_KetQuaXep k
    INNER JOIN AnhHuong a ON a.MaLop = k.MaLop AND a.MaMon = k.MaMon
    WHERE k.RunID = @RunIDMoi;

    -- Don rac Khoa mo coi (dong da bi xoa o tren) — an toan vi ID la global identity.
    DELETE FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID NOT IN (SELECT ID FROM tblTKB_KetQuaXep);

    SELECT @RunIDMoi AS RunID, N'DaTaoBaseline' AS TrangThai,
           (SELECT COUNT(*) FROM tblTKB_KetQuaXep WHERE RunID = @RunIDMoi) AS SoTietGiuNguyen,
           CAST(NULL AS NVARCHAR(200)) AS ThongBao;
END
