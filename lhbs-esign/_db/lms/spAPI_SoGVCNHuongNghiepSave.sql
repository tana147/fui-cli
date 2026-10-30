CREATE PROCEDURE dbo.spAPI_SoGVCNHuongNghiepSave
    @SoGVCNID varchar(10),
    @JsonHuongNghiep nvarchar(max),
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

    DECLARE @ID int = ISNULL(TRY_CONVERT(int, @SoGVCNID), 0);
    DECLARE @UserID int = ISNULL(TRY_CONVERT(int, @sys_UserID), 0);

    UPDATE dbo.tblSoGVCNHuongNghiep
    SET Enable = 0,
        UpdateUser = @UserID,
        UpdateTime = GETDATE()
    WHERE SoGVCNID = @ID;

    INSERT INTO dbo.tblSoGVCNHuongNghiep
    (
        SoGVCNID, STT, HSLopID, HocSinhID, MaHocSinh, HoTen,
        MonThiTNDanhMucID, MonThiTN, KQTracNghiem, RowIndex, CreateUser, UpdateUser
    )
    SELECT
        @ID, source.STT, source.HSLopID, source.HocSinhID, source.MaHocSinh, source.HoTen,
        dm.DanhMucID, source.MonThiTN, source.KQTracNghiem, source.RowIndex, @UserID, @UserID
    FROM OPENJSON(ISNULL(@JsonHuongNghiep, N'[]'))
    WITH
    (
        STT int '$.STT',
        HSLopID int '$.HSLopID',
        HocSinhID int '$.HocSinhID',
        MaHocSinh varchar(30) '$.MaHocSinh',
        HoTen nvarchar(200) '$.HoTen',
        MonThiTN nvarchar(500) '$.MonThiTN',
        KQTracNghiem nvarchar(max) '$.KQTracNghiem',
        RowIndex int '$.RowIndex'
    ) source
    LEFT JOIN dbo.tblSoGVCNDanhMuc dm ON dm.Loai = 'MON_THI_TN' AND dm.Ten = source.MonThiTN AND dm.Enable = 1
    WHERE NULLIF(LTRIM(RTRIM(CONCAT(source.HoTen, source.MonThiTN, source.KQTracNghiem))), N'') IS NOT NULL;

    UPDATE dbo.tblSoGVCN
    SET TrangThai = CASE WHEN TrangThai = 'NEW' THEN 'DRAFT' ELSE TrangThai END,
        UpdateUser = @UserID,
        UpdateTime = GETDATE()
    WHERE SoGVCNID = @ID
      AND Enable = 1;

    SELECT mess = N'Đã lưu hướng nghiệp', SoGVCNID = @ID;
END

GRANT EXECUTE ON dbo.spAPI_SoGVCNHuongNghiepSave TO [lmslhbs]
