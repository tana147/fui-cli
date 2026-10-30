CREATE PROCEDURE spAPI_TkbKetQuaXepChuyenTiet
    @ID INT,
    @Thu INT,
    @Buoi VARCHAR(10),
    @Tiet INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Chuyen 1 tiet dang co sang 1 o TRONG khac (khac voi DoiTiet la hoan doi 2 tiet da co san cho
    -- nhau) — dap ung yeu cau UI "keo-tha 1 tiet vao o trong" (2026-08-30). Chi cho phep trong CUNG
    -- 1 lop (khong doi Lop/Mon/GV/Phong, chi doi Thu/Buoi/Tiet).

    DECLARE @RunID INT, @MaLop VARCHAR(10), @MaGV VARCHAR(10), @MaPhong VARCHAR(10);
    SELECT @RunID = RunID, @MaLop = MaLop, @MaGV = MaGV, @MaPhong = MaPhong
    FROM tblTKB_KetQuaXep WHERE ID = @ID;

    IF @RunID IS NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy tiết học này' AS Message;
        RETURN;
    END

    -- O dich phai dang TRONG cho chinh lop nay (khong ai khac cua lop dang chiem gio do).
    IF EXISTS (
        SELECT 1 FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID AND MaLop = @MaLop AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet AND ID <> @ID
    )
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Khung giờ đích không còn trống cho lớp này' AS Message;
        RETURN;
    END

    -- GV khong duoc trung lich o khung gio dich (lop khac).
    DECLARE @TrungGV VARCHAR(10);
    SELECT TOP 1 @TrungGV = MaLop FROM tblTKB_KetQuaXep
    WHERE RunID = @RunID AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet AND ID <> @ID AND MaGV = @MaGV;
    IF @TrungGV IS NOT NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Giáo viên đã dạy lớp ' + @TrungGV + N' cùng khung giờ này' AS Message;
        RETURN;
    END

    IF @MaPhong IS NOT NULL
    BEGIN
        DECLARE @TrungPhong VARCHAR(10);
        SELECT TOP 1 @TrungPhong = MaLop FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID AND Thu = @Thu AND Buoi = @Buoi AND Tiet = @Tiet AND ID <> @ID AND MaPhong = @MaPhong;
        IF @TrungPhong IS NOT NULL
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Phòng đã được lớp ' + @TrungPhong + N' dùng cùng khung giờ này' AS Message;
            RETURN;
        END
    END

    UPDATE tblTKB_KetQuaXep SET Thu = @Thu, Buoi = @Buoi, Tiet = @Tiet WHERE ID = @ID;

    -- Nguoi dung chu dong keo-tha tiet nay -> danh dau da khoa tay (2026-09-02), xem tblTKB_KetQuaXep_Khoa.
    IF NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID = @ID)
        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime) VALUES (@ID, @sys_UserID, GETDATE());

    SELECT CAST(1 AS BIT) AS Success, N'Đã chuyển tiết' AS Message;
END
