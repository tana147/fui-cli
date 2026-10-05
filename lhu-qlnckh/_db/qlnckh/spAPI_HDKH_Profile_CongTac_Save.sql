CREATE  PROCEDURE [dbo].[spAPI_HDKH_Profile_CongTac_Save]
    @CongTacID BIGINT = 0,
    @ThoiGian NVARCHAR(100),
    @NoiCongTac NVARCHAR(255),
    @CongViecDamNhiem NVARCHAR(500),
	@NhanVienID VARCHAR(9),
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dbo.tblHDKH_Profile_CongTac AS T
    USING (SELECT @CongTacID AS CongTacID) AS S
    ON (T.CongTacID = S.CongTacID AND S.CongTacID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            ThoiGian = @ThoiGian,
            NoiCongTac = @NoiCongTac,
            CongViecDamNhiem = @CongViecDamNhiem,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (NhanVienID, ThoiGian, NoiCongTac, CongViecDamNhiem, CreateUser)
        VALUES (@NhanVienID, @ThoiGian, @NoiCongTac, @CongViecDamNhiem, @sys_UserID);
        
    SELECT Message = N'Lưu thông tin công tác thành công.';
END
