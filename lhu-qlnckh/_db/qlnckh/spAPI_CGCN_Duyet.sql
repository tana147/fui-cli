CREATE PROC [dbo].[spAPI_CGCN_Duyet]
    @CGCNID INT,
    @TrangThai INT,
    @LyDoReject NVARCHAR(500),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MsgError NVARCHAR(500);

    IF (@TrangThai NOT IN (3, 4))
    BEGIN
        SET @MsgError = N'Trạng thái xét duyệt không hợp lệ (Chỉ chấp nhận 3: Đã duyệt hoặc 4: Cần bổ sung / Từ chối)!';
        RAISERROR(@MsgError, 16, 1);
        RETURN 0;
    END;

    IF (@TrangThai = 4 AND (ISNULL(@LyDoReject, '') = '' OR LEN(LTRIM(RTRIM(@LyDoReject))) = 0))
    BEGIN
        SET @MsgError = N'Bắt buộc phải nhập lý do khi từ chối / trả về hồ sơ!';
        RAISERROR(@MsgError, 16, 1);
        RETURN 0;
    END;

    -- Nếu duyệt thì đảm bảo có SoThuTu chính thức
    IF (@TrangThai = 3)
    BEGIN
        DECLARE @CurrentSTT INT;
        SELECT @CurrentSTT = SoThuTu FROM dbo.ChuyenGiaoCongNghe WHERE CGCNID = @CGCNID;
        
        IF (@CurrentSTT IS NULL OR @CurrentSTT = 0)
        BEGIN
            DECLARE @MaxSTT INT;
            SELECT @MaxSTT = ISNULL(MAX(SoThuTu), 0) + 1 FROM dbo.ChuyenGiaoCongNghe WHERE Is_Xoa = 0 AND TrangThai = 3;
            
            UPDATE dbo.ChuyenGiaoCongNghe
            SET SoThuTu = @MaxSTT
            WHERE CGCNID = @CGCNID;
        END;
    END;

    UPDATE dbo.ChuyenGiaoCongNghe
    SET 
        TrangThai = @TrangThai,
        LyDoReject = CASE WHEN @TrangThai = 4 THEN @LyDoReject ELSE '' END,
        NguoiDuyet = @sys_UserID,
        ThoiGianDuyet = GETDATE(),
        NhanVienCapNhat = ISNULL(@sys_UserID, NhanVienCapNhat),
        ThoiGianCapNhat = GETDATE()
    WHERE CGCNID = @CGCNID;
END;
