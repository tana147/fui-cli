CREATE   PROCEDURE dbo.spAPI_SoGVCNEnsure
    @NienKhoa int,
    @LopID varchar(10),
    @sys_UserID varchar(20),
    @sys_SystemRight int
AS
BEGIN
    SET NOCOUNT ON;
    -- FUI supplies a string user identity; audit triggers read it from SESSION_CONTEXT.
    DECLARE @AuditUser varchar(20) = COALESCE(NULLIF(LTRIM(RTRIM(@sys_UserID)), ''), 'unknown/unavailable');
    EXEC sys.sp_set_session_context
        @key = N'SoGVCN_UserID',
        @value = @AuditUser;

    DECLARE @SoGVCNID int;

    SELECT @SoGVCNID = SoGVCNID
    FROM dbo.tblSoGVCN
    WHERE NienKhoa = @NienKhoa
      AND LopID = @LopID
      AND Enable = 1;

    IF @SoGVCNID IS NULL
    BEGIN
        INSERT INTO dbo.tblSoGVCN(NienKhoa, LopID, CapID, TrangThai, CreateUser, UpdateUser)
        SELECT
            @NienKhoa,
            @LopID,
            CASE WHEN l.KhoiID BETWEEN 1 AND 5 THEN 1 WHEN l.KhoiID BETWEEN 6 AND 9 THEN 2 ELSE 3 END,
            'DRAFT',
            @sys_UserID,
            @sys_UserID
        FROM dbo.tblLop l
        WHERE l.LopID = @LopID
          AND l.NienKhoa = @NienKhoa
          AND l.Enable = 1;

        SET @SoGVCNID = SCOPE_IDENTITY();
    END

    SELECT convert_to_object = '', SoGVCNID = @SoGVCNID, mess = N'Đã mở sổ GVCN';
END
