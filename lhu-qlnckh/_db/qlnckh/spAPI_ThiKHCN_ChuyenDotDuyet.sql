CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_ChuyenDotDuyet]
    @KhenThuongIDs VARCHAR(MAX),
    @DotDuyetID INT,
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ids AS TABLE (KhenThuongID INT);

    INSERT INTO @ids (KhenThuongID)
    SELECT CONVERT(INT, data)
    FROM dbo.FN_STRING_SPLIT(@KhenThuongIDs, ',');

    UPDATE K
    SET 
        K.DotDuyetID = @DotDuyetID,
        K.NhanVienCapNhat = @SYS_UserID,
        K.ThoiGianCapNhat = GETDATE()
    FROM ThiKHCN_KhenThuong K
    INNER JOIN @ids i ON K.KhenThuongID = i.KhenThuongID;

    DECLARE @TenDot NVARCHAR(150);
    SELECT @TenDot = TenDotDuyet FROM ThiKHCN_DotDuyet WHERE DotDuyetID = @DotDuyetID;

    INSERT INTO ThiKHCN_LichSu (KhenThuongID, HanhDong, MoTa, NhanVien, ThoiGian)
    SELECT 
        i.KhenThuongID,
        'CHUYEN_DOT_DUYET',
        N'Chuyển hồ sơ vào đợt duyệt: ' + ISNULL(@TenDot, ''),
        @SYS_UserID,
        GETDATE()
    FROM @ids i;

    SELECT 1 AS Result;
END;