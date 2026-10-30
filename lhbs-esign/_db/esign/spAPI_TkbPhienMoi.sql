CREATE PROCEDURE spAPI_TkbPhienMoi
    @Khoi VARCHAR(50) = '',
    @GhiChu NVARCHAR(200) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Tao 1 "phien TKB dang xay" — mot RunID rong, CHUA goi solver. Cac trang khoa tay (Buoc 1-5)
    -- se chen thang du lieu vao tblTKB_KetQuaXep cua RunID nay qua spAPI_TkbKetQuaXepChenKhoa.
    -- Chi khi chay Auto (Buoc 6) thi TrangThai moi chuyen tu 'DangXay' sang trang thai giai solver.
    DECLARE @RunID INT;
    INSERT INTO tblTKB_ChayAutoLog (Khoi, MaxSecs, TrangThai, NguoiChay, SoNhuCau, LoiChiTiet)
    VALUES (
        CASE WHEN CHARINDEX(',', @Khoi) > 0 THEN LEFT(@Khoi, 1) + '+' ELSE @Khoi END,
        0, N'DangXay', @sys_UserID, 0, @GhiChu
    );
    SET @RunID = SCOPE_IDENTITY();

    SELECT @RunID AS RunID, N'DangXay' AS TrangThai, N'Đã tạo phiên TKB mới, sẵn sàng khóa tay' AS ThongBao;
END