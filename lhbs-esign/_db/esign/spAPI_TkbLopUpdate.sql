CREATE PROCEDURE spAPI_TkbLopUpdate
    @MaLop              varchar(10),
    @Khoi               varchar(2),
    @ChuongTrinhDaoTao  nvarchar(50),
    @CoPhongTruyenThong bit,
    @LaLopGoc           bit,
    @LopGocMa           varchar(10),
    @sys_UserID         varchar(9)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblTKB_Lop WHERE MaLop = @MaLop AND Enable = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy lớp cần sửa', 16, 1)
        RETURN
    END

    UPDATE tblTKB_Lop
    SET Khoi = @Khoi,
        ChuongTrinhDaoTao = @ChuongTrinhDaoTao,
        CoPhongTruyenThong = @CoPhongTruyenThong,
        LaLopGoc = @LaLopGoc,
        LopGocMa = NULLIF(@LopGocMa, ''),
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE MaLop = @MaLop

    SELECT mess = N'Cập nhật thành công', id = @MaLop
END
