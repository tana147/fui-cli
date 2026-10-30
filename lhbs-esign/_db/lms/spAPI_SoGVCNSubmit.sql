CREATE   PROCEDURE dbo.spAPI_SoGVCNSubmit
    @SoGVCNID int,
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

    UPDATE dbo.tblSoGVCN
    SET TrangThai = 'SUBMITTED',
        SubmitUser = @sys_UserID,
        SubmitTime = GETDATE(),
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE SoGVCNID = @SoGVCNID
      AND Enable = 1;

    SELECT mess = N'Đã gửi BGH', SoGVCNID = @SoGVCNID;
END
