CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_Ins_NhieuLop_JSON]
    @Thu                 TINYINT,
    @Buoi                TINYINT,
    @TietBatDau          TINYINT,
    @TietKetThuc         TINYINT,
    @NgayApDung          DATE,
    @TuanHocID           INT,
    @NienKhoa            INT,
    @HocKy               INT,
    @GhiChu              NVARCHAR(500),
    @IsTreHan            BIT,
    @TenGiaoVienDangKy   NVARCHAR(200),
    @JsonDangKy          NVARCHAR(MAX),
    @sys_UserID          VARCHAR(20),
    @sys_SystemRight     INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DS TABLE
    (
        LopID INT NOT NULL,
        TenLop VARCHAR(10) NOT NULL,
        KhoiID INT NULL,
        MonHocID INT NULL,
        TenMonHoc NVARCHAR(100) NULL,
        JsonHocSinh NVARCHAR(MAX) NOT NULL
    );

    INSERT INTO @DS (LopID, TenLop, KhoiID, MonHocID, TenMonHoc, JsonHocSinh)
    SELECT LopID, TenLop, KhoiID, MonHocID, TenMonHoc, JsonHocSinh
    FROM OPENJSON(@JsonDangKy)
    WITH
    (
        LopID INT,
        TenLop VARCHAR(10),
        KhoiID INT,
        MonHocID INT,
        TenMonHoc NVARCHAR(100),
        JsonHocSinh NVARCHAR(MAX) AS JSON
    );

    IF NOT EXISTS (SELECT 1 FROM @DS)
    BEGIN
        RAISERROR(N'Không có lớp thực tế để lưu đăng ký.', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT LopID FROM @DS GROUP BY LopID HAVING COUNT(*) > 1)
    BEGIN
        RAISERROR(N'Danh sách đăng ký chứa trùng lớp.', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM @DS WHERE ISJSON(JsonHocSinh) <> 1 OR NOT EXISTS (SELECT 1 FROM OPENJSON(JsonHocSinh)))
    BEGIN
        RAISERROR(N'Một lớp không có học sinh được chọn.', 16, 1);
        RETURN;
    END;

    -- Kiểm tra toàn bộ trước khi ghi để không có tình huống 10A1 lưu xong
    -- nhưng 10A2 lỗi trùng lịch.
    IF EXISTS
    (
        SELECT 1
        FROM @DS ds
        INNER JOIN dbo.tblDangKyMangLaptop dk ON dk.LopID = ds.LopID
            AND dk.Enable = 1
            AND dk.NgayApDung = @NgayApDung
            AND dk.Buoi = @Buoi
            AND dk.TietBatDau <= @TietKetThuc
            AND dk.TietKetThuc >= @TietBatDau
    )
    BEGIN
        DECLARE @TenLopTrung VARCHAR(10), @TenGVTrung NVARCHAR(200);
        SELECT TOP 1 @TenLopTrung = ds.TenLop, @TenGVTrung = dk.TenGiaoVienDangKy
        FROM @DS ds
        INNER JOIN dbo.tblDangKyMangLaptop dk ON dk.LopID = ds.LopID
            AND dk.Enable = 1
            AND dk.NgayApDung = @NgayApDung
            AND dk.Buoi = @Buoi
            AND dk.TietBatDau <= @TietKetThuc
            AND dk.TietKetThuc >= @TietBatDau;
        RAISERROR(N'Lớp %s đã có đăng ký trùng buổi/tiết (do %s đăng ký). Chưa lưu lớp nào.', 16, 1, @TenLopTrung, @TenGVTrung);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @LopID INT, @TenLop VARCHAR(10), @KhoiID INT, @MonHocID INT,
                @TenMonHoc NVARCHAR(100), @JsonHocSinh NVARCHAR(MAX);
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT LopID, TenLop, KhoiID, MonHocID, TenMonHoc, JsonHocSinh FROM @DS;

        OPEN cur;
        FETCH NEXT FROM cur INTO @LopID, @TenLop, @KhoiID, @MonHocID, @TenMonHoc, @JsonHocSinh;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.spAPI_DangKyMangLaptop_Ins_JSON
                @LopID = @LopID, @TenLop = @TenLop, @KhoiID = @KhoiID,
                @MonHocID = @MonHocID, @TenMonHoc = @TenMonHoc,
                @Thu = @Thu, @Buoi = @Buoi, @TietBatDau = @TietBatDau,
                @TietKetThuc = @TietKetThuc, @NgayApDung = @NgayApDung,
                @TuanHocID = @TuanHocID, @NienKhoa = @NienKhoa, @HocKy = @HocKy,
                @GhiChu = @GhiChu, @IsTreHan = @IsTreHan,
                @JsonHocSinh = @JsonHocSinh, @TenGiaoVienDangKy = @TenGiaoVienDangKy,
                @sys_UserID = @sys_UserID, @sys_SystemRight = @sys_SystemRight;
            FETCH NEXT FROM cur INTO @LopID, @TenLop, @KhoiID, @MonHocID, @TenMonHoc, @JsonHocSinh;
        END;
        CLOSE cur;
        DEALLOCATE cur;

        COMMIT TRANSACTION;
        SELECT SoLopDaDangKy = COUNT(*) FROM @DS;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur') >= -1
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END;
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
