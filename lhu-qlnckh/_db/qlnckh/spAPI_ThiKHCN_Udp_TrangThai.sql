CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_Udp_TrangThai]
    @KhenThuongID INT,
    @TrangThai TINYINT,
    @LyDoReject NVARCHAR(500),
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ThiKHCN_KhenThuong
    SET 
        TrangThai = @TrangThai,
        LyDoReject = CASE WHEN @TrangThai = 4 THEN @LyDoReject ELSE NULL END,
        NguoiDuyet = CASE WHEN @TrangThai IN (3, 4) THEN @SYS_UserID ELSE NguoiDuyet END,
        ThoiGianDuyet = CASE WHEN @TrangThai IN (3, 4) THEN GETDATE() ELSE ThoiGianDuyet END,
        NhanVienCapNhat = @SYS_UserID,
        ThoiGianCapNhat = GETDATE()
    WHERE KhenThuongID = @KhenThuongID;

    DECLARE @TenHanhDong VARCHAR(50);
    DECLARE @MoTaHanhDong NVARCHAR(500);

    IF @TrangThai = 2
    BEGIN
        SET @TenHanhDong = 'CHO_DUYET';
        SET @MoTaHanhDong = N'Chuyển sang trạng thái Chờ duyệt';
    END
    ELSE IF @TrangThai = 3
    BEGIN
        SET @TenHanhDong = 'DUYET';
        SET @MoTaHanhDong = N'Hội đồng duyệt hồ sơ đề xuất';
    END
    ELSE IF @TrangThai = 4
    BEGIN
        SET @TenHanhDong = 'TU_CHOI';
        SET @MoTaHanhDong = N'Từ chối hồ sơ. Lý do: ' + ISNULL(@LyDoReject, '');
    END
    ELSE
    BEGIN
        SET @TenHanhDong = 'CAP_NHAT_TT';
        SET @MoTaHanhDong = N'Cập nhật trạng thái ' + CONVERT(VARCHAR(5), @TrangThai);
    END;

    INSERT INTO ThiKHCN_LichSu (KhenThuongID, HanhDong, MoTa, NhanVien, ThoiGian)
    VALUES (@KhenThuongID, @TenHanhDong, @MoTaHanhDong, @SYS_UserID, GETDATE());

    SELECT 1 AS Result;
END;