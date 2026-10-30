CREATE PROCEDURE [dbo].[spAPI_DashboardPhanPhoiDiem_Get1]
    @NienKhoa  INT,
    @KhoiID    INT,
    @MonHocID  INT,
    @MaCotDiem NVARCHAR(MAX) -- Chuỗi các MaCotDiem, phân tách bằng dấu phẩy
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaCotDiemTable TABLE (MaCotDiem NVARCHAR(50));
    INSERT INTO @MaCotDiemTable
    SELECT LTRIM(RTRIM(value))
    FROM STRING_SPLIT(@MaCotDiem, ',');

    -- Lấy dữ liệu chi tiết để vẽ KDE
    IF @KhoiID BETWEEN 1 AND 9
    BEGIN
        -- TH, THCS dùng tblLop
        SELECT 
            tl.LopID,
            tl.TenLop,
            hs.HocSinhID,
            hs.Ho + N' ' + hs.Ten AS HoTen,
            tmh.MonHocName,
            tmh.MonHocCode,
            tbdct.MaCotDiem,
            CASE
                WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
                     AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                ELSE NULL
            END AS Diem,
            tbdct.ThuTuCotDiem
        FROM dbo.tblKetQuaHocTap tkqht
        INNER JOIN dbo.tblLop tl ON tl.LopID = tkqht.LopID AND tl.KhoiID = @KhoiID AND tl.NienKhoa = @NienKhoa
        INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = tkqht.HocSinhID
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = @MonHocID
        INNER JOIN @MaCotDiemTable mcd ON tbdct.MaCotDiem = mcd.MaCotDiem
        WHERE tkqht.NienKhoa = @NienKhoa
          AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
          AND tkqht.Enable = 1
        ORDER BY Diem;
    END
    ELSE
    BEGIN
        -- THPT dùng tblNhom
        SELECT 
            tl.NhomID AS LopID,
            tl.TenNhom AS TenLop,
            hs.HocSinhID,
            hs.Ho + N' ' + hs.Ten AS HoTen,
            tmh.MonHocName,
            tmh.MonHocCode,
            tbdct.MaCotDiem,
            CASE
                WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
                     AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                ELSE NULL
            END AS Diem,
            tbdct.ThuTuCotDiem
        FROM dbo.tblKetQuaHocTap tkqht
        INNER JOIN dbo.tblNhom tl ON tl.NhomID = tkqht.LopID AND tl.KhoiID = @KhoiID and tl.IsNhomLMS_GiaoBai = 0
        INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = tkqht.HocSinhID
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = @MonHocID
        INNER JOIN @MaCotDiemTable mcd ON tbdct.MaCotDiem = mcd.MaCotDiem
        WHERE tkqht.NienKhoa = @NienKhoa
          AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
          AND tkqht.Enable = 1
        ORDER BY Diem;
    END
END
