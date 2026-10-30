CREATE PROC [dbo].[spAPI_CongBoBangDiem_Update_Mo_KyDanhGia]
@NienKhoa INT,
@CapID INT,
@KyDanhGia INT
AS
BEGIN
    update dbo.tblCongBoBangDiem
	SET
		Is_Public = 1
	WHERE NamHoc = @NienKhoa
	AND CapID = @CapID
	AND KyDanhGia = @KyDanhGia
END