CREATE   PROCEDURE dbo.spAPI_SoGVCNSave
    @SoGVCNID varchar(10),
    @ThongTinLop nvarchar(max),
    @ChiTieu nvarchar(max),
    @SiSo nvarchar(max),
    @GiaoVienBoMon nvarchar(max),
    @BanDaiDienCMHS nvarchar(max),
    @CanBoLop nvarchar(max),
    @HuongNghiep nvarchar(max),
    @sys_UserID varchar(10),
    @sys_SystemRight varchar(10)
AS
BEGIN
    SET NOCOUNT ON;
    -- FUI supplies a string user identity; audit triggers read it from SESSION_CONTEXT.
    DECLARE @AuditUser varchar(20) = COALESCE(NULLIF(LTRIM(RTRIM(@sys_UserID)), ''), 'unknown/unavailable');
    EXEC sys.sp_set_session_context
        @key = N'SoGVCN_UserID',
        @value = @AuditUser;

    UPDATE dbo.tblSoGVCN
    SET ThongTinLop = @ThongTinLop,
        ChiTieu = @ChiTieu,
        SiSo = @SiSo,
        GiaoVienBoMon = @GiaoVienBoMon,
        BanDaiDienCMHS = @BanDaiDienCMHS,
        CanBoLop = @CanBoLop,
        HuongNghiep = @HuongNghiep,
        TrangThai = CASE WHEN TrangThai = 'NEW' THEN 'DRAFT' ELSE TrangThai END,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE SoGVCNID = @SoGVCNID
      AND Enable = 1;

    SELECT mess = N'Đã lưu nháp', SoGVCNID = @SoGVCNID;
END
