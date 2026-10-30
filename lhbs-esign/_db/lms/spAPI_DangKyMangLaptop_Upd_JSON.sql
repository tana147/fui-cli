CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_Upd_JSON]
    @DangKyID       INT
  , @Thu            TINYINT
  , @TietBatDau     TINYINT
  , @TietKetThuc    TINYINT
  , @NgayApDung     DATE
  , @GhiChu         NVARCHAR(500)
  , @IsTreHan       BIT
  , @JsonHocSinh    NVARCHAR(MAX)
  , @sys_UserID     VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblDangKyMangLaptop
    SET    Thu = @Thu, TietBatDau = @TietBatDau, TietKetThuc = @TietKetThuc,
           NgayApDung = @NgayApDung, GhiChu = @GhiChu, IsTreHan = @IsTreHan,
           UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE  DangKyID = @DangKyID AND GiaoVienDangKyID = @sys_UserID AND Enable = 1;

    -- Đồng bộ danh sách học sinh: tắt các em không còn trong danh sách mới
    UPDATE hs
    SET    hs.Enable = 0, hs.UpdateUser = @sys_UserID, hs.UpdateTime = GETDATE()
    FROM   dbo.tblDangKyMangLaptop_HocSinh AS hs
    WHERE  hs.DangKyID = @DangKyID AND hs.Enable = 1
      AND  NOT EXISTS (
               SELECT 1 FROM OPENJSON(@JsonHocSinh) WITH ( HocSinhID INT ) AS j
               WHERE j.HocSinhID = hs.HocSinhID
           );

    -- Thêm học sinh mới xuất hiện trong danh sách
    INSERT INTO dbo.tblDangKyMangLaptop_HocSinh (DangKyID, HocSinhID, HoTen, Enable, CreateUser, CreateTime)
    SELECT @DangKyID, j.HocSinhID, j.HoTen, 1, @sys_UserID, GETDATE()
    FROM OPENJSON(@JsonHocSinh) WITH ( HocSinhID INT, HoTen NVARCHAR(200) ) AS j
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.tblDangKyMangLaptop_HocSinh AS hs
        WHERE hs.DangKyID = @DangKyID AND hs.HocSinhID = j.HocSinhID AND hs.Enable = 1
    );

    SELECT Updated = @@ROWCOUNT;
END
