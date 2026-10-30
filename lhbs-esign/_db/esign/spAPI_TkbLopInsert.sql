CREATE PROCEDURE spAPI_TkbLopInsert
    @MaLop              varchar(10),
    @Khoi               varchar(2),
    @ChuongTrinhDaoTao  nvarchar(50),
    @CoPhongTruyenThong bit,
    @LaLopGoc           bit,
    @LopGocMa           varchar(10),
    @sys_UserID         varchar(9)
AS
BEGIN
    IF @MaLop = '' OR @Khoi = ''
    BEGIN
        RAISERROR(N'Thiếu Mã lớp hoặc Khối', 16, 1)
        RETURN
    END
    IF EXISTS (SELECT 1 FROM tblTKB_Lop WHERE MaLop = @MaLop)
    BEGIN
        RAISERROR(N'Mã lớp đã tồn tại', 16, 1)
        RETURN
    END

    INSERT INTO tblTKB_Lop (MaLop, Khoi, ChuongTrinhDaoTao, CoPhongTruyenThong, LaLopGoc, LopGocMa, CreateUser, CreateTime, UpdateUser, UpdateTime, Enable)
    VALUES (@MaLop, @Khoi, @ChuongTrinhDaoTao, @CoPhongTruyenThong, @LaLopGoc, NULLIF(@LopGocMa, ''), @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1)

    SELECT mess = N'Thêm thành công', id = @MaLop
END
