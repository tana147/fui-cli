CREATE PROCEDURE spAPI_TkbKetQuaXepThemTuDo
    @RunID INT,
    @MaLop VARCHAR(10),
    @MaMon VARCHAR(10),
    @MaGV VARCHAR(10),
    @Thu INT,
    @Buoi VARCHAR(10),
    @Tiet INT,
    @MaPhong VARCHAR(10) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Them 1 tiet TU DO (mon+GV bat ky, khong bat buoc nam trong danh sach "thieu dinh muc") vao
    -- 1 o trong tren luoi — cho truong hop phat sinh dot xuat khac dinh muc (2026-08-30). Neu
    -- MaLop+MaMon+MaGV trung voi 1 dong dang "thieu", tru luon dong do de khong bao thieu ao.

    IF EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @MaLop AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet)
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Khung giờ này đã bị chiếm mất — tải lại lịch' AS Message;
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaGV = @MaGV AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet)
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Giáo viên đã có lịch khác đúng khung giờ này' AS Message;
        RETURN;
    END

    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
    VALUES (@RunID, @MaLop, @Thu, @Buoi, @Tiet, @MaMon, @MaGV, @MaPhong);

    -- Danh dau da khoa tay (2026-09-02) — them tu do la hanh dong hoan toan chu dong cua nguoi dung,
    -- xem tblTKB_KetQuaXep_Khoa / spAPI_TkbChayAutoPhanConLai.
    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime) VALUES (SCOPE_IDENTITY(), @sys_UserID, GETDATE());

    UPDATE tblTKB_ChayAutoKhongXepDuoc SET SoTiet = SoTiet - 1
    WHERE RunID = @RunID AND MaLop = @MaLop AND MaMon = @MaMon AND MaGV = @MaGV AND SoTiet > 0;

    DELETE FROM tblTKB_ChayAutoKhongXepDuoc
    WHERE RunID = @RunID AND MaLop = @MaLop AND MaMon = @MaMon AND MaGV = @MaGV AND SoTiet <= 0;

    SELECT CAST(1 AS BIT) AS Success, N'Đã thêm vào lịch' AS Message;
END
