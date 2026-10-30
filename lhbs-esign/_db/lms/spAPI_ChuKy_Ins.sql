CREATE PROC [dbo].[spAPI_ChuKy_Ins]
    @GiaoVienID VARCHAR(10),
    @HinhAnhChuKy CHAR(32),
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    DECLARE @MsgError NVARCHAR(500);
    IF EXISTS
    (
        SELECT TOP 1
               *
        FROM dbo.tblChuKy
        WHERE GiaoVienID = @GiaoVienID
              AND Enable = 1
    )
    BEGIN
        SET @MsgError = N'Giáo viên này đã có chữ ký';
        RAISERROR(@MsgError, 16, 1);
        RETURN 0;
    END;
    ELSE
    BEGIN
        INSERT INTO dbo.tblChuKy
        (
            [HinhAnhChuKy],
            [GiaoVienID],
            [Enable],
            [CreateUser],
            [CreateTime]
        )
        VALUES
        (@HinhAnhChuKy, @GiaoVienID, 1, @SYS_USERID, GETDATE());
    END;

END;