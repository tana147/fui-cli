CREATE PROCEDURE spAPI_TkbDayThayInsert
    @NgayApDung DATE,
    @MaGVVang VARCHAR(15),
    @ItemsJson NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO tblTKB_DayThay (NgayApDung, KetQuaXepID, MaGVVang, MaGVDayThay, LyDo, CreateUser, CreateTime, UpdateUser, UpdateTime, Enable)
    SELECT @NgayApDung, KetQuaXepID, @MaGVVang, NULLIF(MaGVDayThay, ''), LyDo, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1
    FROM OPENJSON(@ItemsJson)
    WITH (
        KetQuaXepID INT '$.KetQuaXepID',
        MaGVDayThay VARCHAR(15) '$.MaGVDayThay',
        LyDo NVARCHAR(200) '$.LyDo'
    );

    SELECT mess = N'Đã lưu dạy thay'
END