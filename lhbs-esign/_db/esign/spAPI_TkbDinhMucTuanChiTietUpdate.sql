CREATE PROCEDURE spAPI_TkbDinhMucTuanChiTietUpdate
    @PhanCongID      bigint,
    @SoTietChuanTuan int,
    @sys_UserID      varchar(9)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblTKB_PhanCongGiangDay WHERE PhanCongID = @PhanCongID AND Enable = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy phân công cần sửa', 16, 1)
        RETURN
    END

    UPDATE tblTKB_PhanCongGiangDay
    SET SoTietChuanTuan = @SoTietChuanTuan,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE PhanCongID = @PhanCongID

    SELECT mess = N'Cập nhật thành công', id = @PhanCongID
END
