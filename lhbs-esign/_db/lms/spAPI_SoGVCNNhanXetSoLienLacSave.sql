CREATE   PROCEDURE dbo.spAPI_SoGVCNNhanXetSoLienLacSave
    @SoGVCNID varchar(10),
    @JsonRows nvarchar(max),
    @sys_UserID varchar(10),
    @sys_SystemRight varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID int = ISNULL(TRY_CONVERT(int, @sys_UserID), 0);

    DECLARE @Rows TABLE
    (
        HSLopID int NOT NULL,
        Thang int NOT NULL,
        NhanXet nvarchar(max) NULL
    );

    INSERT INTO @Rows (HSLopID, Thang, NhanXet)
    SELECT HSLopID, Thang, NhanXet
    FROM OPENJSON(@JsonRows)
    WITH
    (
        HSLopID int '$.HSLopID',
        Thang int '$.Thang',
        NhanXet nvarchar(max) '$.NhanXet'
    )
    WHERE HSLopID IS NOT NULL
      AND Thang IS NOT NULL;

    UPDATE target
    SET target.NhanXet = source.NhanXet,
        target.UpdateUser = @UserID,
        target.UpdateTime = GETDATE(),
        target.Enable = 1
    FROM dbo.tblSoGVCNNhanXetSoLienLac target
    INNER JOIN @Rows source
        ON source.HSLopID = target.HSLopID
       AND source.Thang = target.Thang
    WHERE target.SoGVCNID = @SoGVCNID;

    INSERT INTO dbo.tblSoGVCNNhanXetSoLienLac
    (
        SoGVCNID,
        HSLopID,
        Thang,
        NhanXet,
        CreateUser,
        UpdateUser
    )
    SELECT
        @SoGVCNID,
        source.HSLopID,
        source.Thang,
        source.NhanXet,
        @UserID,
        @UserID
    FROM @Rows source
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.tblSoGVCNNhanXetSoLienLac target
        WHERE target.SoGVCNID = @SoGVCNID
          AND target.HSLopID = source.HSLopID
          AND target.Thang = source.Thang
    );

    SELECT mess = N'Đã lưu nhận xét sổ liên lạc', SoGVCNID = @SoGVCNID;
END
