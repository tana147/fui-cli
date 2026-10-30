CREATE PROCEDURE spAPI_TkbMonQuyTacUpdate
    @ID         int,
    @MaMon      varchar(15),
    @Khoi       varchar(2) = NULL,
    @LoaiQuyTac varchar(30),
    @ThamSo     nvarchar(500) = NULL,
    @GhiChu     nvarchar(300) = NULL,
    @Enable     bit = 1,
    @sys_UserID varchar(9)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblTKB_MonQuyTac WHERE ID = @ID)
    BEGIN
        RAISERROR(N'Không tìm thấy quy tắc', 16, 1)
        RETURN
    END
    IF @Khoi = '' SET @Khoi = NULL;
    IF @ThamSo IS NULL OR @ThamSo = '' SET @ThamSo = '{}';

    UPDATE tblTKB_MonQuyTac
    SET MaMon = @MaMon, Khoi = @Khoi, LoaiQuyTac = @LoaiQuyTac, ThamSo = @ThamSo,
        GhiChu = @GhiChu, Enable = @Enable, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE ID = @ID

    SELECT mess = N'Cập nhật thành công'
END
