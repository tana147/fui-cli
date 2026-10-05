CREATE PROCEDURE [dbo].[spAPI_HDKH_Profile_CongTrinhDaCongBo_Save]
    @CongTrinhID BIGINT = 0,
    @TenTacGia NVARCHAR(500),
    @TenCongTrinh NVARCHAR(1000),
    @TapChi_HoiThao NVARCHAR(500),
    @GhiChu NVARCHAR(500),
	@NhanVienID VARCHAR(9),
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dbo.tblHDKH_Profile_CongTrinhDaCongBo AS T
    USING (SELECT @CongTrinhID AS CongTrinhID) AS S
    ON (T.CongTrinhID = S.CongTrinhID AND S.CongTrinhID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            TenTacGia = @TenTacGia,
            TenCongTrinh = @TenCongTrinh,
            TapChi_HoiThao = @TapChi_HoiThao,
            GhiChu = @GhiChu,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (NhanVienID, TenTacGia, TenCongTrinh, TapChi_HoiThao, GhiChu, CreateUser)
        VALUES (@NhanVienID, @TenTacGia, @TenCongTrinh, @TapChi_HoiThao, @GhiChu, @sys_UserID);
        
    SELECT Message = N'Lưu thông tin công trình thành công.';
END
