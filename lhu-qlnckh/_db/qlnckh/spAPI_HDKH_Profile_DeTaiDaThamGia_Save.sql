CREATE  PROCEDURE [dbo].[spAPI_HDKH_Profile_DeTaiDaThamGia_Save]
    @DeTaiID BIGINT = 0,
    @TenDeTai NVARCHAR(1000),
    @CoQuanTaiTro NVARCHAR(255),
    @ThoiGianThucHien NVARCHAR(100),
    @VaiTro NVARCHAR(100),
	@NhanVienID VARCHAR(9),
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    MERGE dbo.tblHDKH_Profile_DeTaiDaThamGia AS T
    USING (SELECT @DeTaiID AS DeTaiID) AS S
    ON (T.DeTaiID = S.DeTaiID AND S.DeTaiID > 0)
    WHEN MATCHED THEN
        UPDATE SET
            TenDeTai = @TenDeTai,
            CoQuanTaiTro = @CoQuanTaiTro,
            ThoiGianThucHien = @ThoiGianThucHien,
            VaiTro = @VaiTro,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (NhanVienID, TenDeTai, CoQuanTaiTro, ThoiGianThucHien, VaiTro, CreateUser)
        VALUES (@NhanVienID, @TenDeTai, @CoQuanTaiTro, @ThoiGianThucHien, @VaiTro, @sys_UserID);
        
    SELECT Message = N'Lưu thông tin đề tài thành công.';
END
