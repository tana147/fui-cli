CREATE PROCEDURE [dbo].[spAPI_DashboardDiemTrungBinhTheoThemeVaLop_Get]
    @HocKy    NVARCHAR(10) -- Học kỳ: 'HK1' hoặc 'HK2'
  , @KhoiID   INT
  , @LopID    NVARCHAR(10)
  , @MonHocID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tạo bảng tạm để chứa danh sách theme
    CREATE TABLE #ThemeList
    (
        Theme NVARCHAR(50)
    );

    -- Chèn các theme tương ứng với học kỳ
    IF @HocKy = 'HK1'
    BEGIN
        INSERT INTO #ThemeList
        (
            Theme
        )
        VALUES
        (
            'Theme1_Total'
        )
      , (
            'Theme2_Total'
        )
      , (
            'Theme3_Total'
        )
      , (
            'Theme4_Total'
        );
    END;
    ELSE IF @HocKy = 'HK2'
    BEGIN
        INSERT INTO #ThemeList
        (
            Theme
        )
        VALUES
        (
            'Theme5_Total'
        )
      , (
            'Theme6_Total'
        )
      , (
            'Theme7_Total'
        )
      , (
            'Theme8_Total'
        );
    END;
    ELSE
    BEGIN
        RAISERROR('Học kỳ không hợp lệ! Chỉ chấp nhận HK1 hoặc HK2.', 16, 1);
        RETURN;
    END;
    DECLARE @IsNumber BIT = CASE WHEN ISNUMERIC(@LopID) = 1 THEN 1 ELSE 0 END;
    IF @IsNumber = 1
    BEGIN;
        -- Truy vấn dữ liệu và tính điểm trung bình theo lớp
        WITH ClassScores AS
        (
            SELECT tbdct.MaCotDiem
                 , tl.TenLop
                 , CAST(tkqht.KetQuaDanhGia_VI AS FLOAT) AS Diem -- Sử dụng cột KetQuaDanhGia_VI làm điểm
            FROM
                   dbo.tblKetQuaHocTap                    tkqht
                   INNER JOIN dbo.tblHocSinhLop           thsl ON tkqht.HocSinhID  = thsl.HocSinhID
                   INNER JOIN dbo.tblLop                  tl ON tl.LopID           = thsl.LopID AND tl.NienKhoa = thsl.NienKhoa
                   INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
                   INNER JOIN dbo.tblMonHoc               tmh ON tmhl.MonHocID     = tmh.MonHocID
                   INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
            WHERE
                   tl.KhoiID     = @KhoiID
              AND  tmh.MonHocID   = @MonHocID
              AND  tl.LopID       = @LopID
              AND  tbdct.Semester = @HocKy
              AND  tbdct.MaCotDiem IN
                   (
                       SELECT Theme
                       FROM
                             #ThemeList
                   )
              AND  tkqht.Enable   = 1
        )
        SELECT MaCotDiem
             , TenLop
             , AVG(Diem) AS DiemTrungBinhLop -- Tính điểm trung bình theo lớp cho từng theme
        FROM
               ClassScores
        GROUP BY
               MaCotDiem
             , TenLop;
		-- Dọn dẹp bảng tạm
    END;
    ELSE
    BEGIN
         -- Truy vấn dữ liệu và tính điểm trung bình theo lớp
        WITH ClassScores AS
        (
            SELECT tbdct.MaCotDiem
                 , tl.TenNhom as TenLop
                 , CAST(tkqht.KetQuaDanhGia_VI AS FLOAT) AS Diem -- Sử dụng cột KetQuaDanhGia_VI làm điểm
            FROM
                   dbo.tblKetQuaHocTap                    tkqht
                   INNER JOIN dbo.tblHocSinhNhom           thsn ON tkqht.HocSinhID  = thsn.HocSinhID and thsn.Enable = 1
                   INNER JOIN dbo.tblNhom                  tl ON tl.NhomID           = thsn.NhomID and tl.IsNhomLMS_GiaoBai = 0
                   INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
                   INNER JOIN dbo.tblMonHoc               tmh ON tmhl.MonHocID     = tmh.MonHocID
                   INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
            WHERE
                   tl.KhoiID     = @KhoiID
              AND  tmh.MonHocID   = @MonHocID
              AND  tl.NhomID       = @LopID
              AND  tbdct.Semester = @HocKy
              AND  tbdct.MaCotDiem IN
                   (
                       SELECT Theme
                       FROM
                             #ThemeList
                   )
              AND  tkqht.Enable   = 1
        )
        SELECT MaCotDiem
             , TenLop
             , AVG(Diem) AS DiemTrungBinhLop -- Tính điểm trung bình theo lớp cho từng theme
        FROM
               ClassScores
        GROUP BY
               MaCotDiem
             , TenLop;
		-- Dọn dẹp bảng tạm
    END;

    DROP TABLE #ThemeList;
END;