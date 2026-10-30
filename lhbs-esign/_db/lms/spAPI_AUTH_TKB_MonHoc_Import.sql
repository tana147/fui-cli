CREATE PROCEDURE dbo.spAPI_AUTH_TKB_MonHoc_Import
    @Rows NVARCHAR(MAX),
    @SYS_USERID VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TempMonHoc TABLE (
        MaMon VARCHAR(50) NOT NULL,
        TenMonHoc NVARCHAR(255) NULL
    );

    INSERT INTO @TempMonHoc (MaMon, TenMonHoc)
    SELECT DISTINCT
        LTRIM(RTRIM(MaMon)),
        NULLIF(LTRIM(RTRIM(TenMonHoc)), '')
    FROM OPENJSON(@Rows)
    WITH (
        MaMon VARCHAR(50) '$.MaMon',
        TenMonHoc NVARCHAR(255) '$.TenMonHoc'
    )
    WHERE NULLIF(LTRIM(RTRIM(MaMon)), '') IS NOT NULL;

    UPDATE M
    SET M.TenMonHoc = S.TenMonHoc
    FROM dbo.tblTKB_MonHoc M
    INNER JOIN @TempMonHoc S ON S.MaMon = M.MaMon
    WHERE ISNULL(M.TenMonHoc, '') <> ISNULL(S.TenMonHoc, '');

    INSERT INTO dbo.tblTKB_MonHoc (MaMon, TenMonHoc)
    SELECT S.MaMon, S.TenMonHoc
    FROM @TempMonHoc S
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.tblTKB_MonHoc M
        WHERE M.MaMon = S.MaMon
    );

    SELECT M.MonHocID, M.MaMon, M.TenMonHoc
    FROM dbo.tblTKB_MonHoc M
    INNER JOIN @TempMonHoc S ON S.MaMon = M.MaMon
    ORDER BY M.MaMon;
END
