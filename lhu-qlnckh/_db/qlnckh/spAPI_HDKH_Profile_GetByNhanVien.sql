CREATE PROCEDURE [dbo].[spAPI_HDKH_Profile_GetByNhanVien]
	@NhanVienID VARCHAR(9),
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Thông tin cá nhân
    SELECT * FROM dbo.tblHDKH_Profile_CaNhan WHERE NhanVienID = @NhanVienID AND IsDeleted = 0;

    -- Result Set 2: Quá trình đào tạo
    SELECT * FROM dbo.tblHDKH_Profile_DaoTao WHERE NhanVienID = @NhanVienID AND IsDeleted = 0 ORDER BY NamTotNghiep DESC;

    -- Result Set 3: Quá trình công tác
    SELECT * FROM dbo.tblHDKH_Profile_CongTac WHERE NhanVienID = @NhanVienID AND IsDeleted = 0 ORDER BY ThoiGian DESC;

    -- Result Set 4: Đề tài đã tham gia
    SELECT * FROM dbo.tblHDKH_Profile_DeTaiDaThamGia WHERE NhanVienID = @NhanVienID AND IsDeleted = 0 ORDER BY ThoiGianThucHien DESC;

    -- Result Set 5: Công trình đã công bố
    SELECT * FROM dbo.tblHDKH_Profile_CongTrinhDaCongBo WHERE NhanVienID = @NhanVienID AND IsDeleted = 0 ORDER BY CreateTime DESC;
END
