CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_Ins_JSON]
    @LopID              INT
  , @TenLop             VARCHAR(10)
  , @KhoiID             INT
  , @MonHocID           INT
  , @TenMonHoc          NVARCHAR(100)
  , @Thu                TINYINT
  , @Buoi               TINYINT  -- 1=Sáng, 2=Chiều, 3=Tối
  , @TietBatDau         TINYINT
  , @TietKetThuc        TINYINT
  , @NgayApDung         DATE
  , @TuanHocID          INT
  , @NienKhoa           INT
  , @HocKy              INT
  , @GhiChu             NVARCHAR(500)
  , @IsTreHan           BIT
  , @JsonHocSinh        NVARCHAR(MAX)  -- [{"HocSinhID":1,"HoTen":"...","LoaiThietBi":"Laptop,Tablet"}]
  , @TenGiaoVienDangKy  NVARCHAR(200)
  , @sys_UserID         VARCHAR(20)
  , @sys_SystemRight    INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TuanHocIDThuc INT;
    SELECT TOP 1 @TuanHocIDThuc = TuanHocID
    FROM dbo.tblTuanHocTap
    WHERE NienKhoa = @NienKhoa AND @NgayApDung BETWEEN NgayBatDau AND NgayKetThuc;
    SET @TuanHocIDThuc = ISNULL(@TuanHocIDThuc, @TuanHocID);

    -- Chặn đăng ký trùng: cùng lớp, cùng ngày, cùng buổi, tiết bị chồng lấn với 1 lượt đã đăng ký còn hiệu lực
    DECLARE @TenGVTrung NVARCHAR(200);
    SELECT TOP 1 @TenGVTrung = dk.TenGiaoVienDangKy
    FROM dbo.tblDangKyMangLaptop dk
    WHERE dk.Enable = 1
      AND dk.LopID = @LopID
      AND dk.NgayApDung = @NgayApDung
      AND dk.Buoi = @Buoi
      AND dk.TietBatDau <= @TietKetThuc
      AND dk.TietKetThuc >= @TietBatDau;

    IF @TenGVTrung IS NOT NULL
    BEGIN
        RAISERROR(N'Lớp %s đã có đăng ký trùng buổi/tiết vào ngày này (do %s đăng ký). Vui lòng kiểm tra lại.', 16, 1, @TenLop, @TenGVTrung);
        RETURN;
    END

    DECLARE @LoaiThietBiTongHop NVARCHAR(200);
    SELECT @LoaiThietBiTongHop = STRING_AGG(Loai, N', ')
    FROM
    (
        SELECT DISTINCT LTRIM(RTRIM(value)) AS Loai
        FROM OPENJSON(@JsonHocSinh) WITH ( LoaiThietBi NVARCHAR(200) ) AS j
             CROSS APPLY STRING_SPLIT(j.LoaiThietBi, ',')
        WHERE LTRIM(RTRIM(value)) <> N''
    ) AS x;

    INSERT INTO dbo.tblDangKyMangLaptop
    (
        LopID, TenLop, KhoiID, MonHocID, TenMonHoc, LoaiThietBi, GiaoVienDangKyID, TenGiaoVienDangKy,
        Thu, Buoi, TietBatDau, TietKetThuc, NgayApDung, TuanHocID, NienKhoa, HocKy, GhiChu, IsTreHan,
        Enable, CreateUser, CreateTime
    )
    VALUES
    (
        @LopID, @TenLop, @KhoiID, @MonHocID, @TenMonHoc, @LoaiThietBiTongHop, @sys_UserID, @TenGiaoVienDangKy,
        @Thu, @Buoi, @TietBatDau, @TietKetThuc, @NgayApDung, @TuanHocIDThuc, @NienKhoa, @HocKy, @GhiChu, @IsTreHan,
        1, @sys_UserID, GETDATE()
    );

    DECLARE @DangKyID INT = SCOPE_IDENTITY();

    INSERT INTO dbo.tblDangKyMangLaptop_HocSinh (DangKyID, HocSinhID, HoTen, LoaiThietBi, Enable, CreateUser, CreateTime)
    SELECT @DangKyID, j.HocSinhID, j.HoTen, j.LoaiThietBi, 1, @sys_UserID, GETDATE()
    FROM OPENJSON(@JsonHocSinh) WITH ( HocSinhID INT, HoTen NVARCHAR(200), LoaiThietBi NVARCHAR(200) ) AS j;

    DECLARE @GVCNUserID VARCHAR(20);
    SELECT TOP 1 @GVCNUserID = CAST(l.GVCN AS VARCHAR(20))
    FROM dbo.tblLop l
    WHERE l.LopID = @LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa;

    DECLARE @NoiDungAlert NVARCHAR(100) = LEFT(
        CASE WHEN ISNULL(@sys_UserID, '') = ISNULL(@GVCNUserID, '') THEN N'GVCN ' ELSE N'GVBM ' END
        + ISNULL(@TenGiaoVienDangKy, N'') + N' đăng ký HS mang laptop lớp ' + ISNULL(@TenLop, N'')
        + N' - Thứ ' + CAST(@Thu AS NVARCHAR) + N', tiết ' + CAST(@TietBatDau AS NVARCHAR) + N'-' + CAST(@TietKetThuc AS NVARCHAR)
        + N', ngày ' + CONVERT(NVARCHAR, @NgayApDung, 103), 100);

    -- Alert đúng ngữ cảnh lớp: nếu người đăng ký là GVCN thì chỉ gửi quản sinh;
    -- nếu là GVBM thì gửi đúng GVCN của lớp và quản sinh.
    IF ISNULL(@sys_UserID, '') = ISNULL(@GVCNUserID, '')
    BEGIN
        INSERT INTO dbo.tblAlert
        (TypeAlert, ContentAlert, DateAlert, CapID, NienKhoa, Enable, CreateUser, CreateTime, UpdateUser, UpdateTime, UserRight)
        VALUES
        ('ALERT', @NoiDungAlert, GETDATE(), 0, @NienKhoa, 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), '4');
    END
    ELSE
    BEGIN
        IF ISNULL(@GVCNUserID, '') <> ''
        BEGIN
            INSERT INTO dbo.tblAlert
            (TypeAlert, ContentAlert, DateAlert, CapID, NienKhoa, Enable, CreateUser, CreateTime, UpdateUser, UpdateTime, UserRight)
            VALUES
            ('ALERT', @NoiDungAlert, GETDATE(), 0, @NienKhoa, 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), @GVCNUserID);
        END

        INSERT INTO dbo.tblAlert
        (TypeAlert, ContentAlert, DateAlert, CapID, NienKhoa, Enable, CreateUser, CreateTime, UpdateUser, UpdateTime, UserRight)
        VALUES
        ('ALERT', @NoiDungAlert, GETDATE(), 0, @NienKhoa, 1, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), '4');
    END

    SELECT DangKyID = @DangKyID;
END
