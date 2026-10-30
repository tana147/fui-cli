CREATE PROCEDURE spAPI_TkbKetQuaXepLopList
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Loai MaMon='HOP': MaLop cua tiet HOP la ma nhom (Tổ/Khối) tam dung, khong phai ma lop that —
    -- de lot vao list nay se lam sai dropdown "Lop" o trang Sua tay/Xuat-In (xem ra soat 2026-08-24).
    SELECT DISTINCT MaLop FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaMon <> 'HOP' ORDER BY MaLop;
END