CREATE   PROCEDURE dbo.spAPI_SoGVCNTheoDoiRenLuyenSave
    @SoGVCNID varchar(10),
    @JsonRows nvarchar(max),
    @sys_UserID varchar(10),
    @sys_SystemRight varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Trigger audit nhận diện người sửa qua SESSION_CONTEXT; không được ép mã
    -- FUI như NA0000022 sang INT vì sẽ biến thành 0/unknown.
    DECLARE @UserID varchar(20) = COALESCE(NULLIF(LTRIM(RTRIM(@sys_UserID)), ''), 'unknown/unavailable');
    EXEC sys.sp_set_session_context
        @key = N'SoGVCN_UserID',
        @value = @UserID;

    DECLARE @Rows TABLE
    (
        HSLopID int NOT NULL,
        Thang int NOT NULL,
        NoiDung nvarchar(max) NULL
    );

    INSERT INTO @Rows (HSLopID, Thang, NoiDung)
    SELECT HSLopID, Thang, NoiDung
    FROM OPENJSON(@JsonRows)
    WITH
    (
        HSLopID int '$.HSLopID',
        Thang int '$.Thang',
        NoiDung nvarchar(max) '$.NoiDung'
    )
    WHERE HSLopID IS NOT NULL
      AND Thang IS NOT NULL;

    UPDATE target
    SET target.NoiDung = source.NoiDung,
        target.UpdateUser = @UserID,
        target.UpdateTime = GETDATE(),
        target.Enable = 1
    FROM dbo.tblSoGVCNTheoDoiRenLuyen target
    INNER JOIN @Rows source
        ON source.HSLopID = target.HSLopID
       AND source.Thang = target.Thang
    WHERE target.SoGVCNID = @SoGVCNID;

    INSERT INTO dbo.tblSoGVCNTheoDoiRenLuyen
    (
        SoGVCNID,
        HSLopID,
        Thang,
        NoiDung,
        CreateUser,
        UpdateUser
    )
    SELECT
        @SoGVCNID,
        source.HSLopID,
        source.Thang,
        source.NoiDung,
        @UserID,
        @UserID
    FROM @Rows source
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.tblSoGVCNTheoDoiRenLuyen target
        WHERE target.SoGVCNID = @SoGVCNID
          AND target.HSLopID = source.HSLopID
          AND target.Thang = source.Thang
    );

    SELECT mess = N'Đã lưu theo dõi rèn luyện', SoGVCNID = @SoGVCNID;
END
