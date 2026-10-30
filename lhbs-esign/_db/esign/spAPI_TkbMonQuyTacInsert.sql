CREATE PROCEDURE spAPI_TkbMonQuyTacInsert
    @MaMon      varchar(15),
    @Khoi       varchar(2) = NULL,
    @LoaiQuyTac varchar(30),
    @ThamSo     nvarchar(500) = NULL,
    @GhiChu     nvarchar(300) = NULL,
    @sys_UserID varchar(9)
AS
BEGIN
    IF @MaMon = '' OR @LoaiQuyTac = ''
    BEGIN
        RAISERROR(N'Thiếu Mã môn hoặc Loại quy tắc', 16, 1)
        RETURN
    END
    IF @Khoi = '' SET @Khoi = NULL;
    IF @ThamSo IS NULL OR @ThamSo = '' SET @ThamSo = '{}';

    INSERT INTO tblTKB_MonQuyTac (MaMon, Khoi, LoaiQuyTac, ThamSo, GhiChu, CreateUser, CreateTime, UpdateUser, UpdateTime, Enable)
    VALUES (@MaMon, @Khoi, @LoaiQuyTac, @ThamSo, @GhiChu, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1)

    SELECT mess = N'Thêm thành công', id = SCOPE_IDENTITY()
END
