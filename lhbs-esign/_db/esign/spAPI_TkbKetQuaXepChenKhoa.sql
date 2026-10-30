CREATE PROCEDURE spAPI_TkbKetQuaXepChenKhoa
    @RunID INT,
    @MaLop VARCHAR(10),
    @Thu INT,
    @Buoi VARCHAR(10),
    @Tiet INT,
    @MaMon VARCHAR(10),
    @MaGV VARCHAR(10),
    @MaPhong VARCHAR(10) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- SP dung chung cho moi trang "khoa tay" (Buoc 1-5 theo R17): chen THANG 1 dong that vao
    -- tblTKB_KetQuaXep cua phien dang xay — KHONG luu vao bang cau hinh rieng de solver tu suy
    -- luan lai. Nho vay TKB xem duoc ngay sau moi lan khoa, khong can cho Auto chay.

    IF NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID)
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy phiên TKB này' AS Message;
        RETURN;
    END

    -- Kiem tra xung dot GV (khong duoc bi xep 2 noi cung luc, ke ca dang khoa tay)
    IF EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet AND MaGV = @MaGV)
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'GV đã có lịch khác vào đúng khung giờ này trong phiên TKB đó' AS Message;
        RETURN;
    END

    -- Kiem tra xung dot Lop (bo qua neu MaLop la ma nhom tam vd hop to, khong phai lop hoc that)
    IF EXISTS (SELECT 1 FROM tblTKB_Lop WHERE MaLop = @MaLop AND Enable = 1)
       AND EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet AND MaLop = @MaLop)
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Lớp đã có tiết khác vào đúng khung giờ này trong phiên TKB đó' AS Message;
        RETURN;
    END

    IF @MaPhong IS NOT NULL AND EXISTS (
        SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet AND MaPhong = @MaPhong
    )
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Phòng đã bận vào đúng khung giờ này trong phiên TKB đó' AS Message;
        RETURN;
    END

    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
    VALUES (@RunID, @MaLop, @Thu, @Buoi, @Tiet, @MaMon, @MaGV, @MaPhong);

    UPDATE tblTKB_ChayAutoLog SET SoNhuCau = (SELECT COUNT(*) FROM tblTKB_KetQuaXep WHERE RunID = @RunID) WHERE RunID = @RunID;

    SELECT CAST(1 AS BIT) AS Success, N'Đã khóa vào TKB' AS Message, SCOPE_IDENTITY() AS KetQuaXepID;
END