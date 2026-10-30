CREATE PROCEDURE dbo.spAPI_SoGVCNKeHoachThangSave
    @SoGVCNID int,
    @Thang int,
    @ChuDe nvarchar(max),
    @MucTieu nvarchar(max),
    @NhiemVu nvarchar(max),
    @KeHoachTuan nvarchar(max),
    @DanhGia nvarchar(max),
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

    IF EXISTS (SELECT 1 FROM dbo.tblSoGVCNKeHoachThang WHERE SoGVCNID = @SoGVCNID AND Thang = @Thang AND Enable = 1)
    BEGIN
        UPDATE dbo.tblSoGVCNKeHoachThang
        SET ChuDe = @ChuDe,
            MucTieu = @MucTieu,
            NhiemVu = @NhiemVu,
            KeHoachTuan = @KeHoachTuan,
            DanhGia = @DanhGia,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE SoGVCNID = @SoGVCNID
          AND Thang = @Thang
          AND Enable = 1;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tblSoGVCNKeHoachThang(SoGVCNID, Thang, ChuDe, MucTieu, NhiemVu, KeHoachTuan, DanhGia, CreateUser, UpdateUser)
        VALUES(@SoGVCNID, @Thang, @ChuDe, @MucTieu, @NhiemVu, @KeHoachTuan, @DanhGia, @sys_UserID, @sys_UserID);
    END

    SELECT mess = N'Đã lưu kế hoạch tháng', SoGVCNID = @SoGVCNID, Thang = @Thang;
END
