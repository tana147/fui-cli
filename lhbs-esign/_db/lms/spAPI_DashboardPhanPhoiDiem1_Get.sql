CREATE PROCEDURE [dbo].[spAPI_DashboardPhanPhoiDiem1_Get]
    @NienKhoa  INT
  , @KhoiID    INT
  , @MonHocID  INT
  , @MaCotDiem NVARCHAR(MAX) -- Chuỗi các MaCotDiem, phân tách bằng dấu phẩy
AS
BEGIN
    SET NOCOUNT ON;

    -- Tách chuỗi MaCotDiem thành bảng tạm
    DECLARE @MaCotDiemTable TABLE
    (
        MaCotDiem NVARCHAR(50)
    );
    INSERT INTO @MaCotDiemTable
    (
        MaCotDiem
    )
    SELECT LTRIM(RTRIM(value)) -- Sử dụng LTRIM và RTRIM thay thế TRIM
    FROM
           STRING_SPLIT(@MaCotDiem, ',');

    -- [Phần comment CTE đã được giữ nguyên]

    --data để vẽ KDE
    SELECT tl.LopID
         , tl.TenLop
         , hs.HocSinhID
         , hs.Ho + N' ' + hs.Ten AS HoTen
         , tmh.MonHocName
         , tmh.MonHocCode
         , tbdct.MaCotDiem
         , CASE
                WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
                 AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                ELSE NULL
           END                   AS Diem
         , tbdct.ThuTuCotDiem -- Thứ tự cột điểm
    FROM
           dbo.tblKetQuaHocTap                    tkqht
           INNER JOIN dbo.tblLop                  tl ON tl.LopID           = tkqht.LopID AND tl.NienKhoa = @NienKhoa
                                                    AND tl.KhoiID          = @KhoiID
           INNER JOIN dbo.tblHocSinh              hs ON hs.HocSinhID       = tkqht.HocSinhID
           INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
           INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
           INNER JOIN dbo.tblMonHoc               tmh ON tmh.MonHocID      = tmhl.MonHocID
                                                    AND tmh.MonHocID      = @MonHocID
           INNER JOIN @MaCotDiemTable             mcd ON tbdct.MaCotDiem   = mcd.MaCotDiem
    WHERE
           tkqht.NienKhoa                                    = @NienKhoa
      AND  TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
      AND  tkqht.Enable                                       = 1
    ORDER BY
           Diem;

    DECLARE @CapID INT;
    IF @KhoiID IN (1, 2, 3, 4, 5)
    BEGIN
        SET @CapID = 1;
    END;
    ELSE IF @KhoiID IN (6, 7, 8, 9)
    BEGIN
        SET @CapID = 2;
    END;
    ELSE
    BEGIN
        SET @CapID = 3;
    END;

    SELECT tl.KhoiID
         , N'Khối ' + CAST(tl.KhoiID AS VARCHAR) AS TenKhoi
         , tl.LopID
         , tl.TenLop
         , hs.HocSinhID
         , hs.Ho + N' ' + hs.Ten                 AS HoTen
         , tmh.MonHocName
         , tmh.MonHocCode
         , tbdct.MaCotDiem
         , CASE
                WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
                 AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                ELSE NULL
           END                                   AS Diem
         , tbdct.ThuTuCotDiem -- Thứ tự cột điểm
    FROM
           dbo.tblKetQuaHocTap                    tkqht
           INNER JOIN dbo.tblLop                  tl ON tl.LopID           = tkqht.LopID AND tl.NienKhoa = @NienKhoa
                                                    AND tl.CapID           = @CapID
           INNER JOIN dbo.tblHocSinh              hs ON hs.HocSinhID       = tkqht.HocSinhID
           INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
           INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
           INNER JOIN dbo.tblMonHoc               tmh ON tmh.MonHocID      = tmhl.MonHocID
                                                    AND tmh.MonHocID      = @MonHocID
           INNER JOIN @MaCotDiemTable             mcd ON tbdct.MaCotDiem   = mcd.MaCotDiem
    WHERE
           tkqht.NienKhoa                                    = @NienKhoa
      AND  TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
      AND  tkqht.Enable                                       = 1
    ORDER BY
           tl.TenLop -- Thay đổi từ TenLop thành tl.TenLop để rõ ràng hơn
         , Diem;
END;
