CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_Del_ByID]
    @KhenThuongID INT,
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ThiKHCN_KhenThuong
    SET 
        Is_Xoa = 1,
        NhanVienCapNhat = @SYS_UserID,
        ThoiGianCapNhat = GETDATE()
    WHERE KhenThuongID = @KhenThuongID;

    UPDATE ThiKHCN_ThanhVien
    SET Is_Xoa = 1
    WHERE KhenThuongID = @KhenThuongID;

    UPDATE ThiKHCN_File
    SET Is_Xoa = 1
    WHERE KhenThuongID = @KhenThuongID;

    INSERT INTO ThiKHCN_LichSu (KhenThuongID, HanhDong, MoTa, NhanVien, ThoiGian)
    VALUES (@KhenThuongID, 'XOA', N'Xóa hồ sơ đề xuất', @SYS_UserID, GETDATE());

    SELECT 1 AS Result;
END;