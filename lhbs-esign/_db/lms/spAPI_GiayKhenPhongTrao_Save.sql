
CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTrao_Save]
    @PhongTraoID INT
  , @TenPhongTrao NVARCHAR(300)
  , @LoaiMau INT
  , @DanhHieu_VI NVARCHAR(500)
  , @DanhHieu_EN NVARCHAR(500)
  , @NamHoc NVARCHAR(100)
  , @NgayCap_VI NVARCHAR(100)
  , @NgayCap_EN NVARCHAR(100)
  , @SoQuyetDinh NVARCHAR(100)
  , @KhoiID INT
  , @HocKy INT
  , @NienKhoa INT
  , @GhiChu NVARCHAR(500)
  , @CacGiai NVARCHAR(1000)
  , @DongJson NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF @DongJson IS NOT NULL AND ISJSON(@DongJson) <> 1
    BEGIN
        RAISERROR(N'Danh sách dòng nội dung không đúng định dạng JSON.', 16, 1);
        RETURN;
    END

    IF @PhongTraoID = 0 OR @PhongTraoID IS NULL
    BEGIN
        INSERT INTO dbo.tblGiayKhenPhongTrao
        (
            TenPhongTrao, LoaiMau, DanhHieu_VI, DanhHieu_EN, NamHoc,
            NgayCap_VI, NgayCap_EN, SoQuyetDinh, KhoiID, HocKy, NienKhoa,
            GhiChu, Enable, CreateUser, CreateTime
        )
        VALUES
        (
            @TenPhongTrao, @LoaiMau, @DanhHieu_VI, @DanhHieu_EN, ISNULL(NULLIF(@NamHoc, ''), N'Năm học/ School Year 2026 - 2027'),
            @NgayCap_VI, @NgayCap_EN, @SoQuyetDinh, @KhoiID, @HocKy, @NienKhoa,
            @GhiChu, 1, @sys_UserID, GETDATE()
        );
        SET @PhongTraoID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblGiayKhenPhongTrao
        SET TenPhongTrao = @TenPhongTrao
          , LoaiMau = @LoaiMau
          , DanhHieu_VI = @DanhHieu_VI
          , DanhHieu_EN = @DanhHieu_EN
          , NamHoc = ISNULL(@NamHoc, NamHoc)
          , NgayCap_VI = @NgayCap_VI
          , NgayCap_EN = @NgayCap_EN
          , SoQuyetDinh = @SoQuyetDinh
          , KhoiID = @KhoiID
          , HocKy = @HocKy
          , NienKhoa = @NienKhoa
          , GhiChu = @GhiChu
          , UpdateUser = @sys_UserID
          , UpdateTime = GETDATE()
        WHERE PhongTraoID = @PhongTraoID;
    END

    /* Dòng nội dung là dữ liệu động; các cột cũ chỉ giữ tương thích với luồng in hiện tại. */
    IF @DongJson IS NOT NULL
    BEGIN
        DELETE FROM dbo.tblGiayKhenPhongTraoDong
        WHERE PhongTraoID = @PhongTraoID;

        INSERT INTO dbo.tblGiayKhenPhongTraoDong
        (
            PhongTraoID, ThuTuDong, TenDong, MaDong, NgonNgu, NoiDung,
            KieuDuLieu, BatBuoc, Enable, CreateUser, CreateTime
        )
        SELECT @PhongTraoID,
               d.ThuTuDong,
               COALESCE(NULLIF(d.TenDong, N''), N'Dòng ' + CONVERT(NVARCHAR(10), d.ThuTuDong)),
               NULLIF(d.MaDong, N''),
               NULLIF(d.NgonNgu, ''),
               d.NoiDung,
               COALESCE(NULLIF(d.KieuDuLieu, ''), 'text'),
               COALESCE(d.BatBuoc, 0),
               COALESCE(d.Enable, 1),
               @sys_UserID,
               GETDATE()
        FROM OPENJSON(@DongJson)
        WITH
        (
            ThuTuDong INT '$.ThuTuDong',
            TenDong NVARCHAR(100) '$.TenDong',
            MaDong NVARCHAR(100) '$.MaDong',
            NgonNgu VARCHAR(10) '$.NgonNgu',
            NoiDung NVARCHAR(1000) '$.NoiDung',
            KieuDuLieu VARCHAR(30) '$.KieuDuLieu',
            BatBuoc BIT '$.BatBuoc',
            Enable BIT '$.Enable'
        ) d
        WHERE d.ThuTuDong > 0;
    END

    IF @CacGiai IS NOT NULL
    BEGIN
        DELETE FROM dbo.tblGiayKhenPhongTraoGiai WHERE PhongTraoID = @PhongTraoID;
        
        INSERT INTO dbo.tblGiayKhenPhongTraoGiai (PhongTraoID, TenGiai_VI, TenGiai_EN, ThuTu, Enable, CreateUser, CreateTime)
        SELECT @PhongTraoID, TRIM(value), 
               CASE TRIM(value) 
                 WHEN N'Giải Nhất' THEN 'First Prize' 
                 WHEN N'Giải Nhì' THEN 'Second Prize' 
                 WHEN N'Giải Ba' THEN 'Third Prize' 
                 WHEN N'Giải Khuyến khích' THEN 'Consolation Prize' 
                 ELSE TRIM(value) 
               END,
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), 1, @sys_UserID, GETDATE()
        FROM STRING_SPLIT(@CacGiai, ',')
        WHERE LEN(TRIM(value)) > 0;
    END

    SELECT PhongTraoID = @PhongTraoID;
END;
